-- Add thumbnail_url to modules table
BEGIN;

-- Add thumbnail_url column to modules table
ALTER TABLE modules
ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_modules_thumbnail ON modules(thumbnail_url);

-- Create function to handle thumbnail cleanup
CREATE OR REPLACE FUNCTION handle_module_thumbnail_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete thumbnail from storage if exists
    IF OLD.thumbnail_url IS NOT NULL THEN
        PERFORM storage.delete('images', split_part(OLD.thumbnail_url, '/', -1));
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for thumbnail cleanup
DROP TRIGGER IF EXISTS delete_module_thumbnail_trigger ON modules;
CREATE TRIGGER delete_module_thumbnail_trigger
    BEFORE DELETE ON modules
    FOR EACH ROW
    EXECUTE FUNCTION handle_module_thumbnail_deletion();

-- Create storage policies for images if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'objects' 
        AND policyname = 'Users can upload images'
    ) THEN
        CREATE POLICY "Users can upload images"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'images');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'objects' 
        AND policyname = 'Public image access'
    ) THEN
        CREATE POLICY "Public image access"
        ON storage.objects FOR SELECT
        TO public
        USING (bucket_id = 'images');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'objects' 
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
END $$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;