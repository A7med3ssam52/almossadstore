import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useCart } from '../../context/CartContext';
import { supabase } from '../../supabaseClient';
import { ChevronRight, MapPin, Phone, User, CheckCircle2, ShieldCheck, Loader2 } from 'lucide-react';

const Checkout = () => {
    const { cartItems, subtotal, clearCart } = useCart();
    const navigate = useNavigate();
    
    const [user, setUser] = useState(null);
    const [loadingAuth, setLoadingAuth] = useState(true);
    const [placingOrder, setPlacingOrder] = useState(false);
    
    const [form, setForm] = useState({
        fullName: '',
        phone: '',
        city: '',
        address: '',
        notes: ''
    });

    // 1. Auth Guard & Initial Hydration
    useEffect(() => {
        const checkAuth = async () => {
            const { data: { session } } = await supabase.auth.getSession();
            if (!session) {
                // Allow guest checkout
                setLoadingAuth(false);
            } else {
                setUser(session.user);
                setLoadingAuth(false);
            }
        };

        if (cartItems.length === 0) {
            navigate('/catalog'); // Don't allow empty checkout
            return;
        }

        checkAuth();
    }, [navigate, cartItems.length]);

    // 2. Handlers
    const handleInputChange = (e) => {
        setForm({ ...form, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setPlacingOrder(true);

        try {
            // Calculate final totals (Add shipping if applicable, here we assume free shipping for simplicity)
            const shippingCost = 0; 
            const totalAmount = subtotal + shippingCost;

            // Prepare Order Payload
            const orderData = {
                user_id: user?.id || null,
                status: 'pending',
                total_amount: totalAmount,
                shipping_address: `${form.city} - ${form.address}`,
                contact_phone: form.phone,
                customer_name: form.fullName, // Additional metadata
                items: cartItems.map(item => ({
                    product_id: item.id,
                    quantity: item.quantity,
                    unit_price: item.price,
                    options: item.options
                }))
            };

            // Assuming `createOrder` handles both the order header and the items
            // You might need to adjust this based on your exact Supabase schema
            const { data, error } = await supabase.from('orders').insert({
                user_id: user?.id || null,
                total_amount: totalAmount,
                status: 'pending',
                customer_name: form.fullName,
                shipping_address: orderData.shipping_address,
                contact_phone: orderData.contact_phone,
                notes: form.notes,
                payment_status: 'unpaid',
                shipping_cost: shippingCost
            }).select().single();

            if (error) throw error;

            // Insert Items
            const orderItems = orderData.items.map(item => ({
                order_id: data.id,
                ...item
            }));

            const { error: itemsError } = await supabase.from('order_items').insert(orderItems);
            if (itemsError) throw itemsError;

            // Success!
            clearCart();
            navigate(`/checkout/success?id=${data.id}`);

        } catch (error) {
            console.error('Error placing order:', error);
            alert('حدث خطأ أثناء إتمام الطلب، يرجى المحاولة مرة أخرى.');
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
                {/* Header */}
                <div className="flex items-center justify-between mb-8">
                    <h1 className="text-3xl font-black text-slate-900">إتمام الطلب</h1>
                    <button onClick={() => navigate(-1)} className="flex items-center gap-2 text-sm font-bold text-slate-500 hover:text-slate-900 transition-colors">
                        العودة للسلة <ChevronRight size={16} />
                    </button>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
                    
                    {/* Left Column (Forms) */}
                    <div className="lg:col-span-2 space-y-6">
                        <form id="checkout-form" onSubmit={handleSubmit} className="p-8 bg-white border border-slate-100 shadow-xl shadow-slate-900/5 rounded-[2.5rem] space-y-8">
                            
                            {/* Section 1: Contact Info */}
                            <div>
                                <h2 className="text-xl font-black text-slate-900 mb-6 flex items-center gap-3">
                                    <div className="w-8 h-8 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center text-sm">1</div>
                                    بيانات الاتصال
                                </h2>
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                                    <div>
                                        <label className={labelClasses}><User size={14}/> الاسم بالكامل</label>
                                        <input required name="fullName" value={form.fullName} onChange={handleInputChange} type="text" placeholder="الاسم ثلاثي" className={inputClasses} />
                                    </div>
                                    <div>
                                        <label className={labelClasses}><Phone size={14}/> رقم الجوال</label>
                                        <input required name="phone" value={form.phone} onChange={handleInputChange} type="tel" placeholder="05XXXXXXXX" className={inputClasses} dir="ltr" />
                                    </div>
                                </div>
                            </div>

                            <hr className="border-slate-100" />

                            {/* Section 2: Shipping Info */}
                            <div>
                                <h2 className="text-xl font-black text-slate-900 mb-6 flex items-center gap-3">
                                    <div className="w-8 h-8 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center text-sm">2</div>
                                    عنوان التوصيل
                                </h2>
                                <div className="space-y-5">
                                    <div>
                                        <label className={labelClasses}><MapPin size={14}/> المدينة</label>
                                        <select required name="city" value={form.city} onChange={handleInputChange} className={`${inputClasses} appearance-none`}>
                                            <option value="">اختر المدينة...</option>
                                            <option value="الرياض">الرياض</option>
                                            <option value="جدة">جدة</option>
                                            <option value="الدمام">الدمام</option>
                                            <option value="مكة المكرمة">مكة المكرمة</option>
                                            <option value="المدينة المنورة">المدينة المنورة</option>
                                        </select>
                                    </div>
                                    <div>
                                        <label className={labelClasses}>تفاصيل العنوان (الحي، الشارع، المبنى)</label>
                                        <input required name="address" value={form.address} onChange={handleInputChange} type="text" placeholder="مثال: حي الياسمين، شارع العليا، مبنى 12" className={inputClasses} />
                                    </div>
                                    <div>
                                        <label className={labelClasses}>ملاحظات إضافية (اختياري)</label>
                                        <textarea name="notes" value={form.notes} onChange={handleInputChange} placeholder="أي تعليمات خاصة بالتوصيل..." className={`${inputClasses} resize-none h-24`} />
                                    </div>
                                </div>
                            </div>

                            <hr className="border-slate-100" />

                            {/* Section 3: Payment */}
                            <div>
                                <h2 className="text-xl font-black text-slate-900 mb-6 flex items-center gap-3">
                                    <div className="w-8 h-8 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center text-sm">3</div>
                                    طريقة الدفع
                                </h2>
                                <div className="p-5 border-2 border-orange-500 bg-orange-50/50 rounded-3xl flex items-start gap-4 cursor-pointer relative overflow-hidden">
                                    <div className="absolute top-0 right-0 w-16 h-16 bg-gradient-to-br from-orange-500 to-orange-400 opacity-10 rounded-bl-full" />
                                    <div className="mt-1">
                                        <div className="w-5 h-5 rounded-full border-4 border-orange-500 bg-white" />
                                    </div>
                                    <div>
                                        <h3 className="font-black text-slate-900 text-lg">الدفع عند الاستلام (COD)</h3>
                                        <p className="text-sm font-bold text-slate-500 mt-1">ادفع نقداً أو بالبطاقة عند استلامك للطلب.</p>
                                    </div>
                                </div>
                            </div>

                        </form>
                    </div>

                    {/* Right Column (Summary) */}
                    <div className="lg:sticky lg:top-8 space-y-6">
                        <div className="p-8 bg-slate-900 rounded-[2.5rem] text-white shadow-2xl shadow-slate-900/20">
                            <h3 className="text-xl font-black mb-6 border-b border-slate-800 pb-4">ملخص الطلب</h3>
                            
                            <div className="space-y-4 max-h-[40vh] overflow-y-auto pr-2 custom-scrollbar">
                                {cartItems.map((item, idx) => (
                                    <div key={idx} className="flex gap-4">
                                        <div className="w-16 h-16 bg-white/10 rounded-2xl p-1 shrink-0">
                                            {item.image_url ? (
                                                <img src={item.image_url} className="w-full h-full object-cover rounded-xl" alt="" />
                                            ) : (
                                                <div className="w-full h-full bg-slate-800 rounded-xl" />
                                            )}
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
                                <div className="flex justify-between text-slate-400 font-bold text-sm">
                                    <span>تكلفة الشحن</span>
                                    <span className="text-green-400">مجاناً</span>
                                </div>
                                <div className="flex justify-between items-end pt-4 border-t border-slate-800">
                                    <span className="font-bold">الإجمالي</span>
                                    <div className="text-left">
                                        <span className="text-3xl font-black">{subtotal.toLocaleString()}</span>
                                        <span className="text-sm ml-1 text-slate-400 font-bold">ج.م</span>
                                    </div>
                                </div>
                            </div>

                            <button 
                                type="submit"
                                form="checkout-form"
                                disabled={placingOrder}
                                className="w-full mt-8 py-4 bg-orange-600 hover:bg-orange-500 text-white rounded-[2rem] font-bold text-lg flex items-center justify-center gap-3 transition-all shadow-xl shadow-orange-600/20 active:scale-95 disabled:opacity-50"
                            >
                                {placingOrder ? (
                                    <><Loader2 size={20} className="animate-spin" /> جاري تأكيد الطلب...</>
                                ) : (
                                    <><CheckCircle2 size={20} /> تأكيد الطلب الآن</>
                                )}
                            </button>
                            
                            <div className="mt-6 flex items-center justify-center gap-2 text-xs font-bold text-slate-400">
                                <ShieldCheck size={14} className="text-green-400" />
                                تسوق آمن ومحمي 100%
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </div>
    );
};

export default Checkout;
