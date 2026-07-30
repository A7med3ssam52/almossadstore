import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Image as ImageIcon, Plus, Trash2, Eye, EyeOff, X, Check, GripVertical, ExternalLink, Link as LinkIcon, Hash, Loader2, ImagePlus } from 'lucide-react';
import { getBanners, createBanner, updateBanner, deleteBanner } from '@/services/supabase/contentService';
import Modal from '@/components/UI/Modal';

const Toast = ({ msg, type }) => (
    <motion.div initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 30 }}
        className={`fixed bottom-6 left-6 z-[99999] flex items-center gap-3 px-5 py-3 rounded-2xl shadow-2xl border backdrop-blur-xl
        ${type === 'success' ? 'bg-white border-green-100 text-green-700' : 'bg-white border-red-100 text-red-700'}`}>
        {type === 'success' ? <Check size={16} className="text-green-600" /> : <X size={16} className="text-red-600" />}
        <span className="text-sm font-bold">{msg}</span>
    </motion.div>
);

const BannerForm = ({ banner, onClose, onSaved }) => {
    const [form, setForm] = useState({
        title: banner?.title || '',
        image_url: banner?.image_url || '',
        link_url: banner?.link_url || '',
        sort_order: banner?.sort_order || 1,
        is_active: banner?.is_active ?? true,
    });
    const [saving, setSaving] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        if (banner?.id) await updateBanner(banner.id, form);
        else await createBanner(form);
        setSaving(false);
        onSaved(banner ? 'تم تحديث البانر بنجاح' : 'تم إضافة البانر الجديد بنجاح');
    };

    const inputClasses = "w-full bg-slate-50 border border-slate-200/60 rounded-3xl px-4 py-3.5 text-slate-900 text-sm focus:outline-none focus:ring-4 focus:ring-orange-500/10 focus:border-orange-500 transition-all font-medium placeholder:text-slate-400";
    const labelClasses = "flex items-center gap-2 text-[10px] font-black text-slate-500 uppercase tracking-widest mb-2 mr-1";

    return (
        <form onSubmit={handleSubmit} className="space-y-6">
            <div>
                <label className={labelClasses}>عنوان البانر</label>
                <input type="text" value={form.title} onChange={e => setForm({ ...form, title: e.target.value })}
                    placeholder="مثلاً: تخفيضات الشتاء 2024"
                    className={inputClasses} />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label className={labelClasses}>رابط الصورة (Image URL)</label>
                    <div className="relative">
                        <input type="url" value={form.image_url} onChange={e => setForm({ ...form, image_url: e.target.value })}
                            placeholder="https://..."
                            className={`${inputClasses} pl-10`} />
                        <ImageIcon size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                    </div>
                </div>
                <div>
                    <label className={labelClasses}>رابط التحويل (Link URL)</label>
                    <div className="relative">
                        <input type="text" value={form.link_url} onChange={e => setForm({ ...form, link_url: e.target.value })}
                            placeholder="/categories/watches"
                            className={`${inputClasses} pl-10`} />
                        <LinkIcon size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                    </div>
                </div>
            </div>

            <div className="flex items-center gap-6">
                <div className="flex-1">
                    <label className={labelClasses}>ترتيب العرض</label>
                    <div className="relative">
                        <input type="number" value={form.sort_order} onChange={e => setForm({ ...form, sort_order: parseInt(e.target.value) })}
                            className={`${inputClasses} pl-10 text-center font-bold`} />
                        <Hash size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                    </div>
                </div>
                
                <div className="shrink-0 flex flex-col pt-4">
                    <label className="flex items-center gap-3 cursor-pointer p-3.5 px-6 bg-slate-50 border border-slate-200/60 rounded-2xl hover:bg-white transition-all group shadow-sm active:scale-95">
                        <div 
                            className={`w-10 h-5 rounded-full transition-all relative ${form.is_active ? 'bg-slate-900 shadow-lg shadow-slate-900/10' : 'bg-slate-200'}`}
                            onClick={() => setForm(f => ({ ...f, is_active: !f.is_active }))}
                        >
                            <div className={`absolute top-0.5 w-4 h-4 bg-white rounded-full shadow-sm transition-all ${form.is_active ? 'right-5' : 'left-0.5'}`} />
                        </div>
                        <span className="text-xs font-black text-slate-600 group-hover:text-slate-900 transition-colors uppercase tracking-widest">تفعيل</span>
                    </label>
                </div>
            </div>

            <div className="flex gap-4 pt-4 border-t border-slate-100">
                <button type="button" onClick={onClose} className="flex-1 px-6 py-4 bg-slate-100 text-slate-600 rounded-3xl text-sm font-bold hover:bg-slate-200 transition-all">إلغاء</button>
                <button type="submit" disabled={saving} className="flex-[2] px-6 py-4 bg-slate-900 rounded-3xl text-sm font-bold text-white hover:bg-orange-600 disabled:opacity-50 transition-all shadow-xl shadow-slate-900/10 flex items-center justify-center gap-2">
                    {saving && <Loader2 size={16} className="animate-spin" />}
                    {banner ? 'حفظ التعديلات' : 'إضافة الآن'}
                </button>
            </div>
        </form>
    );
};

const Banners = () => {
    const [banners, setBanners] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [editBanner, setEditBanner] = useState(null);
    const [toast, setToast] = useState(null);

    const showToast = (msg, type = 'success') => {
        setToast({ msg, type });
        setTimeout(() => setToast(null), 3000);
    };

    const loadBanners = async () => {
        setLoading(true);
        const { data } = await getBanners();
        setBanners(data || []);
        setLoading(false);
    };

    useEffect(() => { loadBanners(); }, []);

    const handleDelete = async (id) => {
        const { error } = await deleteBanner(id);
        if (error) showToast('فشل الحذف', 'error');
        else { showToast('تم حذف البانر بنجاح'); loadBanners(); }
    };

    const handleToggle = async (banner) => {
        await updateBanner(banner.id, { is_active: !banner.is_active });
        loadBanners();
    };

    const handleSaved = (msg) => {
        setShowForm(false);
        setEditBanner(null);
        showToast(msg);
        loadBanners();
    };

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8" dir="rtl">
            <header className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-black text-slate-900 tracking-tight border-r-4 border-orange-500 pr-4">محرر البانرات</h1>
                    <p className="text-slate-500 text-sm font-bold mt-1 pr-5">إدارة صور الشريط الإعلاني في الواجهة الرئيسية لمتجر آل مسعد</p>
                </div>
                <button onClick={() => { setEditBanner(null); setShowForm(true); }}
                    className="flex items-center gap-2 px-6 py-3.5 bg-slate-900 hover:bg-orange-600 rounded-2xl text-white font-bold text-sm transition-all shadow-xl shadow-slate-900/10 hover:scale-105 active:scale-95">
                    <Plus size={18} /> إضافة بانر إعلاني
                </button>
            </header>

            {loading ? (
                <div className="flex items-center justify-center py-24"><div className="w-10 h-10 border-4 border-orange-500 border-t-transparent rounded-full animate-spin" /></div>
            ) : (
                <div className="space-y-4">
                    {banners.map((banner, i) => (
                        <motion.div key={banner.id} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}
                            className={`bg-white border rounded-[2rem] p-6 flex flex-col md:flex-row items-center gap-6 group transition-all shadow-sm ${banner.is_active ? 'border-slate-200 hover:border-orange-500/20 hover:shadow-xl hover:shadow-orange-500/5' : 'border-slate-100 opacity-50 grayscale'}`}>
                            
                            <GripVertical size={20} className="hidden md:block text-slate-300 cursor-grab shrink-0 transition-colors group-hover:text-slate-900" />

                            {/* Preview */}
                            <div className="w-full md:w-32 h-24 md:h-18 bg-slate-50 rounded-2xl overflow-hidden border border-slate-100 shrink-0 flex items-center justify-center transition-all group-hover:scale-105 shadow-inner">
                                {banner.image_url
                                    ? <img src={banner.image_url} alt={banner.title} className="w-full h-full object-cover" onError={e => e.target.style.display = 'none'} />
                                    : <ImageIcon size={24} className="text-slate-200" />
                                }
                            </div>

                            {/* Info */}
                            <div className="flex-1 min-w-0 text-center md:text-right w-full">
                                <p className="font-black text-slate-900 text-lg truncate">{banner.title}</p>
                                <div className="flex flex-wrap items-center justify-center md:justify-start gap-4 mt-2">
                                    <p className="text-xs text-slate-500 flex items-center gap-1.5 font-medium bg-slate-50 px-3 py-1 rounded-lg">
                                        <ExternalLink size={12} className="text-slate-400" /> {banner.link_url || 'لا يوجد رابط'}
                                    </p>
                                    <span className="text-[10px] text-slate-400 font-black uppercase tracking-widest bg-slate-50 px-3 py-1 rounded-lg flex items-center gap-1">
                                        <Hash size={10} /> الترتيب: {banner.sort_order}
                                    </span>
                                    <span className={`text-[10px] font-black px-3 py-1 rounded-full border uppercase tracking-widest ${banner.is_active ? 'bg-green-50 text-green-700 border-green-100 shadow-sm shadow-green-600/5' : 'bg-slate-50 text-slate-500 border-slate-100'}`}>
                                        {banner.is_active ? 'مُفعَّل' : 'معطَّل'}
                                    </span>
                                </div>
                            </div>

                            {/* Actions */}
                            <div className="flex items-center gap-2 opacity-100 lg:group-hover:opacity-100 transition-all">
                                <button onClick={() => handleToggle(banner)}
                                    className="p-3 text-slate-400 hover:text-slate-900 hover:bg-slate-50 rounded-xl transition-all border border-transparent hover:border-slate-100"
                                    title={banner.is_active ? 'إخفاء' : 'إظهار'}>
                                    {banner.is_active ? <EyeOff size={18} /> : <Eye size={18} />}
                                </button>
                                <button onClick={() => { setEditBanner(banner); setShowForm(true); }}
                                    className="p-3 text-slate-400 hover:text-orange-600 hover:bg-orange-50 rounded-xl transition-all border border-transparent hover:border-orange-100"
                                    title="تعديل">
                                    <Edit size={18} className="translate-x-[1px]" />
                                </button>
                                <button onClick={() => handleDelete(banner.id)}
                                    className="p-3 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-xl transition-all border border-transparent hover:border-red-100"
                                    title="حذف">
                                    <Trash2 size={18} />
                                </button>
                            </div>
                        </motion.div>
                    ))}

                    {banners.length === 0 && (
                        <div className="text-center py-24 bg-slate-50/50 rounded-[3rem] border-2 border-dashed border-slate-200">
                            <ImagePlus size={48} className="mx-auto mb-4 text-slate-200" />
                            <p className="font-black text-slate-400 uppercase tracking-widest text-sm">لا توجد بانرات متاحة الآن</p>
                        </div>
                    )}
                </div>
            )}

            <Modal 
                isOpen={showForm} 
                onClose={() => { setShowForm(false); setEditBanner(null); }}
                title={editBanner ? 'تعديل البانر إعلاني' : 'إضافة بانر جديد'}
                description="اجذب انتباه عملائك ببانرات احترافية في الصفحة الرئيسية"
            >
                <BannerForm banner={editBanner} onClose={() => { setShowForm(false); setEditBanner(null); }} onSaved={handleSaved} />
            </Modal>

            <AnimatePresence>
                {toast && <Toast key={toast.msg} msg={toast.msg} type={toast.type} />}
            </AnimatePresence>
        </motion.div>
    );
};

export default Banners;


