import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;

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
            signInWithPassword: async () => ({ data: { user: null }, error: null }),
            signUp: async () => ({ data: { user: null }, error: null })
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
                order: () => chain,
                limit: () => chain,
                single: async () => ({ data: null, error: null }),
                then: (onfulfilled) => Promise.resolve({ data: [], error: null, count: 0 }).then(onfulfilled)
            };
            return chain;
        },
        storage: {
            from: () => ({
                upload: async () => ({ error: null }),
                getPublicUrl: () => ({ data: { publicUrl: '' } })
            })
        }
    };
