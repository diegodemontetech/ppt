-- Fix PDF storage and policies
BEGIN;

-- Create PDFs bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('pdfs', 'pdfs', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies
DROP POLICY IF EXISTS "Users can upload pdfs" ON storage.objects;
DROP POLICY IF EXISTS "Public pdf access" ON storage.objects;
DROP POLICY IF EXISTS "Admin pdf deletion" ON storage.objects;

-- Create storage policies for PDFs
CREATE POLICY "Users can upload pdfs"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'pdfs');

CREATE POLICY "Public pdf access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'pdfs');

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

-- Create function to handle ebook deletion
CREATE OR REPLACE FUNCTION handle_ebook_deletion()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete PDF from storage if exists
  IF OLD.pdf_url IS NOT NULL THEN
    PERFORM storage.delete('pdfs', split_part(OLD.pdf_url, '/', -1));
  END IF;
  -- Delete cover from storage if exists
  IF OLD.cover_url IS NOT NULL THEN
    PERFORM storage.delete('images', split_part(OLD.cover_url, '/', -1));
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for ebook deletion
DROP TRIGGER IF EXISTS delete_ebook_files_trigger ON ebooks;
CREATE TRIGGER delete_ebook_files_trigger
  BEFORE DELETE ON ebooks
  FOR EACH ROW
  EXECUTE FUNCTION handle_ebook_deletion();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;