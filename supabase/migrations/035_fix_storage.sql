-- Configure storage bucket and policies
DO $$ 
DECLARE
  bucket_exists BOOLEAN;
BEGIN
  -- Check if videos bucket exists
  SELECT EXISTS (
    SELECT 1 FROM storage.buckets WHERE id = 'videos'
  ) INTO bucket_exists;

  -- Create videos bucket if it doesn't exist
  IF NOT bucket_exists THEN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('videos', 'videos', true);
  END IF;

  -- Drop existing storage policies
  DROP POLICY IF EXISTS "Authenticated users can upload videos" ON storage.objects;
  DROP POLICY IF EXISTS "Anyone can view videos" ON storage.objects;
  DROP POLICY IF EXISTS "Admins can delete videos" ON storage.objects;

  -- Create new storage policies
  CREATE POLICY "Authenticated users can upload videos"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'videos');

  CREATE POLICY "Anyone can view videos"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'videos');

  CREATE POLICY "Admins can delete videos"
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

END $$;