-- ============================================================
-- back.sql - Al Mossad Store: Complete Idempotent Setup Script
-- Safe to run multiple times. Will NOT delete existing data.
-- Run this in the Supabase SQL Editor.
-- ============================================================

-- 0. Enable Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

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

-- ─── 14. Initial Seed Data ────────────────────────────────
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

-- ─── 15. Reload PostgREST Schema Cache ────────────────────
NOTIFY pgrst, 'reload schema';
