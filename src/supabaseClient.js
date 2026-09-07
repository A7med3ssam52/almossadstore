import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://bbmnnvzuhjgrtbhksmel.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_sigZDu-zp-uioBSTzmwEBw_ajz7DscX';

const isValidUrl = (url) => {
    try {
        new URL(url);
        return true;
    } catch {
        return false;
    }
};

const isConfigured = !!(supabaseUrl && supabaseAnonKey && isValidUrl(supabaseUrl));

// Silent in production - only warn in development with friendly Arabic
if (!isConfigured && import.meta.env.DEV) {
    console.debug('المتجر يعمل في الوضع التجريبي بدون اتصال بقاعدة البيانات');
}

export const supabase = isConfigured
    ? createClient(supabaseUrl, supabaseAnonKey)
    : {
        auth: {
            onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => { } } } }),
            getSession: async () => ({ data: { session: null } }),
            getUser: async () => ({ data: { user: null }, error: null }),
            signOut: async () => ({ error: null }),
            signInWithPassword: async () => ({ data: { user: null }, error: { message: 'Supabase غير مُهيأ — تأكد من VITE_SUPABASE_URL في .env' } }),
            signUp: async () => ({ data: { user: null }, error: { message: 'Supabase غير مُهيأ — تأكد من VITE_SUPABASE_URL في .env' } })
        },
        from: () => {
            const chain = {
                select: () => chain,
                insert: () => chain,
                update: () => chain,
                delete: () => chain,
                eq: () => chain,
                or: () => chain,
                ilike: () => chain,
                in: () => chain,
                order: () => chain,
                limit: () => chain,
                single: async () => ({ data: null, error: { message: 'Supabase غير مُهيأ' } }),
                then: (onfulfilled) => Promise.resolve({ data: [], error: { message: 'Supabase غير مُهيأ' }, count: 0 }).then(onfulfilled)
            };
            return chain;
        },
        rpc: async () => ({ data: null, error: { message: 'Supabase غير مُهيأ' } }),
        storage: {
            from: () => ({
                upload: async () => ({ error: { message: 'Supabase غير مُهيأ' } }),
                getPublicUrl: () => ({ data: { publicUrl: '' } })
            })
        }
    };

// Expose for debugging and legacy global references (prevents "supabase is not defined" ReferenceError)
if (typeof window !== 'undefined') {
    // @ts-ignore
    window.supabase = supabase;
    // @ts-ignore
    window._supabaseConfigured = isConfigured;
}
