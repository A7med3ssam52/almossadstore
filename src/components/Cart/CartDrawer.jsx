import React, { useEffect, useRef, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
    X, Trash2, Plus, Minus, ShoppingBag, ArrowLeft,
    AlertTriangle, ShieldCheck, Truck, RefreshCw, Ticket, Check, Loader2, PackageSearch, Sparkles
} from 'lucide-react';
import { useCart } from '../../context/CartContext';
import { useNavigate } from 'react-router-dom';
import { formatPrice } from '@/utils/formatters';

// ── Helpers ──
const canonicalKey = (options) => {
    if (!options || typeof options !== 'object') return '{}';
    try {
        const sorted = {};
        Object.keys(options).sort().forEach((k) => (sorted[k] = options[k]));
        return JSON.stringify(sorted);
    } catch {
        return JSON.stringify(options || {});
    }
};

const CartDrawer = () => {
    const {
        isCartOpen,
        closeCart,
        cartItems,
        totalItems,
        subtotal,
        discountAmount,
        totalAmount,
        FREE_SHIPPING_THRESHOLD,
        shippingProgress,
        freeShippingRemaining,
        updateQuantity,
        removeFromCart,
        clearCart,
        coupon,
        couponCode,
        setCouponCode,
        couponError,
        couponLoading,
        applyCoupon,
        removeCoupon,
    } = useCart();

    const navigate = useNavigate();
    const closeBtnRef = useRef(null);
    const drawerRef = useRef(null);
    const [localCouponInput, setLocalCouponInput] = useState('');

    // sync local coupon input with context when coupon changes
    useEffect(() => {
        if (coupon) setLocalCouponInput(coupon.code);
        else setLocalCouponInput('');
    }, [coupon]);

    const handleCheckout = () => {
        closeCart();
        navigate('/checkout');
    };
    const handleExplore = () => {
        closeCart();
        navigate('/catalog');
    };
    const handleOffers = () => {
        closeCart();
        navigate('/offers');
    };

    const handleApplyCoupon = async () => {
        const code = (localCouponInput || '').trim().toUpperCase();
        if (!code) return;
        setCouponCode(code);
        await applyCoupon(code);
    };

    const handleClearCart = () => {
        if (cartItems.length === 0) return;
        const ok = window.confirm(`هل أنت متأكد من إفراغ السلة؟ (${cartItems.length} منتجات)`);
        if (ok) clearCart();
    };

    // ── Body scroll lock + focus trap ──
    useEffect(() => {
        if (isCartOpen) {
            const scrollBarWidth = window.innerWidth - document.documentElement.clientWidth;
            document.body.style.overflow = 'hidden';
            document.documentElement.style.scrollbarGutter = 'stable';
            if (scrollBarWidth > 0) {
                document.body.style.paddingLeft = `${scrollBarWidth}px`;
                document.body.style.paddingRight = `${scrollBarWidth}px`;
            }
            setTimeout(() => closeBtnRef.current?.focus(), 60);
            const onKey = (e) => {
                if (e.key === 'Escape') closeCart();
                if (e.key === 'Tab' && drawerRef.current) {
                    const focusable = drawerRef.current.querySelectorAll(
                        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
                    );
                    if (!focusable.length) return;
                    const first = focusable[0];
                    const last = focusable[focusable.length - 1];
                    if (e.shiftKey && document.activeElement === first) {
                        e.preventDefault();
                        last.focus();
                    } else if (!e.shiftKey && document.activeElement === last) {
                        e.preventDefault();
                        first.focus();
                    }
                }
            };
            window.addEventListener('keydown', onKey);
            return () => {
                document.body.style.overflow = '';
                document.body.style.paddingLeft = '';
                document.body.style.paddingRight = '';
                document.documentElement.style.scrollbarGutter = '';
                window.removeEventListener('keydown', onKey);
            };
        } else {
            document.body.style.overflow = '';
            document.body.style.paddingLeft = '';
            document.body.style.paddingRight = '';
            document.documentElement.style.scrollbarGutter = '';
        }
        return () => {
            document.body.style.overflow = '';
            document.body.style.paddingLeft = '';
            document.body.style.paddingRight = '';
            document.documentElement.style.scrollbarGutter = '';
        };
    }, [isCartOpen, closeCart]);

    if (typeof window === 'undefined') return null;

    const isEmpty = cartItems.length === 0;
    const hasCoupon = !!coupon;
    const isFreeShipping = subtotal >= FREE_SHIPPING_THRESHOLD;

    return (
        <AnimatePresence>
            {isCartOpen && (
                <>
                    {/* Backdrop */}
                    <motion.div
                        key="cart-backdrop"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        transition={{ duration: 0.2, ease: 'easeOut' }}
                        onClick={closeCart}
                        aria-hidden="true"
                        className="fixed inset-0 bg-slate-900/45 backdrop-blur-[2px] z-[9998]"
                    />

                    {/* Drawer */}
                    <motion.div
                        key="cart-drawer"
                        dir="rtl"
                        ref={drawerRef}
                        role="dialog"
                        aria-modal="true"
                        aria-label="سلة التسوق"
                        initial={{ x: '100%' }}
                        animate={{ x: 0 }}
                        exit={{ x: '100%' }}
                        transition={{ type: 'spring', damping: 30, stiffness: 360, mass: 0.9 }}
                        className="fixed inset-y-0 right-0 z-[9999] flex flex-col bg-white border-l border-slate-200 shadow-[-16px_0_48px_rgba(15,23,42,0.12)] overflow-hidden"
                        style={{
                            width: '100%',
                            maxWidth: '460px',
                            height: '100dvh',
                            fontFamily: 'Cairo, sans-serif',
                        }}
                    >
                        {/* ── Header ── */}
                        <div className="shrink-0 bg-white border-b border-slate-100 sticky top-0 z-10">
                            <div className="flex items-center justify-between px-5 py-4">
                                <div className="flex items-center gap-3.5">
                                    <div className="w-10 h-10 rounded-2xl bg-slate-900 text-white flex items-center justify-center shadow-sm">
                                        <ShoppingBag size={18} strokeWidth={2.2} />
                                    </div>
                                    <div>
                                        <h2 className="text-[17px] font-black text-slate-900 leading-none tracking-tight">سلة التسوق</h2>
                                        <p className="text-[12px] font-bold text-slate-500 mt-1 flex items-center gap-1.5">
                                            {isEmpty ? (
                                                'فارغة'
                                            ) : (
                                                <>
                                                    <span>{totalItems} {totalItems === 1 ? 'منتج' : 'منتجات'}</span>
                                                    <span className="w-1 h-1 bg-slate-300 rounded-full" />
                                                    <span className="text-slate-900">{cartItems.length} عناصر</span>
                                                </>
                                            )}
                                        </p>
                                    </div>
                                </div>
                                <div className="flex items-center gap-2">
                                    {!isEmpty && (
                                        <span className="hidden sm:inline-flex items-center gap-1 text-[10px] font-black tracking-widest bg-orange-50 text-orange-700 border border-orange-200 px-2.5 py-1 rounded-full">
                                            <Sparkles size={10} /> {isFreeShipping ? 'شحن مجاني ✓' : `متبقي ${formatPrice(freeShippingRemaining)}`}
                                        </span>
                                    )}
                                    <button
                                        ref={closeBtnRef}
                                        onClick={closeCart}
                                        aria-label="إغلاق السلة"
                                        className="w-9 h-9 rounded-full bg-white border border-slate-200 text-slate-600 hover:bg-slate-900 hover:text-white hover:border-slate-900 hover:rotate-90 transition-all duration-300 flex items-center justify-center"
                                    >
                                        <X size={16} strokeWidth={2.2} />
                                    </button>
                                </div>
                            </div>

                            {/* Free shipping progress — minimal thin bar (B) */}
                            {!isEmpty && (
                                <div className="px-5 pb-3">
                                    <div className="flex items-center justify-between text-[11px] font-bold mb-1.5">
                                        <span className={`flex items-center gap-1.5 ${isFreeShipping ? 'text-emerald-700' : 'text-slate-600'}`}>
                                            <Truck size={13} className={isFreeShipping ? 'text-emerald-600' : 'text-slate-400'} />
                                            {isFreeShipping ? 'مبروك! طلبك مؤهل للشحن المجاني 🎉' : `أضف ${formatPrice(freeShippingRemaining)} للشحن المجاني`}
                                        </span>
                                        <span className="text-slate-400 font-semibold text-[10px]">{shippingProgress}%</span>
                                    </div>
                                    <div className="h-1.5 bg-slate-100 rounded-full overflow-hidden">
                                        <motion.div
                                            initial={{ width: 0 }}
                                            animate={{ width: `${shippingProgress}%` }}
                                            transition={{ duration: 0.6, ease: 'easeOut' }}
                                            className={`h-full rounded-full ${isFreeShipping ? 'bg-emerald-500' : 'bg-gradient-to-l from-orange-600 to-amber-500'}`}
                                        />
                                    </div>
                                </div>
                            )}
                        </div>

                        {/* ── Scrollable Content ── */}
                        <div className="flex-1 overflow-y-auto overscroll-contain bg-[#f8fafc]">
                            {isEmpty ? (
                                <div className="h-full flex flex-col">
                                    <div className="flex-1 flex flex-col items-center justify-center text-center px-8 py-10 gap-6">
                                        <div className="relative">
                                            <div className="w-28 h-28 bg-white border border-slate-200 rounded-[28px] flex items-center justify-center shadow-sm">
                                                <PackageSearch size={40} className="text-slate-300" strokeWidth={1.6} />
                                            </div>
                                            <span className="absolute -top-1.5 -right-1.5 w-7 h-7 bg-slate-900 text-white rounded-full flex items-center justify-center text-[11px] font-black shadow">0</span>
                                        </div>
                                        <div>
                                            <h3 className="text-[22px] font-black text-slate-900">سلتك فارغة</h3>
                                            <p className="text-[13px] font-medium text-slate-500 mt-2 leading-relaxed max-w-[300px] mx-auto">
                                                لا توجد منتجات في السلة بعد. اكتشف مجموعتنا من الحدايد، البويات والعدد اليدوية وأضف ما يعجبك.
                                            </p>
                                        </div>
                                        <div className="w-full max-w-[320px] space-y-3">
                                            <button
                                                onClick={handleExplore}
                                                className="w-full py-4 bg-slate-900 hover:bg-orange-600 text-white rounded-2xl font-black text-[14px] flex items-center justify-center gap-2 transition-colors shadow-lg shadow-slate-900/10 active:scale-[0.98]"
                                            >
                                                تصفح المنتجات <ArrowLeft size={16} className="rotate-180" />
                                            </button>
                                            <button
                                                onClick={handleOffers}
                                                className="w-full py-3.5 bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 rounded-2xl font-black text-[13px] transition-colors"
                                            >
                                                استكشاف العروض
                                            </button>
                                        </div>
                                        <div className="flex items-center justify-center gap-4 text-[11px] font-bold text-slate-400 pt-2">
                                            <span className="flex items-center gap-1.5"><Truck size={14} /> شحن سريع</span>
                                            <span className="w-1 h-1 bg-slate-300 rounded-full" />
                                            <span className="flex items-center gap-1.5"><ShieldCheck size={14} /> دفع آمن</span>
                                            <span className="w-1 h-1 bg-slate-300 rounded-full" />
                                            <span className="flex items-center gap-1.5"><RefreshCw size={14} /> إرجاع 14 يوم</span>
                                        </div>
                                    </div>

                                    {/* Benefits footer for empty - subtle */}
                                    <div className="p-4 bg-white border-t border-slate-100">
                                        <div className="grid grid-cols-3 gap-3">
                                            {[
                                                { icon: Truck, label: 'توصيل سريع', sub: 'لكل المحافظات' },
                                                { icon: ShieldCheck, label: 'منتجات أصلية', sub: 'ضمان الجودة' },
                                                { icon: RefreshCw, label: 'إرجاع سهل', sub: 'خلال 14 يوم' },
                                            ].map((b) => (
                                                <div key={b.label} className="text-center bg-slate-50 border border-slate-100 rounded-2xl p-3">
                                                    <b.icon size={18} className="mx-auto text-slate-600 mb-1.5" />
                                                    <p className="text-[11px] font-black text-slate-800 leading-none">{b.label}</p>
                                                    <p className="text-[10px] font-bold text-slate-400 mt-1">{b.sub}</p>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                </div>
                            ) : (
                                <div className="p-3 space-y-3">
                                    {/* Toolbar — compact */}
                                    <div className="flex items-center justify-between">
                                        <p className="text-[11px] font-bold tracking-wide text-slate-400">{cartItems.length} عناصر • {totalItems} قطعة</p>
                                        <button
                                            onClick={handleClearCart}
                                            className="text-[11px] font-bold text-slate-500 hover:text-red-600 flex items-center gap-1 px-2.5 py-1 rounded-full hover:bg-red-50 border border-transparent hover:border-red-100 transition-colors"
                                        >
                                            <Trash2 size={12} /> إفراغ
                                        </button>
                                    </div>

                                    {/* Coupon — compact minimal */}
                                    <div className="bg-white border border-slate-200 rounded-xl p-2.5">
                                        <div className="flex items-center gap-2 text-[11px] font-bold text-slate-600 mb-2">
                                            <Ticket size={13} className="text-orange-600" /> كود الخصم
                                            {hasCoupon && <span className="mr-auto text-emerald-700 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded-full text-[10px] font-bold">تم التطبيق</span>}
                                        </div>
                                        {!hasCoupon ? (
                                            <>
                                                <div className="flex gap-2">
                                                    <input
                                                        value={localCouponInput}
                                                        onChange={(e) => setLocalCouponInput(e.target.value.toUpperCase())}
                                                        onKeyDown={(e) => e.key === 'Enter' && handleApplyCoupon()}
                                                        placeholder="WELCOME20"
                                                        className="flex-1 h-10 bg-slate-50 border border-slate-200 rounded-xl px-3 text-sm font-mono tracking-widest text-center uppercase placeholder:tracking-normal focus:outline-none focus:ring-2 focus:ring-orange-500/15 focus:border-orange-300 transition"
                                                        disabled={couponLoading}
                                                    />
                                                    <button
                                                        onClick={handleApplyCoupon}
                                                        disabled={couponLoading || !localCouponInput.trim()}
                                                        className="h-10 px-4 bg-slate-900 hover:bg-orange-600 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-xl text-sm font-bold flex items-center gap-1.5 transition-colors shrink-0"
                                                    >
                                                        {couponLoading ? <Loader2 size={13} className="animate-spin" /> : <Check size={13} />} تطبيق
                                                    </button>
                                                </div>
                                                {couponError && <p className="text-[11px] font-bold text-red-600 mt-2 bg-red-50 border border-red-100 rounded-xl px-3 py-2">{couponError}</p>}
                                            </>
                                        ) : (
                                            <div className="flex items-center justify-between gap-3 bg-emerald-50 border border-emerald-200 rounded-xl px-3 py-2.5">
                                                <div className="flex items-center gap-2.5 min-w-0">
                                                    <div className="w-7 h-7 rounded-full bg-emerald-600 text-white flex items-center justify-center shrink-0"><Ticket size={12} /></div>
                                                    <div className="min-w-0">
                                                        <p className="font-mono font-bold text-emerald-800 text-sm leading-none">{coupon.code}</p>
                                                        <p className="text-[11px] font-semibold text-emerald-700 mt-0.5">
                                                            خصم {coupon.discount_type === 'percentage' ? `${coupon.discount_value}%` : formatPrice(coupon.discount_value)} • وفّرت {formatPrice(discountAmount)}
                                                        </p>
                                                    </div>
                                                </div>
                                                <button
                                                    onClick={removeCoupon}
                                                    className="w-7 h-7 rounded-full bg-white border border-emerald-200 text-emerald-700 hover:bg-red-50 hover:text-red-600 hover:border-red-200 flex items-center justify-center shrink-0 transition-colors"
                                                    aria-label="إزالة الكوبون"
                                                >
                                                    <X size={12} />
                                                </button>
                                            </div>
                                        )}
                                    </div>

                                    {/* Items — List style (B): unified container with divide-y */}
                                    <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden divide-y divide-slate-100">
                                        <AnimatePresence mode="popLayout" initial={false}>
                                            {cartItems.map((item) => {
                                                const key = `${item.id}-${canonicalKey(item.options)}`;
                                                const isLowStock = item.stock_quantity != null && item.quantity >= item.stock_quantity;
                                                const unitPrice = Number(item.price) || 0;
                                                const lineTotal = unitPrice * (Number(item.quantity) || 0);
                                                return (
                                                    <motion.div
                                                        key={key}
                                                        layout
                                                        initial={{ opacity: 0, y: 6 }}
                                                        animate={{ opacity: 1, y: 0 }}
                                                        exit={{ opacity: 0, y: -6, transition: { duration: 0.16 } }}
                                                        transition={{ type: 'spring', damping: 28, stiffness: 340 }}
                                                        className="group flex gap-3 p-3 hover:bg-slate-50/70 transition-colors"
                                                    >
                                                        {/* Image — 64px compact, no badge */}
                                                        <div className="relative shrink-0">
                                                            <img
                                                                src={item.image_url || item.image || 'https://placehold.co/120x120/f8fafc/94a3b8?text=IMG'}
                                                                alt={item.name}
                                                                className="w-16 h-16 rounded-xl object-cover bg-slate-50 border border-slate-100"
                                                                loading="lazy"
                                                                onError={(e) => {
                                                                    e.currentTarget.src = 'https://placehold.co/120x120/f8fafc/94a3b8?text=IMG';
                                                                }}
                                                            />
                                                        </div>

                                                        {/* Content */}
                                                        <div className="flex-1 min-w-0 flex flex-col gap-1.5">
                                                            <div className="flex items-start justify-between gap-2">
                                                                <h3 className="font-bold text-slate-900 text-[13px] leading-snug line-clamp-2">{item.name}</h3>
                                                                <button
                                                                    onClick={() => removeFromCart(item.id, item.options)}
                                                                    aria-label={`حذف ${item.name}`}
                                                                    className="w-6 h-6 rounded-full bg-white border border-slate-200 text-slate-400 hover:bg-red-50 hover:text-red-600 hover:border-red-200 flex items-center justify-center shrink-0 transition-colors"
                                                                >
                                                                    <Trash2 size={11} />
                                                                </button>
                                                            </div>

                                                            {/* Options — smaller pills */}
                                                            {item.options && Object.keys(item.options).length > 0 && (
                                                                <div className="flex flex-wrap gap-1">
                                                                    {Object.entries(item.options).map(([k, v]) => (
                                                                        <span
                                                                            key={k}
                                                                            className="inline-flex items-center text-[10px] font-semibold text-slate-600 bg-slate-50 border border-slate-200 px-1.5 py-0.5 rounded-full"
                                                                        >
                                                                            {String(v)}
                                                                        </span>
                                                                    ))}
                                                                </div>
                                                            )}

                                                            {/* Low stock — minimal */}
                                                            {isLowStock && (
                                                                <span className="inline-flex items-center gap-1 text-[10px] font-bold text-amber-700 bg-amber-50 border border-amber-200 rounded-full px-2 py-0.5 w-fit">
                                                                    <AlertTriangle size={10} /> متبقي {item.stock_quantity} فقط
                                                                </span>
                                                            )}

                                                            {/* Price + Stepper — simplified */}
                                                            <div className="mt-0.5 flex items-center justify-between gap-2">
                                                                <div className="flex flex-col">
                                                                    <span className="text-[14px] font-bold text-slate-900 leading-none tracking-tight">{formatPrice(lineTotal)}</span>
                                                                    <span className="text-[11px] font-medium text-slate-400 mt-0.5">
                                                                        {formatPrice(unitPrice)} × {item.quantity}
                                                                    </span>
                                                                </div>

                                                                {/* Stepper — display only, no input */}
                                                                <div className="flex items-center gap-0.5 bg-white border border-slate-200 rounded-full p-0.5 shrink-0">
                                                                    <button
                                                                        onClick={() => {
                                                                            if (item.quantity <= 1) {
                                                                                removeFromCart(item.id, item.options);
                                                                            } else {
                                                                                updateQuantity(item.id, -1, item.options);
                                                                            }
                                                                        }}
                                                                        aria-label="إنقاص الكمية"
                                                                        className="w-7 h-7 rounded-full bg-slate-50 border border-slate-200 text-slate-600 hover:bg-slate-900 hover:text-white hover:border-slate-900 flex items-center justify-center active:scale-95 transition-colors"
                                                                    >
                                                                        <Minus size={11} strokeWidth={2.4} />
                                                                    </button>

                                                                    <span className="w-7 text-center text-[13px] font-bold text-slate-900 tabular-nums select-none">{item.quantity}</span>

                                                                    <button
                                                                        onClick={() => updateQuantity(item.id, 1, item.options)}
                                                                        disabled={isLowStock}
                                                                        aria-label="زيادة الكمية"
                                                                        className="w-7 h-7 rounded-full bg-slate-900 text-white hover:bg-orange-600 disabled:opacity-30 disabled:cursor-not-allowed flex items-center justify-center active:scale-95 transition-colors"
                                                                    >
                                                                        <Plus size={11} strokeWidth={2.4} />
                                                                    </button>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </motion.div>
                                                );
                                            })}
                                        </AnimatePresence>
                                    </div>

                                    {/* Security / reassurance — lighter */}
                                    <div className="flex items-center justify-center gap-2 text-[10px] font-semibold tracking-wide text-slate-400 pt-1">
                                        <span className="flex items-center gap-1"><ShieldCheck size={12} className="text-emerald-500" /> دفع آمن</span>
                                        <span className="w-1 h-1 bg-slate-300 rounded-full" />
                                        <span>استرجاع 14 يوم</span>
                                        <span className="w-1 h-1 bg-slate-300 rounded-full" />
                                        <span>منتجات أصلية</span>
                                    </div>
                                </div>
                            )}
                        </div>

                        {/* ── Footer ── */}
                        {!isEmpty && (
                            <div className="shrink-0 bg-white border-t border-slate-200 shadow-[0_-12px_32px_rgba(15,23,42,0.06)]">
                                <div className="p-5 space-y-3">
                                    <div className="space-y-2">
                                        <div className="flex justify-between items-center text-[13px]">
                                            <span className="text-slate-500 font-bold">المجموع الفرعي</span>
                                            <span className="font-black text-slate-900 tabular-nums">{formatPrice(subtotal)}</span>
                                        </div>
                                        {discountAmount > 0 && (
                                            <div className="flex justify-between items-center text-[13px]">
                                                <span className="text-emerald-700 font-black flex items-center gap-1.5"><Ticket size={12} /> خصم {hasCoupon ? `(${coupon.code})` : ''}</span>
                                                <span className="font-black text-emerald-700 tabular-nums">-{formatPrice(discountAmount)}</span>
                                            </div>
                                        )}
                                        <div className="flex justify-between items-center text-[13px]">
                                            <span className="text-slate-500 font-bold">الشحن</span>
                                            <span className={`font-black px-2.5 py-1 rounded-full text-[11px] border ${isFreeShipping ? 'bg-emerald-50 text-emerald-700 border-emerald-200' : 'bg-slate-50 text-slate-600 border-slate-200'}`}>
                                                {isFreeShipping ? 'مجاني 🎉' : formatPrice(0) + ' • مجاني فوق ' + formatPrice(FREE_SHIPPING_THRESHOLD)}
                                            </span>
                                        </div>
                                        <div className="pt-3 border-t border-slate-100 flex justify-between items-center">
                                            <span className="text-[14px] font-black text-slate-900">الإجمالي</span>
                                            <span className="text-[22px] font-black tracking-tight tabular-nums" style={{ color: discountAmount > 0 ? '#059669' : '#ea580c' }}>
                                                {formatPrice(totalAmount)}
                                            </span>
                                        </div>
                                        <p className="text-[10px] font-bold text-slate-400 text-center">شامل الضريبة • الدفع عند الاستلام متاح</p>
                                    </div>

                                    <button
                                        onClick={handleCheckout}
                                        className="group w-full h-[52px] bg-slate-900 hover:bg-orange-600 text-white rounded-2xl font-black text-[15px] flex items-center justify-center gap-2.5 transition-all shadow-lg shadow-slate-900/10 active:scale-[0.98]"
                                    >
                                        متابعة إتمام الطلب
                                        <ArrowLeft size={18} strokeWidth={2.5} className="transition-transform duration-300 group-hover:-translate-x-1" />
                                    </button>
                                    <button
                                        onClick={closeCart}
                                        className="w-full h-11 bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 rounded-2xl font-black text-[13px] transition-colors"
                                    >
                                        متابعة التسوق
                                    </button>
                                    <p className="text-center text-[10px] font-bold text-slate-400">بالمتابعة أنت توافق على الشروط والأحكام</p>
                                </div>
                            </div>
                        )}
                    </motion.div>
                </>
            )}
        </AnimatePresence>
    );
};

export default CartDrawer;
