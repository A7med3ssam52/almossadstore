import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { ShoppingBag, Clock, ChevronLeft, Calendar } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { getRecentOrders } from '@/services/supabase/metrics';
import { getProducts } from '@/services/supabase/inventoryService';
import { supabase } from '@/services/supabase/adminClient';

const QuickActions = () => {
    const navigate = useNavigate();
    const [recentOrders, setRecentOrders] = useState([]);
    const [loading, setLoading] = useState(true);
    const [lowStock, setLowStock] = useState([]);

    const fetchData = async () => {
        try {
            const [orders, prodRes] = await Promise.all([
                getRecentOrders(5),
                getProducts()
            ]);
            setRecentOrders(orders);
            const low = (prodRes.data||[]).filter(p=> (p.stock_quantity||0) <=5).slice(0,5).map(p=>({
                name: p.name, stock: p.stock_quantity, unit: 'قطعة'
            }));
            setLowStock(low);
        } catch (error) {
            console.error("Error fetching dashboard feeds:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
        // Realtime for new orders
        let channel;
        try {
            channel = supabase.channel('orders-realtime').on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'orders' }, ()=> fetchData()).subscribe();
        } catch {}
        return ()=> { if(channel) supabase.removeChannel(channel); };
    }, []);

    return (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mt-10">
            <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} className="lg:col-span-2 p-8 bg-white border border-slate-200 rounded-[2.5rem] shadow-sm hover:shadow-xl hover:shadow-slate-200/60 relative group overflow-hidden">
                <div className="flex items-center justify-between mb-8">
                    <div className="flex flex-col">
                        <h3 className="text-xl font-black text-slate-900 tracking-tight leading-none">آخر الطلبات</h3>
                        <p className="text-slate-500 text-[10px] font-bold tracking-widest uppercase mt-2 font-sans flex items-center gap-1.5 opacity-80"><Calendar size={12} className="text-[#3A3F45]" /> Real-time Feed</p>
                    </div>
                    <motion.button whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }} onClick={() => navigate('/admin/orders')} className="group/btn flex items-center gap-2 px-6 py-2 bg-slate-50 border border-slate-200 rounded-2xl text-[11px] font-black text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition-all duration-300 tracking-wide">
                        عرض الكل <ChevronLeft size={16} className="text-slate-400 group-hover/btn:text-[#3A3F45] transition-colors" />
                    </motion.button>
                </div>
                <div className="space-y-4">
                    {loading ? (
                        <div className="h-40 flex items-center justify-center text-slate-400 text-xs font-bold uppercase tracking-widest">جاري تحميل الطلبات...</div>
                    ) : recentOrders.length > 0 ? (
                        recentOrders.map((order) => (
                            <div key={order.rawId || order.id} onClick={()=> navigate(`/admin/orders/${order.rawId}`)} className="p-4 bg-slate-50 border border-slate-100 rounded-[1.5rem] flex items-center justify-between group/item hover:bg-white hover:border-[#3A3F45]/20 hover:shadow-lg hover:shadow-[#1F2933]/5 transition-all duration-300 cursor-pointer relative overflow-hidden">
                                <div className="flex items-center gap-4 relative z-10">
                                    <div className="w-12 h-12 bg-white border border-slate-200 rounded-xl flex items-center justify-center transition-transform group-hover/item:scale-110 shadow-sm"><ShoppingBag size={20} className="text-[#3A3F45] opacity-80" /></div>
                                    <div className="flex flex-col gap-0.5">
                                        <span className="text-[13px] font-black text-slate-900 tracking-wide font-sans">{order.id}</span>
                                        <p className="text-[11px] font-bold text-slate-500 opacity-90">{order.customer}</p>
                                    </div>
                                </div>
                                <div className="flex flex-col items-end gap-1.5 relative z-10 text-left">
                                    <span className="text-[12px] font-black text-slate-900 tracking-widest font-sans">{order.total}</span>
                                    <div className="flex items-center gap-2"><Clock size={12} className="text-slate-400" /><span className="text-[10px] font-black text-slate-400 uppercase tracking-widest font-sans">{order.time}</span></div>
                                </div>
                                <div className={`absolute right-0 top-0 w-1 h-full rounded-r-2xl transition-all duration-300 opacity-0 group-hover/item:opacity-100 ${order.status === 'pending' ? 'bg-[#1F2933]' : 'bg-green-600'}`}></div>
                            </div>
                        ))
                    ) : (
                        <div className="h-40 flex items-center justify-center text-slate-400 text-xs font-bold uppercase tracking-widest">لا يوجد طلبات بعد</div>
                    )}
                </div>
            </motion.div>

            <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} className="p-8 bg-white border border-slate-200 rounded-[2.5rem] shadow-sm">
                <h3 className="text-xl font-black text-slate-900 mb-6">تنبيهات المخزون</h3>
                {lowStock.length ? lowStock.map((it, idx)=> (
                    <div key={idx} className="p-4 bg-amber-50 border border-amber-200 rounded-2xl flex justify-between items-center mb-3">
                        <span className="text-sm font-bold text-slate-900 truncate">{it.name}</span>
                        <span className="text-xs font-black text-amber-700 bg-white px-3 py-1 rounded-full border border-amber-200">{it.stock} {it.unit}</span>
                    </div>
                )) : <p className="text-sm text-slate-400 text-center py-8">المخزون جيد</p>}
                <button onClick={()=> navigate('/admin/products')} className="w-full mt-4 py-3 bg-slate-900 text-white rounded-2xl text-sm font-bold hover:bg-slate-800">إدارة المنتجات</button>
            </motion.div>
        </div>
    );
};
export default QuickActions;