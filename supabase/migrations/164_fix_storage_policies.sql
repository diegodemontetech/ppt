-- Fix storage policies conflict
BEGIN;

-- Drop existing policies if they exist
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can upload documents" ON storage.objects;
    DROP POLICY IF EXISTS "Public document access" ON storage.objects;
    DROP POLICY IF EXISTS "Admin document deletion" ON storage.objects;
EXCEPTION 
    WHEN undefined_object THEN 
        NULL;
END $$;

-- Create storage policies with IF NOT EXISTS check
DO $$ 
BEGIN
    -- Check if policy exists before creating
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Users can upload documents'
    ) THEN
        CREATE POLICY "Users can upload documents"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'documents');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Public document access'
    ) THEN
        CREATE POLICY "Public document access"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'documents');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname = 'Admin document deletion'
    ) THEN
        CREATE POLICY "Admin document deletion"
        ON storage.objects FOR DELETE
        TO authenticated
        USING (
            bucket_id = 'documents' 
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