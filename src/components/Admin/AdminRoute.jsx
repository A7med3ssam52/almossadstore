import React, { useEffect, useState } from 'react';
import { Outlet, useNavigate } from 'react-router-dom';
import { checkIsAdmin } from '@/services/supabase/adminClient';

/**
 * AdminRoute Guard
 * Protects all /admin/* routes.
 * Only allows access if the logged-in user has role = 'admin' in the profiles table.
 * Redirects to the storefront home if not authenticated or not an admin.
 */
const AdminRoute = () => {
    const navigate = useNavigate();
    const [status, setStatus] = useState('checking'); // 'checking' | 'authorized' | 'denied'

    useEffect(() => {
        const verify = async () => {
            try {
                const isAdmin = await checkIsAdmin();
                if (isAdmin) {
                    setStatus('authorized');
                } else {
                    setStatus('denied');
                    navigate('/', { replace: true });
                }
            } catch {
                setStatus('denied');
                navigate('/', { replace: true });
            }
        };
        verify();
    }, [navigate]);

    if (status === 'checking') {
        return (
            <div
                style={{
                    minHeight: '100vh',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    background: '#f8fafc',
                    gap: '16px',
                }}
            >
                <div
                    style={{
                        width: '44px',
                        height: '44px',
                        border: '4px solid #e2e8f0',
                        borderTop: '4px solid #ea580c',
                        borderRadius: '50%',
                        animation: 'spin 0.8s linear infinite',
                    }}
                />
                <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
                <p style={{ color: '#94a3b8', fontWeight: 700, fontSize: '0.9rem' }}>
                    جارٍ التحقق من الصلاحيات...
                </p>
            </div>
        );
    }

    if (status === 'authorized') {
        return <Outlet />;
    }

    return null;
};

export default AdminRoute;
