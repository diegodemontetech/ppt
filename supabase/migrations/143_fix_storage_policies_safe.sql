-- Fix storage policies with safe checks
BEGIN;

-- Drop existing policies first to avoid conflicts
DO $$ 
BEGIN
    -- Drop attachment policies if they exist
    DROP POLICY IF EXISTS "Users can upload attachments" ON storage.objects;
    DROP POLICY IF EXISTS "Public attachment access" ON storage.objects;
    DROP POLICY IF EXISTS "Admin attachment deletion" ON storage.objects;
    
    -- Create storage bucket if not exists
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('attachments', 'attachments', true)
    ON CONFLICT (id) DO NOTHING;

    -- Create new policies
    CREATE POLICY "Users can upload attachments"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'attachments');

    CREATE POLICY "Public attachment access"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'attachments');

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
END $$;

-- Create function to handle file deletion
CREATE OR REPLACE FUNCTION handle_attachment_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete file from storage if exists
    IF OLD.file_url IS NOT NULL THEN
        PERFORM storage.delete('attachments', split_part(OLD.file_url, '/', -1));
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for file cleanup
DROP TRIGGER IF EXISTS delete_attachment_trigger ON lesson_attachments;
CREATE TRIGGER delete_attachment_trigger
    BEFORE DELETE ON lesson_attachments
    FOR EACH ROW
    EXECUTE FUNCTION handle_attachment_deletion();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;