import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { LayoutGrid, GripVertical, Eye, EyeOff } from 'lucide-react';

const DEFAULT_SECTIONS = [
    { id: 'hero', label: 'الشريط الإعلاني (Hero Slider)', visible: true },
    { id: 'categories', label: 'تصنيفات المنتجات', visible: true },
    { id: 'flash_sale', label: 'عروض مميزة (Flash Sale)', visible: true },
    { id: 'featured_products', label: 'منتجات مميزة', visible: false },
    { id: 'brands', label: 'العلامات التجارية', visible: false },
    { id: 'newsletter', label: 'النشرة البريدية', visible: true },
];

const HomeLayout = () => {
    const [sections, setSections] = useState(DEFAULT_SECTIONS);
    const [saved, setSaved] = useState(false);

    const toggleVisible = (id) => {
        setSections(prev => prev.map(s => s.id === id ? { ...s, visible: !s.visible } : s));
    };

    const moveUp = (idx) => {
        if (idx === 0) return;
        setSections(prev => {
            const arr = [...prev];
            [arr[idx - 1], arr[idx]] = [arr[idx], arr[idx - 1]];
            return arr;
        });
    };

    const moveDown = (idx) => {
        if (idx === sections.length - 1) return;
        setSections(prev => {
            const arr = [...prev];
            [arr[idx], arr[idx + 1]] = [arr[idx + 1], arr[idx]];
            return arr;
        });
    };

    const handleSave = () => {
        // Store in localStorage as fallback (Supabase would persist this)
        localStorage.setItem('adminHomeLayout', JSON.stringify(sections));
        setSaved(true);
        setTimeout(() => setSaved(false), 2000);
    };

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8 max-w-2xl" dir="rtl">
            <header>
                <h1 className="text-3xl font-black text-slate-900 tracking-tight border-r-4 border-[#1F2933] pr-4">ترتيب الصفحة الرئيسية</h1>
                <p className="text-slate-500 text-sm font-bold mt-1 pr-5">رتّب وتحكم في العناصر الظاهرة في الواجهة</p>
            </header>

            <div className="bg-white border border-slate-200 rounded-3xl overflow-hidden divide-y divide-slate-100 shadow-sm transition-all duration-500">
                {sections.map((section, idx) => (
                    <motion.div key={section.id} layout
                        className={`flex items-center gap-4 p-5 group transition-colors ${section.visible ? 'hover:bg-slate-50' : 'opacity-40 grayscale bg-slate-50/30'}`}>
                        <GripVertical size={20} className="text-slate-300 cursor-grab shrink-0 group-hover:text-slate-900 transition-colors" />

                        <div className="flex-1">
                            <p className={`font-black text-sm transition-colors ${section.visible ? 'text-slate-900' : 'text-slate-400'}`}>{section.label}</p>
                            <div className="flex items-center gap-2 mt-0.5">
                                <span className="bg-slate-100 text-slate-500 px-1.5 py-0.5 rounded text-[10px] font-bold">الترتيب: {idx + 1}</span>
                            </div>
                        </div>

                        <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button onClick={() => moveUp(idx)} disabled={idx === 0}
                                className="p-2 text-slate-400 hover:text-slate-900 hover:bg-slate-100 disabled:opacity-20 rounded-lg transition-all text-xs font-black shadow-sm">▲</button>
                            <button onClick={() => moveDown(idx)} disabled={idx === sections.length - 1}
                                className="p-2 text-slate-400 hover:text-slate-900 hover:bg-slate-100 disabled:opacity-20 rounded-lg transition-all text-xs font-black shadow-sm">▼</button>
                        </div>

                        <button onClick={() => toggleVisible(section.id)}
                            className={`p-2.5 rounded-xl transition-all shadow-sm active:scale-95 ${section.visible ? 'text-green-600 bg-green-50 hover:bg-green-100 border border-green-200' : 'text-slate-400 bg-slate-50 hover:bg-slate-100 border border-slate-200'}`}>
                            {section.visible ? <Eye size={16} /> : <EyeOff size={16} />}
                        </button>
                    </motion.div>
                ))}
            </div>

            <button onClick={handleSave}
                className={`w-full py-4 rounded-2xl text-sm font-black transition-all ${saved ? 'bg-green-600 text-white' : 'bg-[#1F2933] hover:bg-[#3A3F45] text-white shadow-lg shadow-[#1F2933]/20 active:scale-95'}`}>
                {saved ? '✓ تم حفظ الترتيب الجديد' : 'حفظ الترتيب'}
            </button>
        </motion.div>
    );
};

export default HomeLayout;

