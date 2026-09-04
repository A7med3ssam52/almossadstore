import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useCart } from '../../context/CartContext';
import { supabase } from '../../supabaseClient';
import { validateCoupon, calculateDiscount, incrementCouponUsage } from '@/services/supabase/couponService';
import { ChevronRight, MapPin, Phone, User, CheckCircle2, ShieldCheck, Loader2, Ticket, X, Check } from 'lucide-react';

const Checkout = () => {
    const { cartItems, subtotal, clearCart } = useCart();
    const navigate = useNavigate();
    
    const [user, setUser] = useState(null);
    const [loadingAuth, setLoadingAuth] = useState(true);
    const [placingOrder, setPlacingOrder] = useState(false);
    const [errorMsg, setErrorMsg] = useState('');
    
    const [form, setForm] = useState({
        fullName: '',
        phone: '',
        city: '',
        otherCity: '',
        address: '',
        notes: ''
    });

    // Coupon state
    const [couponCode, setCouponCode] = useState('');
    const [coupon, setCoupon] = useState(null);
    const [couponError, setCouponError] = useState('');
    const [couponLoading, setCouponLoading] = useState(false);

    const discountAmount = coupon ? calculateDiscount(subtotal, coupon) : 0;
    const shippingCost = 0;
    const totalAmount = Math.max(0, subtotal - discountAmount + shippingCost);

    useEffect(() => {
        const checkAuth = async () => {
            const { data: { session } } = await supabase.auth.getSession();
            setUser(session?.user || null);
            setLoadingAuth(false);
        };
        if (cartItems.length === 0) {
            navigate('/catalog');
            return;
        }
        checkAuth();
    }, [navigate, cartItems.length]);

    const handleInputChange = (e) => {
        setForm({ ...form, [e.target.name]: e.target.value });
        if (errorMsg) setErrorMsg('');
    };

    const handleApplyCoupon = async () => {
        setCouponError('');
        if (!couponCode.trim()) { setCouponError('أدخل كود الكوبون'); return; }
        setCouponLoading(true);
        const res = await validateCoupon(couponCode);
        if (res.valid) {
            setCoupon(res.coupon);
            setCouponError('');
        } else {
            setCoupon(null);
            setCouponError(res.error);
        }
        setCouponLoading(false);
    };
    const handleRemoveCoupon = () => { setCoupon(null); setCouponCode(''); setCouponError(''); };

    const validateForm = () => {
        if (!form.fullName.trim() || form.fullName.trim().length < 3) { setErrorMsg('الاسم يجب أن يكون 3 أحرف على الأقل'); return false; }
        const phoneDigits = form.phone.replace(/\D/g,'');
        if (phoneDigits.length < 10 || phoneDigits.length > 15) { setErrorMsg('رقم الهاتف غير صحيح (10-15 رقم)'); return false; }
        if (!form.city) { setErrorMsg('اختر المدينة'); return false; }
        if (form.city === 'مدينة أخرى' && !form.otherCity.trim()) { setErrorMsg('حدد المدينة'); return false; }
        if (form.city === 'مدينة أخرى' && form.otherCity.trim().length < 2) { setErrorMsg('اسم المدينة غير صحيح'); return false; }
        if (!form.address.trim() || form.address.trim().length < 8) { setErrorMsg('العنوان يجب أن يكون 8 أحرف على الأقل'); return false; }
        // stock check before submit
        for (const item of cartItems) {
            if (item.stock_quantity !== undefined && item.quantity > item.stock_quantity) {
                setErrorMsg(`الكمية المطلوبة لـ ${item.name} غير متوفرة (المتاح: ${item.stock_quantity})`);
                return false;
            }
        }
        return true;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setErrorMsg('');
        if (!validateForm()) return;
        // prevent double submit if discount > subtotal
        if (coupon && discountAmount > subtotal) { setErrorMsg('الخصم أكبر من الإجمالي'); return; }
        setPlacingOrder(true);

        let createdOrderId = null;
        try {
            const resolvedCity = form.city === 'مدينة أخرى' ? form.otherCity.trim() : form.city;
            // Prepare shipping_address as JSON string for backward compat + structured
            const shippingAddressPayload = JSON.stringify({
                city: resolvedCity,
                originalCity: form.city,
                otherCity: form.city === 'مدينة أخرى' ? form.otherCity.trim() : null,
                address: form.address,
                phone: form.phone,
                name: form.fullName
            });
            // Also keep legacy text for old readers: city - address
            const legacyShippingText = `${resolvedCity} - ${form.address}`;

            const { data, error } = await supabase.from('orders').insert({
                user_id: user?.id || null,
                total_amount: totalAmount,
                status: 'pending',
                customer_name: form.fullName,
                shipping_address: shippingAddressPayload,
                contact_phone: form.phone,
                notes: form.notes,
                payment_status: 'unpaid',
                shipping_cost: shippingCost,
                coupon_id: coupon?.id && !coupon.id.startsWith('mock-') ? coupon.id : null,
                coupon_code: coupon?.code || null,
                discount_amount: discountAmount
            }).select().single();

            if (error) throw error;
            createdOrderId = data.id;

            const orderItems = cartItems.map(item => ({
                order_id: data.id,
                product_id: item.id,
                quantity: item.quantity,
                unit_price: item.price,
                options: item.options || {}
            }));

            const { error: itemsError } = await supabase.from('order_items').insert(orderItems);
            if (itemsError) {
                // rollback order if items failed (transaction simulation)
                await supabase.from('orders').delete().eq('id', data.id);
                throw itemsError;
            }

            // Decrement stock + increment coupon usage (best effort, non-blocking)
            try {
                for (const item of cartItems) {
                    if (item.id) {
                        await supabase.rpc('decrement_stock', { p_product_id: item.id, p_qty: item.quantity }).then(r=>{
                            if (r.error) throw r.error;
                        }).catch(async ()=> {
                            // fallback direct update if rpc missing
                            const { data: prod } = await supabase.from('products').select('stock_quantity').eq('id', item.id).single();
                            if (prod) await supabase.from('products').update({ stock_quantity: Math.max(0, (prod.stock_quantity||0) - item.quantity) }).eq('id', item.id);
                        });
                    }
                }
                if (coupon?.id) await incrementCouponUsage(coupon.id);
            } catch (stockErr) { console.warn('stock/coupon post-process failed', stockErr); }

            clearCart();
            navigate(`/checkout/success?id=${data.id}`);

        } catch (error) {
            console.error('Error placing order:', error);
            setErrorMsg(error.message || 'حدث خطأ أثناء إنشاء الطلب. حاول مرة أخرى.');
            // if we created order but items failed and rollback also failed, at least inform
        } finally {
            setPlacingOrder(false);
        }
    };

    if (loadingAuth) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-slate-50">
                <Loader2 size={40} className="text-orange-600 animate-spin" />
            </div>
        );
    }

    const inputClasses = "w-full bg-slate-50 border border-slate-200/60 rounded-3xl px-5 py-4 text-slate-900 text-sm focus:outline-none focus:ring-4 focus:ring-orange-500/10 focus:border-orange-500 transition-all placeholder:text-slate-400 font-medium";
    const labelClasses = "flex items-center gap-2 text-[11px] font-black text-slate-500 uppercase tracking-widest mb-2 mr-1";

    return (
        <div className="min-h-screen bg-slate-50 pt-8 pb-24" dir="rtl">
            <div className="container mx-auto px-4 max-w-6xl">
                <div className="flex items-center justify-between mb-8">
                    <h1 className="text-3xl font-black text-slate-900">إتمام الطلب</h1>
                    <button onClick={() => navigate(-1)} className="flex items-center gap-2 text-sm font-bold text-slate-500 hover:text-slate-900 transition-colors">
                        العودة <ChevronRight size={16} />
                    </button>
                </div>

                {errorMsg && (
                    <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-2xl flex items-center gap-3 text-red-700 text-sm font-bold">
                        <X size={16}/> {errorMsg}
                    </div>
                )}

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
                    <div className="lg:col-span-2 space-y-6">
                        <form id="checkout-form" onSubmit={handleSubmit} className="p-8 bg-white border border-slate-100 shadow-xl shadow-slate-900/5 rounded-[2.5rem] space-y-8">
                            <div>
                                <h2 className="text-xl font-black text-slate-900 mb-6 flex items-center gap-3">
                                    <div className="w-8 h-8 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center text-sm">1</div>
                                    معلومات التواصل
                                </h2>
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                                    <div>
                                        <label className={labelClasses}><User size={14}/> الاسم الكامل</label>
                                        <input required name="fullName" value={form.fullName} onChange={handleInputChange} type="text" placeholder="مثال: أحمد محمد" className={inputClasses} />
                                    </div>
                                    <div>
                                        <label className={labelClasses}><Phone size={14}/> رقم الهاتف</label>
                                        <input required name="phone" value={form.phone} onChange={handleInputChange} type="tel" placeholder="01XXXXXXXXX" className={inputClasses} dir="ltr" pattern="[0-9+ ]{10,15}" />
                                    </div>
                                </div>
                            </div>
                            <hr className="border-slate-100" />
                            <div>
                                <h2 className="text-xl font-black text-slate-900 mb-6 flex items-center gap-3">
                                    <div className="w-8 h-8 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center text-sm">2</div>
                                    عنوان الشحن
                                </h2>
                                <div className="space-y-5">
                                    <div>
                                        <label className={labelClasses}><MapPin size={14}/> المدينة</label>
                                        <select required name="city" value={form.city} onChange={handleInputChange} className={`${inputClasses} appearance-none`}>
                                            <option value="">اختر المدينة...</option>
                                            <option value="القاهرة">القاهرة</option>
                                            <option value="الجيزة">الجيزة</option>
                                            <option value="الإسكندرية">الإسكندرية</option>
                                            <option value="المنصورة">المنصورة</option>
                                            <option value="طنطا">طنطا</option>
                                            <option value="أسيوط">أسيوط</option>
                                            <option value="مدينة أخرى">مدينة أخرى</option>
                                        </select>
                                    </div>
                                    {form.city === 'مدينة أخرى' && (
                                        <div className="animate-fade-in">
                                            <label className={labelClasses}>حدد المدينة</label>
                                            <input
                                                required
                                                name="otherCity"
                                                value={form.otherCity}
                                                onChange={handleInputChange}
                                                type="text"
                                                placeholder="اكتب اسم مدينتك..."
                                                className={inputClasses}
                                            />
                                        </div>
                                    )}
                                    <div>
                                        <label className={labelClasses}>العنوان التفصيلي</label>
                                        <input required name="address" value={form.address} onChange={handleInputChange} type="text" placeholder="مثال: شارع 15، عمارة 3، شقة 12" className={inputClasses} />
                                    </div>
                                    <div>
                                        <label className={labelClasses}>ملاحظات (اختياري)</label>
                                        <textarea name="notes" value={form.notes} onChange={handleInputChange} placeholder="أي ملاحظات إضافية..." className={`${inputClasses} resize-none h-24`} />
                                    </div>
                                </div>
                            </div>
                            <hr className="border-slate-100" />
                            <div>
                                <h2 className="text-xl font-black text-slate-900 mb-6 flex items-center gap-3">
                                    <div className="w-8 h-8 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center text-sm">3</div>
                                    الدفع
                                </h2>
                                <div className="p-5 border-2 border-orange-500 bg-orange-50/50 rounded-3xl flex items-start gap-4 cursor-pointer relative overflow-hidden">
                                    <div className="absolute top-0 right-0 w-16 h-16 bg-gradient-to-br from-orange-500 to-orange-400 opacity-10 rounded-bl-full" />
                                    <div className="mt-1"><div className="w-5 h-5 rounded-full border-4 border-orange-500 bg-white" /></div>
                                    <div>
                                        <h3 className="font-black text-slate-900 text-lg">الدفع عند الاستلام (COD)</h3>
                                        <p className="text-sm font-bold text-slate-500 mt-1">الدفع نقداً عند استلام الطلب.</p>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>

                    <div className="lg:sticky lg:top-8 space-y-6">
                        {/* Coupon */}
                        <div className="p-6 bg-white border border-slate-200 rounded-[2rem] shadow-sm">
                            <h3 className="text-sm font-black text-slate-900 mb-3 flex items-center gap-2"><Ticket size={16} className="text-orange-600"/> كود الخصم</h3>
                            {!coupon ? (
                                <div className="flex gap-2">
                                    <input value={couponCode} onChange={e=>setCouponCode(e.target.value.toUpperCase())} placeholder="WELCOME20" className="flex-1 bg-slate-50 border border-slate-200 rounded-2xl px-4 py-3 text-sm font-mono tracking-widest text-center uppercase focus:outline-none focus:ring-2 focus:ring-orange-500/20" />
                                    <button type="button" onClick={handleApplyCoupon} disabled={couponLoading} className="px-5 py-3 bg-slate-900 text-white rounded-2xl text-sm font-bold hover:bg-orange-600 disabled:opacity-50 flex items-center gap-2">
                                        {couponLoading ? <Loader2 size={14} className="animate-spin"/> : <Check size={14}/>} تطبيق
                                    </button>
                                </div>
                            ) : (
                                <div className="flex items-center justify-between p-3 bg-green-50 border border-green-200 rounded-2xl">
                                    <span className="font-mono font-black text-green-700">{coupon.code} - {coupon.discount_type==='percentage' ? coupon.discount_value+'%' : coupon.discount_value+' ج.م'}</span>
                                    <button type="button" onClick={handleRemoveCoupon} className="p-2 text-slate-400 hover:text-red-600"><X size={16}/></button>
                                </div>
                            )}
                            {couponError && <p className="text-xs font-bold text-red-600 mt-2">{couponError}</p>}
                            {coupon && <p className="text-xs font-bold text-green-600 mt-2">تم تطبيق الخصم: {discountAmount.toLocaleString()} ج.م</p>}
                        </div>

                        <div className="p-8 bg-slate-900 rounded-[2.5rem] text-white shadow-2xl shadow-slate-900/20">
                            <h3 className="text-xl font-black mb-6 border-b border-slate-800 pb-4">ملخص الطلب</h3>
                            <div className="space-y-4 max-h-[40vh] overflow-y-auto pr-2 custom-scrollbar">
                                {cartItems.map((item, idx) => (
                                    <div key={idx} className="flex gap-4">
                                        <div className="w-16 h-16 bg-white/10 rounded-2xl p-1 shrink-0">
                                            {item.image_url || item.image ? <img src={item.image_url || item.image} className="w-full h-full object-cover rounded-xl" alt="" /> : <div className="w-full h-full bg-slate-800 rounded-xl" />}
                                        </div>
                                        <div className="flex-1">
                                            <p className="font-bold text-sm line-clamp-2 leading-tight mb-1">{item.name}</p>
                                            <p className="text-xs text-slate-400 font-bold">الكمية: {item.quantity}</p>
                                            <p className="text-sm font-black text-orange-400 mt-1">{(item.price * item.quantity).toLocaleString()} ج.م</p>
                                        </div>
                                    </div>
                                ))}
                            </div>
                            <div className="mt-6 pt-6 border-t border-slate-800 space-y-3">
                                <div className="flex justify-between text-slate-400 font-bold text-sm">
                                    <span>المجموع الفرعي</span>
                                    <span>{subtotal.toLocaleString()} ج.م</span>
                                </div>
                                {discountAmount > 0 && (
                                    <div className="flex justify-between text-green-400 font-bold text-sm">
                                        <span>خصم ({coupon.code})</span>
                                        <span>-{discountAmount.toLocaleString()} ج.م</span>
                                    </div>
                                )}
                                <div className="flex justify-between text-slate-400 font-bold text-sm">
                                    <span>الشحن</span>
                                    <span className="text-green-400">مجاني</span>
                                </div>
                                <div className="flex justify-between items-end pt-4 border-t border-slate-800">
                                    <span className="font-bold">الإجمالي</span>
                                    <div className="text-left">
                                        <span className="text-3xl font-black">{totalAmount.toLocaleString()}</span>
                                        <span className="text-sm ml-1 text-slate-400 font-bold">ج.م</span>
                                    </div>
                                </div>
                            </div>
                            <button type="submit" form="checkout-form" disabled={placingOrder} className="w-full mt-8 py-4 bg-orange-600 hover:bg-orange-500 text-white rounded-[2rem] font-bold text-lg flex items-center justify-center gap-3 transition-all shadow-xl shadow-orange-600/20 active:scale-95 disabled:opacity-50">
                                {placingOrder ? <><Loader2 size={20} className="animate-spin" /> جارٍ تأكيد الطلب...</> : <><CheckCircle2 size={20} /> تأكيد الطلب</>}
                            </button>
                            <div className="mt-6 flex items-center justify-center gap-2 text-xs font-bold text-slate-400">
                                <ShieldCheck size={14} className="text-green-400" /> دفع آمن 100%
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};
export default Checkout;