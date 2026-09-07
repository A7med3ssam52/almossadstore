import { supabase } from './adminClient';

const MOCK_BANNERS = [
    { id: 1, title: 'عروض الصيف الكبرى', image_url: '', link_url: '/offers', sort_order: 1, is_active: true },
    { id: 2, title: 'تشكيلة الدهانات الجديدة', image_url: '', link_url: '/category/paints', sort_order: 2, is_active: true },
];

const MOCK_ANNOUNCEMENT = { id: 1, text: 'شحن مجاني للطلبات فوق 500 ريال! 🎉', bg_color: '#ea580c', text_color: '#ffffff', is_active: true };

const isConfigured = () => {
    const url = import.meta.env.VITE_SUPABASE_URL || 'https://bbmnnvzuhjgrtbhksmel.supabase.co';
    const key = import.meta.env.VITE_SUPABASE_ANON_KEY || import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_sigZDu-zp-uioBSTzmwEBw_ajz7DscX';
    return !!(url && key && url.startsWith('http'));
};

export const getBanners = async () => {
    if (!isConfigured()) return { data: MOCK_BANNERS, error: null };
    try {
        const { data, error } = await supabase.from('banners').select('*').order('sort_order');
        if (error) throw error;
        return { data, error: null };
    } catch { return { data: MOCK_BANNERS, error: null }; }
};

export const createBanner = async (bannerData) => {
    if (!isConfigured()) return { data: { ...bannerData, id: Date.now() }, error: null };
    try {
        const { data, error } = await supabase.from('banners').insert(bannerData).select().single();
        if (error) throw error;
        return { data, error: null };
    } catch (e) { return { data: null, error: e.message }; }
};

export const updateBanner = async (id, updates) => {
    if (!isConfigured()) return { data: { id, ...updates }, error: null };
    try {
        const { data, error } = await supabase.from('banners').update(updates).eq('id', id).select().single();
        if (error) throw error;
        return { data, error: null };
    } catch (e) { return { data: null, error: e.message }; }
};

export const deleteBanner = async (id) => {
    if (!isConfigured()) return { error: null };
    try {
        const { error } = await supabase.from('banners').delete().eq('id', id);
        if (error) throw error;
        return { error: null };
    } catch (e) { return { error: e.message }; }
};

export const getAnnouncement = async () => {
    if (!isConfigured()) return { data: MOCK_ANNOUNCEMENT, error: null };
    try {
        const { data, error } = await supabase.from('announcements').select('*').single();
        if (error) throw error;
        return { data, error: null };
    } catch { return { data: MOCK_ANNOUNCEMENT, error: null }; }
};

export const updateAnnouncement = async (updates) => {
    if (!isConfigured()) return { data: updates, error: null };
    try {
        const { data, error } = await supabase.from('announcements').upsert(updates).select().single();
        if (error) throw error;
        return { data, error: null };
    } catch (e) { return { data: null, error: e.message }; }
};
