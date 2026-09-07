import { supabase } from '../supabaseClient';

// Get or create a session ID for anonymous tracking
const getSessionId = () => {
    let sessionId = sessionStorage.getItem('al_mossad_analytics_session');
    if (!sessionId) {
        sessionId = crypto.randomUUID();
        sessionStorage.setItem('al_mossad_analytics_session', sessionId);
    }
    return sessionId;
};

export const logEvent = async ({ step_name, event_type, path, metadata = {} }) => {
    try {
        const { error } = await supabase.from('auth_analytics').insert({
            session_id: getSessionId(),
            step_name,
            event_type,
            path,
            metadata: {
                ...metadata,
                userAgent: navigator.userAgent,
                language: navigator.language,
                screenResolution: `${window.screen.width}x${window.screen.height}`,
            }
        });

        if (error) {
            console.error('Analytics logging error:', error);
        }
    } catch (err) {
        console.error('Failed to log analytics event:', err);
    }
};

export const ANALYTICS_EVENTS = {
    STEP_VIEW: 'STEP_VIEW',
    STEP_COMPLETE: 'STEP_COMPLETE',
    BACK_CLICK: 'BACK_CLICK'
};

export const ANALYTICS_STEPS = {
    FOUNDATIONS: 'Foundations',
    SECURITY: 'Security',
    ACCESS: 'Access',
    LOGIN_EMAIL: 'Login_Email',
    LOGIN_PASSWORD: 'Login_Password'
};
