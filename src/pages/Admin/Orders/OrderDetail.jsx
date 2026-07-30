import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { ArrowRight, Download, MessageCircle, Package, MapPin, CreditCard, Clock } from 'lucide-react';
import { useParams, useNavigate } from 'react-router-dom';
import { getOrderById, updateOrderStatus } from '@/services/supabase/orderService';

const STATUS_CONFIG = {
    pending: { label: 'قيد الانتظار', cls: 'bg-slate-200 text-slate-700 border-slate-300' },
    processing: { label: 'قيد التنفيذ', cls: 'bg-blue-100 text-blue-700 border-blue-200' },
    completed: { label: 'مكتمل', cls: 'bg-green-100 text-green-700 border-green-200' },
    cancelled: { label: 'ملغى', cls: 'bg-red-100 text-red-700 border-red-200' },
};

const MOCK_ITEMS = [
    { name: 'دهان جوتن فينوماستيك أبيض', qty: 2, price: 185 },
    { name: 'فرشاة دهان 4 بوصة', qty: 3, price: 35 },
];

const OrderDetail = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const [order, setOrder] = useState(null);
    const [loading, setLoading] = useState(true);
    const [updatingStatus, setUpdatingStatus] = useState(false);

    useEffect(() => {
        (async () => {
            const { data } = await getOrderById(id);
            setOrder(data);
            setLoading(false);
        })();
    }, [id]);

    const handleStatusChange = async (newStatus) => {
        setUpdatingStatus(true);
        await updateOrderStatus(order.id, newStatus);
        setOrder(prev => ({ ...prev, status: newStatus }));
        setUpdatingStatus(false);
    };

    const handleWhatsApp = () => {
        const phone = order?.shipping_address?.phone || '';
        const msg = encodeURIComponent(`مرحباً ${order?.profiles?.full_name || ''}، طلبك رقم #${order?.id?.slice(-6).toUpperCase()} الآن في حالة: ${STATUS_CONFIG[order?.status]?.label}`);
        window.open(`https://wa.me/${phone}?text=${msg}`, '_blank');
    };

    const handleDownloadInvoice = async () => {
        const { generateInvoicePDF } = await import('@/services/admin/invoiceGenerator');
        generateInvoicePDF(order, MOCK_ITEMS);
    };

    if (loading) return (
        <div className="flex items-center justify-center py-24">
            <div className="w-8 h-8 border-2 border-[#1F2933] border-t-transparent rounded-full animate-spin" />
        </div>
    );

    if (!order) return (
        <div className="text-center py-24 text-slate-500">لم يتم العثور على الطلب</div>
    );

    const cfg = STATUS_CONFIG[order.status] || STATUS_CONFIG.pending;

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8 max-w-4xl mx-auto" dir="rtl">
            {/* Header */}
            <header className="flex items-center gap-4">
                <button onClick={() => navigate('/admin/orders')}
                    className="p-2 text-slate-400 hover:text-slate-900 hover:bg-slate-100 rounded-xl transition-all">
                    <ArrowRight size={20} />
                </button>
                <div>
                    <h1 className="text-3xl font-black text-slate-900 tracking-tight">
                        طلب #{order.id.slice(-6).toUpperCase()}
                    </h1>
                    <p className="text-slate-500 text-sm mt-1">{new Date(order.created_at).toLocaleString('ar-SA')}</p>
                </div>
                <div className="mr-auto flex gap-3">
                    <button onClick={handleWhatsApp}
                        className="flex items-center gap-2 px-4 py-2 bg-green-50 border border-green-200 text-green-700 rounded-2xl text-sm font-bold hover:bg-green-100 transition-all">
                        <MessageCircle size={16} /> واتساب
                    </button>
                    <button onClick={handleDownloadInvoice}
                        className="flex items-center gap-2 px-4 py-2 bg-[#1F2933] text-white rounded-2xl text-sm font-bold hover:bg-[#3A3F45] transition-all shadow-lg shadow-[#1F2933]/10">
                        <Download size={16} /> تحميل الفاتورة
                    </button>
                </div>
            </header>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Order Items */}
                <div className="lg:col-span-2 space-y-4">
                    <div className="bg-white border border-slate-200 rounded-3xl p-6 shadow-sm">
                        <h2 className="text-lg font-black text-slate-900 mb-4 flex items-center gap-2">
                            <Package size={18} className="text-[#3A3F45]" /> عناصر الطلب
                        </h2>
                        <div className="space-y-3">
                            {MOCK_ITEMS.map((item, i) => (
                                <div key={i} className="flex items-center justify-between p-4 bg-slate-50 rounded-2xl border border-slate-100">
                                    <div>
                                        <p className="text-sm font-bold text-slate-900">{item.name}</p>
                                        <p className="text-xs text-slate-500">الكمية: {item.qty}</p>
                                    </div>
                                    <span className="text-sm font-black text-slate-900 font-sans">{(item.price * item.qty).toLocaleString()} جنيه مصرى</span>
                                </div>
                            ))}
                            <div className="border-t border-slate-100 pt-3 mt-3 flex justify-between">
                                <span className="font-black text-slate-900">الإجمالي</span>
                                <span className="font-black text-[#1F2933] font-sans text-lg">{Number(order.total_amount).toLocaleString()} جنيه مصرى</span>
                            </div>
                        </div>
                    </div>

                    {/* Shipping Address */}
                    <div className="bg-white border border-slate-200 rounded-3xl p-6 shadow-sm">
                        <h2 className="text-lg font-black text-slate-900 mb-4 flex items-center gap-2">
                            <MapPin size={18} className="text-[#3A3F45]" /> عنوان الشحن
                        </h2>
                        <div className="space-y-2">
                            <p className="text-slate-900 font-bold">{order.shipping_address?.name}</p>
                            <p className="text-slate-600 text-sm">{order.shipping_address?.city}</p>
                            <p className="text-slate-500 text-sm font-sans">{order.shipping_address?.phone}</p>
                        </div>
                    </div>
                </div>

                {/* Sidebar */}
                <div className="space-y-4">
                    {/* Status */}
                    <div className="bg-white border border-slate-200 rounded-3xl p-6 shadow-sm">
                        <h2 className="text-sm font-black text-slate-500 uppercase tracking-widest mb-3">حالة الطلب</h2>
                        <span className={`inline-flex px-3 py-1.5 rounded-full text-sm font-black border ${cfg.cls} mb-4`}>{cfg.label}</span>
                        <div className="space-y-2">
                            {Object.entries(STATUS_CONFIG).map(([k, v]) => (
                                <button key={k} disabled={order.status === k || updatingStatus} onClick={() => handleStatusChange(k)}
                                    className={`w-full text-right px-4 py-2.5 rounded-xl text-sm font-bold transition-all border
                                    ${order.status === k ? `${v.cls} cursor-default` : 'text-slate-500 border-slate-100 hover:bg-slate-50 hover:text-slate-900'}`}>
                                    {v.label}
                                </button>
                            ))}
                        </div>
                    </div>

                    {/* Payment */}
                    <div className="bg-white border border-slate-200 rounded-3xl p-6 shadow-sm">
                        <h2 className="text-sm font-black text-slate-500 uppercase tracking-widest mb-3 flex items-center gap-2">
                            <CreditCard size={14} /> الدفع
                        </h2>
                        <div className="space-y-2">
                            <div className="flex justify-between">
                                <span className="text-slate-500 text-sm">الحالة</span>
                                <span className={`text-sm font-bold ${order.payment_status === 'paid' ? 'text-green-600' : 'text-[#1F2933]'}`}>
                                    {order.payment_status === 'paid' ? 'مدفوع' : order.payment_status === 'refunded' ? 'مسترد' : 'غير مدفوع'}
                                </span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-slate-500 text-sm">الإجمالي</span>
                                <span className="text-slate-900 font-black font-sans">{Number(order.total_amount).toLocaleString()} جنيه مصرى</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </motion.div>
    );
};

export default OrderDetail;

