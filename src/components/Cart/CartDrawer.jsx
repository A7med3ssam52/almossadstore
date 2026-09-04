import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Trash2, Plus, Minus, ShoppingBag, ArrowLeft, AlertTriangle } from 'lucide-react';
import { useCart } from '../../context/CartContext';
import { useNavigate } from 'react-router-dom';
import { formatPrice } from '@/utils/formatters';

const CartDrawer = () => {
    const { isCartOpen, closeCart, cartItems, totalItems, subtotal, updateQuantity, removeFromCart, clearCart } = useCart();
    const navigate = useNavigate();

    const handleCheckout = () => {
        closeCart();
        navigate('/checkout');
    };

    // Prevent body scroll when open
    React.useEffect(() => {
        if (isCartOpen) {
            document.body.style.overflow = 'hidden';
        } else {
            document.body.style.overflow = '';
        }
        return () => { document.body.style.overflow = ''; };
    }, [isCartOpen]);

    if (typeof window === 'undefined') return null;

    return (
        <AnimatePresence>
            {isCartOpen && (
                <>
                    <motion.div
                        key="cart-backdrop"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        transition={{ duration: 0.2 }}
                        onClick={closeCart}
                        className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-[99998]"
                    />

                    <motion.div
                        key="cart-drawer-panel"
                        initial={{ x: '100%' }}
                        animate={{ x: 0 }}
                        exit={{ x: '100%' }}
                        transition={{ type: 'spring', damping: 28, stiffness: 260 }}
                        className="fixed inset-y-0 right-0 bg-white flex flex-col overflow-hidden z-[99999] border-l border-slate-100"
                        style={{
                            width: '100%',
                            maxWidth: '420px',
                            height: '100dvh',
                            fontFamily: 'Cairo, sans-serif',
                        }}
                    >
                        {/* Header */}
                        <div className="shrink-0 flex items-center justify-between p-6 bg-white border-b border-slate-100">
                            <div className="flex items-center gap-3">
                                <div className="w-10 h-10 bg-orange-600 text-white rounded-xl flex items-center justify-center shadow-sm">
                                    <ShoppingBag size={20} strokeWidth={2.2} />
                                </div>
                                <div>
                                    <h2 className="text-lg font-black text-slate-900 leading-none">سلة التسوق</h2>
                                    <p className="text-xs font-bold text-slate-500 mt-1">{totalItems === 0 ? 'فارغة' : `${totalItems} ${totalItems === 1 ? 'منتج' : 'منتجات'}`}</p>
                                </div>
                            </div>
                            <button
                                onClick={closeCart}
                                aria-label="إغلاق"
                                className="w-9 h-9 rounded-full bg-slate-50 border border-slate-200 flex items-center justify-center text-slate-500 hover:bg-slate-900 hover:text-white hover:border-slate-900 transition-all"
                            >
                                <X size={16} />
                            </button>
                        </div>

                        {/* Items - single scroll container */}
                        <div className="flex-1 overflow-y-auto overscroll-contain">
                            {cartItems.length === 0 ? (
                                <div className="h-full min-h-[400px] flex flex-col items-center justify-center text-center p-8 gap-6">
                                    <div className="w-24 h-24 bg-orange-50 border border-orange-100 rounded-3xl flex items-center justify-center">
                                        <ShoppingBag size={40} className="text-orange-300" />
                                    </div>
                                    <div>
                                        <p className="text-xl font-black text-slate-900">سلتك فارغة</p>
                                        <p className="text-sm text-slate-500 mt-2 leading-relaxed">ابدأ بإضافة منتجاتك المفضلة<br/>واستكشف عروضنا المميزة</p>
                                    </div>
                                    <button
                                        onClick={closeCart}
                                        className="w-full max-w-[260px] py-4 bg-slate-900 text-white rounded-2xl font-bold hover:bg-orange-600 transition-colors shadow-lg"
                                    >
                                        تابع التسوق
                                    </button>
                                </div>
                            ) : (
                                <div className="p-4 space-y-3">
                                    {cartItems.length > 1 && (
                                        <div className="flex justify-between items-center pb-2">
                                            <span className="text-xs font-bold text-slate-400">{cartItems.length} منتجات</span>
                                            <button onClick={clearCart} className="text-xs font-bold text-red-500 hover:text-red-600 flex items-center gap-1">
                                                <Trash2 size={12} /> إفراغ السلة
                                            </button>
                                        </div>
                                    )}
                                    <AnimatePresence mode="popLayout" initial={false}>
                                        {cartItems.map((item) => {
                                            const isLowStock = item.stock_quantity !== undefined && item.stock_quantity !== null && item.quantity >= item.stock_quantity;
                                            const unitPrice = Number(item.price) || 0;
                                            return (
                                                <motion.div
                                                    key={`${item.id}-${JSON.stringify(item.options)}`}
                                                    layout
                                                    initial={{ opacity: 0, y: 12 }}
                                                    animate={{ opacity: 1, y: 0 }}
                                                    exit={{ opacity: 0, scale: 0.95 }}
                                                    className="bg-white p-3 rounded-2xl border border-slate-200 flex gap-3 hover:border-slate-300 hover:shadow-sm transition-all"
                                                >
                                                    <img
                                                        src={item.image_url || item.image || 'https://placehold.co/100x100/f1f5f9/94a3b8?text=IMG'}
                                                        alt={item.name}
                                                        className="w-20 h-20 rounded-xl object-cover bg-slate-50 border border-slate-100 shrink-0"
                                                        onError={(e)=> e.target.src='https://placehold.co/100x100/f1f5f9/94a3b8?text=IMG'}
                                                    />
                                                    <div className="flex-1 min-w-0 flex flex-col justify-between py-1">
                                                        <div>
                                                            <div className="flex justify-between items-start gap-2">
                                                                <h3 className="font-bold text-slate-900 text-sm leading-tight line-clamp-2 flex-1">{item.name}</h3>
                                                                <button
                                                                    onClick={() => removeFromCart(item.id, item.options)}
                                                                    aria-label="حذف"
                                                                    className="w-7 h-7 rounded-full bg-slate-50 border border-slate-200 flex items-center justify-center text-slate-400 hover:bg-red-50 hover:text-red-500 hover:border-red-200 transition-colors shrink-0"
                                                                >
                                                                    <Trash2 size={12} />
                                                                </button>
                                                            </div>
                                                            {item.options && Object.keys(item.options).length > 0 && (
                                                                <div className="flex flex-wrap gap-1 mt-1">
                                                                    {Object.entries(item.options).map(([k, v]) => (
                                                                        <span key={k} className="text-[10px] font-bold text-slate-600 bg-slate-100 px-2 py-0.5 rounded-full border border-slate-200">
                                                                            {String(v)}
                                                                        </span>
                                                                    ))}
                                                                </div>
                                                            )}
                                                            {isLowStock && (
                                                                <div className="flex items-center gap-1 mt-1.5 text-[10px] font-bold text-amber-700 bg-amber-50 border border-amber-200 rounded-full px-2 py-0.5 w-fit">
                                                                    <AlertTriangle size={10} /> المتاح: {item.stock_quantity}
                                                                </div>
                                                            )}
                                                        </div>

                                                        <div className="mt-2 flex items-center justify-between gap-2">
                                                            <div className="flex flex-col">
                                                                <span className="text-[15px] font-black text-slate-900 leading-none">{formatPrice(unitPrice * item.quantity)}</span>
                                                                {item.quantity > 1 && (
                                                                    <span className="text-[10px] text-slate-400 font-bold mt-0.5">{formatPrice(unitPrice)} × {item.quantity}</span>
                                                                )}
                                                            </div>

                                                            <div className="flex items-center bg-slate-50 border border-slate-200 rounded-full p-1 gap-1 shrink-0">
                                                                <button
                                                                    onClick={() => updateQuantity(item.id, -1, item.options)}
                                                                    disabled={item.quantity <= 1}
                                                                    aria-label="إنقاص"
                                                                    className="w-7 h-7 rounded-full bg-white border border-slate-200 flex items-center justify-center text-slate-600 hover:bg-slate-900 hover:text-white hover:border-slate-900 disabled:opacity-40 disabled:cursor-not-allowed transition-colors shadow-sm"
                                                                >
                                                                    <Minus size={12} />
                                                                </button>
                                                                <span className="w-7 text-center text-sm font-black text-slate-900">{item.quantity}</span>
                                                                <button
                                                                    onClick={() => updateQuantity(item.id, 1, item.options)}
                                                                    disabled={isLowStock}
                                                                    aria-label="زيادة"
                                                                    className="w-7 h-7 rounded-full bg-slate-900 text-white flex items-center justify-center hover:bg-orange-600 disabled:opacity-40 disabled:cursor-not-allowed transition-colors shadow-sm"
                                                                >
                                                                    <Plus size={12} />
                                                                </button>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </motion.div>
                                            );
                                        })}
                                    </AnimatePresence>
                                </div>
                            )}
                        </div>

                        {/* Footer - sticky bottom */}
                        {cartItems.length > 0 && (
                            <div className="shrink-0 p-6 bg-white border-t border-slate-100 shadow-[0_-8px_24px_rgba(0,0,0,0.04)]">
                                <div className="space-y-2.5 mb-5">
                                    <div className="flex justify-between items-center text-sm">
                                        <span className="text-slate-500 font-bold">المجموع الفرعي</span>
                                        <span className="font-bold text-slate-900">{formatPrice(subtotal)}</span>
                                    </div>
                                    <div className="flex justify-between items-center text-xs">
                                        <span className="text-slate-400 font-bold">الشحن</span>
                                        <span className="font-black text-green-600 bg-green-50 border border-green-200 px-2.5 py-1 rounded-full text-[11px]">مجاني</span>
                                    </div>
                                    <div className="pt-3 mt-1 border-t border-slate-100 flex justify-between items-center">
                                        <span className="text-sm font-black text-slate-900">الإجمالي</span>
                                        <span className="text-xl font-black text-slate-900">{formatPrice(subtotal)}</span>
                                    </div>
                                </div>

                                <button
                                    onClick={handleCheckout}
                                    className="w-full py-4 bg-orange-600 hover:bg-orange-700 text-white rounded-2xl font-black text-[15px] flex items-center justify-center gap-2 transition-colors shadow-lg shadow-orange-600/15 active:scale-[0.98]"
                                >
                                    متابعة الطلب
                                    <ArrowLeft size={18} />
                                </button>
                                <button
                                    onClick={closeCart}
                                    className="w-full mt-3 py-3 bg-white border border-slate-200 text-slate-700 rounded-2xl font-bold text-sm hover:bg-slate-50 transition-colors"
                                >
                                    متابعة التسوق
                                </button>
                                <p className="text-center text-[10px] font-bold text-slate-400 mt-3">دفع آمن • استرجاع خلال 14 يوم</p>
                            </div>
                        )}
                    </motion.div>
                </>
            )}
        </AnimatePresence>
    );
};

export default CartDrawer;