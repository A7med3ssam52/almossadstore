-- ─── Add category_ids JSONB Column ───
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS category_ids JSONB DEFAULT '[]'::jsonb;

-- ─── Migrate existing category_id to the new array (only if empty) ───
UPDATE public.products 
SET category_ids = jsonb_build_array(category_id)
WHERE category_ids = '[]'::jsonb AND category_id IS NOT NULL;

-- ─── Comment on column ───
COMMENT ON COLUMN public.products.category_ids IS 'Array of category IDs for products that belong to multiple categories.';
