-- ─── Seed Initial Categories ───
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

-- ─── Optional: Add unique constraint to prevent future duplicates ───
-- ALTER TABLE public.categories ADD CONSTRAINT categories_name_unique UNIQUE (name);
