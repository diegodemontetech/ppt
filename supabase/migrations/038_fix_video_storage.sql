-- Fix video storage and URLs
BEGIN;

-- Ensure videos bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('videos', 'videos', true)
ON CONFLICT (id) DO NOTHING;

-- Update lessons table to use storage path
ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS video_storage_path TEXT;

-- Create policies for videos bucket
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

-- Add trigger to clean up storage when lesson is deleted
CREATE OR REPLACE FUNCTION handle_lesson_deletion()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete video from storage if exists
  IF OLD.video_url IS NOT NULL THEN
    PERFORM storage.delete('videos', OLD.video_url);
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for lesson deletion
DROP TRIGGER IF EXISTS delete_lesson_video_trigger ON lessons;
CREATE TRIGGER delete_lesson_video_trigger
  BEFORE DELETE ON lessons
  FOR EACH ROW
  EXECUTE FUNCTION handle_lesson_deletion();

COMMIT;