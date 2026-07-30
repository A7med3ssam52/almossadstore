import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

const isValidUrl = (url) => {
    try {
        new URL(url);
        return true;
    } catch {
        return false;
    }
};

if (!supabaseUrl || !supabaseAnonKey || !isValidUrl(supabaseUrl)) {
    console.warn('Supabase credentials are missing or invalid in .env file. Auth features will not work.');
}

export const supabase = (supabaseUrl && isValidUrl(supabaseUrl))
    ? createClient(supabaseUrl, supabaseAnonKey)
    : {
        auth: {
            onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => { } } } }),
            getSession: async () => ({ data: { session: null } }),
            signOut: async () => ({ error: null }),
            signInWithPassword: async () => ({ data: { user: null }, error: new Error('Supabase not configured') }),
            signUp: async () => ({ data: { user: null }, error: new Error('Supabase not configured') })
        },
        from: () => ({
            insert: async () => ({ error: new Error('Supabase not configured') }),
            select: () => ({
                eq: () => ({
                    single: async () => ({ data: null, error: new Error('Supabase not configured') })
                })
            })
        })
    };
