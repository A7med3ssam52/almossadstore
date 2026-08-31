-- ============================================================
-- make_admin_email.sql - Al Mossad Store: Promote User to Admin by Email
-- Run this in the Supabase SQL Editor (https://supabase.com/dashboard/project/bbmnnvzuhjgrtbhksmel/sql/new)
-- ============================================================

-- Replace 'YOUR_EMAIL@example.com' with the actual email you want to make admin
-- Example: UPDATE public.profiles SET role = 'admin' WHERE email = 'admin@almossadstore.com';

UPDATE public.profiles
SET role = 'admin'
WHERE email = 'YOUR_EMAIL@example.com';

-- Verify the change
SELECT id, email, role, full_name, created_at
FROM public.profiles
WHERE email = 'YOUR_EMAIL@example.com';

-- ============================================================
-- Alternative: Create admin user if not exists (requires service_role)
-- Only use this if the user hasn't signed up yet
-- ============================================================

-- DO $$
-- DECLARE
--     new_user_id UUID := gen_random_uuid();
--     admin_email TEXT := 'admin@almossadstore.com';
--     admin_pass  TEXT := 'Al-Mossad2026Online!';
-- BEGIN
--     -- Check if user already exists in auth
--     IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = admin_email) THEN
--         INSERT INTO auth.users (
--             instance_id, id, aud, role, email, encrypted_password,
--             email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
--             created_at, updated_at
--         ) VALUES (
--             '00000000-0000-0000-0000-000000000000',
--             new_user_id,
--             'authenticated', 'authenticated', admin_email,
--             crypt(admin_pass, gen_salt('bf')),
--             NOW(),
--             '{"provider":"email","providers":["email"]}',
--             '{"full_name":"مدير النظام"}',
--             NOW(), NOW()
--         );
--         INSERT INTO auth.identities (id, user_id, identity_data, provider, created_at, updated_at)
--         VALUES (new_user_id, new_user_id, jsonb_build_object('sub', new_user_id::text, 'email', admin_email), 'email', NOW(), NOW());
--         INSERT INTO public.profiles (id, full_name, role) VALUES (new_user_id, 'مدير النظام', 'admin');
--         RAISE NOTICE 'Admin created: %', admin_email;
--     ELSE
--         UPDATE public.profiles SET role = 'admin' WHERE email = admin_email;
--         RAISE NOTICE 'Admin role updated for: %', admin_email;
--     END IF;
-- END $$;

-- ============================================================
-- After running: Try login at your store's /login page
-- ============================================================