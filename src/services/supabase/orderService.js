import { supabase } from './adminClient';

const isConfigured = () => {
    const url = import.meta.env.VITE_SUPABASE_URL || 'https://bbmnnvzuhjgrtbhksmel.supabase.co';
    const key = import.meta.env.VITE_SUPABASE_ANON_KEY || import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_sigZDu-zp-uioBSTzmwEBw_ajz7DscX';
    return !!(url && key && url.startsWith('http'));
};

export const getOrders = async (filters = {}) => {
    if (!isConfigured()) return { data: [], error: null };
    try {
        // FIX: removed failing profiles(full_name) join – FK orders.user_id -> auth.users not profiles
        // orders already stores customer_name + shipping_address JSON, so no join needed
        let q = supabase.from('orders').select('*').order('created_at', { ascending: false });
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
    if (!isConfigured()) return { data: null, error: null };
    try {
        // FIX: removed profiles join (no FK) – use customer_name/shipping_address instead
        const { data, error } = await supabase.from('orders').select('*').eq('id', id).single();
        if (error) throw error;
        // Also fetch order_items with product info (FK order_items.product_id -> products.id exists)
        const { data: items, error: itemsError } = await supabase.from('order_items').select('*, products(name, images, base_price)').eq('order_id', id);
        if (!itemsError) data.items = items || [];
        // Optional: enrich with profile name if user_id present (best-effort, non-blocking)
        if (data.user_id) {
            try {
                const { data: prof } = await supabase.from('profiles').select('full_name').eq('id', data.user_id).single();
                if (prof?.full_name) data.profiles = prof;
            } catch {}
        }
        return { data, error: null };
    } catch (e) {
        console.error('getOrderById error:', e);
        return { data: null, error: e.message };
    }
};

export const updateOrderStatus = async (id, status) => {
    if (!isConfigured()) return { error: null };
    try {
        const { error } = await supabase.from('orders').update({ status, updated_at: new Date().toISOString() }).eq('id', id);
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

export const getOrderItems = async (orderId) => {
    if (!isConfigured()) return { data: [], error: null };
    try {
        const { data, error } = await supabase.from('order_items').select('*, products(name, images)').eq('order_id', orderId);
        if (error) throw error;
        return { data: data||[], error: null };
    } catch(e){ return { data: [], error: e.message }; }
};