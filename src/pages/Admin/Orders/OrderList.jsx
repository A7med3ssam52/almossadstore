import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { ShoppingCart, Clock, Check, X, AlertCircle, ChevronLeft } from 'lucide-react';
import { getOrders, updateOrderStatus } from '@/services/supabase/orderService';
import { useNavigate } from 'react-router-dom';

const STATUS_CONFIG = {
    pending: { label: 'قيد الانتظار', cls: 'bg-slate-200 text-slate-700 border-slate-300', icon: Clock },
    processing: { label: 'قيد التجهيز', cls: 'bg-blue-100 text-blue-700 border-blue-200', icon: AlertCircle },
    completed: { label: 'مكتمل', cls: 'bg-green-100 text-green-700 border-green-200', icon: Check },
    cancelled: { label: 'ملغي', cls: 'bg-red-100 text-red-700 border-red-200', icon: X },
};
const TABS = [
    { key: 'all', label: 'الكل' },
    { key: 'pending', label: 'قيد الانتظار' },
    { key: 'processing', label: 'قيد التجهيز' },
    { key: 'completed', label: 'مكتمل' },
    { key: 'cancelled', label: 'ملغي' },
];
const formatTime = (iso) => {
    const d = new Date(iso);
    const diff = Date.now() - d.getTime();
    const m = Math.floor(diff / 60000);
    if (m < 1) return 'الآن';
    if (m < 60) return `منذ ${m} دقيقة`;
    const h = Math.floor(m / 60);
    if (h < 24) return `منذ ${h} ساعة`;
    return d.toLocaleDateString('ar-SA');
};
const getCustomerName = (order) => {
    if (order.profiles?.full_name) return order.profiles.full_name;
    if (order.customer_name) return order.customer_name;
    try {
        const s = typeof order.shipping_address === 'string' ? JSON.parse(order.shipping_address) : order.shipping_address;
        if (s?.name) return s.name;
        if (typeof order.shipping_address === 'string' && order.shipping_address.includes('-')) return order.shipping_address.split('-')[0].trim();
    } catch {}
    return 'زبون';
};
const OrderList = () => {
    const [orders, setOrders] = useState([]);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState('all');
    const [updating, setUpdating] = useState(null);
    const navigate = useNavigate();
    const loadOrders = async () => {
        setLoading(true);
        const { data } = await getOrders({ status: activeTab });
        setOrders(data || []);
        setLoading(false);
    };
    useEffect(() => { loadOrders(); }, [activeTab]);
    const handleStatusChange = async (orderId, newStatus) => {
        setUpdating(orderId);
        await updateOrderStatus(orderId, newStatus);
        await loadOrders();
        setUpdating(null);
    };
    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8" dir="rtl">
            <header>
                <h1 className="text-3xl font-black text-slate-900 tracking-tight border-r-4 border-[#1F2933] pr-4">إدارة الطلبات</h1>
                <p className="text-slate-500 text-sm font-bold mt-1 pr-5">{orders.length} طلب</p>
            </header>
            <div className="flex gap-2 flex-wrap p-1 bg-slate-100 rounded-2xl w-fit border border-slate-200">
                {TABS.map(tab => (
                    <button key={tab.key} onClick={() => setActiveTab(tab.key)} className={`px-5 py-2 rounded-xl text-sm font-black transition-all ${activeTab === tab.key ? 'bg-[#1F2933] text-white shadow-lg shadow-[#1F2933]/20' : 'text-slate-500 hover:text-slate-900'}`}>{tab.label}</button>
                ))}
            </div>
            <div className="bg-white border border-slate-200 rounded-3xl overflow-hidden shadow-sm">
                {loading ? (
                    <div className="flex items-center justify-center py-24"><div className="w-8 h-8 border-2 border-[#1F2933] border-t-transparent rounded-full animate-spin" /></div>
                ) : orders.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-24 gap-4"><ShoppingCart size={48} className="text-slate-200" /><p className="text-slate-400 font-bold">لا يوجد طلبات</p></div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead><tr className="border-b border-slate-100 bg-slate-50/50">{['رقم الطلب','العميل','الإجمالي','الحالة','الوقت','إجراء'].map(h => (<th key={h} className="text-right text-[11px] font-black text-slate-500 uppercase tracking-widest px-6 py-4">{h}</th>))}</tr></thead>
                            <tbody className="divide-y divide-slate-50">
                                {orders.map((order, i) => {
                                    const cfg = STATUS_CONFIG[order.status] || STATUS_CONFIG.pending;
                                    return (
                                        <motion.tr key={order.id} initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.04 }} className="hover:bg-slate-50 transition-colors group cursor-pointer" onClick={() => navigate(`/admin/orders/${order.id}`)}>
                                            <td className="px-6 py-4"><span className="text-sm font-black text-slate-900 font-sans">#{order.id.slice(-6).toUpperCase()}</span>{order.coupon_code && <span className="mr-2 text-[10px] bg-green-100 text-green-700 px-2 py-0.5 rounded-full font-bold">{order.coupon_code}</span>}</td>
                                            <td className="px-6 py-4"><span className="text-sm text-slate-600">{getCustomerName(order)}</span></td>
                                            <td className="px-6 py-4"><span className="text-sm font-black text-slate-900 font-sans">{Number(order.total_amount).toLocaleString()} ج.م</span>{Number(order.discount_amount)>0 && <span className="mr-2 text-xs text-green-600">(-{Number(order.discount_amount).toLocaleString()})</span>}</td>
                                            <td className="px-6 py-4" onClick={e => e.stopPropagation()}><select value={order.status} onChange={e => handleStatusChange(order.id, e.target.value)} disabled={updating === order.id} className={`inline-flex items-center px-3 py-1.5 rounded-full text-[11px] font-black border appearance-none cursor-pointer focus:outline-none ${cfg.cls}`}>{Object.entries(STATUS_CONFIG).map(([k, v]) => (<option key={k} value={k}>{v.label}</option>))}</select></td>
                                            <td className="px-6 py-4"><span className="text-xs text-slate-400">{formatTime(order.created_at)}</span></td>
                                            <td className="px-6 py-4"><button onClick={e => { e.stopPropagation(); navigate(`/admin/orders/${order.id}`); }} className="opacity-100 lg:opacity-0 lg:group-hover:opacity-100 p-2 text-slate-400 hover:text-[#1F2933] hover:bg-slate-100 rounded-xl transition-all flex items-center gap-1 text-xs font-bold whitespace-nowrap">التفاصيل <ChevronLeft size={14} /></button></td>
                                        </motion.tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </motion.div>
    );
};
export default OrderList;