import React, { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Package, Plus, Search, Filter, Edit, Trash2, AlertTriangle, X, Check } from 'lucide-react';
import { getProducts, deleteProduct, getCategories } from '@/services/supabase/inventoryService';

import ProductForm from '@/components/Admin/Products/ProductForm';
import Modal from '@/components/ui/Modal';

const statusBadge = (stock) => {
    if (stock === 0) return { label: 'نفد', cls: 'bg-red-100 text-red-700 border-red-200' };
    if (stock <= 5) return { label: 'منخفض', cls: 'bg-slate-200 text-slate-700 border-slate-300' };
    return { label: 'متوفر', cls: 'bg-green-100 text-green-700 border-green-200' };
};

const Toast = ({ msg, type, onClose }) => (
    <motion.div initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 30 }}
        className={`fixed bottom-6 left-6 z-[999] flex items-center gap-3 px-5 py-3 rounded-2xl shadow-2xl border backdrop-blur-xl
        ${type === 'success' ? 'bg-white border-green-100 text-green-700' : 'bg-white border-red-100 text-red-700'}`}>
        {type === 'success' ? <Check size={16} className="text-green-600" /> : <X size={16} className="text-red-600" />}
        <span className="text-sm font-bold">{msg}</span>
    </motion.div>
);

const Products = () => {
    const [products, setProducts] = useState([]);
    const [categories, setCategories] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [categoryFilter, setCategoryFilter] = useState('');
    const [showForm, setShowForm] = useState(false);
    const [editProduct, setEditProduct] = useState(null);
    const [toast, setToast] = useState(null);
    const [confirmDelete, setConfirmDelete] = useState(null);

    const showToast = (msg, type = 'success') => {
        setToast({ msg, type });
        setTimeout(() => setToast(null), 3000);
    };

    const [currentPage, setCurrentPage] = useState(1);

    const loadData = useCallback(async () => {
        setLoading(true);
        const [prodRes, catRes] = await Promise.all([
            getProducts({ search, categoryId: categoryFilter ? parseInt(categoryFilter) : null }),
            getCategories()
        ]);
        setProducts(prodRes.data || []);
        setCategories(catRes.data || []);
        setCurrentPage(1); // Reset page on filter/search change
        setLoading(false);
    }, [search, categoryFilter]);

    useEffect(() => { loadData(); }, [loadData]);

    const handleDelete = async (id) => {
        const { error } = await deleteProduct(id);
        if (error) { showToast('فشل حذف المنتج', 'error'); }
        else { showToast('تم حذف المنتج بنجاح'); loadData(); }
        setConfirmDelete(null);
    };

    const handleSaved = (msg) => {
        setShowForm(false);
        setEditProduct(null);
        showToast(msg);
        loadData();
    };

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8" dir="rtl">
            {/* Header */}
            <header className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-black text-slate-900 tracking-tight border-r-4 border-[#1F2933] pr-4">
                        إدارة المنتجات
                    </h1>
                    <p className="text-slate-500 text-sm font-bold mt-1 pr-5">{products.length} منتج في الكتالوج</p>
                </div>
                <button 
                    onClick={() => { setEditProduct(null); setShowForm(true); }}
                    className="flex items-center gap-2 px-8 py-4 bg-[#1F2933] hover:bg-[#3A3F45] rounded-full text-white font-bold text-sm transition-all shadow-lg shadow-[#1F2933]/20 hover:scale-105 active:scale-95"
                >
                    <Plus size={18} />
                    إضافة منتج جديد
                </button>
            </header>

            {/* Filters */}
            <div className="flex flex-col sm:flex-row gap-3">
                <div className="relative flex-1">
                    <Search size={16} className="absolute right-6 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input type="text" placeholder="ابحث عن منتج..." value={search}
                        onChange={e => setSearch(e.target.value)}
                        className="w-full bg-slate-100/60 border-none rounded-full pr-14 pl-6 py-4.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-4 focus:ring-[#3A3F45]/5 transition-all shadow-sm focus:bg-white" />
                </div>
                <div className="relative">
                    <Filter size={16} className="absolute right-6 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                    <select value={categoryFilter} onChange={e => setCategoryFilter(e.target.value)}
                        className="bg-slate-100/60 border-none rounded-full pr-14 pl-10 py-4.5 text-sm text-slate-900 appearance-none focus:outline-none focus:ring-4 focus:ring-[#3A3F45]/5 transition-all min-w-[220px] shadow-sm focus:bg-white">
                        <option value="">كل التصنيفات</option>
                        {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                    </select>
                </div>
            </div>

            {/* Table */}
            <div className="bg-white border border-slate-200/60 rounded-[2rem] overflow-hidden shadow-sm">
                {loading ? (
                    <div className="flex items-center justify-center py-24">
                        <div className="w-8 h-8 border-2 border-[#1F2933] border-t-transparent rounded-full animate-spin" />
                    </div>
                ) : products.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-24 gap-4">
                        <Package size={48} className="text-slate-200" />
                        <p className="text-slate-400 font-bold">لا توجد منتجات</p>
                        <button onClick={() => setShowForm(true)} className="text-[#1F2933] text-sm font-bold hover:underline">+ أضف أول منتج</button>
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead>
                                <tr className="border-b border-slate-100 bg-slate-50/50">
                                    <th className="text-right text-[11px] font-black text-slate-500 uppercase tracking-widest px-6 py-4">المنتج</th>
                                    <th className="text-right text-[11px] font-black text-slate-500 uppercase tracking-widest px-6 py-4 hidden sm:table-cell">التصنيف</th>
                                    <th className="text-right text-[11px] font-black text-slate-500 uppercase tracking-widest px-6 py-4">السعر</th>
                                    <th className="text-right text-[11px] font-black text-slate-500 uppercase tracking-widest px-6 py-4 hidden md:table-cell">المخزون</th>
                                    <th className="text-right text-[11px] font-black text-slate-500 uppercase tracking-widest px-6 py-4">الحالة</th>
                                    <th className="px-6 py-4" />
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-50">
                                {products.slice((currentPage - 1) * 10, currentPage * 10).map((p, i) => {
                                    const badge = statusBadge(p.stock_quantity);
                                    const mainImage = p.images?.[0];
                                    return (
                                        <motion.tr key={p.id} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.04 }}
                                            className="hover:bg-slate-50 transition-colors group">
                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-10 h-10 bg-slate-100 rounded-xl flex items-center justify-center shrink-0 border border-slate-200 overflow-hidden">
                                                        {mainImage ? (
                                                            <img src={mainImage} alt="" className="w-full h-full object-cover" />
                                                        ) : (
                                                            <Package size={18} className="text-[#1F2933]" />
                                                        )}
                                                    </div>
                                                    <div>
                                                        <p className="text-sm font-black text-slate-900">{p.name}</p>
                                                        <p className="text-xs text-slate-500 truncate max-w-[200px]">{p.description}</p>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="px-6 py-4 hidden sm:table-cell">
                                                <span className="text-sm text-slate-500">{p.categories?.name || '—'}</span>
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className="text-sm font-black text-slate-900 font-sans">{Number(p.base_price).toLocaleString()} جنيه مصرى</span>
                                            </td>
                                            <td className="px-6 py-4 hidden md:table-cell">
                                                <span className="text-sm text-slate-700 font-bold font-sans">{p.stock_quantity}</span>
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className={`inline-flex items-center px-3 py-1 rounded-full text-[11px] font-black border ${badge.cls}`}>{badge.label}</span>
                                            </td>
                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-2 opacity-100 lg:opacity-0 lg:group-hover:opacity-100 transition-opacity">
                                                    <button onClick={() => { setEditProduct(p); setShowForm(true); }}
                                                        className="p-2 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-xl transition-all">
                                                        <Edit size={15} />
                                                    </button>
                                                    <button onClick={() => setConfirmDelete(p.id)}
                                                        className="p-2 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-xl transition-all">
                                                        <Trash2 size={15} />
                                                    </button>
                                                </div>
                                            </td>
                                        </motion.tr>
                                    );
                                })}
                            </tbody>
                        </table>

                        {/* Pagination */}
                        <div className="flex items-center justify-between border-t border-slate-100 px-6 py-4 bg-slate-50/30">
                            <span className="text-sm text-slate-500 font-bold">
                                صفحة {currentPage} من {Math.max(1, Math.ceil(products.length / 10))}
                            </span>
                            <div className="flex gap-2">
                                <button 
                                    onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                                    disabled={currentPage === 1}
                                    className="px-4 py-2 bg-white border border-slate-200 text-slate-700 text-sm font-bold rounded-xl hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                                >
                                    السابق
                                </button>
                                <button 
                                    onClick={() => setCurrentPage(prev => Math.min(Math.ceil(products.length / 10), prev + 1))}
                                    disabled={currentPage === Math.ceil(products.length / 10) || products.length === 0}
                                    className="px-4 py-2 bg-white border border-slate-200 text-slate-700 text-sm font-bold rounded-xl hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                                >
                                    التالي
                                </button>
                            </div>
                        </div>
                    </div>
                )}
            </div>

            {/* Modals */}
            <AnimatePresence>
                <Modal 
                    isOpen={showForm} 
                    onClose={() => { setShowForm(false); setEditProduct(null); }}
                    size="xl"
                    title={editProduct ? 'تعديل المنتج' : 'إضافة منتج جديد'}
                    description="أكمل التفاصيل أدناه لظهور المنتج بشكل جذاب للمتسوقين"
                >
                    <ProductForm
                        product={editProduct}
                        categories={categories}
                        onClose={() => { setShowForm(false); setEditProduct(null); }}
                        onSaved={handleSaved}
                        onRefreshCategories={loadData}
                    />
                </Modal>
                
                <Modal 
                    isOpen={!!confirmDelete} 
                    onClose={() => setConfirmDelete(null)}
                    title="تأكيد حذف المنتج"
                    description="هل أنت متأكد من حذف هذا المنتج؟ لا يمكن التراجع عن هذا الإجراء وسيتم مسحه نهائياً."
                >
                    <div className="flex flex-col items-center py-4">
                        <div className="w-20 h-20 bg-red-50 rounded-[2rem] flex items-center justify-center mb-6 shadow-sm border border-red-100/50">
                            <AlertTriangle size={40} className="text-red-600" />
                        </div>
                        <div className="flex gap-4 w-full pt-4 border-t border-slate-100">
                            <button onClick={() => setConfirmDelete(null)}
                                className="flex-1 px-6 py-4 bg-slate-100 text-slate-600 rounded-2xl text-sm font-bold hover:bg-slate-200 transition-all font-sans">إلغاء</button>
                            <button onClick={() => handleDelete(confirmDelete)}
                                className="flex-[2] px-6 py-4 bg-red-600 rounded-2xl text-sm font-bold text-white hover:bg-red-500 transition-all shadow-xl shadow-red-600/20 font-sans">حذف المنتج نهائياً</button>
                        </div>
                    </div>
                </Modal>

                {toast && <Toast key={toast.msg} msg={toast.msg} type={toast.type} onClose={() => setToast(null)} />}
            </AnimatePresence>
        </motion.div>
    );
};

export default Products;
