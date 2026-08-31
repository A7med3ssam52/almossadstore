import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || '';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || '';

// Create a safe client or a mock to prevent crashes
const mockSupabase = {
    auth: {
        getUser: async () => ({ data: { user: null }, error: null }),
        getSession: async () => ({ data: { session: null }, error: null }),
        onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => { } } } })
    },
    from: () => {
        const chain = {
            select: () => chain,
            eq: () => chain,
            order: () => chain,
            limit: () => chain,
            single: async () => ({ data: null, error: null }),
            then: (onfulfilled) => Promise.resolve({ data: [], error: null, count: 0 }).then(onfulfilled)
        };
        return chain;
    }
};

export const supabase = (supabaseUrl && supabaseAnonKey && supabaseUrl.startsWith('http'))
    ? createClient(supabaseUrl, supabaseAnonKey)
    : mockSupabase;

/**
 * Utility to check if the current user has an admin role.
 * This is used for frontend logic and route protection.
 */
export const checkIsAdmin = async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return false;

    const { data: profile, error } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    if (error || !profile) return false;
    return profile.role === 'admin';
};
