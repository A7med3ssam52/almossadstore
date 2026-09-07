-- ============================================================
-- 20260907_fix_orders_dashboard.sql - FIX: Orders not appearing in Dashboard
-- Root causes fixed:
-- 1) profiles join bug (PGRST200) – removed from orderService
-- 2) anon guest INSERT/SELECT RLS blocked – added explicit anon policies
-- 3) Missing GRANTs for orders/order_items
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor > New query)
-- Idempotent – safe to run multiple times
-- ============================================================

-- 0. Ensure extensions & helper function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public;

-- 1. Grants (required even with RLS)
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.order_items TO anon, authenticated, service_role;
GRANT SELECT ON public.products TO anon, authenticated, service_role;
GRANT SELECT ON public.profiles TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.coupons TO authenticated, service_role;
GRANT SELECT ON public.coupons TO anon, authenticated;

-- 2. Enable RLS (idempotent)
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- 3. Fix Orders policies
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
    CREATE POLICY "Users can view own orders" ON public.orders
        FOR SELECT TO authenticated USING (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Guests can view guest orders" ON public.orders;
    CREATE POLICY "Guests can view guest orders" ON public.orders
        FOR SELECT TO anon, authenticated USING (user_id IS NULL);

    DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
    CREATE POLICY "Users can create own orders" ON public.orders
        FOR INSERT TO anon, authenticated WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

    DROP POLICY IF EXISTS "Anonymous can create guest orders" ON public.orders;
    CREATE POLICY "Anonymous can create guest orders" ON public.orders
        FOR INSERT TO anon WITH CHECK (user_id IS NULL);

    DROP POLICY IF EXISTS "Admin full access to orders" ON public.orders;
    CREATE POLICY "Admin full access to orders" ON public.orders
        FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
END $$;

-- 4. Fix Order Items policies
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
    CREATE POLICY "Users can view own order items" ON public.order_items
        FOR SELECT TO authenticated USING (
            EXISTS (SELECT 1 FROM public.orders WHERE id = order_items.order_id AND user_id = auth.uid())
        );

    DROP POLICY IF EXISTS "Guests can view guest order items" ON public.order_items;
    CREATE POLICY "Guests can view guest order items" ON public.order_items
        FOR SELECT TO anon, authenticated USING (
            EXISTS (SELECT 1 FROM public.orders WHERE id = order_items.order_id AND user_id IS NULL)
        );

    DROP POLICY IF EXISTS "Users can insert own order items" ON public.order_items;
    CREATE POLICY "Users can insert own order items" ON public.order_items
        FOR INSERT TO anon, authenticated WITH CHECK (
            EXISTS (SELECT 1 FROM public.orders WHERE id = order_items.order_id AND (user_id = auth.uid() OR user_id IS NULL))
        );

    DROP POLICY IF EXISTS "Anonymous can insert guest order items" ON public.order_items;
    CREATE POLICY "Anonymous can insert guest order items" ON public.order_items
        FOR INSERT TO anon WITH CHECK (
            EXISTS (SELECT 1 FROM public.orders WHERE id = order_items.order_id AND user_id IS NULL)
        );

    DROP POLICY IF EXISTS "Admin full access to order items" ON public.order_items;
    CREATE POLICY "Admin full access to order items" ON public.order_items
        FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
END $$;

-- 5. Ensure coupons linkage columns exist
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

-- 6. Reload PostgREST cache
NOTIFY pgrst, 'reload schema';

-- 7. Verification (run manually to check)
-- SELECT * FROM pg_policies WHERE tablename IN ('orders','order_items');
-- As anon: should be able to INSERT guest order -> test in SQL Editor with: SET ROLE anon; INSERT INTO orders(user_id, customer_name, total_amount) VALUES (NULL, 'test', 100);
