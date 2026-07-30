import { supabase } from './adminClient';

const isConfigured = () => !!import.meta.env.VITE_SUPABASE_URL;

export const getOrders = async (filters = {}) => {
    if (!isConfigured()) return { data: [], error: null };
    
    try {
        let q = supabase.from('orders').select('*, profiles(full_name)').order('created_at', { ascending: false });
        if (filters.status && filters.status !== 'all') q = q.eq('status', filters.status);
        const { data, error } = await q;
        if (error) throw error;
        return { data: data || [], error: null };
    } catch (e) {
        console.error('getOrders error:', e);
        return { data: [], error: e.message };
    }
};

export const getOrderById = async (id) => {
    if (!isConfigured()) return { data: null, error: 'Not configured' };
    try {
        const { data, error } = await supabase.from('orders').select('*, profiles(full_name, id)').eq('id', id).single();
        if (error) throw error;
        return { data, error: null };
    } catch (e) {
        console.error('getOrderById error:', e);
        return { data: null, error: e.message };
    }
};

export const updateOrderStatus = async (id, status) => {
    if (!isConfigured()) return { error: 'Not configured' };
    try {
        const { error } = await supabase.from('orders').update({ status }).eq('id', id);
        if (error) throw error;
        return { error: null };
    } catch (e) { return { error: e.message }; }
};

export const getOrdersCount = async () => {
    if (!isConfigured()) return {};
    try {
        const { data, error } = await supabase.from('orders').select('status');
        if (error) throw error;
        if (!data) return {};
        return data.reduce((acc, o) => { acc[o.status] = (acc[o.status] || 0) + 1; return acc; }, {});
    } catch (e) {
        console.error('getOrdersCount error:', e);
        return {};
    }
};

