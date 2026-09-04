-- ============================================================
-- 20260405_coupons.sql - Al Mossad Store: Coupons + Order discount linkage
-- Run this in Supabase SQL Editor. Idempotent.
-- ============================================================

-- 1. Coupons Table
CREATE TABLE IF NOT EXISTS public.coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage','fixed')),
    discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value > 0),
    expiry_date DATE,
    usage_limit INTEGER DEFAULT 100 CHECK (usage_limit > 0),
    used_count INTEGER DEFAULT 0 CHECK (used_count >= 0),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_coupons_code ON public.coupons(code);
CREATE INDEX IF NOT EXISTS idx_coupons_active_expiry ON public.coupons(is_active, expiry_date);

-- 2. Enable RLS
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Admin full access to coupons" ON public.coupons;
    CREATE POLICY "Admin full access to coupons" ON public.coupons
        FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

    DROP POLICY IF EXISTS "Public can validate active coupons" ON public.coupons;
    CREATE POLICY "Public can validate active coupons" ON public.coupons
        FOR SELECT USING (is_active = true AND (expiry_date IS NULL OR expiry_date >= CURRENT_DATE) AND used_count < usage_limit);

    DROP POLICY IF EXISTS "Users can validate coupon by code" ON public.coupons;
    CREATE POLICY "Users can validate coupon by code" ON public.coupons
        FOR SELECT USING (true);
END $$;

-- 3. Link orders to coupons + discount tracking
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='coupon_id') THEN
        ALTER TABLE public.orders ADD COLUMN coupon_id UUID REFERENCES public.coupons(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='discount_amount') THEN
        ALTER TABLE public.orders ADD COLUMN discount_amount DECIMAL(10,2) DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='coupon_code') THEN
        ALTER TABLE public.orders ADD COLUMN coupon_code TEXT;
    END IF;
END $$;

-- 4. Function to safely increment used_count (called from checkout after successful order)
CREATE OR REPLACE FUNCTION public.increment_coupon_usage(p_coupon_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.coupons SET used_count = used_count + 1, updated_at = NOW() WHERE id = p_coupon_id AND used_count < usage_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Trigger to maintain updated_at
DROP TRIGGER IF EXISTS coupons_updated_at ON public.coupons;
CREATE TRIGGER coupons_updated_at BEFORE UPDATE ON public.coupons FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 6. Stock decrement helper: call after order_items insert to reduce stock safely
CREATE OR REPLACE FUNCTION public.decrement_stock(p_product_id UUID, p_qty INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE public.products SET stock_quantity = GREATEST(0, stock_quantity - p_qty), updated_at = NOW() WHERE id = p_product_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Fix orders.shipping_address to JSONB if still TEXT (idempotent helper)
DO $$
BEGIN
    -- If shipping_address is TEXT, we keep it TEXT for backward compat but add JSONB parsing helpers in app layer.
    -- This migration does NOT alter type to avoid data loss; app now handles both.
    RAISE NOTICE 'coupons migration done';
END $$;

-- 8. Seed example coupons if not exists
INSERT INTO public.coupons (code, discount_type, discount_value, expiry_date, usage_limit, is_active)
VALUES 
    ('WELCOME20', 'percentage', 20, '2026-12-31', 100, true),
    ('SAVE50', 'fixed', 50, '2026-06-30', 50, true),
    ('RAMADAN25', 'percentage', 25, '2026-09-01', 200, true)
ON CONFLICT (code) DO NOTHING;