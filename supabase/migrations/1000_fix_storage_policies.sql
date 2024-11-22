-- Fix storage policies by safely dropping and recreating them
BEGIN;

-- First drop all existing storage policies
DO $$ 
BEGIN
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
EXCEPTION 
    WHEN undefined_object THEN 
        NULL;
END $$;

-- Create storage buckets if they don't exist
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('videos', 'videos', true),
    ('images', 'images', true),
    ('pdfs', 'pdfs', true),
    ('attachments', 'attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Create new storage policies with safe checks
DO $$ 
BEGIN
    -- Videos policies
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Users can upload videos'
    ) THEN
        CREATE POLICY "Users can upload videos"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'videos');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Public video access'
    ) THEN
        CREATE POLICY "Public video access"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'videos');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Admin video deletion'
    ) THEN
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
    END IF;

    -- Images policies
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Users can upload images'
    ) THEN
        CREATE POLICY "Users can upload images"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'images');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Public image access'
    ) THEN
        CREATE POLICY "Public image access"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'images');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Admin image deletion'
    ) THEN
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
    END IF;

    -- PDFs policies
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Users can upload pdfs'
    ) THEN
        CREATE POLICY "Users can upload pdfs"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'pdfs');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Public pdf access'
    ) THEN
        CREATE POLICY "Public pdf access"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'pdfs');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Admin pdf deletion'
    ) THEN
        CREATE POLICY "Admin pdf deletion"
        ON storage.objects FOR DELETE
        TO authenticated
        USING (
            bucket_id = 'pdfs' 
            AND EXISTS (
                SELECT 1 
                FROM auth.users 
                WHERE id = auth.uid() 
                AND raw_user_meta_data->>'role' = 'admin'
            )
        );
    END IF;

    -- Attachments policies
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Users can upload attachments'
    ) THEN
        CREATE POLICY "Users can upload attachments"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'attachments');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Public attachment access'
    ) THEN
        CREATE POLICY "Public attachment access"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'attachments');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Admin attachment deletion'
    ) THEN
        CREATE POLICY "Admin attachment deletion"
        ON storage.objects FOR DELETE
        TO authenticated
        USING (
            bucket_id = 'attachments' 
            AND EXISTS (
                SELECT 1 
                FROM auth.users 
                WHERE id = auth.uid() 
                AND raw_user_meta_data->>'role' = 'admin'
            )
        );
    END IF;
END $$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;