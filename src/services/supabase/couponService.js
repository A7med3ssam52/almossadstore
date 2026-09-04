import { supabase } from './adminClient';

const isConfigured = () => {
  const url = import.meta.env.VITE_SUPABASE_URL || 'https://bbmnnvzuhjgrtbhksmel.supabase.co';
  const key = import.meta.env.VITE_SUPABASE_ANON_KEY || import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_sigZDu-zp-uioBSTzmwEBw_ajz7DscX';
  return !!(url && key && url.startsWith('http'));
};

// Validate coupon by code - checks active, expiry, usage_limit
export const validateCoupon = async (code) => {
  if (!code) return { valid: false, error: 'أدخل كود الكوبون' };
  const normalized = code.trim().toUpperCase();
  if (!isConfigured()) {
    // Fallback mock for dev without Supabase
    const mocks = {
      'WELCOME20': { id: 'mock-1', code: 'WELCOME20', discount_type: 'percentage', discount_value: 20 },
      'SAVE50': { id: 'mock-2', code: 'SAVE50', discount_type: 'fixed', discount_value: 50 },
      'RAMADAN25': { id: 'mock-3', code: 'RAMADAN25', discount_type: 'percentage', discount_value: 25 },
    };
    const c = mocks[normalized];
    if (c) return { valid: true, coupon: c };
    return { valid: false, error: 'كود غير صحيح' };
  }
  try {
    const { data, error } = await supabase.from('coupons').select('*').eq('code', normalized).single();
    if (error || !data) return { valid: false, error: 'كود غير صحيح' };
    if (!data.is_active) return { valid: false, error: 'الكوبون غير مفعل' };
    if (data.expiry_date && new Date(data.expiry_date) < new Date(new Date().toISOString().split('T')[0])) {
      return { valid: false, error: 'الكوبون منتهي' };
    }
    if (data.used_count >= data.usage_limit) return { valid: false, error: 'تم استهلاك الحد الأقصى للكوبون' };
    return { valid: true, coupon: data };
  } catch (e) {
    return { valid: false, error: e.message };
  }
};

export const calculateDiscount = (subtotal, coupon) => {
  if (!coupon) return 0;
  if (coupon.discount_type === 'percentage') {
    const pct = Math.min(100, Math.max(0, Number(coupon.discount_value)));
    return Math.round((subtotal * pct) / 100 * 100) / 100;
  }
  // fixed: cap at subtotal (no negative total)
  return Math.min(Number(coupon.discount_value), subtotal);
};

export const incrementCouponUsage = async (couponId) => {
  if (!isConfigured() || !couponId || couponId.startsWith('mock-')) return;
  try {
    await supabase.rpc('increment_coupon_usage', { p_coupon_id: couponId });
  } catch (e) {
    console.warn('incrementCouponUsage failed', e);
    // fallback direct update
    const { data } = await supabase.from('coupons').select('used_count').eq('id', couponId).single();
    if (data) await supabase.from('coupons').update({ used_count: data.used_count + 1 }).eq('id', couponId);
  }
};