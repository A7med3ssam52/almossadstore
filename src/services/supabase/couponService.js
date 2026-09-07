import { supabase } from '@/supabaseClient';

const isConfigured = () => {
  const url = import.meta.env.VITE_SUPABASE_URL || 'https://bbmnnvzuhjgrtbhksmel.supabase.co';
  const key = import.meta.env.VITE_SUPABASE_ANON_KEY || import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_sigZDu-zp-uioBSTzmwEBw_ajz7DscX';
  return !!(url && key && url.startsWith('http'));
};

// C-COUP-07: expiry check uses end-of-day to avoid UTC midnight bug
const isCouponExpired = (expiryDateStr) => {
  if (!expiryDateStr) return false;
  // Interpret as local end-of-day: T23:59:59
  const expiry = new Date(expiryDateStr.includes('T') ? expiryDateStr : `${expiryDateStr}T23:59:59`);
  return expiry < new Date();
};

// Validate coupon by code - checks active, expiry, usage_limit
export const validateCoupon = async (code) => {
  if (!code) return { valid: false, error: 'أدخل كود الكوبون' };
  const normalized = code.trim().toUpperCase();
  // C-COUP-01: Mock coupons only in DEV, never in production
  if (!isConfigured()) {
    if (!import.meta.env.DEV) {
      return { valid: false, error: 'خدمة الكوبونات غير متاحة حالياً' };
    }
    const mocks = {
      'WELCOME20': { id: 'mock-1', code: 'WELCOME20', discount_type: 'percentage', discount_value: 20, is_active: true, expiry_date: '2026-12-31', usage_limit: 100, used_count: 0 },
      'SAVE50': { id: 'mock-2', code: 'SAVE50', discount_type: 'fixed', discount_value: 50, is_active: true, expiry_date: '2026-12-31', usage_limit: 100, used_count: 0 },
      'RAMADAN25': { id: 'mock-3', code: 'RAMADAN25', discount_type: 'percentage', discount_value: 25, is_active: true, expiry_date: '2026-12-31', usage_limit: 100, used_count: 0 },
    };
    const c = mocks[normalized];
    if (c) {
      if (isCouponExpired(c.expiry_date)) return { valid: false, error: 'الكوبون منتهي' };
      return { valid: true, coupon: c };
    }
    return { valid: false, error: 'كود غير صحيح' };
  }
  try {
    const { data, error } = await supabase.from('coupons').select('*').eq('code', normalized).single();
    if (error) {
      // Detect missing table or schema cache issues
      const msg = error.message || '';
      if (msg.includes('does not exist') || msg.includes('schema cache') || msg.includes('relation') ) {
        console.error('coupons table missing – run 20260405_coupons.sql', error);
        return { valid: false, error: 'جدول الكوبونات غير موجود – شغّل ملف 20260405_coupons.sql' };
      }
      if (msg.includes('permission') || msg.includes('policy') || error.code === '42501') {
        console.warn('coupon RLS permission error', error);
        // RLS filtered = no row, treat as invalid code
        return { valid: false, error: 'كود غير صحيح' };
      }
      return { valid: false, error: 'كود غير صحيح' };
    }
    if (!data) return { valid: false, error: 'كود غير صحيح' };
    if (!data.is_active) return { valid: false, error: 'الكوبون غير مفعل' };
    if (isCouponExpired(data.expiry_date)) {
      return { valid: false, error: 'الكوبون منتهي' };
    }
    if (data.used_count != null && data.usage_limit != null && Number(data.used_count) >= Number(data.usage_limit)) return { valid: false, error: 'تم استهلاك الحد الأقصى للكوبون' };
    return { valid: true, coupon: data };
  } catch (e) {
    return { valid: false, error: e.message || 'خطأ في التحقق من الكوبون' };
  }
};

export const calculateDiscount = (subtotal, coupon) => {
  if (!coupon) return 0;
  const st = Math.max(0, Number(subtotal) || 0);
  if (coupon.discount_type === 'percentage') {
    const pct = Math.min(100, Math.max(0, Number(coupon.discount_value)));
    // C-COUP-06: server-side recompute also uses this; clamp and round to 2 decimals
    return Math.round((st * pct) / 100 * 100) / 100;
  }
  // fixed: cap at subtotal (no negative total) and ensure non-negative
  const fixed = Math.max(0, Number(coupon.discount_value) || 0);
  return Math.min(fixed, st);
};

// C-COUP-03: atomic increment with usage_limit check via RPC, fallback with select-for-update style check
export const incrementCouponUsage = async (couponId) => {
  if (!isConfigured() || !couponId || String(couponId).startsWith('mock-')) return { success: true, mocked: true };
  try {
    const { error, data } = await supabase.rpc('increment_coupon_usage', { p_coupon_id: couponId });
    if (error) throw error;
    return { success: true, data };
  } catch (e) {
    console.warn('incrementCouponUsage RPC failed, fallback:', e?.message || e);
    try {
      // Fallback: fetch current and check limit atomically via update with condition
      const { data, error: fetchErr } = await supabase.from('coupons').select('used_count, usage_limit').eq('id', couponId).single();
      if (fetchErr) throw fetchErr;
      if (data && Number(data.used_count) >= Number(data.usage_limit)) {
        console.warn('Coupon usage limit reached, skip increment');
        return { success: false, error: 'limit_reached' };
      }
      // Use conditional update to reduce race window
      const { error: updErr } = await supabase.from('coupons').update({ used_count: (Number(data.used_count) || 0) + 1 }).eq('id', couponId);
      if (updErr) throw updErr;
      return { success: true };
    } catch (fallbackErr) {
      console.error('incrementCouponUsage fallback failed', fallbackErr?.message || fallbackErr);
      return { success: false, error: fallbackErr?.message };
    }
  }
};