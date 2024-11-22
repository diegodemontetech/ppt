-- Fix courses table schema
BEGIN;

-- Add missing columns to courses table
ALTER TABLE courses 
ADD COLUMN IF NOT EXISTS thumbnail_url TEXT,
ADD COLUMN IF NOT EXISTS video_url TEXT,
ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;

-- Create index for video and thumbnail URLs
CREATE INDEX IF NOT EXISTS idx_courses_video_url ON courses(video_url);
CREATE INDEX IF NOT EXISTS idx_courses_thumbnail_url ON courses(thumbnail_url);

-- Add trigger to clean up storage when course is deleted
CREATE OR REPLACE FUNCTION handle_course_deletion()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete video from storage if exists
  IF OLD.video_url IS NOT NULL THEN
    PERFORM storage.delete('videos', OLD.video_url);
  END IF;
  -- Delete thumbnail from storage if exists
  IF OLD.thumbnail_url IS NOT NULL THEN
    PERFORM storage.delete('images', OLD.thumbnail_url);
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for course deletion
DROP TRIGGER IF EXISTS delete_course_files_trigger ON courses;
CREATE TRIGGER delete_course_files_trigger
  BEFORE DELETE ON courses
  FOR EACH ROW
  EXECUTE FUNCTION handle_course_deletion();

-- Ensure storage buckets exist
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('videos', 'videos', true),
  ('images', 'images', true)
ON CONFLICT (id) DO NOTHING;

-- Update storage policies
DROP POLICY IF EXISTS "Users can upload videos" ON storage.objects;
DROP POLICY IF EXISTS "Public video access" ON storage.objects;
DROP POLICY IF EXISTS "Admin video deletion" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Public image access" ON storage.objects;
DROP POLICY IF EXISTS "Admin image deletion" ON storage.objects;

-- Create new storage policies
CREATE POLICY "Users can upload videos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'videos');

CREATE POLICY "Public video access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'videos');

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

CREATE POLICY "Users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'images');

CREATE POLICY "Public image access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'images');

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

COMMIT;