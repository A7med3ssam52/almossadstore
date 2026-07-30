import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Store, Percent, Save, Check } from 'lucide-react';

const GeneralSettings = () => {
    const [form, setForm] = useState({
        store_name: 'آل مسعد للحديد والبويات',
        store_email: 'info@almossad.com',
        store_phone: '01284858999',
        store_address: '39 شارع ربيع الجيزي - الجيزة - بجوار مستشفى أم المصريين',
        vat_number: '123-456-789',
        vat_rate: 14,
        currency: 'EGP',
        currency_symbol: 'جنيه مصرى',
        order_min: 100,
    });
    const [saved, setSaved] = useState(false);

    const handleSave = () => {
        localStorage.setItem('storeSettings', JSON.stringify(form));
        setSaved(true);
        setTimeout(() => setSaved(false), 2500);
    };

    const Field = ({ label, field, type = 'text', disabled }) => (
        <div>
            <label className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-1.5 block">{label}</label>
            <input type={type} disabled={disabled} value={form[field]} onChange={e => setForm({ ...form, [field]: e.target.value })}
                className="w-full bg-slate-50/80 border-none rounded-xl px-4 py-3 text-slate-900 text-sm focus:outline-none focus:ring-2 focus:ring-[#3A3F45]/20 focus:bg-white transition-all shadow-sm disabled:opacity-50 disabled:cursor-not-allowed" />
        </div>
    );

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8 max-w-2xl mx-auto" dir="rtl">
            <header>
                <h1 className="text-3xl font-black text-slate-900 tracking-tight border-r-4 border-[#1F2933] pr-4">إعدادات المتجر</h1>
                <p className="text-slate-500 text-sm font-bold mt-1 pr-5">المعلومات الأساسية والإعدادات الضريبية</p>
            </header>

            {/* Store Info */}
            <div className="bg-white border border-slate-200 rounded-3xl p-8 space-y-5 shadow-sm">
                <div className="flex items-center gap-3 mb-6">
                    <div className="p-3 bg-slate-100 rounded-2xl border border-slate-200">
                        <Store size={20} className="text-[#1F2933]" />
                    </div>
                    <div>
                        <h2 className="font-black text-slate-900">معلومات المتجر</h2>
                        <p className="text-xs text-slate-500">البيانات الأساسية التي تظهر في الواجهة</p>
                    </div>
                </div>
                <Field label="اسم المتجر" field="store_name" />
                <div className="grid grid-cols-2 gap-4">
                    <Field label="البريد الإلكتروني" field="store_email" type="email" />
                    <Field label="رقم الهاتف" field="store_phone" />
                </div>
                <Field label="العنوان" field="store_address" />
            </div>

            {/* Financial Settings */}
            <div className="bg-white border border-slate-200 rounded-3xl p-8 space-y-5 shadow-sm">
                <div className="flex items-center gap-3 mb-6">
                    <div className="p-3 bg-green-50 rounded-2xl border border-green-100">
                        <Percent size={20} className="text-green-600" />
                    </div>
                    <div>
                        <h2 className="font-black text-slate-900">الماليات والعملة</h2>
                        <p className="text-xs text-slate-500">إعدادات العملة والحد الأدنى للطلبات</p>
                    </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                    <Field label="العملة" field="currency" />
                    <Field label="رمز العملة" field="currency_symbol" />
                </div>

            </div>

            <button onClick={handleSave}
                className={`w-full py-3.5 rounded-2xl text-sm font-black transition-all flex items-center justify-center gap-2
                ${saved ? 'bg-green-600 text-white' : 'bg-[#1F2933] hover:bg-[#3A3F45] text-white shadow-lg shadow-[#1F2933]/20'}`}>
                {saved ? <><Check size={18} /> تم الحفظ</> : <><Save size={18} /> حفظ الإعدادات</>}
            </button>
        </motion.div>
    );
};

export default GeneralSettings;

