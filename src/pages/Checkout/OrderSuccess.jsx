import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Link, useSearchParams } from 'react-router-dom';
import { CheckCircle2, Package, ShoppingBag, Loader2, Phone, MessageCircle, Home, Truck, ShieldCheck, Clock3 } from 'lucide-react';
import confetti from 'canvas-confetti';
import { supabase } from '@/supabaseClient';

const OrderSuccess = () => {
    const [searchParams] = useSearchParams();
    const orderId = searchParams.get('id');
    const [order, setOrder] = useState(null);
    const [loadingOrder, setLoadingOrder] = useState(!!orderId);
    const [orderError, setOrderError] = useState('');

    useEffect(() => {
        // C-CHK-07: respect prefers-reduced-motion
        const prefersReduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        if (prefersReduced) return;
        // Trigger confetti on mount
        const duration = 3 * 1000;
        const animationEnd = Date.now() + duration;
        const defaults = { startVelocity: 30, spread: 360, ticks: 60, zIndex: 0 };

        const randomInRange = (min, max) => Math.random() * (max - min) + min;

        const interval = setInterval(function() {
            const timeLeft = animationEnd - Date.now();

            if (timeLeft <= 0) {
                return clearInterval(interval);
            }

            const particleCount = 50 * (timeLeft / duration);
            confetti(Object.assign({}, defaults, { particleCount, origin: { x: randomInRange(0.1, 0.3), y: Math.random() - 0.2 } }));
            confetti(Object.assign({}, defaults, { particleCount, origin: { x: randomInRange(0.7, 0.9), y: Math.random() - 0.2 } }));
        }, 250);

        return () => clearInterval(interval);
    }, []);

    // C-CHK-03: جلب بيانات الطلب وتحقق الملكية
    useEffect(() => {
        if (!orderId) { setLoadingOrder(false); return; }
        let cancelled = false;
        (async () => {
            setLoadingOrder(true);
            try {
                const { data: { user } } = await supabase.auth.getUser();
                const { data, error } = await supabase.from('orders').select('id, total_amount, status, customer_name, user_id').eq('id', orderId).single();
                if (cancelled) return;
                if (error) throw error;
                if (!data) { setOrderError('الطلب غير موجود'); return; }
                // تحقق ملكية: إذا الطلب مرتبط بمستخدم والمسجل ليس نفس المستخدم => إخفاء التفاصيل الحساسة
                if (data.user_id && user && data.user_id !== user.id) {
                    setOrderError('ليس لديك صلاحية عرض هذا الطلب');
                    setOrder(null);
                    return;
                }
                setOrder(data);
            } catch (e) {
                if (!cancelled) setOrderError(e.message || 'تعذر جلب بيانات الطلب');
            } finally {
                if (!cancelled) setLoadingOrder(false);
            }
        })();
        return () => { cancelled = true; };
    }, [orderId]);

    const shortId = orderId ? orderId.split('-')[0].toUpperCase() : '—';
    const waNumber = '201284858999';
    const waMessage = encodeURIComponent(`مرحبا آل مسعد 👋\nأستفسر عن طلبي رقم #${shortId}\n${order ? `الإجمالي: ${Number(order.total_amount).toLocaleString()} ج.م` : ''}`);

    return (
        <div className="min-h-screen bg-[#f8fafc] flex items-center justify-center p-4 py-10" dir="rtl">
            <motion.div
                initial={{ opacity: 0, scale: 0.96, y: 16 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                transition={{ type: "spring", stiffness: 220, damping: 22 }}
                className="max-w-[520px] w-full bg-white rounded-[2.5rem] overflow-hidden shadow-[0_24px_64px_rgba(15,23,42,0.12)] border border-slate-100"
            >
                {/* Brand header – آل مسعد */}
                <div className="bg-slate-900 px-8 py-6 text-white relative overflow-hidden">
                    <div className="absolute -top-10 -left-10 w-32 h-32 bg-orange-500/20 rounded-full blur-2xl" />
                    <div className="absolute -bottom-8 -right-8 w-24 h-24 bg-white/5 rounded-full" />
                    <div className="relative flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-2xl bg-white text-slate-900 flex items-center justify-center font-black text-sm">آل</div>
                            <div>
                                <p className="font-black text-[18px] leading-none tracking-tight">آل مسعد</p>
                                <p className="text-[11px] font-bold tracking-[0.18em] text-orange-300 uppercase">Al Mossad Store</p>
                            </div>
                        </div>
                        <span className="text-[11px] font-black bg-white/10 border border-white/10 px-3 py-1.5 rounded-full backdrop-blur">الدفع عند الاستلام ✓</span>
                    </div>
                </div>

                <div className="p-8 sm:p-10 text-center">
                    <motion.div
                        initial={{ scale: 0 }}
                        animate={{ scale: 1 }}
                        transition={{ delay: 0.15, type: "spring", stiffness: 260 }}
                        className="w-[88px] h-[88px] bg-gradient-to-br from-emerald-500 to-green-600 rounded-[1.75rem] flex items-center justify-center mx-auto mb-6 shadow-xl shadow-emerald-500/20 relative"
                    >
                        <CheckCircle2 size={44} className="text-white" strokeWidth={2.6} />
                        <span className="absolute -top-1 -right-1 w-6 h-6 bg-orange-500 border-2 border-white rounded-full flex items-center justify-center text-white text-[10px] font-black">✓</span>
                    </motion.div>

                    <h1 className="text-[28px] font-black text-slate-900 leading-none tracking-tight">تم استلام طلبك بنجاح!</h1>
                    <p className="text-[14px] font-bold text-slate-500 mt-3 leading-relaxed">
                        شكراً لثقتك في <span className="text-slate-900 font-black">آل مسعد</span> لتجارة الحدايد والبويات.<br />
                        طلبك الآن <span className="text-orange-600">قيد المراجعة</span> وسيتواصل معك فريقنا خلال ساعات لتأكيد التفاصيل.
                    </p>

                    {/* Order card – Branded */}
                    <div className="mt-8 bg-slate-50 rounded-[1.75rem] p-5 border border-slate-100 text-right">
                        <div className="flex items-start justify-between gap-4">
                            <div className="flex-1">
                                <p className="text-[11px] font-black tracking-widest text-slate-400 uppercase">رقم الطلب • آل مسعد</p>
                                {loadingOrder ? (
                                    <span className="flex items-center gap-2 text-slate-500 text-sm font-bold mt-1"><Loader2 size={16} className="animate-spin" /> جارٍ التحميل...</span>
                                ) : orderError ? (
                                    <p className="text-xs font-bold text-red-600 mt-1">{orderError}</p>
                                ) : (
                                    <p className="font-mono text-[20px] font-black text-slate-900 tracking-wide mt-1">#{shortId}</p>
                                )}
                                {order && (
                                    <div className="mt-3 flex flex-wrap gap-2">
                                        <span className="inline-flex items-center gap-1.5 bg-white border border-slate-200 rounded-full px-3 py-1.5 text-xs font-black text-slate-700">
                                            <Clock3 size={12} className="text-orange-500" /> {order.status === 'pending' ? 'قيد المراجعة' : order.status}
                                        </span>
                                        <span className="inline-flex items-center bg-slate-900 text-white rounded-full px-3 py-1.5 text-xs font-black">
                                            {Number(order.total_amount).toLocaleString()} ج.م
                                        </span>
                                    </div>
                                )}
                                <p className="text-[11px] font-bold text-slate-400 mt-3 flex items-center gap-1.5">
                                    <ShieldCheck size={12} className="text-emerald-500" /> طلبك محفوظ وآمن • الدفع عند الاستلام
                                </p>
                            </div>
                            <div className="w-14 h-14 bg-white rounded-2xl flex items-center justify-center shadow-sm border border-slate-100 shrink-0">
                                <Package size={26} className="text-orange-600" />
                            </div>
                        </div>

                        {/* Next steps */}
                        <div className="mt-5 grid grid-cols-3 gap-2">
                            {[
                                { icon: Clock3, label: 'مراجعة', sub: 'خلال ساعات' },
                                { icon: Phone, label: 'تأكيد', sub: 'اتصال هاتفي' },
                                { icon: Truck, label: 'توصيل', sub: 'حتى باب البيت' },
                            ].map(s => (
                                <div key={s.label} className="bg-white border border-slate-100 rounded-2xl p-3 text-center">
                                    <s.icon size={16} className="mx-auto text-slate-700 mb-1" />
                                    <p className="text-[11px] font-black text-slate-900">{s.label}</p>
                                    <p className="text-[10px] font-bold text-slate-400">{s.sub}</p>
                                </div>
                            ))}
                        </div>
                    </div>

                    {/* Trust + contact */}
                    <div className="mt-6 bg-orange-50 border border-orange-100 rounded-2xl p-4 flex items-center gap-3 text-right">
                        <div className="w-10 h-10 rounded-xl bg-white border border-orange-100 flex items-center justify-center shrink-0">
                            <MessageCircle size={18} className="text-orange-600" />
                        </div>
                        <div className="flex-1">
                            <p className="text-xs font-black text-slate-900">تحتاج مساعدة؟ تواصل مع آل مسعد مباشرة</p>
                            <p className="text-[11px] font-bold text-slate-500">39 شارع ربيع الجيزي - الجيزة • 01284858999</p>
                        </div>
                        <a href={`https://wa.me/${waNumber}?text=${waMessage}`} target="_blank" rel="noreferrer" className="shrink-0 bg-[#25D366] hover:bg-[#1ebe5d] text-white rounded-xl px-4 py-2.5 text-xs font-black transition-colors">
                            واتساب
                        </a>
                    </div>

                    {/* Actions */}
                    <div className="mt-8 space-y-3">
                        <Link to="/catalog" className="w-full py-4 bg-slate-900 hover:bg-orange-600 text-white rounded-2xl font-black text-[15px] flex items-center justify-center gap-2 transition-colors shadow-lg shadow-slate-900/10 active:scale-[0.98]">
                            <ShoppingBag size={18} /> متابعة التسوق
                        </Link>
                        <div className="grid grid-cols-2 gap-3">
                            <Link to="/" className="py-3.5 bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 rounded-2xl font-black text-sm flex items-center justify-center gap-1.5 transition-colors">
                                <Home size={16} /> الرئيسية
                            </Link>
                            <a href={`https://wa.me/${waNumber}?text=${waMessage}`} target="_blank" rel="noreferrer" className="py-3.5 bg-emerald-50 border border-emerald-200 hover:bg-emerald-100 text-emerald-700 rounded-2xl font-black text-sm flex items-center justify-center gap-1.5 transition-colors">
                                <MessageCircle size={16} /> متابعة الطلب
                            </a>
                        </div>
                        <p className="text-[11px] font-bold text-slate-400 pt-1">ستصلك رسالة تأكيد على الهاتف خلال قليل • شكراً لاختيارك آل مسعد ❤️</p>
                    </div>
                </div>

                <div className="bg-slate-50 border-t border-slate-100 px-8 py-4 flex items-center justify-center gap-2 text-[11px] font-bold text-slate-400">
                    <span>© {new Date().getFullYear()} آل مسعد لتجارة الحدايد والبويات</span>
                    <span className="w-1 h-1 bg-slate-300 rounded-full" />
                    <span className="text-slate-500">جميع الحقوق محفوظة</span>
                </div>
            </motion.div>
        </div>
    );
};

export default OrderSuccess;
