import React from 'react';
import {
    ResponsiveContainer,
    AreaChart,
    Area,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip
} from 'recharts';
import { motion } from 'framer-motion';

const defaultData = [
    { name: 'السبت', sales: 4000, revenue: 2400 },
    { name: 'الأحد', sales: 3000, revenue: 1398 },
    { name: 'الأثنين', sales: 2000, revenue: 9800 },
    { name: 'الثلاثاء', sales: 2780, revenue: 3908 },
    { name: 'الأربعاء', sales: 1890, revenue: 4800 },
    { name: 'الخميس', sales: 2390, revenue: 3800 },
    { name: 'الجمعة', sales: 3490, revenue: 4300 },
];

/**
 * SalesChart Component
 * Visualizes sales and revenue using a smooth AreaChart from Recharts.
 */
const SalesChart = ({ data = defaultData, activeDays = 7, onTimeframeChange }) => {
    const isEmpty = !data || data.length === 0 || data.every((d) => (Number(d.sales) || 0) === 0 && (Number(d.revenue) || 0) === 0);

    return (
        <motion.div
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            className="p-8 bg-white border border-slate-200 rounded-[2.5rem] shadow-sm hover:shadow-xl hover:shadow-slate-200/60 relative group overflow-hidden"
        >
            <div className="flex items-center justify-between mb-10">
                <div className="flex flex-col gap-1">
                    <h3 className="text-xl font-black text-slate-900 tracking-tight leading-none">نظرة عامة على المبيعات</h3>
                    <p className="text-slate-500 text-xs font-bold tracking-widest uppercase mt-1">Sales & Revenue Performance</p>
                </div>

                {/* Toggle Controls */}
                <div className="flex items-center gap-2 p-1 bg-slate-100 rounded-xl border border-slate-200 backdrop-blur-md">
                    <button 
                        onClick={() => onTimeframeChange?.(7)}
                        className={`px-4 py-1.5 text-[11px] font-black tracking-widest rounded-lg transition-all
                        ${activeDays === 7 ? 'bg-[#1F2933] text-white shadow-lg shadow-[#1F2933]/20' : 'text-slate-500 hover:text-slate-900'}`}
                    >
                        أسبوعي
                    </button>
                    <button 
                        onClick={() => onTimeframeChange?.(30)}
                        className={`px-4 py-1.5 text-[11px] font-black tracking-widest rounded-lg transition-all
                        ${activeDays === 30 ? 'bg-[#1F2933] text-white shadow-lg shadow-[#1F2933]/20' : 'text-slate-500 hover:text-slate-900'}`}
                    >
                        شهري
                    </button>
                </div>
            </div>

            <div className="h-[350px] w-full font-sans">
                {isEmpty ? (
                    <div className="flex h-full w-full items-center justify-center">
                        <p className="text-center text-slate-400 font-bold text-sm">لا يوجد بيانات مبيعات</p>
                    </div>
                ) : (
                    <ResponsiveContainer width="100%" height="100%">
                        <AreaChart data={data}>
                            <defs>
                                <linearGradient id="colorSales" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="#f97316" stopOpacity={0.2} />
                                    <stop offset="95%" stopColor="#f97316" stopOpacity={0} />
                                </linearGradient>
                                <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="#2563eb" stopOpacity={0.2} />
                                    <stop offset="95%" stopColor="#2563eb" stopOpacity={0} />
                                </linearGradient>
                            </defs>
                            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                            <XAxis
                                dataKey="name"
                                axisLine={false}
                                tickLine={false}
                                tick={{ fill: '#64748b', fontSize: 10, fontWeight: 800 }}
                                dy={15}
                            />
                            <YAxis
                                axisLine={false}
                                tickLine={false}
                                tick={{ fill: '#64748b', fontSize: 10, fontWeight: 800 }}
                                dx={-15}
                            />
                            <Tooltip
                                contentStyle={{
                                    backgroundColor: '#ffffff',
                                    border: '1px solid #e2e8f0',
                                    borderRadius: '16px',
                                    backdropFilter: 'blur(20px)',
                                    boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
                                    color: '#0f172a',
                                    fontSize: '12px',
                                    fontWeight: 'bold',
                                    textAlign: 'right'
                                }}
                                itemStyle={{ color: '#0f172a' }}
                                cursor={{ stroke: '#f97316', strokeWidth: 2, strokeDasharray: '5 5' }}
                            />
                            <Area
                                type="monotone"
                                dataKey="sales"
                                stroke="#f97316"
                                strokeWidth={3}
                                fillOpacity={1}
                                fill="url(#colorSales)"
                                animationDuration={2000}
                            />
                            <Area
                                type="monotone"
                                dataKey="revenue"
                                stroke="#2563eb"
                                strokeWidth={3}
                                fillOpacity={1}
                                fill="url(#colorRevenue)"
                                animationDuration={2500}
                            />
                        </AreaChart>
                    </ResponsiveContainer>
                )}
            </div>

            <div className="absolute -bottom-10 -right-10 w-40 h-40 bg-slate-100 rounded-full blur-[80px] pointer-events-none opacity-0 group-hover:opacity-100 transition-opacity duration-700"></div>
        </motion.div>
    );
};

export default SalesChart;
