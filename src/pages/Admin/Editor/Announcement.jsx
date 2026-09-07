import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Megaphone, Check, X } from 'lucide-react';
import { getAnnouncement, updateAnnouncement } from '@/services/supabase/contentService';

const Announcement = () => {
    const [form, setForm] = useState({ text: '', bg_color: '#ea580c', text_color: '#ffffff', is_active: true });
    const [saving, setSaving] = useState(false);
    const [saved, setSaved] = useState(false);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        (async () => {
            const { data } = await getAnnouncement();
            if (data) setForm(data);
            setLoading(false);
        })();
    }, []);

    const handleSave = async () => {
        setSaving(true);
        await updateAnnouncement(form);
        setSaving(false);
        setSaved(true);
        setTimeout(() => setSaved(false), 2000);
    };

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8 max-w-2xl" dir="rtl">
            <header>
                <h1 className="text-3xl font-black text-slate-900 tracking-tight border-r-4 border-[#1F2933] pr-4">شريط الإعلانات</h1>
                <p className="text-slate-500 text-sm font-bold mt-1 pr-5">تحكم في النص والألوان الظاهرة أعلى الموقع</p>
            </header>

            {/* Live Preview */}
            <div className="rounded-2xl overflow-hidden border border-slate-200 shadow-sm transition-all duration-500">
                <div className="px-4 py-2 text-xs font-bold text-slate-400 uppercase tracking-widest bg-slate-50 border-b border-slate-100 italic">معاينة مباشرة</div>
                <div className="p-2 bg-white">
                    <div className="rounded-xl px-6 py-3 text-center text-sm font-black transition-all shadow-glow"
                        style={{ backgroundColor: form.bg_color, color: form.text_color }}>
                        {form.text || 'نص الإعلان هنا...'}
                    </div>
                </div>
            </div>

            {/* Form */}
            <div className="bg-white border border-slate-200 rounded-3xl p-8 space-y-6 shadow-sm">
                <div>
                    <label className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-2 block">نص الإعلان</label>
                    <input type="text" value={form.text} onChange={e => setForm({ ...form, text: e.target.value })}
                        className="w-full bg-slate-50/80 border-none rounded-xl px-4 py-3 text-slate-900 text-sm focus:outline-none focus:ring-2 focus:ring-[#3A3F45]/20 focus:bg-white transition-all shadow-sm"
                        placeholder="شحن مجاني للطلبات فوق 500 ريال! 🎉" />
                </div>

                <div className="grid grid-cols-2 gap-4">
                    <div>
                        <label className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-2 block">لون الخلفية</label>
                        <div className="flex items-center gap-3">
                            <input type="color" value={form.bg_color} onChange={e => setForm({ ...form, bg_color: e.target.value })}
                                className="w-12 h-12 rounded-xl border-none cursor-pointer bg-slate-50 overflow-hidden shadow-sm" />
                            <input type="text" value={form.bg_color} onChange={e => setForm({ ...form, bg_color: e.target.value })}
                                className="flex-1 bg-slate-50/80 border-none rounded-xl px-3 py-2.5 text-slate-900 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-[#3A3F45]/20 focus:bg-white shadow-sm" />
                        </div>
                    </div>
                    <div>
                        <label className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-2 block">لون النص</label>
                        <div className="flex items-center gap-3">
                            <input type="color" value={form.text_color} onChange={e => setForm({ ...form, text_color: e.target.value })}
                                className="w-12 h-12 rounded-xl border-none cursor-pointer bg-slate-50 overflow-hidden shadow-sm" />
                            <input type="text" value={form.text_color} onChange={e => setForm({ ...form, text_color: e.target.value })}
                                className="flex-1 bg-slate-50/80 border-none rounded-xl px-3 py-2.5 text-slate-900 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-[#3A3F45]/20 focus:bg-white shadow-sm" />
                        </div>
                    </div>
                </div>

                <label className="flex items-center gap-3 cursor-pointer group">
                    <div className={`w-12 h-6 rounded-full transition-all relative ${form.is_active ? 'bg-[#1F2933]' : 'bg-slate-200'}`}
                        onClick={() => setForm(f => ({ ...f, is_active: !f.is_active }))}>
                        <div className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-all ${form.is_active ? 'right-0.5' : 'left-0.5'}`} />
                    </div>
                    <span className="text-sm font-bold text-slate-600 group-hover:text-slate-900 transition-colors">{form.is_active ? 'الشريط مُفعَّل' : 'الشريط مُعطَّل'}</span>
                </label>

                <button onClick={handleSave} disabled={saving}
                    className={`w-full py-3.5 rounded-2xl text-sm font-black transition-all ${saved ? 'bg-green-600 text-white' : 'bg-[#1F2933] hover:bg-[#3A3F45] text-white shadow-lg shadow-[#1F2933]/20'} disabled:opacity-50`}>
                    {saved ? '✓ تم الحفظ بنجاح' : saving ? 'جارٍ الحفظ...' : 'حفظ التغييرات'}
                </button>
            </div>
        </motion.div>
    );
};

export default Announcement;

