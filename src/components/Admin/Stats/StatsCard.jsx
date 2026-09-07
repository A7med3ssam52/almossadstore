import React from 'react';
import { motion } from 'framer-motion';
import { TrendingUp, TrendingDown } from 'lucide-react';
import { Card, CardContent } from "@/components/ui/card";

const StatsCard = ({ title, value, icon, trend, trendValue, color = "orange", progress = 70, targetLabel = "Target 80%" }) => {
    const isPositive = trend === 'up';

    return (
        <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4 }}
            className="group"
        >
            <Card className="relative overflow-hidden border-slate-200 bg-white hover:border-[#3A3F45]/30 transition-all duration-500 group-hover:-translate-y-1 shadow-sm hover:shadow-2xl hover:shadow-[#1F2933]/10 rounded-[2.5rem]">
                {/* Visual Glow */}
                <div className={`absolute inset-0 bg-gradient-to-br transition-opacity duration-500 opacity-[0.05] group-hover:opacity-[0.1] pointer-events-none
                    ${color === 'orange' ? 'from-[#1F2933] to-transparent' : 'from-blue-600 to-transparent'}`}>
                </div>

                <CardContent className="p-6 relative z-10">
                    <div className="flex items-start justify-between mb-4">
                        <div className={`p-4 rounded-2xl shadow-sm transition-transform duration-500 group-hover:scale-110 group-hover:rotate-3
                            ${color === 'orange' ? 'bg-slate-100 text-[#1F2933] ring-1 ring-[#3A3F45]/10' : 'bg-blue-50 text-blue-600 ring-1 ring-blue-500/10'}`}>
                            {icon}
                        </div>

                        <div className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[10px] font-black tracking-tight leading-none
                            ${isPositive ? 'bg-green-100 text-green-700 border border-green-200' : 'bg-red-100 text-red-700 border border-red-200'}`}>
                            {isPositive ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
                            <span className="font-sans">{trendValue}</span>
                        </div>
                    </div>

                    <div className="space-y-1">
                        <p className="text-slate-500 text-[11px] font-black tracking-widest uppercase opacity-80">{title}</p>
                        <h3 className="text-3xl font-black text-slate-900 tracking-tighter leading-none shadow-sm font-sans pt-1">
                            {value}
                        </h3>
                        <div className="pt-5 flex items-center justify-between">
                            <div className="h-1.5 flex-1 bg-slate-100 rounded-full overflow-hidden mr-3">
                                <motion.div
                                    initial={{ width: 0 }}
                                    animate={{ width: `${progress}%` }}
                                    transition={{ duration: 1.5, delay: 0.5, ease: "circOut" }}
                                    className={`h-full rounded-full ${color === 'orange' ? 'bg-[#1F2933] shadow-[0_0_10px_rgba(31,41,51,0.2)]' : 'bg-blue-600 shadow-[0_0_10px_rgba(37,99,235,0.2)]'}`}
                                ></motion.div>
                            </div>
                            <span className="text-[9px] text-slate-400 font-bold tracking-widest uppercase">{targetLabel}</span>
                        </div>
                    </div>
                </CardContent>

                {/* Decorative Blur Circle */}
                <div className="absolute -bottom-10 -left-10 w-32 h-32 bg-[#1F2933]/10 rounded-full blur-3xl opacity-0 group-hover:opacity-100 transition-opacity duration-700"></div>
            </Card>
        </motion.div>
    );
};

export default StatsCard;

