-- Fix storage policies with complete safe checks
BEGIN;

-- Function to check if a policy exists
CREATE OR REPLACE FUNCTION policy_exists(
    policy_name TEXT,
    table_name TEXT,
    schema_name TEXT DEFAULT 'storage'
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = schema_name
        AND tablename = table_name
        AND policyname = policy_name
    );
END;
$$ LANGUAGE plpgsql;

-- Function to check if a bucket exists
CREATE OR REPLACE FUNCTION bucket_exists(bucket_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM storage.buckets WHERE id = bucket_name
    );
END;
$$ LANGUAGE plpgsql;

-- Function to safely create a bucket
CREATE OR REPLACE FUNCTION create_storage_bucket(
    bucket_name TEXT,
    is_public BOOLEAN DEFAULT true
) RETURNS void AS $$
BEGIN
    IF NOT bucket_exists(bucket_name) THEN
        INSERT INTO storage.buckets (id, name, public)
        VALUES (bucket_name, bucket_name, is_public);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to safely create a policy
CREATE OR REPLACE FUNCTION create_storage_policy(
    policy_name TEXT,
    policy_operation TEXT,
    policy_role TEXT,
    policy_check TEXT,
    bucket_name TEXT
) RETURNS void AS $$
BEGIN
    IF NOT policy_exists(policy_name, 'objects') THEN
        EXECUTE format(
            'CREATE POLICY %I ON storage.objects FOR %s TO %s WITH CHECK (%s)',
            policy_name,
            policy_operation,
            policy_role,
            policy_check
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create all required storage buckets
DO $$ 
BEGIN
    -- Videos bucket
    PERFORM create_storage_bucket('videos');
    
    -- Images bucket
    PERFORM create_storage_bucket('images');
    
    -- PDFs bucket
    PERFORM create_storage_bucket('pdfs');
    
    -- Attachments bucket
    PERFORM create_storage_bucket('attachments');
END $$;

-- Create all storage policies
DO $$ 
BEGIN
    -- Videos policies
    IF NOT policy_exists('Users can upload videos', 'objects') THEN
        CREATE POLICY "Users can upload videos"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'videos');
    END IF;

    IF NOT policy_exists('Public video access', 'objects') THEN
        CREATE POLICY "Public video access"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'videos');
    END IF;

    IF NOT policy_exists('Admin video deletion', 'objects') THEN
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
    IF NOT policy_exists('Users can upload images', 'objects') THEN
        CREATE POLICY "Users can upload images"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'images');
    END IF;

    IF NOT policy_exists('Public image access', 'objects') THEN
        CREATE POLICY "Public image access"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'images');
    END IF;

    IF NOT policy_exists('Admin image deletion', 'objects') THEN
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
    IF NOT policy_exists('Users can upload pdfs', 'objects') THEN
        CREATE POLICY "Users can upload pdfs"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'pdfs');
    END IF;

    IF NOT policy_exists('Public pdf access', 'objects') THEN
        CREATE POLICY "Public pdf access"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'pdfs');
    END IF;

    IF NOT policy_exists('Admin pdf deletion', 'objects') THEN
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
    IF NOT policy_exists('Users can upload attachments', 'objects') THEN
        CREATE POLICY "Users can upload attachments"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'attachments');
    END IF;

    IF NOT policy_exists('Public attachment access', 'objects') THEN
        CREATE POLICY "Public attachment access"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'attachments');
    END IF;

    IF NOT policy_exists('Admin attachment deletion', 'objects') THEN
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

-- Create function to handle file deletion
CREATE OR REPLACE FUNCTION handle_storage_file_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete file from storage if exists
    IF OLD.file_url IS NOT NULL THEN
        -- Extract bucket and filename from URL
        DECLARE
            bucket_name TEXT;
            file_name TEXT;
        BEGIN
            -- Simple URL parsing - adjust if your URLs have a different format
            bucket_name := split_part(OLD.file_url, '/', 4);
            file_name := split_part(OLD.file_url, '/', 5);
            
            IF bucket_name IS NOT NULL AND file_name IS NOT NULL THEN
                PERFORM storage.delete(bucket_name, file_name);
            END IF;
        END;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers for file cleanup
DO $$ 
BEGIN
    -- For lesson attachments
    DROP TRIGGER IF EXISTS delete_attachment_file_trigger ON lesson_attachments;
    CREATE TRIGGER delete_attachment_file_trigger
        BEFORE DELETE ON lesson_attachments
        FOR EACH ROW
        EXECUTE FUNCTION handle_storage_file_deletion();
END $$;

-- Drop helper functions
DROP FUNCTION policy_exists;
DROP FUNCTION bucket_exists;
DROP FUNCTION create_storage_bucket;
DROP FUNCTION create_storage_policy;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;