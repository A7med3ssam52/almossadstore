import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useAuthJourney } from './hooks/useAuthJourney';
import { logEvent, ANALYTICS_EVENTS, ANALYTICS_STEPS } from '../../services/analyticsService';
import ProgressBar from './StoryJourney/ProgressBar';
import StageErrorBoundary from './StoryJourney/StageErrorBoundary';
import './StoryJourney/StoryJourney.css';
import { supabase } from '../../supabaseClient';
import { checkIsAdmin } from '../../services/supabase/adminClient';

import { AlertCircle, CheckCircle } from 'lucide-react';

const StoryLogin = () => {
    const navigate = useNavigate();
    const { currentStep, formData, updateData, nextStep, prevStep, goToStep } = useAuthJourney('login');
    const [password, setPassword] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [success, setSuccess] = useState(null);

    useEffect(() => {
        logEvent({
            step_name: currentStep === 1 ? ANALYTICS_STEPS.LOGIN_EMAIL : ANALYTICS_STEPS.LOGIN_PASSWORD,
            event_type: ANALYTICS_EVENTS.STEP_VIEW,
            path: '/login'
        });
    }, [currentStep]);

    const handleNext = async () => {
        if (!formData.email) return;

        await logEvent({
            step_name: ANALYTICS_STEPS.LOGIN_EMAIL,
            event_type: ANALYTICS_EVENTS.STEP_COMPLETE,
            path: '/login'
        });
        nextStep();
    };

    const handleLogin = async () => {
        setLoading(true);
        setError(null);
        setSuccess(null);
        try {
            const { error: loginError } = await supabase.auth.signInWithPassword({
                email: formData.email,
                password: password,
            });

            if (loginError) throw loginError;

            setSuccess('تم تسجيل الدخول بنجاح! جاري التحويل...');

            await logEvent({
                step_name: ANALYTICS_STEPS.LOGIN_PASSWORD,
                event_type: ANALYTICS_EVENTS.STEP_COMPLETE,
                path: '/login',
                metadata: { success: true }
            });

            // Check if admin to redirect
            const isAdmin = await checkIsAdmin();
            
            setTimeout(() => {
                window.dispatchEvent(new Event('auth:close'));
                
                // Use absolute redirect for admin to ensure a clean session state
                if (isAdmin) {
                    window.location.href = '/admin';
                }
            }, 800);
            
        } catch (err) {
            console.error('Login error:', err);
            setError(err.message === 'Invalid login credentials' ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة' : err.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="story-auth-container">
            <div className="story-stage-wrapper">
                <StageErrorBoundary>
                    <div className="stage-boundary-wrapper">
                        
                        {/* Auth Feedback Messages */}
                        <AnimatePresence mode="wait">
                            {(error || success) && (
                                <motion.div 
                                    className="auth-message-wrapper"
                                    initial={{ height: 0, opacity: 0, marginBottom: 0 }}
                                    animate={{ height: 'auto', opacity: 1, marginBottom: '1.5rem' }}
                                    exit={{ height: 0, opacity: 0, marginBottom: 0 }}
                                    transition={{ type: "spring", stiffness: 300, damping: 30 }}
                                >
                                    {error && (
                                        <div className="auth-error-message animate-fade-in">
                                            <AlertCircle size={18} />
                                            <span>{error}</span>
                                        </div>
                                    )}
                                    {success && (
                                        <div className="auth-success-message animate-fade-in">
                                            <CheckCircle size={18} />
                                            <span>{success}</span>
                                        </div>
                                    )}
                                </motion.div>
                            )}
                        </AnimatePresence>

                        <AnimatePresence mode="wait">
                            {currentStep === 1 ? (
                                <motion.div
                                    key="login-email"
                                    className="stage-container"
                                    initial={{ opacity: 0, y: 20 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    exit={{ opacity: 0, y: -20 }}
                                >
                                    <div className="micro-copy" style={{ color: '#0f172a' }}>مرحباً بعودتك! ادخل بريدك الإلكتروني للمتابعة.</div>
                                    <div className="stage-content">
                                        <div className="form-group">
                                            <label>البريد الإلكتروني</label>
                                            <input
                                                type="email"
                                                placeholder="example@mail.com"
                                                value={formData.email || ''}
                                                onChange={(e) => updateData({ email: e.target.value })}
                                                onKeyPress={(e) => e.key === 'Enter' && handleNext()}
                                            />
                                        </div>
                                        <div className="stage-actions">
                                            <button
                                                className="btn-next"
                                                onClick={handleNext}
                                                disabled={!formData.email}
                                                style={{ width: '100%' }}
                                            >
                                                متابعة
                                            </button>
                                        </div>
                                        <div style={{ marginTop: '1.5rem', textAlign: 'center' }}>
                                            <p style={{ color: '#64748b', fontSize: '0.9rem' }}>
                                                ليس لديك حساب؟ <span onClick={() => window.dispatchEvent(new CustomEvent('auth:open', { detail: { mode: 'signup' } }))} style={{ color: '#0f172a', cursor: 'pointer', fontWeight: 700 }}>سجل الآن</span>
                                            </p>
                                        </div>
                                    </div>
                                </motion.div>
                            ) : (
                                <motion.div
                                    key="login-password"
                                    className="stage-container"
                                    initial={{ opacity: 0, y: 20 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    exit={{ opacity: 0, y: -20 }}
                                >
                                    <div className="micro-copy" style={{ color: '#0f172a' }}>أدخل كلمة المرور لتسجيل الدخول.</div>
                                    <div className="stage-content">
                                        <div className="form-group">
                                            <label>كلمة المرور</label>
                                            <input
                                                type="password"
                                                placeholder="••••••••"
                                                value={password}
                                                onChange={(e) => setPassword(e.target.value)}
                                                onKeyPress={(e) => e.key === 'Enter' && handleLogin()}
                                                autoFocus
                                            />
                                        </div>
                                        <div className="stage-actions">
                                            <button className="btn-back" onClick={prevStep}>
                                                رجوع
                                            </button>
                                            <button
                                                className="btn-submit"
                                                onClick={handleLogin}
                                                disabled={!password || loading}
                                            >
                                                {loading ? 'جاري الدخول...' : 'تسجيل الدخول'}
                                            </button>
                                        </div>
                                    </div>
                                </motion.div>
                            )}
                        </AnimatePresence>
                    </div>
                </StageErrorBoundary>
            </div>
        </div>
    );
};

export default StoryLogin;
