import { supabase } from '@/supabaseClient';

const isConfigured = () => !!import.meta.env.VITE_SUPABASE_URL && import.meta.env.VITE_SUPABASE_URL !== 'your_supabase_url_here';

/* ─── Products ─── */
export const getProducts = async (filters = {}) => {
    if (!isConfigured()) {
        console.warn('Supabase not configured, returning empty data');
        return { data: [], error: null };
    }
    try {
        let q = supabase.from('products').select('*, categories(name)').order('created_at', { ascending: false });
        if (filters.search) q = q.ilike('name', `%${filters.search}%`);
        if (filters.categoryId) {
            // Support filtering by either the legacy single category_id or the new category_ids array
            q = q.or(`category_id.eq.${filters.categoryId},category_ids.cs.[${filters.categoryId}]`);
        }
        const { data, error } = await q;
        if (error) throw error;
        return { data: data || [], error: null };
    } catch (error) { 
        console.error('Error fetching products:', error);
        return { data: [], error }; 
    }
};

export const getProductById = async (id) => {
    if (!isConfigured()) return { data: null, error: 'Not configured' };
    try {
        const { data, error } = await supabase
            .from('products')
            .select('*, categories(name), product_variants(*)')
            .eq('id', id)
            .single();
        if (error) throw error;
        return { data, error: null };
    } catch (error) { 
        console.error('Error fetching product by id:', error);
        return { data: null, error }; 
    }
};

export const createProduct = async (productData) => {
    if (!isConfigured()) return { data: null, error: 'Not configured' };
    try {
        // Ensure numeric fields are properly typed for back.sql schema
        const sanitized = {
            ...productData,
            base_price: parseFloat(productData.base_price) || 0,
            discount: parseInt(productData.discount) || 0,
            stock_quantity: parseInt(productData.stock_quantity) || 0,
            is_featured: !!productData.is_featured,
            category_ids: Array.isArray(productData.category_ids) ? productData.category_ids : []
        };
        const { data, error } = await supabase.from('products').insert(sanitized).select().single();
        if (error) throw error;
        return { data, error: null };
    } catch (e) { 
        console.error('Error creating product:', e);
        return { data: null, error: e.message }; 
    }
};

export const updateProduct = async (id, updates) => {
    if (!isConfigured()) return { data: null, error: 'Not configured' };
    try {
        // Ensure numeric fields are properly typed
        const sanitized = {
            ...updates,
            base_price: parseFloat(updates.base_price) || 0,
            discount: parseInt(updates.discount) || 0,
            stock_quantity: parseInt(updates.stock_quantity) || 0,
            is_featured: !!updates.is_featured,
            category_ids: Array.isArray(updates.category_ids) ? updates.category_ids : updates.category_ids ? [updates.category_ids] : undefined,
            updated_at: new Date().toISOString(),
        };
        const { data, error } = await supabase.from('products').update(sanitized).eq('id', id).select().single();
        if (error) throw error;
        return { data, error: null };
    } catch (e) { 
        console.error('Error updating product:', e);
        return { data: null, error: e.message }; 
    }
};

export const deleteProduct = async (id) => {
    if (!isConfigured()) return { error: 'Not configured' };
    try {
        const { error } = await supabase.from('products').delete().eq('id', id);
        if (error) throw error;
        return { error: null };
    } catch (e) { 
        console.error('Error deleting product:', e);
        return { error: e.message }; 
    }
};

export const updateStock = async (productId, newQty) => {
    if (!isConfigured()) return { error: 'Not configured' };
    try {
        const { error } = await supabase.from('products').update({ stock_quantity: newQty }).eq('id', productId);
        if (error) throw error;
        return { error: null };
    } catch (e) { 
        console.error('Error updating stock:', e);
        return { error: e.message }; 
    }
};

/* ─── Image Upload ─── */
export const uploadProductImage = async (file, productId) => {
    if (!isConfigured()) return { url: URL.createObjectURL(file), error: null };
    try {
        const ext = file.name.split('.').pop();
        const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${ext}`;
        const path = `products/${productId}/${fileName}`;
        
        const { error: uploadError } = await supabase.storage.from('product-images').upload(path, file);
        if (uploadError) throw uploadError;
        
        const { data } = supabase.storage.from('product-images').getPublicUrl(path);
        return { url: data.publicUrl, error: null };
    } catch (e) { 
        console.error('Error uploading image:', e);
        return { url: null, error: e.message }; 
    }
};

export const uploadMultipleImages = async (files, productId) => {
    if (!isConfigured()) return { urls: files.map(f => URL.createObjectURL(f)), error: null };
    try {
        const uploadPromises = Array.from(files).map(file => uploadProductImage(file, productId));
        const results = await Promise.all(uploadPromises);
        const urls = results.map(r => r.url).filter(url => !!url);
        const errors = results.filter(r => r.error).map(r => r.error);

        return {
            urls,
            error: errors.length > 0 ? `Failed to upload ${errors.length} images` : null
        };
    } catch (e) { 
        console.error('Error uploading multiple images:', e);
        return { urls: [], error: e.message }; 
    }
};

/* ─── Navigation Data (Mega-Menu) ─── */
export const getNavData = async () => {
    if (!isConfigured()) return { data: [], error: null };
    try {
        // Fetch categories and their products (limit in UI or fetch subset)
        const { data, error } = await supabase
            .from('categories')
            .select('id, name, products(id, name, images, base_price)')
            .order('name');
            
        if (error) throw error;
        return { data: data || [], error: null };
    } catch (error) {
        console.error('Error fetching nav data:', error);
        return { data: [], error };
    }
};

/* ─── Categories ─── */
export const getCategories = async () => {
    if (!isConfigured()) return { data: [], error: null };
    try {
        const { data, error } = await supabase.from('categories').select('*').order('name');
        if (error) throw error;
        return { data: data || [], error: null };
    } catch (error) { 
        console.error('Error fetching categories:', error);
        return { data: [], error }; 
    }
};

export const createCategory = async (catData) => {
    if (!isConfigured()) return { data: null, error: 'Not configured' };
    try {
        const { data, error } = await supabase.from('categories').insert(catData).select().single();
        if (error) throw error;
        return { data, error: null };
    } catch (e) { 
        console.error('Error creating category:', e);
        return { data: null, error: e.message }; 
    }
};

export const updateCategory = async (id, updates) => {
    if (!isConfigured()) return { data: null, error: 'Not configured' };
    try {
        const { data, error } = await supabase.from('categories').update(updates).eq('id', id).select().single();
        if (error) throw error;
        return { data, error: null };
    } catch (e) { 
        console.error('Error updating category:', e);
        return { data: null, error: e.message }; 
    }
};

export const deleteCategory = async (id) => {
    if (!isConfigured()) return { error: 'Not configured' };
    try {
        const { error } = await supabase.from('categories').delete().eq('id', id);
        if (error) throw error;
        return { error: null };
    } catch (e) { 
        console.error('Error deleting category:', e);
        return { error: e.message }; 
    }
};

