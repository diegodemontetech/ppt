-- Create PDFs storage bucket
BEGIN;

-- Create PDFs bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('pdfs', 'pdfs', true)
ON CONFLICT (id) DO NOTHING;

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

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;