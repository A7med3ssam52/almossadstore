import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Trash2, Plus, Minus, ShoppingBag, ArrowLeft } from 'lucide-react';
import { useCart } from '../../context/CartContext';
import { useNavigate } from 'react-router-dom';

const CartDrawer = () => {
    const { isCartOpen, closeCart, cartItems, totalItems, subtotal, updateQuantity, removeFromCart } = useCart();
    const navigate = useNavigate();

    const sidebarVariants = {
        closed: { x: '100%', opacity: 0 },
        open: { x: 0, opacity: 1 }
    };

    const backdropVariants = {
        closed: { opacity: 0 },
        open: { opacity: 1 }
    };

    const handleCheckout = () => {
        closeCart();
        navigate('/checkout');
    };

    React.useEffect(() => {
        console.log("🛒 CartDrawer loaded with Premium UI v2.0 (Glassmorphism & Sync)");
    }, []);

    if (typeof window === 'undefined') return null;

    return (
        <AnimatePresence>
            {isCartOpen && (
                <>
                    {/* Backdrop */}
                    <motion.div
                        key="cart-backdrop"
                        initial="closed"
                        animate="open"
                        exit="closed"
                        variants={backdropVariants}
                        onClick={closeCart}
                        className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-[99998]"
                    />

                    <motion.div
                        key="cart-drawer-panel"
                        initial="closed"
                        animate="open"
                        exit="closed"
                        variants={sidebarVariants}
                        transition={{ type: 'spring', damping: 25, stiffness: 200 }}
                        className="bg-white/95 backdrop-blur-3xl shadow-[-20px_0_50px_rgba(0,0,0,0.1)] flex flex-col rounded-t-[2.5rem] sm:rounded-t-none sm:rounded-l-[3rem] overflow-hidden border-l border-white/20"
                        style={{
                            position: 'fixed',
                            top: 0,
                            right: 0,
                            bottom: 0,
                            height: '100%',
                            maxHeight: '100dvh',
                            width: '100%',
                            maxWidth: '420px',
                            zIndex: 99999,
                            fontFamily: 'Cairo, sans-serif',
                            backdropFilter: 'blur(40px)', // Fallback
                            WebkitBackdropFilter: 'blur(40px)' // Safari
                        }}
                    >
                        {/* Header with high-contrast gradient */}
                        <div className="flex items-center justify-between p-7 bg-gradient-to-l from-orange-600/10 to-transparent border-b border-orange-100/30">
                            <div className="flex items-center gap-4">
                                <div className="p-3 bg-orange-600 text-white rounded-2xl shadow-lg shadow-orange-600/30">
                                    <ShoppingBag size={24} strokeWidth={2.5} />
                                </div>
                                <div className="flex flex-col">
                                    <div className="flex items-center gap-2">
                                        <h2 className="text-2xl font-black text-slate-900 leading-none">سلة المشتريات</h2>
                                        <span className="px-2 py-0.5 bg-orange-100 text-orange-600 text-[10px] font-black rounded-lg uppercase tracking-wider">Premium</span>
                                    </div>
                                    <p className="text-xs font-bold text-slate-500 mt-1">{totalItems} {totalItems === 1 ? 'منتج' : 'منتجات'}</p>
                                </div>
                            </div>
                            <button
                                onClick={closeCart}
                                className="p-2.5 rounded-full bg-slate-100/50 text-slate-400 hover:bg-orange-500 hover:text-white transition-all duration-300 transform hover:rotate-90"
                            >
                                <X size={20} />
                            </button>
                        </div>

                        {/* Cart Items */}
                        <div className="flex-1 overflow-y-auto p-6 space-y-4">
                            {cartItems.length === 0 ? (
                                <div className="h-full flex flex-col items-center justify-center text-center space-y-6 pt-20">
                                    <div className="relative">
                                        <div className="absolute inset-0 bg-orange-100 blur-3xl rounded-full opacity-30 animate-pulse"></div>
                                        <ShoppingBag size={80} className="text-orange-200 relative z-10" />
                                    </div>
                                    <div>
                                        <p className="text-xl font-black text-slate-900">سلة المشتريات فارغة</p>
                                        <p className="text-sm text-slate-500 mt-2 font-medium">ابدأ بإضافة منتجات لتعود إليها لاحقاً</p>
                                    </div>
                                    <button 
                                        onClick={closeCart}
                                        className="px-10 py-4 bg-orange-600 text-white rounded-[2rem] font-black hover:bg-orange-500 transition-all text-sm shadow-xl shadow-orange-600/20 active:scale-95"
                                    >
                                        استكشف المتجر
                                    </button>
                                </div>
                            ) : (
                                <div className="p-4 sm:p-6 overflow-y-auto overflow-x-hidden flex-1 scrollbar-thin scrollbar-thumb-slate-200">
                                    <div className="space-y-4 px-2">
                                        <AnimatePresence mode="popLayout" initial={false}>
                                            {cartItems.map((item) => (
                                                <motion.div
                                                    key={`${item.id}-${JSON.stringify(item.options)}`}
                                                    layout
                                                    initial={{ opacity: 0, y: 20 }}
                                                    animate={{ opacity: 1, y: 0 }}
                                                    exit={{ opacity: 0, x: -20 }}
                                                    className="bg-white p-4 rounded-3xl border border-slate-100 shadow-sm flex gap-4"
                                                >
                                                    <img src={item.image} alt={item.name} className="w-20 h-20 rounded-2xl object-cover bg-slate-100" />
                                                    <div className="flex-1 flex flex-col justify-between">
                                                        <div>
                                                            <div className="flex justify-between items-start">
                                                                <h3 className="font-black text-slate-900 text-sm">{item.name}</h3>
                                                                <button onClick={() => removeFromCart(item.id, item.options)} className="text-slate-300 hover:text-red-500 transition-colors">
                                                                    <Trash2 size={16} />
                                                                </button>
                                                            </div>
                                                            {item.options && Object.entries(item.options).map(([key, value]) => (
                                                                <span key={key} className="text-[10px] text-slate-400 font-bold bg-slate-50 px-2 py-0.5 rounded-md mr-1">
                                                                    {value}
                                                                </span>
                                                            ))}
                                                        </div>

                                                        {/* Price + Qty row */}
                                                        <div className="mt-3 flex items-center justify-between gap-3" dir="rtl">

                                                            {/* Price pill */}
                                                            <div className="flex flex-col items-start gap-0.5">
                                                                <div className="flex items-baseline gap-1.5 bg-gradient-to-l from-orange-50 to-amber-50 border border-orange-100/60 rounded-2xl px-3 py-1.5">
                                                                    <span className="text-xl font-black text-orange-600 font-sans leading-none tracking-tight">
                                                                        {((parseFloat(item.price) || 0) * item.quantity).toLocaleString()}
                                                                    </span>
                                                                    <span className="text-[11px] font-black text-orange-400 mb-0.5">ج.م</span>
                                                                </div>
                                                                {item.quantity > 1 && (
                                                                    <span className="text-[10px] text-slate-400 font-semibold px-1">
                                                                        {(parseFloat(item.price) || 0).toLocaleString()} × {item.quantity}
                                                                    </span>
                                                                )}
                                                            </div>

                                                            {/* Qty stepper */}
                                                            <div className="flex items-center bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-sm shrink-0">
                                                                <button
                                                                    onClick={() => updateQuantity(item.id, -1, item.options)}
                                                                    className="w-8 h-8 flex items-center justify-center text-slate-400 hover:text-orange-600 hover:bg-orange-50 transition-all"
                                                                >
                                                                    <Minus size={13} />
                                                                </button>
                                                                <span className="w-8 text-center text-sm font-black text-slate-900 font-sans border-x border-slate-100">{item.quantity}</span>
                                                                <button
                                                                    onClick={() => updateQuantity(item.id, 1, item.options)}
                                                                    className="w-8 h-8 flex items-center justify-center text-slate-400 hover:text-orange-600 hover:bg-orange-50 transition-all"
                                                                >
                                                                    <Plus size={13} />
                                                                </button>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </motion.div>
                                            ))}
                                        </AnimatePresence>
                                    </div>
                                </div>
                            )}
                        </div>

                        {/* Footer - Floating Glass Effect */}
                        {cartItems.length > 0 && (
                            <div className="p-8 bg-white/80 backdrop-blur-2xl border-t border-white/20 shadow-[0_-20px_50px_rgba(0,0,0,0.05)]">
                                <div className="space-y-4 mb-8">
                                    <div className="flex justify-between items-center text-slate-500 font-bold">
                                        <span>المجموع الفرعي</span>
                                        <span>{subtotal.toLocaleString()} ج.م</span>
                                    </div>
                                    <div className="flex justify-between items-center text-slate-400 text-xs font-bold">
                                        <span>الشحن</span>
                                        <span className="text-orange-500">يُحسب عند الدفع</span>
                                    </div>
                                    <div className="pt-4 border-t border-slate-100 flex justify-between items-end">
                                        <div className="flex flex-col">
                                            <span className="text-xs text-slate-400 font-black uppercase tracking-widest mb-1">الإجمالي التقريبي</span>
                                            <span className="text-3xl font-black text-slate-900 leading-none">
                                                {subtotal.toLocaleString()} <span className="text-sm">ج.م</span>
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                <motion.button
                                    whileHover={{ scale: 1.02, translateY: -2 }}
                                    whileTap={{ scale: 0.98 }}
                                    onClick={handleCheckout}
                                    className="w-full py-5 bg-gradient-to-r from-orange-600 to-orange-500 text-white rounded-[2rem] font-black text-lg shadow-xl shadow-orange-600/20 hover:shadow-orange-600/40 transition-all flex items-center justify-center gap-3 group"
                                >
                                    <span>متابعة إتمام الطلب</span>
                                    <ArrowLeft size={22} className="transition-transform group-hover:-translate-x-2 text-white/80" />
                                </motion.button>
                                
                                <p className="text-center text-[10px] text-slate-400 font-bold mt-4">
                                    تسوق آمن 100% • دفع عند الاستلام • إرجاع سهل
                                </p>
                            </div>
                        )}
                    </motion.div>
                </>
            )}
        </AnimatePresence>
    );
};

export default CartDrawer;
