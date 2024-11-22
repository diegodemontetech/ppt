-- Fix storage policies with safe checks
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

-- Ensure storage bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('attachments', 'attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Safely create storage policies
DO $$ 
BEGIN
    -- Upload policy
    IF NOT policy_exists('Users can upload attachments', 'objects') THEN
        CREATE POLICY "Users can upload attachments"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'attachments');
    END IF;

    -- View policy
    IF NOT policy_exists('Public attachment access', 'objects') THEN
        CREATE POLICY "Public attachment access"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'attachments');
    END IF;

    -- Delete policy
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

-- Drop helper function as it's no longer needed
DROP FUNCTION policy_exists;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;