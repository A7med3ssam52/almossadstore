import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Shield, Key, UserPlus, Mail, Lock, User, AlertCircle, CheckCircle, ChevronLeft, PartyPopper, ArrowRight } from 'lucide-react';
import { supabase } from '../../../supabaseClient';
import confetti from 'canvas-confetti';
import './CreateAccount.css';

const CreateAccount = () => {
    const navigate = useNavigate();
    const [accessCode, setAccessCode] = useState('');
    const [isAuthorized, setIsAuthorized] = useState(false);
    const [accessError, setAccessError] = useState('');

    const [form, setForm] = useState({
        email: '',
        password: '',
        fullName: '',
        role: 'user'
    });
    const [loading, setLoading] = useState(false);
    const [status, setStatus] = useState({ type: null, message: '' });
    const [showSuccess, setShowSuccess] = useState(false);
    const [countdown, setCountdown] = useState(5);

    // 1. Authorize Access
    const handleAuthorize = (e) => {
        e.preventDefault();
        if (accessCode === 'ahmedessamkh') {
            setIsAuthorized(true);
            setAccessError('');
        } else {
            setAccessError('كود الدخول غير صحيح');
        }
    };

    // 2. Create Account
    const handleCreate = async (e) => {
        e.preventDefault();
        setLoading(true);
        setStatus({ type: null, message: '' });

        try {
            // A. Supabase Auth Signup
            const { data: authData, error: authError } = await supabase.auth.signUp({
                email: form.email,
                password: form.password,
                options: {
                    data: {
                        full_name: form.fullName
                    }
                }
            });

            if (authError) throw authError;

            // B. Update Profile Role (Manual update if trigger didn't handle it yet)
            if (authData.user) {
                const { error: profileError } = await supabase
                    .from('profiles')
                    .update({ role: form.role, full_name: form.fullName })
                    .eq('id', authData.user.id);
                
                if (profileError) {
                    console.error('Profile update error:', profileError);
                    // Silently fail but keep notice
                }
            }

            // Success! Trigger Confetti
            confetti({
                particleCount: 150,
                spread: 70,
                origin: { y: 0.6 },
                colors: ['#f97316', '#fbbf24', '#ffffff', '#1e293b']
            });

            setShowSuccess(true);

            // Countdown and Redirect
            let count = 5;
            const timer = setInterval(() => {
                count -= 1;
                setCountdown(count);
                if (count <= 0) {
                    clearInterval(timer);
                    navigate(form.role === 'admin' ? '/admin' : '/');
                }
            }, 1000);

        } catch (err) {
            console.error('Creation error:', err);
            setStatus({ type: 'error', message: err.message });
        } finally {
            setLoading(false);
        }
    };

    // --- RENDER ACCESS GATE ---
    if (!isAuthorized) {
        return (
            <div className="create-auth-gate" dir="rtl">
                <div className="gate-card animate-fade-in text-center">
                    <div className="gate-icon">
                        <Key size={32} />
                    </div>
                    <h2>صفحة محمية</h2>
                    <p>يرجى إدخال كود الدخول للمتابعة</p>
                    
                    <form onSubmit={handleAuthorize} className="gate-form">
                        <div className="input-group">
                            <input 
                                type="password" 
                                placeholder="كود الدخول..."
                                value={accessCode}
                                onChange={(e) => setAccessCode(e.target.value)}
                                autoFocus
                            />
                        </div>
                        {accessError && <div className="gate-error">{accessError}</div>}
                        <button type="submit" className="btn-gate-submit">
                            دخول
                        </button>
                    </form>
                </div>
            </div>
        );
    }

    // --- RENDER CREATION DASHBOARD ---
    return (
        <div className="create-account-container" dir="rtl">
            <div className="create-header">
                <button className="btn-back-home" onClick={() => navigate('/')}>
                    <ChevronLeft size={18} /> العودة للمتجر
                </button>
                <div className="header-badge">
                    <Shield size={14} /> بوابة الإدارة
                </div>
            </div>

            <div className="create-card animate-slide-up">
                <div className="card-top">
                    <div className="title-icon">
                        <UserPlus size={24} />
                    </div>
                    <h1>إنشاء حساب جديد</h1>
                    <p>أدخل البيانات لإنشاء حساب مستخدم أو مسؤول نظام جديد</p>
                </div>

                {status.message && (
                    <div className={`status-banner ${status.type} animate-fade-in`}>
                        {status.type === 'success' ? <CheckCircle size={18} /> : <AlertCircle size={18} />}
                        <span>{status.message}</span>
                    </div>
                )}

                <form onSubmit={handleCreate} className="creation-form">
                    <div className="form-grid">
                        <div className="form-group full-width">
                            <label><User size={16} /> الاسم الكامل</label>
                            <input 
                                type="text" 
                                placeholder="مثال: أحمد عصام"
                                required 
                                value={form.fullName}
                                onChange={(e) => setForm({...form, fullName: e.target.value})}
                            />
                        </div>

                        <div className="form-group">
                            <label><Mail size={16} /> البريد الإلكتروني</label>
                            <input 
                                type="email" 
                                placeholder="mail@example.com"
                                required 
                                value={form.email}
                                onChange={(e) => setForm({...form, email: e.target.value})}
                            />
                        </div>

                        <div className="form-group">
                            <label><Lock size={16} /> كلمة المرور</label>
                            <input 
                                type="password" 
                                placeholder="••••••••"
                                required 
                                value={form.password}
                                onChange={(e) => setForm({...form, password: e.target.value})}
                            />
                        </div>

                        <div className="form-group full-width">
                            <label>نوع الحساب (Role)</label>
                            <div className="role-selector">
                                <label className={`role-option ${form.role === 'user' ? 'active' : ''}`}>
                                    <input 
                                        type="radio" 
                                        name="role" 
                                        value="user" 
                                        checked={form.role === 'user'} 
                                        onChange={(e) => setForm({...form, role: e.target.value})} 
                                    />
                                    <span>مستخدم عادي (User)</span>
                                </label>
                                <label className={`role-option ${form.role === 'admin' ? 'active' : ''}`}>
                                    <input 
                                        type="radio" 
                                        name="role" 
                                        value="admin" 
                                        checked={form.role === 'admin'} 
                                        onChange={(e) => setForm({...form, role: e.target.value})} 
                                    />
                                    <span>مسؤول نظام (Admin)</span>
                                </label>
                            </div>
                        </div>
                    </div>

                    <div className="form-notice">
                        <AlertCircle size={14} />
                        يُرجى ملاحظة أن إنشاء حساب جديد سيؤدي لتسجيل الخروج من الحساب الحالي تلقائياً.
                    </div>

                    <button type="submit" className="btn-create-submit" disabled={loading}>
                        {loading ? 'جاري الإنشاء...' : 'إنشاء الحساب الآن'}
                    </button>
                </form>
            </div>

            {/* --- SUCCESS OVERLAY --- */}
            {showSuccess && (
                <div className="success-full-overlay animate-fade-in" dir="rtl">
                    <div className="success-content-card animate-scale-up">
                        <div className="success-icon-wrapper">
                            <PartyPopper size={48} className="text-orange-500" />
                        </div>
                        
                        <h2>أهلاً بك في عائلة المساعد! 🎊</h2>
                        <p className="success-name">يا {form.fullName}،</p>
                        <p className="success-sub">تم تجهيز حسابك بنجاح. نحن متحمسون جداً لبدء رحلتك معنا.</p>
                        
                        <div className="redirect-info">
                            <div className="spinner-small" />
                            <span>سيتم توجيهك إلى {form.role === 'admin' ? 'لوحة التحكم' : 'المتجر'} خلال {countdown} ثوانٍ...</span>
                        </div>

                        <button 
                            className="btn-success-direct"
                            onClick={() => navigate(form.role === 'admin' ? '/admin' : '/')}
                        >
                            انتقل الآن <ArrowRight size={18} />
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
};

export default CreateAccount;
