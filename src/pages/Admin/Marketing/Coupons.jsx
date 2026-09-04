import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Ticket, Plus, Trash2, Copy, Check, X, Calendar, Hash, RefreshCcw, Loader2 } from 'lucide-react';
import { supabase } from '@/services/supabase/adminClient';
import Modal from '@/components/ui/Modal';

const isConfigured = () => {
    const url = import.meta.env.VITE_SUPABASE_URL || 'https://bbmnnvzuhjgrtbhksmel.supabase.co';
    const key = import.meta.env.VITE_SUPABASE_ANON_KEY || import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_sigZDu-zp-uioBSTzmwEBw_ajz7DscX';
    return !!(url && key && url.startsWith('http'));
};

const Toast = ({ msg, type }) => (
    <motion.div initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 30 }} className={`fixed bottom-6 left-6 z-[99999] flex items-center gap-3 px-5 py-3 rounded-2xl shadow-2xl border backdrop-blur-xl ${type === 'success' ? 'bg-white border-green-100 text-green-700' : 'bg-white border-red-100 text-red-700'}`}>
        {type === 'success' ? <Check size={16} className="text-green-600" /> : <X size={16} className="text-red-600" />}<span className="text-sm font-bold">{msg}</span>
    </motion.div>
);

const CouponForm = ({ onClose, onSaved }) => {
    const [form, setForm] = useState({ code: '', discount_type: 'percentage', discount_value: '', expiry_date: '', usage_limit: 100 });
    const [saving, setSaving] = useState(false);
    const [err, setErr] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        setErr('');
        const val = Number(form.discount_value);
        if (!form.code.trim()) { setErr('أدخل كود الكوبون'); return; }
        if (!val || val<=0) { setErr('قيمة الخصم غير صحيحة'); return; }
        if (form.discount_type==='percentage' && val>100) { setErr('النسبة لا تتجاوز 100%'); return; }
        if (form.expiry_date && new Date(form.expiry_date) < new Date(new Date().toISOString().split('T')[0])) { setErr('تاريخ الانتهاء يجب أن يكون في المستقبل'); return; }
        if (form.usage_limit <1) { setErr('حد الاستخدام يجب أن يكون 1 على الأقل'); return; }
        setSaving(true);
        try {
            const payload = { ...form, code: form.code.trim().toUpperCase(), discount_value: val, usage_limit: Number(form.usage_limit) };
            if (!isConfigured()) { await new Promise(r=>setTimeout(r,800)); onSaved('تم إنشاء الكوبون محلياً'); return; }
            const { error } = await supabase.from('coupons').insert(payload);
            if (error) throw error;
            onSaved('تم إنشاء الكوبون');
        } catch (e) {
            setErr(e.message.includes('duplicate') ? 'الكود موجود مسبقاً' : e.message);
        }
        setSaving(false);
    };

    const generateCode = () => setForm(f => ({ ...f, code: Math.random().toString(36).slice(2, 8).toUpperCase() }));

    const inputClasses = "w-full bg-slate-50 border border-slate-200/60 rounded-3xl px-4 py-3.5 text-slate-900 text-sm focus:outline-none focus:ring-4 focus:ring-orange-500/10 focus:border-orange-500 transition-all font-medium placeholder:text-slate-400";
    const labelClasses = "flex items-center gap-2 text-[10px] font-black text-slate-500 uppercase tracking-widest mb-2 mr-1";
    return (
        <form onSubmit={handleSubmit} className="space-y-6">
            <div>
                <label className={labelClasses}>كود الكوبون</label>
                <div className="flex gap-3">
                    <div className="relative flex-1"><input required type="text" value={form.code} onChange={e => setForm({ ...form, code: e.target.value.toUpperCase() })} placeholder="مثال: RAMADAN25" className={`${inputClasses} font-mono uppercase text-center tracking-[4px]`} /></div>
                    <button type="button" onClick={generateCode} className="px-5 py-3.5 bg-slate-100 rounded-2xl text-xs font-black text-slate-700 hover:bg-slate-200 flex items-center gap-2 shrink-0"><RefreshCcw size={14} /> توليد</button>
                </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
                <div>
                    <label className={labelClasses}>نوع الخصم</label>
                    <select value={form.discount_type} onChange={e => setForm({ ...form, discount_type: e.target.value })} className={`${inputClasses} appearance-none`}><option value="percentage">نسبة مئوية (%)</option><option value="fixed">مبلغ ثابت (ج.م)</option></select>
                </div>
                <div>
                    <label className={labelClasses}>قيمة الخصم</label>
                    <div className="relative"><input required type="number" min="1" max={form.discount_type === 'percentage' ? 100 : undefined} value={form.discount_value} onChange={e => setForm({ ...form, discount_value: e.target.value })} className={`${inputClasses} pl-10`} placeholder="0" /><div className="absolute left-4 top-1/2 -translate-y-1/2 font-black text-slate-400 text-xs">{form.discount_type === 'percentage' ? '%' : 'EGP'}</div></div>
                </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
                <div><label className={labelClasses}>تاريخ الانتهاء</label><div className="relative"><input type="date" value={form.expiry_date} onChange={e => setForm({ ...form, expiry_date: e.target.value })} className={`${inputClasses} pr-10`} /><Calendar size={16} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" /></div></div>
                <div><label className={labelClasses}>حد الاستخدام</label><div className="relative"><input type="number" min="1" value={form.usage_limit} onChange={e => setForm({ ...form, usage_limit: parseInt(e.target.value)||1 })} className={`${inputClasses} pr-10`} /><Hash size={16} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" /></div></div>
            </div>
            {err && <p className="text-sm font-bold text-red-600 bg-red-50 p-3 rounded-xl border border-red-100">{err}</p>}
            <div className="flex gap-4 pt-4 border-t border-slate-100">
                <button type="button" onClick={onClose} className="flex-1 px-6 py-4 bg-slate-100 text-slate-600 rounded-3xl text-sm font-bold hover:bg-slate-200">إلغاء</button>
                <button type="submit" disabled={saving} className="flex-[2] px-6 py-4 bg-slate-900 rounded-3xl text-sm font-bold text-white hover:bg-orange-600 disabled:opacity-50 flex items-center justify-center gap-2">{saving && <Loader2 size={16} className="animate-spin" />} إنشاء الكوبون</button>
            </div>
        </form>
    );
};

const Coupons = () => {
    const [coupons, setCoupons] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [copied, setCopied] = useState(null);
    const [toast, setToast] = useState(null);

    const showToast = (msg, type = 'success') => { setToast({ msg, type }); setTimeout(() => setToast(null), 3000); };

    const loadCoupons = async () => {
        setLoading(true);
        if (!isConfigured()) {
            setCoupons([
                { id: 'mock-1', code: 'WELCOME20', discount_type: 'percentage', discount_value: 20, expiry_date: '2026-12-31', usage_limit: 100, used_count: 12, is_active: true },
                { id: 2, code: 'SAVE50EGP', discount_type: 'fixed', discount_value: 50, expiry_date: '2026-06-30', usage_limit: 50, used_count: 50, is_active: false },
            ]);
            setLoading(false); return;
        }
        const { data, error } = await supabase.from('coupons').select('*').order('created_at', { ascending: false });
        if (!error) setCoupons(data||[]);
        setLoading(false);
    };
    useEffect(()=>{ loadCoupons(); }, []);
    const copyCode = (code) => {
        if (navigator.clipboard) navigator.clipboard.writeText(code);
        else {
            const ta=document.createElement('textarea'); ta.value=code; document.body.appendChild(ta); ta.select(); document.execCommand('copy'); ta.remove();
        }
        setCopied(code); setTimeout(() => setCopied(null), 2000);
    };
    const handleSaved = (msg) => { setShowForm(false); showToast(msg); loadCoupons(); };
    const handleDelete = async (id) => {
        if (!confirm('حذف الكوبون؟')) return;
        if (!isConfigured() || String(id).startsWith('mock-')) { setCoupons(prev=>prev.filter(c=>c.id!==id)); return; }
        const { error } = await supabase.from('coupons').delete().eq('id', id);
        if (!error) { showToast('تم الحذف'); loadCoupons(); } else showToast(error.message, 'error');
    };
    const isExpired = (dateStr) => dateStr && new Date(dateStr) < new Date(new Date().toISOString().split('T')[0]);
    const isExhausted = (c) => c.used_count >= c.usage_limit;

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8" dir="rtl">
            <header className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                <div><h1 className="text-3xl font-black text-slate-900 tracking-tight border-r-4 border-orange-500 pr-4">إدارة الكوبونات</h1><p className="text-slate-500 text-sm font-bold mt-1 pr-5">{coupons.length} كوبون</p></div>
                <button onClick={() => setShowForm(true)} className="flex items-center gap-2 px-6 py-3.5 bg-slate-900 hover:bg-orange-600 rounded-2xl text-white font-bold text-sm shadow-xl"> <Plus size={18} /> إنشاء كوبون</button>
            </header>
            {loading ? <div className="flex justify-center py-16"><Loader2 className="animate-spin text-slate-400" size={32}/></div> : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {coupons.map((coupon, i) => {
                    const expired = isExpired(coupon.expiry_date);
                    const exhausted = isExhausted(coupon);
                    const active = coupon.is_active && !expired && !exhausted;
                    const usagePercent = Math.min(100, Math.round((coupon.used_count / coupon.usage_limit) * 100));
                    return (
                        <motion.div key={coupon.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }} className={`bg-white border rounded-[2rem] p-6 relative overflow-hidden group shadow-sm ${active ? 'border-slate-200 hover:border-orange-500/20 hover:shadow-xl' : 'border-slate-100 opacity-60'}`}>
                            <div className="flex items-start justify-between mb-8">
                                <div className="flex flex-col gap-3">
                                    <div className={`w-12 h-12 rounded-2xl border flex items-center justify-center ${active ? 'bg-orange-50 border-orange-100 text-orange-600' : 'bg-slate-50 border-slate-100 text-slate-400'}`}><Ticket size={24} /></div>
                                    <div>
                                        <button onClick={() => copyCode(coupon.code)} className="font-black text-slate-900 font-mono text-base flex items-center gap-1.5 hover:text-orange-600">{coupon.code} {copied === coupon.code ? <Check size={14} className="text-green-600" /> : <Copy size={13} className="opacity-30" />}</button>
                                        <span className={`text-[10px] font-black px-2 py-0.5 rounded-full border mt-2 inline-block uppercase ${expired ? 'bg-red-50 text-red-600 border-red-100' : exhausted ? 'bg-slate-100 text-slate-600 border-slate-200' : active ? 'bg-green-50 text-green-700 border-green-100' : 'bg-slate-50 text-slate-500 border-slate-100'}`}>{expired ? 'منتهي' : exhausted ? 'مستنفذ' : active ? 'نشط' : 'غير نشط'}</span>
                                    </div>
                                </div>
                                <div className="text-left"><p className="text-3xl font-black text-slate-900">{coupon.discount_value}{coupon.discount_type === 'percentage' ? '%' : ''}<span className="text-xs font-bold text-slate-400 mr-1">{coupon.discount_type === 'fixed' ? 'EGP' : ''}</span></p><p className="text-[10px] text-slate-500 font-black tracking-widest uppercase mt-1">{coupon.discount_type === 'percentage' ? 'نسبة' : 'مبلغ ثابت'}</p></div>
                            </div>
                            <div className="mt-4 mb-4"><div className="flex justify-between text-[10px] font-black text-slate-400 mb-2 uppercase"><span>الاستهلاك</span><span>{coupon.used_count} / {coupon.usage_limit}</span></div><div className="h-2 bg-slate-50 rounded-full overflow-hidden border border-slate-100/50"><motion.div initial={{ width: 0 }} animate={{ width: `${usagePercent}%` }} className={`h-full rounded-full ${usagePercent >= 90 ? 'bg-red-500' : usagePercent >= 60 ? 'bg-orange-500' : 'bg-slate-900'}`} /></div></div>
                            {coupon.expiry_date && <p className="text-[10px] text-slate-400 font-black mt-6 border-t border-slate-50 pt-4 flex items-center gap-2"><Calendar size={12} /> ينتهي: {new Date(coupon.expiry_date).toLocaleDateString('ar-SA')}</p>}
                            <button onClick={() => handleDelete(coupon.id)} className="absolute top-4 left-4 p-2.5 text-slate-300 hover:text-red-600 hover:bg-red-50 rounded-xl opacity-0 group-hover:opacity-100 border border-transparent hover:border-red-100"><Trash2 size={16} /></button>
                        </motion.div>
                    );
                })}
            </div>
            )}
            <Modal isOpen={showForm} onClose={() => setShowForm(false)} title="إنشاء كوبون جديد"><CouponForm onClose={() => setShowForm(false)} onSaved={handleSaved} /></Modal>
            <AnimatePresence>{toast && <Toast key={toast.msg} msg={toast.msg} type={toast.type} />}</AnimatePresence>
        </motion.div>
    );
};
export default Coupons;