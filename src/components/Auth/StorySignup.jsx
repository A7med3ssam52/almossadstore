import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useAuthJourney } from './hooks/useAuthJourney';
import { logEvent, ANALYTICS_EVENTS, ANALYTICS_STEPS } from '../../services/analyticsService';
import ProgressBar from './StoryJourney/ProgressBar';
import StageFoundations from './StoryJourney/StageFoundations';
import StageSecurity from './StoryJourney/StageSecurity';
import StageAccess from './StoryJourney/StageAccess';
import StageErrorBoundary from './StoryJourney/StageErrorBoundary';
import './StoryJourney/StoryJourney.css';
import { supabase } from '../../supabaseClient';
import { showToast } from '../Common/StoreToast';

const StorySignup = () => {
    const navigate = useNavigate();
    const { currentStep, formData, updateData, nextStep, prevStep } = useAuthJourney('signup');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    useEffect(() => {
        logEvent({
            step_name: currentStep === 1 ? ANALYTICS_STEPS.FOUNDATIONS :
                currentStep === 2 ? ANALYTICS_STEPS.SECURITY :
                    ANALYTICS_STEPS.ACCESS,
            event_type: ANALYTICS_EVENTS.STEP_VIEW,
            path: '/signup'
        });
    }, []); // Only on mount

    const handleNext = async () => {
        const stepNames = [ANALYTICS_STEPS.FOUNDATIONS, ANALYTICS_STEPS.SECURITY, ANALYTICS_STEPS.ACCESS];
        await logEvent({
            step_name: stepNames[currentStep - 1],
            event_type: ANALYTICS_EVENTS.STEP_COMPLETE,
            path: '/signup'
        });
        nextStep();
        await logEvent({
            step_name: stepNames[currentStep],
            event_type: ANALYTICS_EVENTS.STEP_VIEW,
            path: '/signup'
        });
    };

    const handleBack = async () => {
        const stepNames = [ANALYTICS_STEPS.FOUNDATIONS, ANALYTICS_STEPS.SECURITY, ANALYTICS_STEPS.ACCESS];
        await logEvent({
            step_name: stepNames[currentStep - 1],
            event_type: ANALYTICS_EVENTS.BACK_CLICK,
            path: '/signup'
        });
        prevStep();
    };

    const handleSubmit = async () => {
        setLoading(true);
        setError(null);

        try {
            // 1. Create Auth User & Pass Metadata
            const { data: authData, error: authError } = await supabase.auth.signUp({
                email: formData.email,
                password: formData.password,
                options: {
                    data: {
                        full_name: formData.fullName,
                        phone_number: formData.phone,
                        address: formData.address,
                    }
                }
            });

            if (authError) throw authError;

            // Note: The `profiles` row is created automatically by a PostgreSQL trigger
            // reacting to the `auth.users` insert, reading the metadata we passed above.

            await logEvent({
                step_name: ANALYTICS_STEPS.ACCESS,
                event_type: ANALYTICS_EVENTS.STEP_COMPLETE,
                path: '/signup',
                metadata: { success: true }
            });

            // Close the auth modal overlay instead of navigating
            window.dispatchEvent(new Event('auth:close'));
            showToast('تم إنشاء الحساب بنجاح! مرحباً بك في آل مسعد ستور', 'success');
        } catch (err) {
            console.error('Signup error:', err);
            setError(err.message);
            showToast('حدث خطأ أثناء إنشاء الحساب، يرجى المحاولة مرة أخرى', 'error');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="story-auth-container">
            <div className="story-stage-wrapper">
                <StageErrorBoundary>
                    <div className="stage-boundary-wrapper">
                        <AnimatePresence mode="wait">
                            {currentStep === 1 && (
                                <StageFoundations
                                    key="foundations"
                                    data={formData}
                                    updateData={updateData}
                                    onNext={handleNext}
                                />
                            )}
                            {currentStep === 2 && (
                                <StageSecurity
                                    key="security"
                                    data={formData}
                                    updateData={updateData}
                                    onNext={handleNext}
                                    onBack={handleBack}
                                />
                            )}
                            {currentStep === 3 && (
                                <StageAccess
                                    key="access"
                                    data={formData}
                                    updateData={updateData}
                                    onBack={handleBack}
                                    onSubmit={handleSubmit}
                                    isLoading={loading}
                                />
                            )}
                        </AnimatePresence>
                    </div>
                </StageErrorBoundary>
            </div>

            {error && <div className="auth-error-message">{error}</div>}
        </div>
    );
};

export default StorySignup;
