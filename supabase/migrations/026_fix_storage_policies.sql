-- Fix storage policies for videos
BEGIN;

-- Ensure bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('videos', 'videos', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated users can upload videos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view videos" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete videos" ON storage.objects;

-- Create new policies
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
  AND (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'admin'
    )
  )
);

-- Update lessons table
ALTER TABLE lessons 
ADD COLUMN IF NOT EXISTS video_storage_path TEXT;

-- Add function to handle video deletion
CREATE OR REPLACE FUNCTION handle_video_deletion()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.video_storage_path IS NOT NULL THEN
    -- Delete video from storage
    PERFORM storage.delete('videos', OLD.video_storage_path);
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for video deletion
DROP TRIGGER IF EXISTS delete_video_trigger ON lessons;
CREATE TRIGGER delete_video_trigger
  BEFORE DELETE ON lessons
  FOR EACH ROW
  EXECUTE FUNCTION handle_video_deletion();

COMMIT;