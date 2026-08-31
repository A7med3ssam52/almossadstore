-- ============================================================
-- last.sql - Al Mossad Store: Unified Complete Setup Script
-- Combines: back.sql + cart_items + auth_analytics + seed + import_data
-- Safe to run multiple times. Will NOT delete existing data.
-- Run this in the Supabase SQL Editor.
-- Generated: 2026-08-31
-- ============================================================

-- ============================================================
-- back.sql - Al Mossad Store: Complete Idempotent Setup Script
-- Safe to run multiple times. Will NOT delete existing data.
-- Run this in the Supabase SQL Editor.
-- ============================================================

-- 0. Enable Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── 1. Categories Table ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.categories (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id BIGINT REFERENCES public.categories(id) ON DELETE SET NULL,
    icon_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 2. Products Table (Full Definition) ──────────────────
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    base_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
    discount INTEGER DEFAULT 0,                          -- نسبة الخصم % للعروض (يستخدمها FlashSale)
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    category_id BIGINT REFERENCES public.categories(id) ON DELETE SET NULL,
    category_ids JSONB DEFAULT '[]'::jsonb,              -- مصفوفة معرفات التصنيفات (لدعم تصنيفات متعددة)
    images JSONB DEFAULT '[]'::jsonb,                    -- مصفوفة روابط الصور
    is_featured BOOLEAN DEFAULT false,                    -- للمنتجات المميزة في الصفحة الرئيسية
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 3. Product Variants Table ────────────────────────────
CREATE TABLE IF NOT EXISTS public.product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    price_modifier DECIMAL(10, 2) DEFAULT 0,
    stock_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 4. Profiles Table ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT,
    phone_number TEXT,
    address TEXT,
    role TEXT DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 5. Migration: Add any missing columns safely ─────────
-- This block ensures ALL columns exist even if the table was created
-- from an older or incomplete version of this script.
DO $$
BEGIN
    -- name (العمود الأساسي)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='products' AND column_name='name'
    ) THEN
        ALTER TABLE public.products ADD COLUMN name TEXT NOT NULL DEFAULT '';
    END IF;

    -- description
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='products' AND column_name='description'
    ) THEN
        ALTER TABLE public.products ADD COLUMN description TEXT;
    END IF;

    -- base_price: rename 'price' if exists, otherwise add
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='products' AND column_name='base_price'
    ) THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema='public' AND table_name='products' AND column_name='price'
        ) THEN
            ALTER TABLE public.products RENAME COLUMN price TO base_price;
        ELSE
            ALTER TABLE public.products ADD COLUMN base_price DECIMAL(10, 2) NOT NULL DEFAULT 0;
        END IF;
    END IF;

    -- discount (نسبة خصم للمنتج تستخدمها FlashSale)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='products' AND column_name='discount'
    ) THEN
        ALTER TABLE public.products ADD COLUMN discount INTEGER DEFAULT 0;
    END IF;

    -- stock_quantity
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='products' AND column_name='stock_quantity'
    ) THEN
        ALTER TABLE public.products ADD COLUMN stock_quantity INTEGER NOT NULL DEFAULT 0;
    END IF;

    -- images (مصفوفة JSONB لروابط الصور)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='products' AND column_name='images'
    ) THEN
        ALTER TABLE public.products ADD COLUMN images JSONB DEFAULT '[]'::jsonb;
    END IF;

    -- category_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='products' AND column_name='category_id'
    ) THEN
        ALTER TABLE public.products ADD COLUMN category_id BIGINT REFERENCES public.categories(id) ON DELETE SET NULL;
    END IF;

    -- is_featured (للمنتجات المميزة)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='products' AND column_name='is_featured'
    ) THEN
        ALTER TABLE public.products ADD COLUMN is_featured BOOLEAN DEFAULT false;
    END IF;

    -- category_ids (لدعم تصنيفات متعددة)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='products' AND column_name='category_ids'
    ) THEN
        ALTER TABLE public.products ADD COLUMN category_ids JSONB DEFAULT '[]'::jsonb;
        -- Migrate existing category_id to the new array if applicable
        UPDATE public.products SET category_ids = jsonb_build_array(category_id) WHERE category_id IS NOT NULL;
    END IF;

    -- updated_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='products' AND column_name='updated_at'
    ) THEN
        ALTER TABLE public.products ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;

    -- created_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='products' AND column_name='created_at'
    ) THEN
        ALTER TABLE public.products ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
    END IF;

    -- ── Profiles ──
    -- Ensure columns exist even if the table was created before the schema sync
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='email') THEN
        ALTER TABLE public.profiles ADD COLUMN email TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='phone_number') THEN
        ALTER TABLE public.profiles ADD COLUMN phone_number TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='address') THEN
        ALTER TABLE public.profiles ADD COLUMN address TEXT;
    END IF;
END $$;

-- ─── 6. Storage Bucket for Product Images ─────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- ─── 7. Enable Row Level Security ─────────────────────────
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ─── 8. is_admin() Helper Function ────────────────────────
-- SECURITY DEFINER bypasses RLS so the function can read profiles
-- without triggering infinite recursion in any profiles policy.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public;

-- ─── 9. RLS Policies ──────────────────────────────────────
DO $$
BEGIN
    -- ── Categories ──
    DROP POLICY IF EXISTS "Public access to categories" ON public.categories;
    CREATE POLICY "Public access to categories" ON public.categories
        FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Admin full access to categories" ON public.categories;
    CREATE POLICY "Admin full access to categories" ON public.categories
        FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

    -- ── Products: قراءة للجميع، كتابة/حذف/تعديل للمسؤول فقط ──
    DROP POLICY IF EXISTS "Public access to products" ON public.products;
    CREATE POLICY "Public access to products" ON public.products
        FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Admin insert products" ON public.products;
    CREATE POLICY "Admin insert products" ON public.products
        FOR INSERT WITH CHECK (public.is_admin());

    DROP POLICY IF EXISTS "Admin update products" ON public.products;
    CREATE POLICY "Admin update products" ON public.products
        FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

    DROP POLICY IF EXISTS "Admin delete products" ON public.products;
    CREATE POLICY "Admin delete products" ON public.products
        FOR DELETE USING (public.is_admin());

    -- إزالة السياسة القديمة الموحدة إن وجدت
    DROP POLICY IF EXISTS "Admin full access to products" ON public.products;

    -- ── Product Variants ──
    DROP POLICY IF EXISTS "Public access to product_variants" ON public.product_variants;
    CREATE POLICY "Public access to product_variants" ON public.product_variants
        FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Admin full access to product_variants" ON public.product_variants;
    CREATE POLICY "Admin full access to product_variants" ON public.product_variants
        FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

    -- ── Profiles: كل مستخدم يرى ويعدل سجله فقط ──
    -- ملاحظة: لا نستخدم is_admin() هنا لمنع التكرار اللانهائي (Infinite Recursion)
    DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
    CREATE POLICY "Users can view own profile" ON public.profiles
        FOR SELECT USING (auth.uid() = id);

    DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
    CREATE POLICY "Users can update own profile" ON public.profiles
        FOR UPDATE USING (auth.uid() = id);

    -- مسموح للمسؤول رؤية كل البروفايلات (عن طريق تجاوز RLS بـ Security Definer في الدوال الأخرى)
    -- لكن هنا نكتفي بالحد الأدنى لمنع الخطأ
    DROP POLICY IF EXISTS "Admin full access to profiles" ON public.profiles;
    
    -- إضافة سياسة INSERT للبروفايل عند التسجيل
    DROP POLICY IF EXISTS "Enable insert for everyone" ON public.profiles;
    CREATE POLICY "Enable insert for everyone" ON public.profiles
        FOR INSERT WITH CHECK (auth.uid() = id);

    -- إزالة السياسات القديمة والمكررة
    DROP POLICY IF EXISTS "Admin full access to profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Enable insert for service role" ON public.profiles;
END $$;

-- ─── 10. Storage Policies ─────────────────────────────────
DO $$
BEGIN
    DROP POLICY IF EXISTS "Public access to product images" ON storage.objects;
    CREATE POLICY "Public access to product images" ON storage.objects
        FOR SELECT USING (bucket_id = 'product-images');

    DROP POLICY IF EXISTS "Admin upload product images" ON storage.objects;
    CREATE POLICY "Admin upload product images" ON storage.objects
        FOR INSERT WITH CHECK (
            bucket_id = 'product-images' AND public.is_admin()
        );

    DROP POLICY IF EXISTS "Admin update product images" ON storage.objects;
    CREATE POLICY "Admin update product images" ON storage.objects
        FOR UPDATE USING (
            bucket_id = 'product-images' AND public.is_admin()
        );

    DROP POLICY IF EXISTS "Admin delete product images" ON storage.objects;
    CREATE POLICY "Admin delete product images" ON storage.objects
        FOR DELETE USING (
            bucket_id = 'product-images' AND public.is_admin()
        );

    -- إزالة السياسة القديمة الموحدة إن وجدت
    DROP POLICY IF EXISTS "Admin full access to product images" ON storage.objects;
END $$;

-- ─── 11. Auto Profile Creation on Sign-Up ─────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    BEGIN
        INSERT INTO public.profiles (id, full_name, role, phone_number, address)
        VALUES (
            new.id, 
            COALESCE(new.raw_user_meta_data->>'full_name', ''), 
            'user',
            new.raw_user_meta_data->>'phone_number',
            new.raw_user_meta_data->>'address'
        )
        ON CONFLICT (id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
        -- Safe fallback in case the database hasn't fully migrated the new columns
        INSERT INTO public.profiles (id, full_name, role)
        VALUES (
            new.id, 
            COALESCE(new.raw_user_meta_data->>'full_name', ''), 
            'user'
        )
        ON CONFLICT (id) DO NOTHING;
    END;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ─── 12. Auto-update `updated_at` on products change ──────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS products_updated_at ON public.products;
CREATE TRIGGER products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─── 13. Orders & Order Items Tables ────────────────────────
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    customer_name TEXT,                                  -- الاسم المكتوب في الطلب
    status TEXT NOT NULL DEFAULT 'pending',              -- pending, processing, shipped, delivered, cancelled
    payment_status TEXT DEFAULT 'unpaid',                -- unpaid, paid, refunded
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    shipping_cost DECIMAL(10, 2) DEFAULT 0,
    shipping_address TEXT,
    contact_phone TEXT,
    notes TEXT,                                          -- ملاحظات العميل
    payment_method TEXT DEFAULT 'COD',
    tracking_number TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    options JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Safe Alterations for Orders ──
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='user_id') THEN
        ALTER TABLE public.orders ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='customer_name') THEN
        ALTER TABLE public.orders ADD COLUMN customer_name TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='status') THEN
        ALTER TABLE public.orders ADD COLUMN status TEXT NOT NULL DEFAULT 'pending';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='payment_status') THEN
        ALTER TABLE public.orders ADD COLUMN payment_status TEXT DEFAULT 'unpaid';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='total_amount') THEN
        ALTER TABLE public.orders ADD COLUMN total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='shipping_cost') THEN
        ALTER TABLE public.orders ADD COLUMN shipping_cost DECIMAL(10, 2) DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='shipping_address') THEN
        ALTER TABLE public.orders ADD COLUMN shipping_address TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='contact_phone') THEN
        ALTER TABLE public.orders ADD COLUMN contact_phone TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='notes') THEN
        ALTER TABLE public.orders ADD COLUMN notes TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='payment_method') THEN
        ALTER TABLE public.orders ADD COLUMN payment_method TEXT DEFAULT 'COD';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='tracking_number') THEN
        ALTER TABLE public.orders ADD COLUMN tracking_number TEXT;
    END IF;

    -- Indexes for performance
    CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
    CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
END $$;

-- Enable RLS for Orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    -- ── Orders Policies ──
    -- Users can view their own orders
    DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
    CREATE POLICY "Users can view own orders" ON public.orders
        FOR SELECT USING (auth.uid() = user_id);

    -- Users can insert their own orders (and guests can insert their own anonymous orders)
    DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
    CREATE POLICY "Users can create own orders" ON public.orders
        FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

    -- Admins can view and manage all orders
    DROP POLICY IF EXISTS "Admin full access to orders" ON public.orders;
    CREATE POLICY "Admin full access to orders" ON public.orders
        FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

    -- ── Order Items Policies ──
    -- Users can view items of their own orders
    DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
    CREATE POLICY "Users can view own order items" ON public.order_items
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM public.orders
                WHERE id = order_items.order_id AND user_id = auth.uid()
            )
        );

    -- Users can insert items into their own orders
    DROP POLICY IF EXISTS "Users can insert own order items" ON public.order_items;
    CREATE POLICY "Users can insert own order items" ON public.order_items
        FOR INSERT WITH CHECK (
            EXISTS (
                SELECT 1 FROM public.orders
                WHERE id = order_items.order_id AND (user_id = auth.uid() OR user_id IS NULL)
            )
        );

    -- Admins can view and manage all order items
    DROP POLICY IF EXISTS "Admin full access to order items" ON public.order_items;
    CREATE POLICY "Admin full access to order items" ON public.order_items
        FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
END $$;

-- Enable updated_at trigger for orders
DROP TRIGGER IF EXISTS orders_updated_at ON public.orders;
CREATE TRIGGER orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ─── 14. Cart Items Table (Persisted Shopping Carts) ──────────
-- Merged from supabase/migrations/20260403_cart_items.sql - adapted for idempotency
CREATE TABLE IF NOT EXISTS public.cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    options JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS cart_items_user_id_idx ON public.cart_items(user_id);
CREATE UNIQUE INDEX IF NOT EXISTS cart_items_user_product_options_idx
ON public.cart_items (user_id, product_id, (options::text));

ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view their own cart items" ON public.cart_items;
    CREATE POLICY "Users can view their own cart items"
    ON public.cart_items FOR SELECT
    USING (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can insert their own cart items" ON public.cart_items;
    CREATE POLICY "Users can insert their own cart items"
    ON public.cart_items FOR INSERT
    WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can update their own cart items" ON public.cart_items;
    CREATE POLICY "Users can update their own cart items"
    ON public.cart_items FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can delete their own cart items" ON public.cart_items;
    CREATE POLICY "Users can delete their own cart items"
    ON public.cart_items FOR DELETE
    USING (auth.uid() = user_id);
END $$;

-- Reuse set_updated_at() for cart_items
DROP TRIGGER IF EXISTS update_cart_items_updated_at ON public.cart_items;
CREATE TRIGGER update_cart_items_updated_at
    BEFORE UPDATE ON public.cart_items
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.cart_items IS 'Stores persistent shopping cart items for authenticated users';

-- ─── 15. Auth Analytics Table ─────────────────────────────────
-- Merged from supabase/migrations/20260304000000_auth_analytics.sql - adapted
CREATE TABLE IF NOT EXISTS public.auth_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    step_name TEXT NOT NULL,
    event_type TEXT NOT NULL,
    path TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb
);

ALTER TABLE public.auth_analytics ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Allow anonymous inserts" ON public.auth_analytics;
    CREATE POLICY "Allow anonymous inserts" ON public.auth_analytics
        FOR INSERT TO anon
        WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow authenticated inserts" ON public.auth_analytics;
    CREATE POLICY "Allow authenticated inserts" ON public.auth_analytics
        FOR INSERT TO authenticated
        WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow service_role all" ON public.auth_analytics;
    CREATE POLICY "Allow service_role all" ON public.auth_analytics
        FOR ALL TO service_role
        USING (true) WITH CHECK (true);
END $$;

COMMENT ON TABLE public.auth_analytics IS 'Tracks user progress through the story-based authentication flow.';

-- ─── 16. Initial Seed Data ────────────────────────────────
-- Ensure the primary categories requested by the user are always available
INSERT INTO public.categories (name)
SELECT name FROM (
    VALUES 
        ('دهانات'),
        ('حدايد'),
        ('ديكور'),
        ('مواد لاصقة'),
        ('العدد اليومية')
) AS t(name)
WHERE NOT EXISTS (
    SELECT 1 FROM public.categories c WHERE c.name = t.name
);

-- ============================================================
-- 17. Product Data Import (from import_data.sql / List.xlsx)
-- Generated via generate_sql.js - Idempotent category + product inserts
-- ============================================================

-- Al Mossad Store Data Import SQL

INSERT INTO public.categories (name) SELECT 'حدايد' WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'حدايد');
INSERT INTO public.categories (name) SELECT 'بويات' WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'بويات');
INSERT INTO public.categories (name) SELECT 'مواد لاصقة' WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'مواد لاصقة');
INSERT INTO public.categories (name) SELECT 'ديكور' WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'ديكور');
INSERT INTO public.categories (name) SELECT 'عدد يدوية' WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'عدد يدوية');

INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طرمبة باب مصفح ٩سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج امبيانس كلر سينفوني ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو معجون لصق فيوتك', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرخ استينسل', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرطاسة وسط', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون اهرام باب شقة عادة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٨فضي السويدية (١٠٧)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج معجون لصق فيوتك', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'عود استيل ذهبي ٢سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس رش بلدي', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون اهرام باب شقة كمبيوتر', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٨نحاسى السويدية (١٠٤)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة سيتوكس ٢٥ Hكجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'عود استيل فضي ٢سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'غيار رولة كبير سويدية ازرقXاحمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون اهرام باب صاج', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٨ ذهبي السويدية (١٠١)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لصق دوكو ٢" السويدية (اخضر)', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'عود زاوية استيل 2.4م', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'غيار رولة صغير السويدية ابيضXاسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون اهرام ٣سكة لطش', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج نفط رومى لتر المهندس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'انبوبة فوم', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'عود زاوية استيل 3م', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'غيار رولة كبير سويدية ابيضXاسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون اهرام درج سكة ورفاص', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج نفط رومى دوبل شفاف كبير المهندس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شريط لحام كهرباء اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'عود استانلس ذهبي ٥سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية يد خشب ابيض ٥٫٢بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل نحاس اهرام ٧٠مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كلة رخام GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كارت لحام حديد 2*1', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة K‏٣٩', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس شمع السويدية', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل نحاس اهرام ٦٠مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ كلة رخام GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كارت لحام شفاف 2*1', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شرائح بديل خشب', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد رولة صغير', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون اهرام درج ٢ سكة مفتوح', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جالون معجون دوكو المهندس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لصق قنديل ٢بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٠١ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكينة معجون ٦" السويدية', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون اهرام درج ٢ سكة مقفول', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سيلر مقاوم (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لصق قنديل ١بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٠٢ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية يد خشب ابيض ٣بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون اهرام باب حجرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بستيك ٣٠٣٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بكرة لصق ١بوصة مميزة ٢x‏١', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٠٣ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'متر قياس ٣م السويدية', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون اهرام باب حمام', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة معجون دايتون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بكرة لصق ٢بوصة مميزة ٢x‏١', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٠٤ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'غيار رولة صغير سويدية اصفرXاسود ١٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مكنة سبليونة داخل اسطامة اهرام', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'GLC (٤٢٠) صبغة اخشاب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بكرة لصق شفاف', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٠٨ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'غيار رولة كبير سويدية اصفرXاسود ٢٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون اهرام زمبلك حمام', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة ورنيش مائى GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'دبل فيس شفاف ٢سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٠٩ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'متر قياس ٥م السويدية', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طرمبة اهرام عادة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ورنيش مائى GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'دبل فيس اخضر', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧١١ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كف معجون السويدية ٢٥سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طرمبة اهرام كومبيوتر', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة كمبليكوGLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لصق ورق حائط ايطالي', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧١٣ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد رولة كبير', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون اهرام الوميتال ٢٠مللي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو بستيك ٣٠٣٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'انبوبة سيليكون اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٢٢ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكينة معجون ٣" السويدية', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل نحاس اهرام ٥٠مللي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش استاندر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'انبوبة سيليكون ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٢٣ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكينة معجون ٥٫١" السويدية', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفصلة مطبخ عدلة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو جلتكس٢٠٠٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'انبوبة سيليكون شفاف', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٢٤ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكينة معجون ٥" السويدية', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفصلة ارو ٦" ذهبي صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش مائى GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'انبوبة سيليكون عضم رمادي كينج بست ٧٠٠٠ حراري', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٢٥ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكينة استانلس ٨بوصة سويدية مميزة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل حديد صيني ١بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'GLC (١٠١) صبغة اخشاب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'انبوبة سيليكون عضم رمادي كينج بست ٥٠٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٢٦ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكينة معجون ٤" السويدية', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل حديد صيني ٥٫١بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو مط٢٠٠(ابيض)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسبراي لصق', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٢٧ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مالك معدن السويدية', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل حديد صيني ٢بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٠٩) بني غامق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'انبوبة امير كبيرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٣٠ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس رش سويدية ٩٩٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل حديد صيني ٥٫٢بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبرك (٧٠٨) بني', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'انبوبة امير صغيرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٣١ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس رش سويدية G‏١٧', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم عجل كاوتش فايبر احمر ٢بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧١٥) احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كارت سيليكون شفاف', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٧٠ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية مميزة ١بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'عين سحرية صيني ذهبي ٧سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٥٠) اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'انبوبة امير الصاروخ كبيرة ٢٠٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٧٧٧ صرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية مميزة ٥٫١بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوز مفصلة مروحة تايواني ٣بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٦١) نبيتي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'انبوبة سيليكون تايندي شفاف', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٠٢', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية مميزة ٢بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوز مفصلة مروحة تايواني ٤بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٩١) جملي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كلة رخام كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٠٣', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية مميزة ٥٫٢بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوز مفصلة مروحة تايواني ٥بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧٨٦) ابيض دوبل', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة لصق سيراميك ٢٥ك (ابيض)savito', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٠٤', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية مميزة ٣بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ترباس شقة صيني كافيه', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بستيك استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة لصق سيراميك ٢٥ك (رصاصي) savito', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٠٥', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية عادة ١بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون زجاج جرار', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢كيه استارت ( ابيض )', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤ غراء سريع', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٠٨', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية عادة ٥٫١بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون ايديال٢٠مم نيكل', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢كيه استارت (اسود)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ غراء سريع', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٠٩', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية عادة ٢بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم عجل كاوتش فايبر احمر ٤بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢كيه استارت (بني)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج غراء سريع', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥١٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية عادة ٥٫٢بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون فندقى ذهبي صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه استارت ( ابيض )', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو غراء سريع', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥١١', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية عادة ٣بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل كمبيوتر ٥٠مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه استارت ( بنى )', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كلة رخام انجليزي', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥١٣', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'غيار رولة كبير سويدية برتقالي', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل كمبيوتر ٦٣مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢كيه استارت (اخضر)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'انبوبة سيليكون عضم رمادي A‏١', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥١٦', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'غيار رولة صغير السويدية مهير', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طرمبة باب مصفح ١١سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه استارت ( اخضر )', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة سيتوكس U', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٢١', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'غيار روله سويديه فتله ١٥ سم ابيضxاسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مجرى درج مرحلتين ٤٥سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه (اسود) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة سيتوكس ٥٠ Uكجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='مواد لاصقة' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٢٣', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكينة استانلس ٦بوصة سويدية مميزة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل مصفح صلب صيني ٨٤مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤كيه (ابيض) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٢٤', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية عادة ٤بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل مصفح نيكل صيني ٩٠مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو مط٢٠٠(عسلى)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٢٦', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية يد خشب ابيض ٢بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل مصفح صلب صيني ٩٤مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤كيه (اسود) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٢٧', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بكرة لصق ١سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل مصفح نيكل صيني ٨٠مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤كيه (احمر) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٢٨', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سويدية يد خشب ابيض ٥٫١بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض موبليا صيني نيكل ٩٦', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤كيه (بنى) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٢٩', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كف معجون السويدية ٢٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض موبليا كافيه صيني ٩٦', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة معجون تاكت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٣١', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكينة استانلس ١٠بوصة يد ابنوس', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة ذهبي ايطالي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢كيه استارت (احمر)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٣٤', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكينة استانلس ١٠بوصة يد احمرXرمادي', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر ذهبي ايطالي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢كيه استارت (ازرق)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٣٧', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد رولة كبيرة سيخ', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام ذهبي ايطالي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢كيه استارت (اصفر)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٣٨', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'غيار رولة كبير سويدية اصفر سيخ', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك ذهبي ايطالي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه استارت (احمر)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٤٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سواحيلي / قطيفة ٤ بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طرمبة كمبيوتر صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه (اخضر) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٤٢', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'غيار رولة صغير السويدية ابيض x اصفر x اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة عجل جرار باب منزلق', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤كيه (ازرق) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٤٤', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكينة استانلس ٦بوصة يد ابنوس', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'متر باب جرار منزلق', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤كيه (اصفر) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٥٣', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مطرقة ٥٫١كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مجرى درج مرحلتين ٥٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه استارت (اصفر)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٥٥', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شاكوش ٢٠٠جم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مجرى درج مرحلتين ٤٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه استارت (ازرق)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٦١', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شاكوش ٣٠٠جم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مجرى درج مرحلتين ٣٥سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤كيه (اخضر) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٦٣', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'متر قياس ٢٠م فايبر', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مجرى درج مرحلتين ٣٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو مط ٢٠٠(اسود)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٦٠٤ بانو', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'متر قياس ٣٠م فايبر', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قفل كمبيوتر ٣٨مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج مط (اسود) GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٦٠٩ بانو', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سراق خشابي (١٨)', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'زورار درج ثقيل ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'GLC (٧١٢) صبغة اخشاب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'K٢٢٠ بانو', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد منشار حدادي', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'زورار درج ثقيل نحاسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧٨٦) ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'زاوية عمود AW‏٠٠٦', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اجنة كاوتش مبططة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'زورار درج ثقيل فضي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧٩١) جملي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'K٢٤٠ بانو', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اجنة كاوتش مسمار', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مكنة قفل باب سلك', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو مط (ازرق) GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'زاوية سادة ٤٠٢٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انجليزي ١٠ بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون حمام اشارة تركى', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغة اخشاب (٠٦) GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'زاوية منقوشة ٤٠٢٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انجليزي ١٢ بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون كومبيوتر تركي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغة اخشاب (٠٧) GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٤٠٢٠ بانو', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة حدادي ٣مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفصلة مطبخ تركي عدلة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'GLC (٠١٩) صبغة اخشاب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥١٥', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة حدادي ٤مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفصلة مطبخ تركي ١/٢ركبه', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢كيه استارت (جملى)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٣٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة حدادي ٥مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفصلة مطبخ تركي ركبه', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧٢٢) لبني', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٤٠٢٢ بانو', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة حدادي ٦مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون امان تركي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٦٢) سيمون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'LE٠٢ بانو', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة حدادي ٨مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طرمبة خرشوفة تركي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٠١) بيج', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة ٥٥٤', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة حدادي ١٠مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طرمبة كمبيوتر تركي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة كيه (ازرق مع) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كورنيشة S‏٢٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة حدادي ١٢مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس ذهبي البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٨٠) فوشيا', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فورفوجيه فيوتك FD‏١٦', 
    0, 
    (SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='ديكور' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'منجفرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر كومكس نيكل كسيك البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو مط٢٠٠ (بنى)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مطرقة نجار مسلح', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس نيكل كسيك البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبرك (٧١٩) اخضر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرخ صنفرة صاروخ ٧بوصة (٣٦)', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس مؤكسد اصفر البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبرك (٧٢١) ازرق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'حجر قطعية حديد ٧بوصة صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون شقة كومكس', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغة اخشاب (٠٤) GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'حجر جلخ ٧بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس نيكل كسيك البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه استارت (جملى)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم انكيه عادة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة كومكس ذهبي البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٢٢) لبني', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم صلب صينى', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر كومكس مؤكسد اصفر البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '(GLC) استوك‎١/٢', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قاعدة صنفرة سفينج ٧بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس ذهبي البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغة اخشاب (٠١) GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'محبس كمبروسر بلاكور', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر كومكس ذهبي البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧٢٥) رمادي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'محبس كمبروسر عادة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة كومكس مؤكسد اصفر البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٦٤) اصفر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح فرنساوى ٨ بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس مؤكسد اصفر البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كلة رخام ٥٠٠٠ (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح فرنساوى ١٠بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة كومكس نيكل كسيك البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٦٧) فيروزي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح فرنساوى ١٢ بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس نيكل كسيك البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '(GLC) ٥٠٠٠ ك كلة رخام‎١/٢', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم فرشة قلم مستريك', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس مؤكسد اصفر البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سيلر مقاوم (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة مسمار دبوس هواء ٣سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس ذهبي البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بستيك ٢٠٢٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة مسمار دبوس هواء ٢سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة كومكس ذهبي كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة ٧٠٧٠ (ابيض)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكين بدرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر كومكس ذهبي كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة معجون دايتون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسطرين مربع يد خشب', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس ذهبي كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة كومبليكو', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مطرقة ١كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس ذهبي كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سيلر استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ميزان ٣٠سم بكر', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس ذهبي كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة معجون اكريليك', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس دوكو مقلوب', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة كومكس نيكل كسيك كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سيلر جيل نيل ٢٩', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سلك كوباية صاروخ حديد مجدول', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر كومكس نيكل كسيك كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١٠١٠ بستلة', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرخ صنفرة اسكوتش ٧بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس نيكل كسيك كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سيلر مقاوم (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرخ صنفرة صاروخ عادة 7بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس نيكل كسيك كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج معجون اكريليك (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كوريك باليد العدل', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس نيكل كسيك كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بستيك ٣٠٣٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة مسمار دبوس هواء صلب صيني ٢سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة كومكس برونزي كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '٢٠٠٠٠ ج جلتكس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة مسمار دبوس هواء صلب صيني ٥سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر كومكس برونزي كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧٥٠) اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة مسمار دبوس هواء صلب صيني ٤سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس برونزي كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧٠٩) بني غامق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة مسمار دبوس هواء ٥سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس برونزي كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧٢١) ازرق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة مسمار دبوس هواء ٤سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس برونزي كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧١٥) احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'حجر جلخ ٩بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة كومكس ذهبي جيرماني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧٦٤) اصفر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفك قلاب عادة وصليبة صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر كومكس ذهبي جيرماني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧٠٢) اصفر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة دبوس دباسة منجد هواء ١٠/١٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس ذهبي جيرماني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧٠١) اصفر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'زانة ٣م صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس ذهبي جيرماني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج معجون دايتون ١٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم الانكيه نجمة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس ذهبي جيرماني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج جلتكس ابيض٢٥٠٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة معلقة ٢٢مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة كومكس كروم فضي جيرماني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة كيه (ابيض مع) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بيبة ١٣مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر كومكس كروم فضي جيرماني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة كيه (اسود مع) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بروة صغيرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس كروم فضي جيرماني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة جلتكس١٥٠٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بروة وسط', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس كروم فضي جيرماني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة جلتكس ٢٥٠٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بروة كبيرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس كروم فضي جيرماني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة جلتكس ٢٠٠٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'برويطة ثقيلة صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس ذهبي ساندي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بستيك ٣٠٣٠ عمق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شنيور ٦٠٠W كراون', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس ذهبي ساندي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ورنيش ستاندر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فاس بلدي باليد صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس ذهبي ساندي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١٥٠٠٠ ج جلتكس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مكنة برشام صفراء', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر كومكس ذهبي رونالدو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '(ج ٠٧٠٧ )ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس دوكو مقلوب صينى', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس ذهبي رونالدو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه (ابيض) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انجليزي ١٤ بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة كومكس ذهبي ماربي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه (ابيض) استارت دوبل', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة حدادي ١٦مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر كومكس ذهبي ماربي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه (جملى) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قاعدة صنفرة سفينج ٥بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس ذهبي ماربي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه (اصفر) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسطوانة خشابي ٥بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس ذهبي ماربي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه (ازرق) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة حدادي ٧مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس ذهبي ماربي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه (احمر) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرخ صنفرة صاروخ ٥بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة كومكس مؤكسد احمر ماربي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه (بنى) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرخ صنفرة اسكوتش ٥بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس مؤكسد احمر ماربي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧٠٨) بني', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مبرد مثلث٨"', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس مؤكسد احمر ماربي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر ك (٧١٩) اخضر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح بلدي ١٠مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام دائري كومكس كروم فضي جيرماني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه لؤلؤ مع دوبل (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سلك كوباية صاروخ نحاس', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر دائري كومكس كروم فضي جيرماني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج برايمر كوش رمادى (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ميزان مياه ٣٠سم فيت صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام دائري كومكس نيكل كسيك ريكاردو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه استارت (اسود)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة حدادي ١٤مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر دائري كومكس نيكل كسيك ريكاردو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤ استارت ميتالك لؤلؤي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة دبوس دباسة منجد هواء ١٠/١٣', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض زاما كومكس ذهبي فيكتوريا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو استارت ميتالك لؤلؤى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة مسمار دبوس هواء صلب صيني ٣سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض زاما كومكس نيكل كسيك فيكتوريا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ استارت ميتالك لؤلؤى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صاروخ ٥بوصة ٧٠٠وات كراون', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض زاما كومكس برونزي فيكتوريا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو معجون دايتون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'حجر قطعية بسكوتة ٩بوصة صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض زاما كومكس مؤكسد اصفر فيكتوريا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة معجون اكريليك', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح ظرف شنيور', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض زاما كومكس مؤكسد احمر فيكتوريا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ معجون فل تايم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة مروحية ٥"', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض زاما كومكس كافيه مع فيكتوريا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو معجون فل تايم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لقمة رباط صليبة تايواني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض زاما كومكس كروم فضي فلوريدا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ٧٠٧٠ (ابيض)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لقمة ١٧مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض زاما كومكس مؤكسد اصفر فلوريدا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو جلتكس ٢٥٠٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'حجر قطعية حديد ٥بوصة صينى', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض بس كومكس ذهبي رويال', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤ استارت ميتالك فضي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة دبوس دباسة يدوي ١٠مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض بس كومكس نيكل كسيك رويال', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ استارت ميتالك فضي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة دبوس دباسة يدوي ٨مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض بس كومكس برونزي رويال', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو استارت ميتالك فضي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح بلدي ٨مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض بس كومكس مؤكسد اصفر رويال', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤ استارت ميتالك ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بيبة ١٢مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض بس كومكس مؤكسد احمر رويال', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ استارت ميتالك ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بيبة ١٧مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض زاما كومكس مؤكسد اصفر رويال', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو استارت ميتالك ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قصافة فيت ٦"', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كوبجة بس كومكس ذهبي كينج', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو استارت ميتالك نحاسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قصافة فيت ٨"', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كوبجة بس كومكس نيكل كسيك كينج', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ استارت ميتالك نحاسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح بلدي ١٢مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كوبجة بس كومكس برونزي كينج', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤ استارت ميتالك نحاسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح بلدي ١٣مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كوبجة بس كومكس مؤكسد احمر كينج', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو غراء ابيض بولي بوند (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح بلدي ١٧مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كوبجة زاما كومكس ذهبي ماركيس', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جالون غراء ابيض بولي بوند (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح بلدي ٢٨X‏٣٠مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كوبجة زاما كومكس ذهبي فيكتوريا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة غراء ابيض بولي بوند (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ساحقة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كوبجة زاما كومكس برونزي فيكتوريا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة كيه مط ابيض (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'خرطوم سوستة كمبروسر', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ترباس مبطط كبير كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش زجاجي مع (٩٠١)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنسة ببوز صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ترباس مبطط كبير كومكس نيكل كسيك', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ورنيش زجاجى (٩٠١)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفك عادة صينى', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ترباس مبطط كبير كومكس مؤكسد اصفر', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش زجاجى مط (١٠٠١)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة بروش', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'عصفورة كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ورنيش زجاجى مط (١٠٠١)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لقمة ٨مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'عصفورة كومكس نيكل كسيك', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه لؤلؤ مع (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كماشة صيني ٨بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'عصفورة كومكس برونزي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٠٠) فضي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بيبة ١٠مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ترباس مدور صغير كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٨٠٠) ذهبى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بيبة ٨مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ترباس مدور وسط كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغه سي سي اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة معلقة ١٦مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ترباس مدور كبير كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغه سي سي  جملي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لقمة ١٠مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ترباس مدور صغير كومكس نيكل كسيك', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغه سي سي بني', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لقمة ١٥مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ترباس مدور صغير كومكس مؤكسد اصفر', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ك اسود مط', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'حجر قطعية بسكوتة ٥بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رقم صفر كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة كيه مط اسود (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شربون شنيور', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رقم واحد كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغه سي سي  احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ظرف تحويل ١٣مم بالوصلة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رقم اثنين كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغه سي سي  اصفر لموني', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انكيه ٤مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رقم ثثة كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج استوك GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انكيه ٥مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رقم اربعة كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو استوك GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انكيه ٦مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رقم خمسة كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'GLC (١١٦) صبغة اخشاب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انكيه ٨مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رقم ستة كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه مط عسلي (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انكيه ١٠مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رقم سبعة كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه مط ابيض (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنسة لحام صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رقم ثمانية كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه مط ابيض دوبل (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كمبروسر ٥٠ نحاس', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شنكل كومكس صغير ١٠سم ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه مط اسود (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة معلقة ٢٥مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شنكل كومكس كبير ١٥سم ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه مط اسود (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة مفصلة ٣٥مللي', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شنكل كومكس صغير ١٠سم فاميه * ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه مط عسلي (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة معلقة ٢٠مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفصلة كومكس ارو بحلية ٥بوصة - ٥٫٢مم ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه مط ابيض (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ازميل يد كاوتش صيني ١٦مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفصلة كومكس ارو بحلية ٥بوصة - ٥٫٢مم نيكل كسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٢٥) رمادي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس سيليكون عادة صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سبليونة شاكوش كومكس نيكل كسيك ريكاردو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٨٦) ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'دباسة مسمار هواء F‏٥', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سبليونة حلقة كومكس نيكل كسيك', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغه سي سي ازرق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سح اركيت كهرباء', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سبليونة شاكوش كومكس ذهبي كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغه سي سي موف', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سح اركيت يدوي', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سبليونة شاكوش كومكس نيكل كسيك كوين', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغه سي سي اخضر فاتح', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'منشار اركيت يدوي', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سيخ سبليونة كومكس ذهبي ٦٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ كيلو ورنيش استاندر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'متر قياس ٥٠م فايبر', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سيخ سبليونة كومكس نيكل كسيك ٦٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة برما ستار (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صفيحة منشار بحدين بولندي', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سيخ سبليونة كومكس ذهبي ١١٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج برما ستار (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صفيحة منشار بحد واحد', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سيخ سبليونة كومكس نيكل كسيك ١١٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه لؤلؤ مع (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'حجر قطعية بسكوتة ٧بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سبليونة شباك كومكس ذهبي ١١٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو برايمر كوش رمادى (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'الماظة رخام ٥بوصة صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سبليونة شباك كومكس كروم ١١٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغه سي سي اخضر غامق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة فدية شنيور عادة ٦مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سبليونة بلكونة كومكس ذهبي ٢١٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغه سي سي سيمون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة فدية شنيور عادة ٨مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سبليونة بلكونة كومكس كروم ٢١٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فرست كوت مط ابيض دوبل', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة فدية شنيور عادة ١٠مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون سلندر كومكس ٧سم - ٣مفتاح', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فرست كوت مط ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة فدية شنيور عادة ١٢مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كالون حجرة كومكس', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه مط ازرق (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قاعدة صنفرة سكوتش ٥بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة جيرماني فضي x ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه مط اخضر (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قاعدة صنفرة سكوتش ٧بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر جيرماني فضي x ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج معجون دايتون زيتي ١١١', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قاعدة صنفرة صاروخ عادة ٥بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام جيرماني فضي x ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧١١) اخضر جنزاري', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قاعدة صنفرة صاروخ ذور واسع ٧بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر جيرماني فضي x ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٨٤) موف', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس رش ويجما ٩٩٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض زاما نابولي كومكس ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧٠٢) اصفر فاتح', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس رش ويجما G‏١٧', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض زاما كومكس ذهبي بولونيا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بستيك ٣٠٣٠ (١٨كيلو)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة معلقة ١٨مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقبض زاما كومكس ذهبي رويال', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '(GLC) ٥٠٠٠ ج كلة رخام', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم بنطة خرشوفة مقاسات', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة كومكس فضي جنوة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'GLC (٤٠٨) صبغة اخشاب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وصلة خرطوم سريعة ١x‏١', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس فضي جنوة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه مط اصفر (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وصلة خرطوم سريعة ٢x‏١', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس فضي جنوة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه مط اخضر (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وصلة خرطوم سريعة ٣x‏١', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس فضي جنوة', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سوبر ك (٧١٧)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وصلة خرطوم سريعة ذكر', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وش كهرباء ساندي ذهبي فتحه', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'GLC (٠٠١) صبغة اخشاب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وصلة خرطوم سريعة نتاية', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وش كهرباء ساندي ذهبي٢فتحه', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة كيه مط احمر (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وصلة خرطوم سريعة عكشة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وش كهرباء ساندي ذهبي٣فتحه', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة كيه مط ازرق (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شاكوش دباسة هواء', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وش كهرباء روما ذهبي فتحه', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه مط بني (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقص سلك', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وش كهرباء روما ذهبي٢فتحه', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه مط بني (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة سلك يدوي نحاس', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وش كهرباء روما ذهبي٣فتحه', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه مط احمر (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قطر معدن صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وش كهرباء روما نيكل فتحه', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيه مط احمر (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قطر بستيك صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وش كهرباء روما نيكل٣فتحه', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو استارت ميتالك احمر مارون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر لفة بسن ٨مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وش كهرباء روما برونزي ٣فتحه', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ استارت ميتالك احمر مارون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر لفة بسن ١٢مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس ذهبي صوفيا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤ استارت ميتالك احمر مارون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر شطف ٨مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس ذهبي صوفيا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة كيه ( اخضر مع ) استارت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر شطف ١٢مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس ذهبي صوفيا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة ورنيش ستاندر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر غسيل ٨مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة كومكس اسود مط البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سوبر ك (٧٨٦) ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر غسيل ١٢مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر كومكس اسود مط البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر ﻻك )٨٠٧( بني‎ ١/٢', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر ارموطية ٨مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس اسود مط البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سوبر ك (٧٥٠) اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر ارموطية ١٢مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس اسود مط البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بوية طرق اصفر ٢٠ لتر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لقمة بنطة راوتر', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس اسود مط البرتو', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بوية طرق اسود ٢٠ لتر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم باغة بستيك', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حجرة كومكس اسود مط هافانا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه مط ازرق (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم جوانتي', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم سلندر كومكس اسود مط هافانا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سوبر ك (٧١٩) اخضر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قاعدة صنفرة صاروخ عادة ٧بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم حمام كومكس اسود مط هافانا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سوبر ك (٧١٥) احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'حجر جلخ حوائط', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد شباك كومكس اسود مط هافانا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سوبر ك (٧٢١) ازرق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر شطف ٣٥مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ سلندر كومكس اسود مط هافانا', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سانيتون٥٫٢لتر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر افريز ٨مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مكنة باب اسباني', 
    0, 
    (SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='حدايد' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سانيتون ١×‏٢', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر افريز ١٢مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سينتال ١×‏٢', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر قلم حفر', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سفير اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر بيضاوي ٨مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سفير اخضر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لقمة شنيور ١٠مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سفير ازرق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'غيار رولة كومبليكوا', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سفير احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وصلة عكشة ذكر', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سفير اصفر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'وصلة عكشة نتاية', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢سفير اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صمولة صاروخ', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢سفير احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مقشطة زجاجي', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢سفير اخضر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'يد صنفرة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢سفير اصفر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم بنطة معلقة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢سفير ازرق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'نظارة حداد لحام', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سينتال ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انكيه ٢مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سانيتون ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انكيه ٣مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سانيتون اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انكيه ٧مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سانيتون بنى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انكيه ١٢مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سفير بنى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انكيه ١٤مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سفير ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انكيه ١٧مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سفير اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح انكيه ١٩مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سفير بنى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لقمة ١٦مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سفير احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شربون ٩ بوش', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سفير اخضر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شربون بوش ٥٫٤', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سفير اصفر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شربون بوش ٥', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سفير ازرق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفك صليبة صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سينتال ٢لتر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر شطف ٤٥مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ورنيش فلوت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرشة قلم مستريك', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ورنيش فلوت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جلبة تحويل راوتر', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢سفير بنى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر لفة بسن ٤١مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو برايمر ٤٨ باكين (احمر)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كاوتشة تجزيع اخشاب', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو بادى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شاكوش سيراميك بلاستيك', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ديرتون ٧٧٧ احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'زاوية علام نجار', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سانيتون احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم مفك الكتروني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ديرتون ٧٧٧ اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفك قب دقرم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ برايمر ٤٨ باكين (احمر )', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم فرشة سلك شنيور', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش فنار', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مالك معدن مشرشر', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو زيت شمس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'متر قياس ١٠م', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو برايمر ٤٨ باكين (رمادي)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة هلتي ٦مم طويلة ٢١سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش فلوت', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة هلتي ٨مم طويلة ٢١سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سفير ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة هلتي ١٠مم طويلة ٢١سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢سفير ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح بلدي ١٤مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج برايمر ٤٨ باكين (رمادي )', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بيبة ١٤مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ديرتون ٧٧٧ اصفر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفتاح بلدي ٢٢مم صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج برايمر ٤٨ باكين (احمر )', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر شطف ٣٠مم كعب ١٢مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ديرتون ٧٧٧ ازرق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر ارموطية ٣١مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ديرتون ٧٧٧ اخضر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة راوتر لفة بسن ٣٥مللي', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ برايمر ٤٨ باكين (رمادي)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مالك بلاستيك', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة ديركوت ٦٦٦', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'خابور فراشة ٦مم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج غراء بنتا احمر (٥٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مضرب بويا كبير هلتي', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو غراء بنتا اخضر (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'حجر قطعية بسكوتة ٥بوصة استانلس', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو غراء بنتا احمر (٥٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس سيليكون (ABT)', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة غراء بنتا اخضر (٢٠٠) ١٣كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'دباسة دبابيس هواء منجد APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة غراء بنتا احمر (٥٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'دباسة دبابيس يدوي APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج غراء بنتا اخضر (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سلاح صينية خشابي ٢٥٫٧بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤ غراء بنتا اخضر (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سلاح ديسك خشابي ١٠بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بنتا بستيك مط (٣٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سلاح ديسك خشابي ١٢بوصة APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سيلر بنتا ٤٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سلاح ديسك خشابي ١٤بوصة APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ غراء بنتا اخضر (٢٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس رش ٤٫١ APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بنتا بستيك نص مع (١١١)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس رش ٦٫١ APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بنتا بستيك ربع مع (١٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس رش ٥٫٢ APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بنتا بستيك مط (٩٩٩)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم مفاتيح بلدي APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة معجون بنتا ٤٠٠ --- ١٥كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قمع رش APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو معجون بنتا ٤٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس رش قمع APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو بستيك ٣٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سلاح صينية خشابي ٢٥٫٩بوصة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو بستيك ٩٩٩', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بلور كهربائي APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سيلر ٩٩٩', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كمبروسر ١٠٠ لتر APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيس غراء بنتا احمر (٥٠) ٩٠٠جم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس رش جانبي F‏٧٥', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيس غراء بنتا ايكو ٩٠٠جم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'دباسة دبابيس صلب APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بنتا بستيك مط ٩٩٩', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة مسمار دبوس هواء صلب ٣سم APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة دوبل بنتا بستيك مط (٩٩٩)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة مسمار دبوس هواء صلب ٤سم APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج غراء بنتا ابيض (٩٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة مسمار دبوس هواء صلب ٥سم APT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة معجون بنتا ٣٠٠ ---- ١٥كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة كورة مميزة (١٥٠) عرض ٢٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو غراء بنتا ايكو (٩٠٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة كورة مميزة (٢٢٠) عرض ٢٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة غراء بنتا اخضر (٢٠٠) ١٨كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة كورة مميزة (١٨٠) عرض ٢٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة غراء بنتا اخضر (٢٠٠) ٩كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة كورة مميزة (١٢٠) عرض ٢٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٤ غراء بنتا ايكو', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة كورة مميزة (٣٢٠) عرض ٢٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة غراء بنتا احمر (٥٠) ٩كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة كورة مميزة عرض ١٠سم (٦٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'برميل غراء بنتا اخضر (٢٠٠) ٤٥كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرخ صنفرة دوكو اسود صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة معجون اونوشيلد', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرخ صنفرة دوكو احمر صيني', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة معجون البريمو هيرو اسكيب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرخ صنفرة دوكو احمر  SIA', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة ديكورا هيرو اسكيب ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة كورة (٣٢٠) عرض ٨سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سيلر ديكورا سكيب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة كورة (٢٢٠) عرض ٨سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سيلر سعادة', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة كورة (١٢٠) عرض ٨سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اكريكوت HD مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة كورة (١٠٠) عرض ٨سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جالون اكريكوت HD مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة كورة (١٠٠) عرض ٢٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة اكريكوت HD مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة كورة (٣٢٠) عرض ٢٠سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اكريكوت HD مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صنفرة كورة (١٥٠) عرض ٨سم', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جالون اكريكوت HD مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرخ صنفرة دوكو احمر فرنساوي', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة اكريكوت HD مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فرخ صنفرة دبابة', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اكريكوت HD مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مسدس سيليكون INCOO', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج اكريكوت HD مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سلاح ديسك خشابي ١٠بوصة Incco', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب اكريكوت HD مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة هلتي ٦مم FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اكريكوت برايت اجشل A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة هلتي ٨مم FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج اكريكوت برايت اجشل A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة هلتي ١٠مم FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب اكريكوت برايت اجشل A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنطة هلتي ١٢مم FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اكريكوت برايت اجشل B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'حجر قطعية  ٩بوصة Fit', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج اكريكوت برايت اجشل B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اجنة هلتى مبطط FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب اكريكوت برايت اجشل B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اجنة هلتي مسمار FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اكريكوت برايت اجشل C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنسة كلابة Fit', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب اكريكوت برايت اجشل C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'الماظة رخام ٧بوصة FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج اكريكوت سيلك ناعم A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنسة ٩بوصة Fit', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب اكريكوت سيلك ناعم A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفك عادة Fit', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج اكريكوت سيلك ناعم B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفك قب عادة وصليبة Fit', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب اكريكوت سيلك ناعم B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفك تيست كهرباء كبير FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج رويال هيلث شيلد A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مفك صليبة Fit', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رويال هيلث شيلد A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'حجر قطعية بسكوتة ٩بوصة Fit', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج رويال هيلث شيلد B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنسة لحام FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رويال هيلث شيلد B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنسة ٨بوصة FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج رويال مط فاخر A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ميزان مياه ٤٠سم FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب رويال مط فاخر A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنسة قصافة Fit', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج رويال مط فاخر B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كماشة ٨بوصة كروم فانديوم FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب رويال مط فاخر B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بنسة ببوز ٦بوصة FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج رويال مط فاخر C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'الماظة رخام ٥بوصة FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رويال ايجشيل فاخر A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اجنة مسمار صلب يد كاوتش FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رويال ايجشيل فاخر B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'طقم مفتاح انكيه مسدس كروم فانديوم FIT', 
    0, 
    (SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='عدد يدوية' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'رويال ايجشيل فاخر C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج رويال سمارت كلين B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج رويال سمارت كلين C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اكريكوت سيلك ناعم A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اكريكوت سيلك ناعم C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج اكريكوت سيلك ناعم C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ديكورا داخلي مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ديكورا داخلي مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ديكورا داخلي مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ديكورا داخلي مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ديكورا داخلي مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ديكورا داخلي مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ديكورا داخلي مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ديكورا داخلي مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكيك لامع A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سكيك  لامع A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكيك لامع B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سكيك لامع B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكيك لامع C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سكيك لامع C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكيك نصف لامع A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سكيك نصف لامع A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكيك نصف لامع B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سكيك نصف لامع B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سكيك نصف لامع C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكيك مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سكيك مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكيك مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سكيك مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سكيك مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سكيك مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سعادة اسكيب ابيض دوبل', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ديكورا داخلي مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج اكريكوت HD مط R', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اكريكوت HD مط R', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بستيك نبيتي c‏١٢١ اسكيب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج رويال هيلث شيلد C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج رويال مط فاخر R', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج معجون البريمو هيرو', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة جلتكس ويزر كوت B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج اكريكوت برايت اجشل C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه اسود مط ديكورا هيرو اسكيب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه ابيض مط ديكورا هيرو اسكيب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة ويزر كوت كسيك B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه ابيض مع ديكورا هيرو اسكيب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه اسود مع ديكورا هيرو اسكيب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج كيه بني غامق ديكورا هيرو اسكيب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة صبغه جملي سكيب', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سايبس ٢٠٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة معجون سايبس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو معجون سايبس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سايبس ٧٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سيلر سايبس ١٨٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة معجون سايبس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج معجون سايبس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سيلر حرارى (sipes)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سايبس ٧٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سايبس ٧٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سايبس ٢٠٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سايبس ٢٠٠٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'حصى جوز بنى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة غراء وتم تحويلها لبولي بوند', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بك على البارد', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جركن نفط فرنساوي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغة اخشاب (٠١٣) WS', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغة اخشاب (٠٧) WS', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'صبغة اخشاب (٠٦) WS', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سيتوكس H', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قورا احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قورا بنى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قورا جملى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قورا لموني', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قورا ازرق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قورا اخضر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قورا اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قورا ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'قورا موف', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة معجون اسمنتى ابيض٢٥ك (safeto)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج معجون سقيه (savito)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سقية سيراميك ٢٠ك ابيض (savito)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر زيجزاج', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢زيجزاج', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة ٧٠٧٠ (اسود)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة ٧٠٧٠ (احمر)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '(ج ٠٧٠٧ )احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '(ج ٠٧٠٧ )اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ٧٠٧٠ احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ٧٠٧٠ اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ستورم شيلد بنيتريتنج سيلر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ستورم شيلد بنيتريتنج سيلر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ستورم شيلد بنيتريتنج سيلر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين٧٠٠٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين٧٠٠٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين٧٠٠٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين٧٠٠٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين٧٠٠٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين٧٠٠٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين٧٠٠٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين٧٠٠٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين٧٠٠٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين٧٠٠٠ Y', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين داي-ستون٧٠٧٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين داي-ستون٧٠٧٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين داي-ستون٧٠٧٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين داي-ستون٧٠٧٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين داي-ستون٧٠٧٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين داي-ستون٧٠٧٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين داي-ستون٧٠٧٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين داي-ستون٧٠٧٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين داي-ستون٧٠٧٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين٨٠٠٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين٨٠٠٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين٨٠٠٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين٨٠٠٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين٨٠٠٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين٨٠٠٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين٨٠٠٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين٨٠٠٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين٨٠٠٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين٨٠٠٠ Y', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين٨٠٠٠ Y', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين جلتكس١٥٠٠٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين جلتكس١٥٠٠٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين جلتكس١٥٠٠٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين جلتكس١٥٠٠٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين جلتكس١٥٠٠٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين جلتكس١٥٠٠٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين جلتكس١٥٠٠٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين جلتكس١٥٠٠٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين جلتكس١٥٠٠٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين جلتكس٢٠٠٠٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين جلتكس٢٠٠٠٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين جلتكس٢٠٠٠٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين جلتكس٢٠٠٠٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين جلتكس٢٠٠٠٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين جلتكس٢٠٠٠٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين جلتكس٢٠٠٠٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين جلتكس٢٠٠٠٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين جلتكس٢٠٠٠٠ C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين داي-تون٣٠٣٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين داي-تون٣٠٣٠ A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين داي-تون٣٠٣٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب سوبر بتين داي-تون٣٠٣٠ B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين سوبر ك مع A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين سوبر ك مع A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين سوبر ك مع B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين سوبر ك مع B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين سوبر ك مع C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين سوبر ك مع C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين سوبر ك نصف مع A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين سوبر ك نصف مع A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين سوبر ك نصف مع B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين سوبر ك نصف مع B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين سوبر ك نصف مع C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين سوبر ك نصف مع C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين سوبر ك مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين سوبر ك مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين سوبر ك مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين سوبر ك مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'سوبر بتين سوبر ك مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سوبر بتين سوبر ك مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر فلفتووا ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج امبيانس كلر فلفتووا ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر فلفتووا نبيتي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر فلفتووا نحاسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر فلفتووا برونزي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج امبيانس كلر فلفتووا نبيتي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج امبيانس كلر فلفتووا نحاسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج امبيانس كلر فلفتووا برونزي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر ارمادا ذهبي٣٠٢', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر ارمادا فضي٣٠١', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج امبيانس كلر ارمادا ذهبي٣٠٢', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج امبيانس كلر ارمادا فضي٣٠١', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر سينفوني١١١', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر سينفوني ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج امبيانس كلر سينفوني ذهبي ١١١', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر سيناو ١٠٢', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر سيناو', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر موازيك نيو', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج امبيانس كلر موازيك نيو', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢امبيانس كلر هاي سينس ذهبي ١٠١', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢امبيانس كلر هاي سينس فضي ١٠٢', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢امبيانس كلر هاي سينس نحاسي ١٠٣', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر هاي سينس ذهبي ١٠١', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر هاي سينس نحاسي ١٠٣', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر ماربللو ستوكو', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج امبيانس كلر ماربللو ستوكو', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج امبيانس كلر ميكسيكانو', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج امبيانس كلر فلفتووا فضي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر فلفتووا فضي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج امبيانس كلر فاروني', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر فاروني', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة ستورم شيلد نانو بنيتريتنج برايمر ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة معجون ستورم شيلد بريميوم فيللر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ امبيانس كلر فلفتووا ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ امبيانس كلر فلفتووا نحاسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ امبيانس كلر فلفتووا برونزي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ امبيانس كلر فلفتووا نبيتي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سوبر بتين برايمر مائي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر سينفوني ١١٢', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر سيناو ١١٦', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر سيناو', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ امبيانس كلر دايموند', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر امبيانس كلر دايموند', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر امبيانس كلر شل شاين فضي ٩٢٥', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر امبيانس كلر شل شاين لؤلؤي ٨٥٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر امبيانس كلر دايموند فضي ٩٢٥', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر امبيانس كلر شل شاين ذهبي عيار ١٨', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر امبيانس كلر كراكيل فينش', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب امبيانس كلر ميكسيكانو', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة فينوماستيك ابيض (سيلك)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بي في ايه برايمر BVA جوتن', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ستوكو معجون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة معجون بريفيكس جوتن', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوليفكس ابيض جوتن', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ديروسان اكشن مط ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ديروسان اكشن سيمي جلوس ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ديروسان اكشن مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ديروسان اكشن مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ديروسان اكشن مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ديروسان اكشن مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ديروسان اكشن مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ديروسان اكشن سيمي جلوس A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ديروسان اكشن سيمي جلوس A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ديروسان اكشن سيمي جلوس A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ديروسان داخلي سلك A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ديروسان داخلي سلك A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك برايمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك بيتي مطفي غني ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك بيتي مطفي غني A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك بيتي مطفي غني A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك بيتي مطفي غني A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك بيتي مطفي غني B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك بيتي مطفي غني B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك بيتي مطفي غني B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك بيتي مطفي غني C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك بيتي مطفي غني C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك بيتي مطفي غني C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك بيتي ناعم حريري(سيلك) A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك بيتي ناعم حريري(سيلك) A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك بيتي ناعم حريري(سيلك) A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك بيتي ناعم حريري(سيلك) B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك بيتي ناعم حريري(سيلك) B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك بيتي ناعم حريري(سيلك) B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك بيتي ناعم حريري(سيلك) C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك بيتي ناعم حريري(سيلك) C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك بيتي ناعم حريري(سيلك) C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك بيتي ناعم حريري(سيلك) Y', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك بيتي ناعم حريري(سيلك) Y', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه ايملشن مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه ايملشن مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك الوان الناصعه ايملشن مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه ايملشن مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه ايملشن مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك الوان الناصعه ايملشن مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه ايملشن مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه ايملشن مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك الوان الناصعه ايملشن مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه ايملشن سيمي جلوس A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه ايملشن سيمي جلوس A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك الوان الناصعه ايملشن سيمي جلوس A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه ايملشن سيمي جلوس B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه ايملشن سيمي جلوس B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه ايملشن سيمي جلوس C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه ايملشن سيمي جلوس C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك مذهل حياة A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك مذهل حياة A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك مذهل حياة A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك مذهل راقي A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك مذهل راقي A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك مذهل راقي A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه انامل مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه انامل مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه انامل مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه انامل مط B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه انامل مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه انامل مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه انامل سيمي جلوسي A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه انامل سيمي جلوسي A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه انامل سيمي جلوسي B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه انامل سيمي جلوسي B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه انامل سيمي جلوسي C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه انامل سيمي جلوسي C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه انامل جلوسي A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه انامل جلوسي A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه انامل جلوسي B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه انامل جلوسي B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'فينوماستيك الوان الناصعه انامل جلوسي C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك الوان الناصعه انامل جلوسي C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'تصميمات ليدي جليز C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'تصميمات ليدي بيرل C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج تصميمات ليدي بيرل C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'تصميمات ليدي ستوكو انتيك C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج تصميمات ليدي ستوكو انتيك C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ليدي ديزاين رومانو ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ليدي ديزاين رومانو(اساسات الوان) B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'تصميمات ليدي رويال فلفيت C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'تصميمات ليدي ميتلك ساند C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'تصميمات ليدي لمسة شمواه', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو بنيتريتنج سيلر جوتن', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بنيتريتنج سيلر جوتن', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بنيتريتنج سيلر جوتن', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بلوك فيلر جوتن', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ايزي كوت بلس مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ايزي كوت بلس مط A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ايزي كوت بلس مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ايزي كوت بلس مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد الكالي ريزستانت برايمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد الوان تدوم مط (كلرست) ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد الوان تدوم سيلك (كلرست) ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوتاشيلد ايترنا ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد ايترنا ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوتاشيلد الوان تدوم مط (كلرست) A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد الوان تدوم مط (كلرست) A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوتاشيلد الوان تدوم مط (كلرست) B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد الوان تدوم مط (كلرست) B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوتاشيلد الوان تدوم مط (كلرست) C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد الوان تدوم مط (كلرست) C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد الوان تدوم سيلك (كلرست) A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوتاشيلد الوان تدوم سيلك (كلرست) B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد الوان تدوم سيلك (كلرست) B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوتاشيلد الوان تدوم سيلك (كلرست) C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد الوان تدوم سيلك (كلرست) C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوتاشيلد الوان تدوم سيلك (كلرست) B.Y', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد الوان تدوم سيلك (كلرست) B .Y', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد الوان تدوم سيلك (كلرست) G .Y', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوتاشيلد ايترنا A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد ايترنا A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوتاشيلد ايترنا B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد ايترنا B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوتاشيلد ايترنا C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيلد ايترنا C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ورنيش كليبر مط شفاف', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ورنيش كليبر جلوسى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة فينوماستيك ابيض (مط)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة فينوماستيك ابيض (سيمي جلوس)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة معجون ستوكو جوتن', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج تصميمات ليدي رويال فلفيت C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'تصميمات ليدي دايموند', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوتاشيلد كلر ست اكستريم مط', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوتاشيلد كربو مط C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جوتاشيلد ديكور هاي بيلد فاين', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك الوان الناصعه انامل سيمي جلوسي C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك هايجين ايملشن سيلك A', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب جوتاشيد ديكور ترافرتين B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج صبغة وود شيلد خارجي Y', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ليدي ديزاين رومانو(اساسات الوان) B', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو معجون شروخ جوتن (Crackfix)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر نفض رومى جوتن', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ديروسان داخلي مط ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فينوماستيك مذهل حياة C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب فينوماستيك الوان الناصعه ايملشن سيمي جلوس C', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ب ديروسان اكشن مط برو ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    '١/٢ كلة رخام ايجيل', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة ايجيل بستيك ايمالتكس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج برايمر ايجيل احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج برايمر ايجيل رصاصي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو بك عربيات النسر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة بستيك سوا ايجيل', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة معجون داخلي سوا', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كلة رخام سوا', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج قطيفة بيور فضي عادة', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج قطيفة بيور فضي ليزر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج قطيفة ارت فضي عادة', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج قطيفة ارت فضي ليزر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو قطيفة بيور فضي عادة', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو قطيفة بيور فضي ليزر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو قطيفة ارت فضي عادة', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو قطيفة بيور نبيتي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو بولو سواحيلي ارت نحاسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو بولو سواحيلي ارت نبيتي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو قطيفة ارت نحاسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو بولو سواحيلي بيور فضي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو بولو سواحيلي بيور ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو بولو سواحيلي بيور نحاسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو قطيفة بيور نحاسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو بولو سواحيلي بيور نبيتي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة ليزر فضي بيور', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'علبة ليزر ذهبي بيور', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو فور جاردنيا رصاصي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو فور تيوليب ذهبيxابيضxبني', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج قطيفة اسينسو فضي عادة', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو قطيفة بيور ذهبي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج قطيفة ماتريكس فضي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات اصفر (٣٠١)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات احمر (٣٠٧)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات ازرق (٣١٥)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات اخضر (٣٢٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات بنى (٣٢٣)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات اسود (٣٢٤)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات نبيتى (٣٢٥)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات جملى (٣٢٦)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات فاني تية (٣٢٧ )', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات سيمون (٣٠٥)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات موف (٣١٤)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات احمر (٣٠٨)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات بريز (٣٠)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بريمو كات اخضر (٣٢١)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة جبس ممتاز ١٢٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جركن ثنر دبابة', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو احمر مارون ١٤٠٦ QM', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سيلر كاترون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فيلر رصاصي GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو فيلر رصاصى المهندس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فيلر ابيض GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اسود مط GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سيلر اخشاب كاترون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو فيلر ابيض ZO', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو ابيض مع GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش مط دوكو GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فيلر رصاصي كاترون (٥كجم)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج فيلر ابيض كاترون (٥كجم)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اصفر اوكسيد (جملي) GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'زجاجة ثنر نيرو ١L', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو احمر ١٢٠ GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو برتقالي ١٣٤٤ QM', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو عسلي s٢٨ QM', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اسود مع GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جركن ثنر كبير صاروخين', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جركن ثنر كبير دبابتين', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو استوك GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج استوك GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كومباوند تلميع المهندس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بوليش تلميع المهندس', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو احمر ١٢٠ GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو ١٤٧٣ QM', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اصفر اكسيد (جملي) GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو فيلر ابيض GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اصفر جملي ٢٠٨ QM', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو فيلر رصاصي GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ورنيش مع دوكو كاترون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اسود مع GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو ابيض مع GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو ازرق GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اصفر لموني GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ورنيش مط دوكو كاترون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو بني ١٦٧٧ GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو ازرق GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو فضي ٦٢٠ GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اخضر ٧٦٠ GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو ابيض مط GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو بني ١٦٧٧ GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جالون فيلر ابيض ZO', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جالون فيلر رصاصي ZO', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش مع دوكو GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو استوك فايبر عربيات GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اسود مط GB', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو ابيض مط (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اسود مط (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو احمر فيات ١٢٠ (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو فضي فيات٦٢٠ GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو جملي فيات ٢٠٨ GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اسود مط (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ورنيش مع دوكو فاتح١١٠٠ (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ورنيش مط دوكو ١٠٠٥ (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو ابيض مرسيدس ١٤٧ GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو فضي فيات ٦٢٠ GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو ذهبي مرسيدس ٤١٩ GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو برتقالي بيجو١٣٤٤ GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش مع دوكو فاتح ١١٠٠ (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو بنفسجي GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اصفر لموني فيات ٢٧٩ GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو احمر مارون بيجو ١٤٠٦ GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو ابيض مع GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش مط دوكو ١٠٠٥ (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو ازرق شفاف GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اخضر شفاف GLC', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش نصف مع دوكو ١٠٣٠ (GLC)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سيلر اخشاب ميدو', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سيلر اخشاب ميدو', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش فينى وود لميع', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش ميدو مع', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسبراي بنى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسبراي ذهبى', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسبراي احمر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسبراي اسود', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسبراي فضي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسبراي اصفر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسبراي ازرق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسبراي اخضر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسبراي اسود مط', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسبراي ابيض', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر مصلب فرن كولون', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسبراي فضي نيكل', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'اسبراي ذهبي جولد', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ثنر ٦٦٦ كولون ٦٫١كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ثنر ٦٦٦ كولون ٢٫٣كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ثنر ٩٠٩٠ موبي كوت ٥٫٤كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو معجون دوكو كابسي ٤٥٠ بورسعيد', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو فيلر بطئ٦٣٥ غامق', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سيرفسر', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو ابيض مط ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اسود مط ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اسود مع ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ورنيش مط دوكو ٢٠٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو ابيض مع ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو ذهبى دوكو كابسى(٢٠١)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اصفر اكسيد (جملي) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج معجون دوكو كابسي ٤٥٠ بورسعيد', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اصفر لموني(٢٢٠) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو ازرق غامق(٤٧٠) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو ازرق فاتح(٢٠٧١) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اصفر كروم(٢٢٣) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو فضي كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اخضر(٢٠٦١) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو احمر(٢٠٥٥) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بويا فرن C‏٢٢٥ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بويا فرن C‏٤٥٦ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بويا فرن C‏٢٢٧ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بويا فرن C‏٢٢٠ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سيرفيسر ٤٦٠ (٥كجم) كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سيرفيسر ٤٦٠ (٣كجم) كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اسود مع ٢٠٥ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بك عربيات كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر بنفسجي ٢٥٥ VIOLET كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو مزيل كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اصفر اوكسيد (جملي) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو احمر مارون(١٤٠٦) ٢٠٥ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو ابيض مط ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو ابيض مع ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اسود مط ٢٠٥ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اخضر(٧٦٠) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو فضي(١٦٠) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو جولد(١٢٤) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو جولد(١٢٤) ٢٠٥ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سيلر ٢٠٠٠S كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ثنر فرن ٦٠٩ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر ورنيش فرن ٣٠٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو استوك فايبر عربيات كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج استوك عربيات كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بويا فرن ٠١٠ ابيض كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اصفر لموني (٢٧٩) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو جولد (٢٥٥) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو ابيض تكوا بطانة', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بويا فرن تكوا ٦٢٥', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بويا فرن تكوا ٧٦٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بويا فرن تكوا ٤٧٤', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بويا فرن تكوا ٢٢٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بويا فرن تكوا ٦٥٩', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بويا فرن تكوا ٦٥٣', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بويا فرن تكوا ٦٥٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بويا فرن ٣٩٢ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بويا فرن ٦٥٣ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج بويا فرن ٦٤٠ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اخضر شفاف ٢٠٥ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو ازرق شفاف ٢٠٥ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو ورنيش مع ٧٣٠٠ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو احمر (١٢٠) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو احمر (٦٥٩) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اسود مع ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ورنيش مط دوكو ٢٠٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بويا فرن C‏٣٩٢ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بويا فرن ٠١٠ ابيض كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج ورنيش مع دوكو ٢٠٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج استوك كابسي رصاصي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر مصلب فرن تكوا كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر مصلب فرن ٦٥١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر ورنيش فرن ٦٠٥٥', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر ورنيش فرن ٣١٠٠ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو اخضر غامق (٧٦٣) ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو دوكو ازرق فاتح ٢٠١ كابسي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر ثنر جوتن', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج استوك سوا', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو استوك سوا', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'جالون سيلر ناشيونال', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مجموعة ج سيلر بروتال', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو ابيض مط ناشيونال', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو ابيض مع ناشيونال', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اسود مط ناشيونال', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اسود مع ناشيونال', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو سيلر بروتال ناشيونال', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مجموعة كيلو ورنيش بروتال ناشيونال مع', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج استوك ناشيونال', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سيلر ناشيونال', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة برايمر ناشيونال رمادي', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج سيلر ٢ ناشيونال ٣ك', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'ج دوكو اخضر ناشيونال', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة دوكو ابيض مع ناشيونال', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سيلر ٢ ناشيونال ٢٥كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'بستلة سيلر ناشيونال ٢٣كجم', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مجموعة كيلو ورنيش مع ايرك', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مجموعة كيلو ورنيش مط ٢٥% ايرك', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مجموعة كيلو ورنيش مط ١٠% ايرك', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مجموعة ج ورنيش مط ٢٥% ايرك', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'مجموعة كيلو ورنيش مط ٤٥% ايرك', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'لتر همر فينش ٦٧٠', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو جبس ممتاز', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو جلس بوند ٤٦٥', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو كيمابوكسي شفاف مجموعة', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'كيلو اديبوند (saveto)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكاره معجون اسمنتى رصاصي٢٥ك (savito)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة معجون سقيه (savito)', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'شكارة لصق سيراميك ٢٠ك (رصاصي) savito', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);
INSERT INTO public.products (name, base_price, category_id, category_ids, images, stock_quantity, discount, is_featured) 
VALUES (
    'امبيانس كلر هاي سينس فضي ١٠٢', 
    0, 
    (SELECT id FROM public.categories WHERE name='بويات' LIMIT 1), 
    jsonb_build_array((SELECT id FROM public.categories WHERE name='بويات' LIMIT 1)), 
    '[]'::jsonb, 
    0, 0, false
);

-- ─── 18. Update Images for Hand Tools (عدد يدوية) ─────────
-- Ensure category icon and products have a visible image
UPDATE public.categories
SET icon_url = 'https://images.unsplash.com/photo-1581244276891-83393a8ba21d?auto=format&fit=crop&q=80&w=600'
WHERE name IN ('عدد يدوية', 'العدد اليومية') AND (icon_url IS NULL OR icon_url = '');

UPDATE public.products
SET images = '["https://images.unsplash.com/photo-1581244276891-83393a8ba21d?auto=format&fit=crop&q=80&w=600"]'::jsonb,
    updated_at = NOW()
WHERE category_id IN (SELECT id FROM public.categories WHERE name IN ('عدد يدوية', 'العدد اليومية'))
  AND (images = '[]'::jsonb OR images IS NULL);

-- Also cover products using category_ids array (for multi-category support)
UPDATE public.products
SET images = '["https://images.unsplash.com/photo-1581244276891-83393a8ba21d?auto=format&fit=crop&q=80&w=600"]'::jsonb,
    updated_at = NOW()
WHERE images = '[]'::jsonb
  AND EXISTS (
    SELECT 1 FROM public.categories c
    WHERE c.name IN ('عدد يدوية', 'العدد اليومية')
      AND c.id::text = ANY(SELECT jsonb_array_elements_text(category_ids))
  );

-- ─── 19. Reload PostgREST Schema Cache ──────────────────────
NOTIFY pgrst, 'reload schema';
