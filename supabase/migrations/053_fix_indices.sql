-- Fix indices and schema issues
BEGIN;

-- Drop existing indices if they exist
DROP INDEX IF EXISTS idx_users_company;
DROP INDEX IF EXISTS idx_departments_company;
DROP INDEX IF EXISTS idx_categories_department;
DROP INDEX IF EXISTS idx_modules_category;
DROP INDEX IF EXISTS idx_modules_company;
DROP INDEX IF EXISTS idx_lessons_module;
DROP INDEX IF EXISTS idx_progress_user;
DROP INDEX IF EXISTS idx_progress_lesson;
DROP INDEX IF EXISTS idx_ratings_lesson;
DROP INDEX IF EXISTS idx_groups_company;
DROP INDEX IF EXISTS idx_live_events_company;
DROP INDEX IF EXISTS idx_notifications_user;
DROP INDEX IF EXISTS idx_templates_company;

-- Create indices
CREATE INDEX IF NOT EXISTS idx_users_company_new ON auth.users(company_id);
CREATE INDEX IF NOT EXISTS idx_departments_company_new ON departments(company_id);
CREATE INDEX IF NOT EXISTS idx_categories_department_new ON categories(department_id);
CREATE INDEX IF NOT EXISTS idx_modules_category_new ON modules(category_id);
CREATE INDEX IF NOT EXISTS idx_modules_company_new ON modules(company_id);
CREATE INDEX IF NOT EXISTS idx_lessons_module_new ON lessons(module_id);
CREATE INDEX IF NOT EXISTS idx_progress_user_new ON lesson_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_lesson_new ON lesson_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_ratings_lesson_new ON lesson_ratings(lesson_id);
CREATE INDEX IF NOT EXISTS idx_groups_company_new ON user_groups(company_id);
CREATE INDEX IF NOT EXISTS idx_live_events_company_new ON live_events(company_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_new ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_templates_company_new ON email_templates(company_id);

-- Ensure storage buckets exist
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('videos', 'videos', true),
  ('images', 'images', true)
ON CONFLICT (id) DO NOTHING;

-- Update storage policies
DROP POLICY IF EXISTS "Users can upload videos" ON storage.objects;
DROP POLICY IF EXISTS "Public video access" ON storage.objects;
DROP POLICY IF EXISTS "Admin video deletion" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Public image access" ON storage.objects;
DROP POLICY IF EXISTS "Admin image deletion" ON storage.objects;

-- Create new storage policies
CREATE POLICY "Users can upload videos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'videos');

CREATE POLICY "Public video access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'videos');

CREATE POLICY "Admin video deletion"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'videos' 
  AND EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'role' = 'admin'
  )
);

CREATE POLICY "Users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'images');

CREATE POLICY "Public image access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'images');

CREATE POLICY "Admin image deletion"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'images' 
  AND EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'role' = 'admin'
  )
);

-- Update admin user
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"admin"'
)
WHERE email = 'diegodemontevpj@gmail.com';

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;