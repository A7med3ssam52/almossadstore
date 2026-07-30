import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import {
    ShoppingBag,
    Clock,
    AlertTriangle,
    ChevronLeft,
    Calendar
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { getRecentOrders } from '@/services/supabase/metrics';

const lowStockItems = [
    { name: 'دهان جوتن فينوماستيك - أبيض مطفي', stock: 3, unit: 'علبة' },
    { name: 'فرشاة دهان احترافية مقاس 4 بوصة', stock: 1, unit: 'قطعة' },
];

/**
 * QuickActions Component
 * Lists recent orders and low-stock alerts on the dashboard.
 * Now fetches real recent orders from Supabase.
 */
const QuickActions = ({ stockAlerts = lowStockItems }) => {
    const navigate = useNavigate();
    const [recentOrders, setRecentOrders] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchOrders = async () => {
            try {
                const orders = await getRecentOrders(5);
                setRecentOrders(orders);
            } catch (error) {
                console.error("Error fetching recent orders:", error);
            } finally {
                setLoading(false);
            }
        };
        fetchOrders();
    }, []);

    return (
        <div className="grid grid-cols-1 gap-8 mt-10">

            {/* Recent Orders Section */}
            <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                className="p-8 bg-white border border-slate-200 rounded-[2.5rem] shadow-sm hover:shadow-xl hover:shadow-slate-200/60 relative group overflow-hidden"
            >
                <div className="flex items-center justify-between mb-8">
                    <div className="flex flex-col">
                        <h3 className="text-xl font-black text-slate-900 tracking-tight leading-none">آخر الطلبات</h3>
                        <p className="text-slate-500 text-[10px] font-bold tracking-widest uppercase mt-2 font-sans flex items-center gap-1.5 opacity-80 backdrop-blur-sm">
                            <Calendar size={12} className="text-[#3A3F45]" />
                            Real-time Feed
                        </p>
                    </div>
                    <motion.button
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                        onClick={() => navigate('/admin/orders')}
                        className="group/btn flex items-center gap-2 px-6 py-2 bg-slate-50 border border-slate-200 rounded-2xl text-[11px] font-black text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition-all duration-300 tracking-wide cursor-pointer focus:outline-none focus:ring-2 focus:ring-[#3A3F45]/20"
                    >
                        مشاهدة الكل
                        <ChevronLeft size={16} className="text-slate-400 group-hover/btn:text-[#3A3F45] transition-colors" />
                    </motion.button>
                </div>

                <div className="space-y-4">
                    {loading ? (
                        <div className="h-40 flex items-center justify-center text-slate-400 text-xs font-bold uppercase tracking-widest">
                            جاري تحميل الطلبات...
                        </div>
                    ) : recentOrders.length > 0 ? (
                        recentOrders.map((order, idx) => (
                            <div key={order.id} className="p-4 bg-slate-50 border border-slate-100 rounded-[1.5rem] flex items-center justify-between group/item hover:bg-white hover:border-[#3A3F45]/20 hover:shadow-lg hover:shadow-[#1F2933]/5 transition-all duration-300 cursor-pointer relative overflow-hidden">
                                <div className="flex items-center gap-4 relative z-10">
                                    <div className="w-12 h-12 bg-white border border-slate-200 rounded-xl flex items-center justify-center transition-transform group-hover/item:scale-110 shadow-sm group-hover/item:border-[#3A3F45]/30">
                                        <ShoppingBag size={20} className="text-[#3A3F45] opacity-80" />
                                    </div>
                                    <div className="flex flex-col gap-0.5">
                                        <span className="text-[13px] font-black text-slate-900 tracking-wide font-sans">{order.id}</span>
                                        <p className="text-[11px] font-bold text-slate-500 opacity-90">{order.customer}</p>
                                    </div>
                                </div>

                                <div className="flex flex-col items-end gap-1.5 relative z-10 text-left">
                                    <span className="text-[12px] font-black text-slate-900 tracking-widest font-sans">{order.total}</span>
                                    <div className="flex items-center gap-2">
                                        <Clock size={12} className="text-slate-400" />
                                        <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest font-sans">{order.time}</span>
                                    </div>
                                </div>

                                {/* Status Glow Indicator */}
                                <div className={`absolute right-0 top-0 w-1 h-full rounded-r-2xl transition-all duration-300 opacity-0 group-hover/item:opacity-100
                    ${order.status === 'pending' ? 'bg-[#1F2933]' : 'bg-green-600'}`}></div>
                            </div>
                        ))
                    ) : (
                        <div className="h-40 flex items-center justify-center text-slate-400 text-xs font-bold uppercase tracking-widest">
                            لا توجد طلبات بعد
                        </div>
                    )}
                </div>
            </motion.div>
        </div>
    );
};

export default QuickActions;

