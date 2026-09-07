// Re-export canonical supabase client to avoid duplicate instances (S-02)
// All app code should import from @/supabaseClient as single source of truth
export { supabase } from '@/supabaseClient';

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
