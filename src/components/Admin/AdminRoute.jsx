import React, { useEffect, useState } from 'react';
import { Outlet, useNavigate, Link } from 'react-router-dom';
import { checkIsAdmin } from '@/services/supabase/adminClient';
import { ShieldAlert, LogIn, Home, RefreshCw } from 'lucide-react';

const AdminRoute = () => {
    const navigate = useNavigate();
    const [status, setStatus] = useState('checking');
    useEffect(() => {
        let isMounted = true;
        const verify = async () => {
            try {
                const isAdmin = await checkIsAdmin();
                if (!isMounted) return;
                if (isAdmin) setStatus('authorized'); else setStatus('denied');
            } catch (err) {
                console.warn('Admin check failed:', err);
                if (!isMounted) return;
                setStatus('denied');
            }
        };
        verify();
        return () => { isMounted = false; };
    }, []);
    if (status === 'checking') {
        return (
            <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', background: '#f8fafc', gap: '16px' }}>
                <div style={{ width: '44px', height: '44px', border: '4px solid #e2e8f0', borderTop: '4px solid #ea580c', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
                <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
                <p style={{ color: '#94a3b8', fontWeight: 700, fontSize: '0.9rem' }}>جارٍ التحقق من الصلاحيات...</p>
            </div>
        );
    }
    if (status === 'authorized') return <Outlet />;
    return (
        <div dir="rtl" style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f8fafc', padding: '24px' }}>
            <div style={{ maxWidth: '520px', width: '100%', background: 'white', borderRadius: '24px', padding: '32px', boxShadow: '0 20px 50px rgba(0,0,0,0.08)', border: '1px solid #f1f5f9', textAlign: 'center' }}>
                <div style={{ width: '64px', height: '64px', background: '#fef2f2', border: '1px solid #fecaca', borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px', color: '#ef4444' }}>
                    <ShieldAlert size={32} />
                </div>
                <h2 style={{ fontSize: '20px', fontWeight: 900, color: '#0f172a', marginBottom: '8px' }}>غير مصرح لك بالدخول</h2>
                <p style={{ color: '#64748b', fontSize: '14px', lineHeight: 1.7, marginBottom: '20px' }}>
                    يجب تسجيل الدخول بحساب أدمن للوصول إلى لوحة التحكم.<br />
                    إذا كنت أدمن بالفعل، تأكد أن حسابك له <code style={{ background: '#f1f5f9', padding: '2px 6px', borderRadius: '6px' }}>role = 'admin'</code> في جدول <code style={{ background: '#f1f5f9', padding: '2px 6px', borderRadius: '6px' }}>profiles</code>.
                </p>
                <div style={{ display: 'flex', gap: '12px', justifyContent: 'center', flexWrap: 'wrap' }}>
                    <button onClick={() => navigate('/?auth=login')} style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', background: '#0f172a', color: 'white', border: 'none', borderRadius: '12px', padding: '12px 20px', fontWeight: 800, cursor: 'pointer' }}>
                        <LogIn size={18} /> تسجيل الدخول
                    </button>
                    <button onClick={() => window.location.reload()} style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', background: 'white', color: '#0f172a', border: '2px solid #e2e8f0', borderRadius: '12px', padding: '12px 20px', fontWeight: 800, cursor: 'pointer' }}>
                        <RefreshCw size={18} /> إعادة المحاولة
                    </button>
                    <Link to="/" style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', background: '#f8fafc', color: '#334155', border: '1px solid #e2e8f0', borderRadius: '12px', padding: '12px 20px', fontWeight: 800, textDecoration: 'none' }}>
                        <Home size={18} /> العودة للمتجر
                    </Link>
                </div>
                <p style={{ marginTop: '16px', fontSize: '11px', color: '#94a3b8', fontWeight: 600 }}>
                    تلميح: بعد تسجيل الدخول، ارجع إلى /admin مرة أخرى. أو شغّل ملف supabase/make_admin_email.sql في Supabase SQL Editor لترقية حسابك.
                </p>
            </div>
        </div>
    );
};
export default AdminRoute;
