import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Users, Plus, Shield, ShieldOff, Trash2, X, Check, Mail, UserPlus, Loader2 } from 'lucide-react';
import Modal from '@/components/UI/Modal';
import AdminLabel from '@/components/Admin/UI/AdminLabel';
import AdminInput from '@/components/Admin/UI/AdminInput';
import AdminSelect from '@/components/Admin/UI/AdminSelect';
import { showAdminToast } from '@/components/Admin/UI/AdminToast';

const MOCK_STAFF = [
    { id: 1, name: 'محمد العلي', email: 'mohammed@almossad.sa', role: 'admin', status: 'active', last_seen: 'الآن' },
    { id: 2, name: 'نورة السعد', email: 'noura@almossad.sa', role: 'moderator', status: 'active', last_seen: 'منذ ساعة' },
    { id: 3, name: 'خالد الحربي', email: 'khalid@almossad.sa', role: 'viewer', status: 'inactive', last_seen: 'منذ 3 أيام' },
];

const ROLE_CFG = {
    admin: { label: 'مدير كامل', cls: 'bg-slate-900 text-white border-slate-900' },
    moderator: { label: 'مشرف', cls: 'bg-orange-100 text-orange-700 border-orange-200' },
    viewer: { label: 'مُراقب', cls: 'bg-slate-100 text-slate-700 border-slate-200' },
};

const Staff = () => {
    const [staff, setStaff] = useState(MOCK_STAFF);
    const [showInvite, setShowInvite] = useState(false);
    const [inviteForm, setInviteForm] = useState({ name: '', email: '', role: 'viewer' });
    const [saving, setSaving] = useState(false);

    const handleInvite = async (e) => {
        e.preventDefault();
        setSaving(true);
        // Simulate API call
        await new Promise(r => setTimeout(r, 1000));
        setStaff(prev => [...prev, { ...inviteForm, id: Date.now(), status: 'active', last_seen: 'جديد' }]);
        setShowInvite(false);
        setSaving(false);
        setInviteForm({ name: '', email: '', role: 'viewer' });
        showAdminToast('تم إرسال دعوة الانضمام بنجاح');
    };

    const handleRemove = (id) => {
        setStaff(prev => prev.filter(s => s.id !== id));
        showAdminToast('تم إزالة العضو من الفريق');
    };

    const handleToggleStatus = (id) => {
        setStaff(prev => prev.map(s => {
            if (s.id === id) {
                return { ...s, status: s.status === 'active' ? 'inactive' : 'active' };
            }
            return s;
        }));
        showAdminToast('تم تحديث حالة العضو');
    };

    return (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8 max-w-4xl" dir="rtl">
            <header className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-black text-slate-900 tracking-tight border-r-4 border-orange-500 pr-4">إدارة الفريق</h1>
                    <p className="text-slate-500 text-sm font-bold mt-1 pr-5">{staff.length} أعضاء مسجلين حالياً</p>
                </div>
                <button onClick={() => setShowInvite(true)}
                    className="flex items-center gap-2 px-6 py-3.5 bg-slate-900 hover:bg-orange-600 rounded-2xl text-white font-bold text-sm transition-all shadow-xl shadow-slate-900/10 hover:scale-105 active:scale-95">
                    <UserPlus size={18} /> دعوة عضو جديد
                </button>
            </header>

            <div className="bg-white border border-slate-200 rounded-[2.5rem] overflow-hidden shadow-sm shadow-slate-200/50">
                <div className="divide-y divide-slate-50">
                    {staff.map((member, i) => {
                        const roleCfg = ROLE_CFG[member.role] || ROLE_CFG.viewer;
                        return (
                            <motion.div key={member.id} initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.06 }}
                                className="flex items-center gap-5 p-6 group hover:bg-slate-50/80 transition-all">
                                {/* Avatar */}
                                <div className="w-14 h-14 bg-gradient-to-br from-slate-800 to-slate-950 rounded-2xl flex items-center justify-center text-white font-black text-lg shrink-0 shadow-lg shadow-slate-900/10 group-hover:scale-110 transition-transform">
                                    {member.name.charAt(0)}
                                </div>

                                {/* Info */}
                                <div className="flex-1 min-w-0">
                                    <div className="flex items-center gap-2 mb-0.5">
                                        <p className="font-black text-slate-900 text-base">{member.name}</p>
                                        {member.status === 'inactive' && <span className="text-[9px] px-2 py-0.5 bg-red-50 text-red-600 rounded-full border border-red-100 font-bold uppercase tracking-wider">معطَّل</span>}
                                    </div>
                                    <p className="text-sm text-slate-500 truncate font-medium">{member.email}</p>
                                    <div className="flex items-center gap-4 mt-1.5">
                                        <span className={`inline-flex px-3 py-1 rounded-full text-[10px] font-black border shrink-0 transition-colors ${roleCfg.cls}`}>{roleCfg.label}</span>
                                        <p className="text-[10px] text-slate-400 font-bold">آخر ظهور: {member.last_seen}</p>
                                    </div>
                                </div>

                                {/* Actions */}
                                <div className="flex items-center gap-2 opacity-0 lg:group-hover:opacity-100 transition-all translate-x-2 group-hover:translate-x-0">
                                    <button onClick={() => handleToggleStatus(member.id)}
                                        className="p-3 text-slate-400 hover:text-slate-900 hover:bg-white rounded-xl shadow-sm transition-all border border-transparent hover:border-slate-100"
                                        title={member.status === 'active' ? 'تعطيل' : 'تفعيل'}>
                                        {member.status === 'active' ? <ShieldOff size={18} /> : <Shield size={18} />}
                                    </button>
                                    <button onClick={() => handleRemove(member.id)}
                                        className="p-3 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-xl transition-all border border-transparent hover:border-red-100">
                                        <Trash2 size={18} />
                                    </button>
                                </div>
                            </motion.div>
                        );
                    })}
                </div>
            </div>

            <Modal 
                isOpen={showInvite} 
                onClose={() => setShowInvite(false)}
                title="إضافة عضو للفريق"
                description="امنح صلاحيات الوصول لأعضاء فريقك للعمل معاً"
            >
                <form onSubmit={handleInvite} className="space-y-6">
                    <div>
                        <AdminLabel>الاسم الكامل</AdminLabel>
                        <AdminInput required type="text" value={inviteForm.name} onChange={e => setInviteForm({ ...inviteForm, name: e.target.value })}
                            placeholder="مثلاً: أحمد فؤاد" />
                    </div>
                    <div>
                        <AdminLabel>البريد الإلكتروني</AdminLabel>
                        <AdminInput required type="email" value={inviteForm.email} onChange={e => setInviteForm({ ...inviteForm, email: e.target.value })}
                            placeholder="name@company.com" icon={Mail} />
                    </div>
                    <div>
                        <AdminLabel>الصلاحية والمسؤوليات</AdminLabel>
                        <AdminSelect value={inviteForm.role} onChange={e => setInviteForm({ ...inviteForm, role: e.target.value })}>
                            {Object.entries(ROLE_CFG).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
                        </AdminSelect>
                    </div>
                    <div className="flex gap-4 pt-4 border-t border-slate-100">
                        <button type="button" onClick={() => setShowInvite(false)} className="flex-1 px-6 py-4 bg-slate-100 text-slate-600 rounded-3xl text-sm font-bold hover:bg-slate-200 transition-all">إلغاء</button>
                        <button type="submit" disabled={saving} className="flex-[2] px-6 py-4 bg-slate-900 rounded-3xl text-sm font-bold text-white hover:bg-orange-600 transition-all shadow-xl shadow-slate-900/10 flex items-center justify-center gap-2">
                            {saving && <Loader2 size={16} className="animate-spin" />}
                            إرسال الدعوة الآن
                        </button>
                    </div>
                </form>
            </Modal>
        </motion.div>
    );
};

export default Staff;
