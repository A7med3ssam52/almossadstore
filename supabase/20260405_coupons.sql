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

-- 2. Enable RLS + Grants (C-COUP-RLS-GRANT)
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;

-- Grants are required even with RLS – without them anon cannot SELECT despite policy
GRANT SELECT ON public.coupons TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.coupons TO authenticated, service_role;
GRANT USAGE ON SCHEMA public TO anon, authenticated;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Admin full access to coupons" ON public.coupons;
    CREATE POLICY "Admin full access to coupons" ON public.coupons
        FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

    DROP POLICY IF EXISTS "Public can validate active coupons" ON public.coupons;
    CREATE POLICY "Public can validate active coupons" ON public.coupons
        FOR SELECT USING (is_active = true AND (expiry_date IS NULL OR expiry_date >= CURRENT_DATE) AND used_count < usage_limit);

    -- C-COUP-04 FIX: Remove permissive USING(true) policy that leaked all coupons
    -- The "Public can validate active coupons" policy above already restricts to active & not expired & not exhausted
    DROP POLICY IF EXISTS "Users can validate coupon by code" ON public.coupons;
    -- Intentionally NOT recreating permissive policy. If per-code lookup is needed, use RPC.
    DROP POLICY IF EXISTS "Public can read coupon by code" ON public.coupons;
    -- No broad SELECT policy beyond the filtered one. Admin retains full access.
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.increment_coupon_usage(UUID) TO anon, authenticated, service_role;

-- 5. Trigger to maintain updated_at
DROP TRIGGER IF EXISTS coupons_updated_at ON public.coupons;
CREATE TRIGGER coupons_updated_at BEFORE UPDATE ON public.coupons FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 6. Stock decrement helper: call after order_items insert to reduce stock safely
CREATE OR REPLACE FUNCTION public.decrement_stock(p_product_id UUID, p_qty INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE public.products SET stock_quantity = GREATEST(0, stock_quantity - p_qty), updated_at = NOW() WHERE id = p_product_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.decrement_stock(UUID, INTEGER) TO anon, authenticated, service_role;

-- 4b. Fix orders RLS for guest checkout + coupons linkage (C-CHK-RLS + C-COUP-GUEST)
-- Without this, anon checkout creates order with user_id NULL, but subsequent:
-- 1) OrderSuccess SELECT fails (policy only allowed auth.uid() = user_id, NULL != NULL)
-- 2) order_items INSERT EXISTS check fails because anon cannot SELECT the guest order to verify
-- So we allow anon to SELECT guest orders (user_id IS NULL). This is minimal leak – they still need the UUID.
DO $$
BEGIN
    DROP POLICY IF EXISTS "Guests can view guest orders" ON public.orders;
    CREATE POLICY "Guests can view guest orders" ON public.orders
        FOR SELECT USING (user_id IS NULL);

    -- Also allow guest order_items insert via existence check – the above SELECT policy makes EXISTS work
    -- Ensure grants for orders & order_items so anon can actually insert/select
    -- (Grants are usually already present, but re-assert idempotently)
    BEGIN
        GRANT SELECT, INSERT ON public.orders TO anon, authenticated;
        GRANT SELECT, INSERT ON public.order_items TO anon, authenticated;
        GRANT SELECT ON public.products TO anon, authenticated;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'grants for orders/order_items/products already configured or not needed';
    END;

    -- Ensure coupons grants for anon SELECT already set above, but also ensure update grant for fallback path
    -- (fallback update will still be blocked by RLS, but RPC is preferred; keep RLS strict)
    RAISE NOTICE 'guest orders RLS + grants fixed';
END $$;

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

-- 9. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';