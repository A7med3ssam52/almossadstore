import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Link, useSearchParams } from 'react-router-dom';
import { CheckCircle2, Package, ArrowRight, ShoppingBag } from 'lucide-react';
import confetti from 'canvas-confetti';

const OrderSuccess = () => {
    const [searchParams] = useSearchParams();
    const orderId = searchParams.get('id');

    useEffect(() => {
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

    return (
        <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4" dir="rtl">
            <motion.div 
                initial={{ opacity: 0, scale: 0.95, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                transition={{ type: "spring", stiffness: 200, damping: 20 }}
                className="max-w-md w-full bg-white rounded-[3rem] p-10 text-center shadow-2xl shadow-slate-900/5 relative overflow-hidden border border-slate-100"
            >
                {/* Decorative Blob */}
                <div className="absolute top-0 right-0 w-32 h-32 bg-green-500/10 rounded-bl-full -z-10" />

                <motion.div 
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ delay: 0.2, type: "spring" }}
                    className="w-24 h-24 bg-green-100 rounded-[2rem] flex items-center justify-center mx-auto mb-8 shadow-xl shadow-green-500/10"
                >
                    <CheckCircle2 size={48} className="text-green-500" strokeWidth={2.5} />
                </motion.div>

                <h1 className="text-3xl font-black text-slate-900 mb-3 tracking-tight">شكراً لك!</h1>
                <p className="text-lg font-bold text-slate-500 mb-8">تم تأكيد طلبك بنجاح وهو الآن قيد المراجعة والتجهيز.</p>

                <div className="bg-slate-50 rounded-3xl p-6 mb-8 border border-slate-100 flex items-center justify-between">
                    <div className="text-right">
                        <p className="text-xs font-black tracking-widest text-slate-400 uppercase mb-1">رقم الطلب</p>
                        <p className="font-mono text-lg font-bold text-slate-900">#{orderId ? orderId.split('-')[0].toUpperCase() : '0000'}</p>
                    </div>
                    <div className="w-12 h-12 bg-white rounded-2xl flex items-center justify-center shadow-sm">
                        <Package size={24} className="text-orange-500" />
                    </div>
                </div>

                <div className="space-y-3">
                    <Link to="/catalog" className="w-full py-4 bg-slate-900 text-white rounded-[2rem] font-bold flex items-center justify-center gap-2 hover:bg-orange-600 transition-all shadow-xl shadow-slate-900/10 active:scale-95">
                        <ShoppingBag size={18} />
                        العودة للتسوق
                    </Link>
                    <Link to="/" className="w-full py-4 bg-slate-50 text-slate-600 rounded-[2rem] font-bold flex items-center justify-center hover:bg-slate-100 transition-all">
                        الصفحة الرئيسية
                    </Link>
                </div>
            </motion.div>
        </div>
    );
};

export default OrderSuccess;
