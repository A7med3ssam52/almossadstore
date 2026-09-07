-- ============================================================
-- make_admin.sql - Al Mossad Store: Promote User to Admin
-- Run this in the Supabase SQL Editor.
-- ============================================================

-- 1. Replace 'user@example.com' with the actual email
UPDATE public.profiles
SET role = 'admin'
WHERE email = 'user@example.com';

-- 2. Verify the change
SELECT id, email, role, full_name 
FROM public.profiles 
WHERE email = 'user@example.com';
