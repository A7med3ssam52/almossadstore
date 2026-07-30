import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Tag, Plus, Edit, Trash2, AlertTriangle, X, Check, FolderOpen, Loader2 } from 'lucide-react';
import { getCategories, createCategory, updateCategory, deleteCategory } from '@/services/supabase/inventoryService';
import Modal from '@/components/UI/Modal';

const Toast = ({ msg, type }) => (
    <motion.div initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 30 }}
        className={`fixed bottom-6 left-6 z-[99999] flex items-center gap-3 px-5 py-3 rounded-2xl shadow-2xl border backdrop-blur-xl
        ${type === 'success' ? 'bg-white border-green-100 text-green-700' : 'bg-white border-red-100 text-red-700'}`}>
        {type === 'success' ? <Check size={16} className="text-green-600" /> : <X size={16} className="text-red-600" />}
        <span className="text-sm font-bold">{msg}</span>
    </motion.div>
);

const CategoryForm = ({ category, categories, onClose, onSaved }) => {
    const [form, setForm] = useState({
        name: category?.name || '',
        parent_id: category?.parent_id || '',
    });
    const [saving, setSaving] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        const payload = { name: form.name, parent_id: form.parent_id || null };
        if (category?.id) { await updateCategory(category.id, payload); }
        else { await createCategory(payload); }
        setSaving(false);
        onSaved(category?.id ? 'تم تحديث التصنيف بنجاح' : 'تم إضافة التصنيف الجديد بنجاح');
    };

    const inputClasses = "w-full bg-slate-100/60 border-transparent rounded-[1.25rem] px-6 py-4 text-slate-900 text-sm focus:outline-none focus:ring-4 focus:ring-orange-500/10 focus:bg-white transition-all duration-500 placeholder:text-slate-400 font-medium shadow-inner active:scale-[0.99]";
    const labelClasses = "flex items-center gap-2 text-[10px] font-black text-slate-500 uppercase tracking-widest mb-2 mr-1";

    return (
        <form onSubmit={handleSubmit} className="space-y-6">
            <div>
                <label className={labelClasses}>
                    <Tag size={12} className="text-orange-500" /> اسم التصنيف
                </label>
                <input 
                    required 
                    type="text" 
                    placeholder="مثلاً: ساعات ذكية"
                    value={form.name} 
                    onChange={e => setForm({ ...form, name: e.target.value })}
                    className={inputClasses} 
                />
            </div>

            <div>
                <label className={labelClasses}>التصنيف الرئيسي (اختياري)</label>
                <div className="relative">
                    <select 
                        value={form.parent_id} 
                        onChange={e => setForm({ ...form, parent_id: e.target.value })}
                        className={`${inputClasses} appearance-none bg-[url('data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20fill%3D%22none%22%20viewBox%3D%220%200%2020%2020%22%3E%3Cpath%20stroke%3D%22%2364748b%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20stroke-width%3D%221.5%22%20d%3D%22m6%208%204%204%204-4%22%2F%3E%3C%2Fsvg%3E')] bg-[length:1.25rem_1.25rem] bg-[position:left_1rem_center] bg-no-repeat`}
                    >
                        <option value="">— تصنيف رئيسي مستقل —</option>
                        {categories.filter(c => c.id !== category?.id).map(c => (
                            <option key={c.id} value={c.id}>{c.name}</option>
                        ))}
                    </select>
                </div>
            </div>

            <div className="flex gap-4 pt-4 border-t border-slate-100">
                <button 
                    type="button" 
                    onClick={onClose} 
                    className="flex-1 px-6 py-4 bg-slate-100 text-slate-500 rounded-full text-sm font-bold hover:bg-slate-200 hover:text-slate-900 transition-all active:scale-95"
                >
                    إلغاء
                </button>
                <button 
                    type="submit" 
                    disabled={saving} 
                    className="flex-[2] px-6 py-4 bg-slate-900 rounded-full text-sm font-bold text-white hover:bg-orange-600 disabled:opacity-50 transition-all shadow-xl shadow-slate-900/10 flex items-center justify-center gap-2 active:scale-95"
                >
                    {saving && <Loader2 size={16} className="animate-spin" />}
                    {category ? 'حفظ التعديلات النهائية' : 'إضافة التصنيف الآن'}
                </button>
            </div>
        </form>
    );
};

const Categories = () => {
    const [categories, setCategories] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [editCat, setEditCat] = useState(null);
    const [confirmDelete, setConfirmDelete] = useState(null);
    const [toast, setToast] = useState(null);

    const showToast = (msg, type = 'success') => {
        setToast({ msg, type });
        setTimeout(() => setToast(null), 3000);
    };

    const loadCategories = async () => {
        setLoading(true);
        const { data } = await getCategories();
        setCategories(data || []);
        setLoading(false);
    };

    useEffect(() => { loadCategories(); }, []);

    const handleDelete = async (id) => {
        const { error } = await deleteCategory(id);
        if (error) showToast('فشل حذف التصنيف', 'error');
        else { showToast('تم حذف التصنيف وجميع توابعه بنجاح'); loadCategories(); }
        setConfirmDelete(null);
    };

    const handleSaved = (msg) => {
        setShowForm(false);
        setEditCat(null);
        showToast(msg);
        loadCategories();
    };

    const parentCategories = categories.filter(c => !c.parent_id);
    const subCategories = categories.filter(c => c.parent_id);
    const getSubCats = (parentId) => subCategories.filter(c => c.parent_id === parentId);

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8" dir="rtl">
            <header className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-black text-slate-900 tracking-tight border-r-4 border-orange-500 pr-4">إدارة التصنيفات</h1>
                    <p className="text-slate-500 text-sm font-bold mt-1 pr-5">{categories.length} تصنيف متاح</p>
                </div>
                <button onClick={() => { setEditCat(null); setShowForm(true); }}
                    className="flex items-center gap-2 px-6 py-3.5 bg-slate-900 hover:bg-orange-600 rounded-2xl text-white font-bold text-sm transition-all shadow-xl shadow-slate-900/10 hover:scale-105 active:scale-95">
                    <Plus size={18} />إضافة تصنيف جديد
                </button>
            </header>

            {loading ? (
                <div className="flex items-center justify-center py-24"><div className="w-10 h-10 border-4 border-orange-500 border-t-transparent rounded-full animate-spin" /></div>
            ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                    {parentCategories.map((cat, i) => {
                        const subs = getSubCats(cat.id);
                        return (
                            <motion.div key={cat.id} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}
                                className="bg-white border border-slate-200 rounded-[2rem] p-6 group hover:border-orange-500/20 transition-all shadow-sm hover:shadow-xl hover:shadow-orange-500/5">
                                <div className="flex items-start justify-between mb-4">
                                    <div className="flex items-center gap-3">
                                        <div className="w-12 h-12 bg-slate-50 rounded-2xl flex items-center justify-center border border-slate-100 shadow-inner group-hover:bg-orange-50 group-hover:border-orange-100 transition-colors">
                                            <Tag size={20} className="text-slate-900 group-hover:text-orange-600 transition-colors" />
                                        </div>
                                        <div>
                                            <p className="font-black text-slate-900">{cat.name}</p>
                                            <p className="text-[10px] text-slate-500 font-bold uppercase tracking-widest">{subs.length} تصنيفات فرعية</p>
                                        </div>
                                    </div>
                                    <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-all translate-y-2 group-hover:translate-y-0">
                                        <button onClick={() => { setEditCat(cat); setShowForm(true); }}
                                            className="p-2.5 text-slate-400 hover:text-orange-600 hover:bg-orange-50 rounded-xl transition-all"><Edit size={16} /></button>
                                        <button onClick={() => setConfirmDelete(cat.id)}
                                            className="p-2.5 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-xl transition-all"><Trash2 size={16} /></button>
                                    </div>
                                </div>
                                {subs.length > 0 && (
                                    <div className="space-y-2.5 border-t border-slate-50 pt-5 mt-2">
                                        {subs.map(sub => (
                                            <div key={sub.id} className="flex items-center justify-between group/sub">
                                                <div className="flex items-center gap-2.5">
                                                    <div className="w-1.5 h-1.5 rounded-full bg-slate-200 group-hover/sub:bg-orange-400 transition-colors" />
                                                    <span className="text-sm text-slate-600 font-medium group-hover/sub:text-slate-900">{sub.name}</span>
                                                </div>
                                                <div className="flex gap-1 opacity-0 group-hover/sub:opacity-100 transition-opacity">
                                                    <button onClick={() => { setEditCat(sub); setShowForm(true); }}
                                                        className="p-1.5 text-slate-400 hover:text-orange-600 hover:bg-orange-50 rounded-lg transition-all"><Edit size={14} /></button>
                                                    <button onClick={() => setConfirmDelete(sub.id)}
                                                        className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-all"><Trash2 size={14} /></button>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </motion.div>
                        );
                    })}

                    <motion.button initial={{ opacity: 0 }} animate={{ opacity: 1 }} onClick={() => { setEditCat(null); setShowForm(true); }}
                        className="bg-white border-2 border-dashed border-slate-200 rounded-[2.5rem] p-10 flex flex-col items-center justify-center gap-4 hover:border-orange-200 hover:bg-orange-50/30 transition-all min-h-[180px] group shadow-sm">
                        <div className="w-14 h-14 bg-slate-50 rounded-[1.5rem] border border-slate-100 flex items-center justify-center group-hover:bg-white group-hover:border-orange-100 transition-all">
                            <Plus size={28} className="text-slate-400 group-hover:text-orange-600 transition-colors" />
                        </div>
                        <span className="text-slate-500 group-hover:text-slate-900 text-sm font-black transition-colors">إضافة تصنيف جديد</span>
                    </motion.button>
                </div>
            )}

            <Modal 
                isOpen={showForm} 
                onClose={() => { setShowForm(false); setEditCat(null); }}
                title={editCat ? 'تعديل التصنيف' : 'إضافة تصنيف جديد'}
                description="نظم منتجاتك بإضافة تصنيفات واضحة وجاذبة"
            >
                <CategoryForm 
                    category={editCat} 
                    categories={categories} 
                    onClose={() => { setShowForm(false); setEditCat(null); }} 
                    onSaved={handleSaved} 
                />
            </Modal>

            <Modal
                isOpen={!!confirmDelete}
                onClose={() => setConfirmDelete(null)}
                size="sm"
            >
                <div className="text-center p-2">
                    <div className="w-20 h-20 bg-red-50 rounded-[2rem] flex items-center justify-center mx-auto mb-6 border border-red-100 shadow-inner">
                        <AlertTriangle size={36} className="text-red-600" />
                    </div>
                    <h3 className="text-2xl font-black text-slate-900 mb-3 tracking-tight">هل أنت متأكد؟</h3>
                    <p className="text-slate-500 text-sm mb-8 leading-relaxed font-medium px-4">
                        سيتم حذف هذا التصنيف نهائياً مع جميع التصنيفات الفرعية المرتبطة به. لا يمكن التراجع عن هذه الخطوة.
                    </p>
                    <div className="flex gap-4">
                        <button 
                            onClick={() => setConfirmDelete(null)} 
                            className="flex-1 px-4 py-4 bg-slate-100 text-slate-600 rounded-2xl text-sm font-bold hover:bg-slate-200 transition-all"
                        >
                            إلغاء
                        </button>
                        <button 
                            onClick={() => handleDelete(confirmDelete)} 
                            className="flex-1 px-4 py-4 bg-red-600 rounded-2xl text-sm font-bold text-white hover:bg-red-700 transition-all shadow-xl shadow-red-600/20"
                        >
                            حذف الآن
                        </button>
                    </div>
                </div>
            </Modal>

            <AnimatePresence>
                {toast && <Toast key={toast.msg} msg={toast.msg} type={toast.type} />}
            </AnimatePresence>
        </motion.div>
    );
};

export default Categories;

