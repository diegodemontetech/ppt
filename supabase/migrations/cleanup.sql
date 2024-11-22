-- Clean up and consolidate migrations
BEGIN;

-- Drop obsolete tables and functions
DROP TABLE IF EXISTS course_ratings CASCADE;
DROP TABLE IF EXISTS ebook_ratings CASCADE;
DROP TABLE IF EXISTS lesson_progress CASCADE;
DROP TABLE IF EXISTS lesson_ratings CASCADE;
DROP TABLE IF EXISTS quizzes CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS modules CASCADE;
DROP TABLE IF EXISTS ebooks CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
DROP TABLE IF EXISTS marketing_box_items CASCADE;
DROP TABLE IF EXISTS marketing_box_categories CASCADE;
DROP TABLE IF EXISTS contracts CASCADE;
DROP TABLE IF EXISTS contract_signatories CASCADE;
DROP TABLE IF EXISTS live_events CASCADE;
DROP TABLE IF EXISTS live_recordings CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS user_group_members CASCADE;
DROP TABLE IF EXISTS user_groups CASCADE;
DROP TABLE IF EXISTS companies CASCADE;
DROP TABLE IF EXISTS workflow_settings CASCADE;
DROP TABLE IF EXISTS email_templates CASCADE;

-- Drop obsolete functions
DROP FUNCTION IF EXISTS update_course_timestamp() CASCADE;
DROP FUNCTION IF EXISTS trigger_update_course_timestamp() CASCADE;
DROP FUNCTION IF EXISTS sync_user_data() CASCADE;
DROP FUNCTION IF EXISTS sync_user_role() CASCADE;
DROP FUNCTION IF EXISTS sync_pipeline_roles() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS handle_video_deletion() CASCADE;
DROP FUNCTION IF EXISTS handle_ebook_deletion() CASCADE;
DROP FUNCTION IF EXISTS handle_contract_deletion() CASCADE;
DROP FUNCTION IF EXISTS handle_attachment_deletion() CASCADE;

-- Drop obsolete triggers
DROP TRIGGER IF EXISTS update_course_timestamp ON lessons;
DROP TRIGGER IF EXISTS sync_user_role_trigger ON auth.users;
DROP TRIGGER IF EXISTS sync_pipeline_roles_trigger ON auth.users;
DROP TRIGGER IF EXISTS delete_video_trigger ON lessons;
DROP TRIGGER IF EXISTS delete_ebook_files_trigger ON ebooks;
DROP TRIGGER IF EXISTS delete_contract_files_trigger ON contracts;
DROP TRIGGER IF EXISTS delete_attachment_trigger ON lesson_attachments;

-- Drop obsolete storage buckets
DELETE FROM storage.buckets WHERE id IN (
    'videos',
    'images',
    'pdfs',
    'attachments',
    'signatures',
    'support-attachments',
    'marketingbox',
    'documents'
);

-- Drop obsolete storage policies
DROP POLICY IF EXISTS "Users can upload videos" ON storage.objects;
DROP POLICY IF EXISTS "Public video access" ON storage.objects;
DROP POLICY IF EXISTS "Admin video deletion" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Public image access" ON storage.objects;
DROP POLICY IF EXISTS "Admin image deletion" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload pdfs" ON storage.objects;
DROP POLICY IF EXISTS "Public pdf access" ON storage.objects;
DROP POLICY IF EXISTS "Admin pdf deletion" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload attachments" ON storage.objects;
DROP POLICY IF EXISTS "Public attachment access" ON storage.objects;
DROP POLICY IF EXISTS "Admin attachment deletion" ON storage.objects;

-- Create necessary storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('videos', 'videos', true),
    ('images', 'images', true),
    ('pdfs', 'pdfs', true),
    ('attachments', 'attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies
DO $$ 
BEGIN
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

    -- Repeat for other buckets...
EXCEPTION 
    WHEN duplicate_object THEN NULL;
END $$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;