-- 0. Enable Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Create a variable for the user ID to ensure consistency
DO $$
DECLARE
    new_user_id UUID := gen_random_uuid();
    admin_email TEXT := 'admin@almossadstore.com';
    admin_pass  TEXT := 'Al-Mossad2026Online!'; -- بمكنك تغيير كلمة المرور هنا
BEGIN
    -- 2. Check if user already exists
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = admin_email) THEN
        
        -- 3. Insert into auth.users (Note: Supabase uses pgcrypto for crypt)
        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            recovery_sent_at,
            last_sign_in_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            confirmation_token,
            email_change,
            email_change_token_new,
            recovery_token
        )
        VALUES (
            '00000000-0000-0000-0000-000000000000',
            new_user_id,
            'authenticated',
            'authenticated',
            admin_email,
            crypt(admin_pass, gen_salt('bf')),
            now(),
            now(),
            now(),
            '{"provider":"email","providers":["email"]}',
            '{"full_name":"مدير النظام"}',
            now(),
            now(),
            '',
            '',
            '',
            ''
        );

        -- 4. Insert into auth.identities
        INSERT INTO auth.identities (
            id,
            user_id,
            identity_data,
            provider,
            last_sign_in_at,
            created_at,
            updated_at
        )
        VALUES (
            new_user_id,
            new_user_id,
            format('{"sub":"%s","email":"%s"}', new_user_id::text, admin_email)::jsonb,
            'email',
            now(),
            now(),
            now()
        );

        -- 5. Update the profile role to 'admin' 
        -- (The trigger handle_new_user should have created it as 'user' automatically)
        -- We wait a bit or just do an UPSERT to be safe
        INSERT INTO public.profiles (id, full_name, role)
        VALUES (new_user_id, 'مدير النظام', 'admin')
        ON CONFLICT (id) DO UPDATE SET role = 'admin';

        RAISE NOTICE 'Admin user created successfully with email: %', admin_email;
    ELSE
        RAISE NOTICE 'User with email % already exists.', admin_email;
    END IF;
END $$;
