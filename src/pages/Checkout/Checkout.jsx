import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useCart } from '../../context/CartContext';
import { supabase } from '../../supabaseClient';
import { validateCoupon, calculateDiscount, incrementCouponUsage } from '@/services/supabase/couponService';
import { getDiscountedPrice } from '@/utils/formatters';
import { ChevronRight, MapPin, Phone, User, CheckCircle2, ShieldCheck, Loader2, Ticket, X, Check } from 'lucide-react';

const Checkout = () => {
    const {
        cartItems, subtotal, discountAmount, totalAmount,
        coupon, couponCode, setCouponCode, couponError, setCouponError, couponLoading, applyCoupon, removeCoupon,
        clearCart, isHydrated, isSyncing
    } = useCart();
    const navigate = useNavigate();

    const [user, setUser] = useState(null);
    const [loadingAuth, setLoadingAuth] = useState(true);
    const [placingOrder, setPlacingOrder] = useState(false);
    const [errorMsg, setErrorMsg] = useState('');
    const [fieldErrors, setFieldErrors] = useState({});

    const [form, setForm] = useState({
        fullName: '',
        phone: '',
        city: '',
        otherCity: '',
        address: '',
        notes: ''
    });

    // Local input for coupon to allow typing without immediately syncing context code
    const [localCouponInput, setLocalCouponInput] = useState(couponCode || '');
    useEffect(() => { setLocalCouponInput(couponCode || ''); }, [couponCode]);

    const shippingCost = 0;
    // total already from context includes discount; keep shipping 0
    const displayTotal = totalAmount + shippingCost;
    const couponApplied = !!coupon;

    useEffect(() => {
        const checkAuth = async () => {
            const { data: { session } } = await supabase.auth.getSession();
            setUser(session?.user || null);
            setLoadingAuth(false);
        };
        checkAuth();
    }, []);

    // C-CART-03: انتظار hydration قبل اتخاذ قرار السلة الفارغة
    useEffect(() => {
        if (!isHydrated || isSyncing) return;
        if (cartItems.length === 0) {
            navigate('/catalog');
        }
    }, [navigate, cartItems.length, isHydrated, isSyncing]);

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setForm({ ...form, [name]: value });
        if (errorMsg) setErrorMsg('');
        if (fieldErrors[name]) setFieldErrors(prev => ({ ...prev, [name]: '' }));
    };

    const handleApplyCoupon = async () => {
        const code = (localCouponInput || '').trim();
        if (!code) { setCouponError('أدخل كود الكوبون'); return; }
        if (couponApplied) { setCouponError('تم تطبيق كوبون بالفعل'); return; }
        const res = await applyCoupon(code);
        if (!res.valid) {
            // error already set in context
        }
    };
    const handleRemoveCoupon = () => { removeCoupon(); setLocalCouponInput(''); };

    const validateForm = () => {
        const errs = {};
        if (!form.fullName.trim() || form.fullName.trim().length < 3) errs.fullName = 'الاسم يجب أن يكون 3 أحرف على الأقل';
        const phoneDigits = form.phone.replace(/\D/g,'');
        if (phoneDigits.length < 10 || phoneDigits.length > 15) errs.phone = 'رقم الهاتف غير صحيح (10-15 رقم)';
        if (!form.city) errs.city = 'اختر المدينة';
        if (form.city === 'مدينة أخرى' && !form.otherCity.trim()) errs.otherCity = 'حدد المدينة';
        if (form.city === 'مدينة أخرى' && form.otherCity.trim().length < 2) errs.otherCity = 'اسم المدينة غير صحيح';
        if (!form.address.trim() || form.address.trim().length < 8) errs.address = 'العنوان يجب أن يكون 8 أحرف على الأقل';

        if (Object.keys(errs).length > 0) {
            setFieldErrors(errs);
            // C-CHK-06: رسائل حقلية بدل رسالة عامة
            const first = Object.values(errs)[0];
            setErrorMsg(first);
            return false;
        }
        setFieldErrors({});
        return true;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setErrorMsg('');
        // C-CART-03: منع الطلب قبل اكتمال hydration
        if (!isHydrated) { setErrorMsg('جارٍ تحميل بيانات السلة، حاول مرة أخرى لحظات'); return; }
        if (isSyncing) { setErrorMsg('جارٍ مزامنة السلة... انتظر لحظات'); return; }
        if (cartItems.length === 0) { setErrorMsg('السلة فارغة'); navigate('/catalog'); return; }
        if (!validateForm()) return;
        if (coupon && discountAmount > subtotal) { setErrorMsg('الخصم أكبر من الإجمالي'); return; }
        setPlacingOrder(true);

        let createdOrderId = null;
        try {
            // C-COUP-02 + C-COUP-06: إعادة validateCoupon قبل الدفع وحساب الخصم server-side
            let freshCoupon = coupon;
            if (coupon) {
                const reval = await validateCoupon(coupon.code);
                if (!reval.valid) {
                    setCouponError(reval.error);
                    removeCoupon();
                    setErrorMsg(`الكوبون لم يعد صالحاً: ${reval.error}`);
                    setPlacingOrder(false);
                    return;
                }
                freshCoupon = reval.coupon;
            }

            // C-CART-06 + C-CHK-02 + C-CART-01: جلب stock حقيقي وأسعار حقيقية من السيرفر
            const ids = cartItems.map(i => i.id);
            let productsDB = [];
            try {
                const { data, error: prodErr } = await supabase.from('products').select('id, base_price, discount, price, sale_price, stock_quantity').in('id', ids);
                if (prodErr) throw prodErr;
                productsDB = data || [];
            } catch(fetchErr){
                console.warn('stock fetch failed, fallback to local check', fetchErr?.message);
                // fallback: if fetch fails (offline), keep local check but warn
                for (const item of cartItems) {
                    if (item.stock_quantity !== undefined && item.quantity > item.stock_quantity) {
                        throw new Error(`الكمية المطلوبة لـ ${item.name} غير متوفرة (المتاح: ${item.stock_quantity})`);
                    }
                }
            }
            const prodMap = new Map(productsDB.map(p => [p.id, p]));
            // إذا نجح الجلب، تحقق دقيق
            if (productsDB.length > 0) {
                for (const item of cartItems) {
                    const dbProd = prodMap.get(item.id);
                    if (!dbProd) {
                        throw new Error(`المنتج ${item.name} غير متوفر حالياً`);
                    }
                    const serverStock = dbProd.stock_quantity;
                    if (serverStock != null && Number(item.quantity) > Number(serverStock)) {
                        throw new Error(`الكمية المطلوبة لـ ${item.name} غير متوفرة (المتاح: ${serverStock})`);
                    }
                    // C-CART-01: كشف تلاعب السعر - لا نثق بسعر العميل
                    const serverPrice = getDiscountedPrice(dbProd);
                    if (Math.abs(serverPrice - Number(item.price)) > 0.01) {
                        console.warn(`Price tamper detected for ${item.id}: client ${item.price} vs server ${serverPrice} - using server price`);
                    }
                }
            }

            // حساب الإجمالي بالأسعار الحقيقية (C-CART-01 + C-COUP-06)
            let serverSubtotal = subtotal;
            let serverTotal = displayTotal;
            let serverDiscount = discountAmount;
            let unitPrices = new Map(cartItems.map(i => [i.id, Number(i.price)||0]));
            if (productsDB.length > 0) {
                serverSubtotal = cartItems.reduce((acc, item) => {
                    const dbProd = prodMap.get(item.id);
                    const sp = dbProd ? getDiscountedPrice(dbProd) : Number(item.price) || 0;
                    unitPrices.set(item.id, sp);
                    return acc + sp * (Number(item.quantity) || 0);
                }, 0);
                serverDiscount = freshCoupon ? calculateDiscount(serverSubtotal, freshCoupon) : 0;
                if (serverDiscount > serverSubtotal) serverDiscount = serverSubtotal;
                serverTotal = Math.max(0, serverSubtotal - serverDiscount + shippingCost);
            } else {
                if (freshCoupon) {
                    serverDiscount = calculateDiscount(serverSubtotal, freshCoupon);
                    serverTotal = Math.max(0, serverSubtotal - serverDiscount + shippingCost);
                }
            }

            const resolvedCity = form.city === 'مدينة أخرى' ? form.otherCity.trim() : form.city;
            const shippingAddressPayload = JSON.stringify({
                city: resolvedCity,
                originalCity: form.city,
                otherCity: form.city === 'مدينة أخرى' ? form.otherCity.trim() : null,
                address: form.address,
                phone: form.phone,
                name: form.fullName
            });

            // C-CHK-01: تحسين error handling والـ rollback
            const { data, error } = await supabase.from('orders').insert({
                user_id: user?.id || null,
                total_amount: serverTotal,
                status: 'pending',
                customer_name: form.fullName,
                shipping_address: shippingAddressPayload,
                contact_phone: form.phone,
                notes: form.notes,
                payment_status: 'unpaid',
                shipping_cost: shippingCost,
                coupon_id: freshCoupon?.id && !String(freshCoupon.id).startsWith('mock-') ? freshCoupon.id : null,
                coupon_code: freshCoupon?.code || null,
                discount_amount: serverDiscount
            }).select().single();

            if (error) throw error;
            createdOrderId = data.id;

            const orderItems = cartItems.map(item => ({
                order_id: data.id,
                product_id: item.id,
                quantity: item.quantity,
                unit_price: unitPrices.get(item.id) ?? (Number(item.price) || 0),
                options: item.options || {}
            }));

            const { error: itemsError } = await supabase.from('order_items').insert(orderItems);
            if (itemsError) {
                // rollback order if items failed
                try { await supabase.from('orders').delete().eq('id', data.id); } catch (rbErr) { console.error('rollback failed', rbErr); }
                throw new Error(itemsError.message || 'فشل حفظ عناصر الطلب');
            }

            // Decrement stock + increment coupon usage (best effort)
            try {
                for (const item of cartItems) {
                    if (item.id) {
                        await supabase.rpc('decrement_stock', { p_product_id: item.id, p_qty: item.quantity }).then(r=>{
                            if (r.error) throw r.error;
                        }).catch(async ()=> {
                            const { data: prod } = await supabase.from('products').select('stock_quantity').eq('id', item.id).single();
                            if (prod) await supabase.from('products').update({ stock_quantity: Math.max(0, (prod.stock_quantity||0) - item.quantity) }).eq('id', item.id);
                        });
                    }
                }
                if (freshCoupon?.id) await incrementCouponUsage(freshCoupon.id);
            } catch (stockErr) { console.warn('stock/coupon post-process failed', stockErr); }

            clearCart();
            navigate(`/checkout/success?id=${data.id}`);

        } catch (error) {
            console.error('Error placing order:', error);
            // C-CHK-06: رسائل أوضح
            let msg = error.message || 'حدث خطأ أثناء إنشاء الطلب. حاول مرة أخرى.';
            if (msg.includes('stock') || msg.includes('المتاح')) msg = msg;
            else if (msg.includes('duplicate') || msg.includes('unique')) msg = 'حدث تعارض أثناء الحفظ، حاول مرة أخرى';
            setErrorMsg(msg);
        } finally {
            setPlacingOrder(false);
        }
    };

    if (loadingAuth || !isHydrated) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-slate-50">
                <Loader2 size={40} className="text-orange-600 animate-spin" />
            </div>
        );
    }

    const inputBase = "w-full bg-slate-50 border rounded-3xl px-5 py-4 text-slate-900 text-sm focus:outline-none focus:ring-4 focus:ring-orange-500/10 transition-all placeholder:text-slate-400 font-medium";
    const inputNormal = "border-slate-200/60 focus:border-orange-500";
    const inputError = "border-red-300 bg-red-50 focus:border-red-400 focus:ring-red-500/10";
    const labelClasses = "flex items-center gap-2 text-[11px] font-black text-slate-500 uppercase tracking-widest mb-2 mr-1";

    const fieldClass = (name) => `${inputBase} ${fieldErrors[name] ? inputError : inputNormal}`;

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
                                        <input required name="fullName" value={form.fullName} onChange={handleInputChange} type="text" placeholder="مثال: أحمد محمد" className={fieldClass('fullName')} aria-invalid={!!fieldErrors.fullName} />
                                        {fieldErrors.fullName && <p className="text-xs font-bold text-red-600 mt-1 pr-1">{fieldErrors.fullName}</p>}
                                    </div>
                                    <div>
                                        <label className={labelClasses}><Phone size={14}/> رقم الهاتف</label>
                                        <input required name="phone" value={form.phone} onChange={handleInputChange} type="tel" placeholder="01XXXXXXXXX" className={fieldClass('phone')} dir="ltr" pattern="[0-9+ ]{10,15}" aria-invalid={!!fieldErrors.phone} />
                                        {fieldErrors.phone && <p className="text-xs font-bold text-red-600 mt-1 pr-1">{fieldErrors.phone}</p>}
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
                                        <select required name="city" value={form.city} onChange={handleInputChange} className={`${fieldClass('city')} appearance-none`} aria-invalid={!!fieldErrors.city}>
                                            <option value="">اختر المدينة...</option>
                                            <option value="القاهرة">القاهرة</option>
                                            <option value="الجيزة">الجيزة</option>
                                            <option value="الإسكندرية">الإسكندرية</option>
                                            <option value="المنصورة">المنصورة</option>
                                            <option value="طنطا">طنطا</option>
                                            <option value="أسيوط">أسيوط</option>
                                            <option value="مدينة أخرى">مدينة أخرى</option>
                                        </select>
                                        {fieldErrors.city && <p className="text-xs font-bold text-red-600 mt-1 pr-1">{fieldErrors.city}</p>}
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
                                                className={fieldClass('otherCity')}
                                                aria-invalid={!!fieldErrors.otherCity}
                                            />
                                            {fieldErrors.otherCity && <p className="text-xs font-bold text-red-600 mt-1 pr-1">{fieldErrors.otherCity}</p>}
                                        </div>
                                    )}
                                    <div>
                                        <label className={labelClasses}>العنوان التفصيلي</label>
                                        <input required name="address" value={form.address} onChange={handleInputChange} type="text" placeholder="مثال: شارع 15، عمارة 3، شقة 12" className={fieldClass('address')} aria-invalid={!!fieldErrors.address} />
                                        {fieldErrors.address && <p className="text-xs font-bold text-red-600 mt-1 pr-1">{fieldErrors.address}</p>}
                                    </div>
                                    <div>
                                        <label className={labelClasses}>ملاحظات (اختياري)</label>
                                        <textarea name="notes" value={form.notes} onChange={handleInputChange} placeholder="أي ملاحظات إضافية..." className={`${fieldClass('notes')} resize-none h-24`} />
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
                        {/* Coupon — متزامن مع السلة */}
                        <div className="p-6 bg-white border border-slate-200 rounded-[2rem] shadow-sm">
                            <h3 className="text-sm font-black text-slate-900 mb-3 flex items-center gap-2"><Ticket size={16} className="text-orange-600"/> كود الخصم {coupon && <span className="mr-auto text-[10px] bg-emerald-50 text-emerald-700 border border-emerald-200 px-2 py-1 rounded-full">مُطبق من السلة</span>}</h3>
                            {!coupon ? (
                                <div className="flex gap-2">
                                    <input value={localCouponInput} onChange={e=>setLocalCouponInput(e.target.value.toUpperCase())} placeholder="WELCOME20" disabled={couponLoading} className="flex-1 bg-slate-50 border border-slate-200 rounded-2xl px-4 py-3 text-sm font-mono tracking-widest text-center uppercase focus:outline-none focus:ring-2 focus:ring-orange-500/20 disabled:opacity-50" />
                                    <button type="button" onClick={handleApplyCoupon} disabled={couponLoading || !localCouponInput.trim()} className="px-5 py-3 bg-slate-900 text-white rounded-2xl text-sm font-bold hover:bg-orange-600 disabled:opacity-50 flex items-center gap-2">
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
                                        <span className="text-3xl font-black">{displayTotal.toLocaleString()}</span>
                                        <span className="text-sm ml-1 text-slate-400 font-bold">ج.م</span>
                                    </div>
                                </div>
                            </div>
                            <button type="submit" form="checkout-form" disabled={placingOrder || !isHydrated || isSyncing} className="w-full mt-8 py-4 bg-orange-600 hover:bg-orange-500 text-white rounded-[2rem] font-bold text-lg flex items-center justify-center gap-3 transition-all shadow-xl shadow-orange-600/20 active:scale-95 disabled:opacity-50">
                                {placingOrder ? <><Loader2 size={20} className="animate-spin" /> جارٍ تأكيد الطلب...</> : <><CheckCircle2 size={20} /> تأكيد الطلب</>}
                            </button>
                            {!isHydrated && <p className="text-xs text-amber-400 text-center mt-3 font-bold">جارٍ تحميل السلة...</p>}
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
