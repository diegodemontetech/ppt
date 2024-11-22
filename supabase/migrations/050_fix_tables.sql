-- Fix tables and storage
BEGIN;

-- First drop dependent objects
DROP TRIGGER IF EXISTS update_course_timestamp ON lessons;
DROP FUNCTION IF EXISTS update_course_timestamp();

-- Rename courses to modules and update references
ALTER TABLE lessons 
DROP CONSTRAINT IF EXISTS lessons_course_id_fkey;

ALTER TABLE courses 
RENAME TO modules;

ALTER TABLE lessons
RENAME COLUMN course_id TO module_id;

ALTER TABLE lessons
ADD CONSTRAINT lessons_module_id_fkey 
FOREIGN KEY (module_id) 
REFERENCES modules(id) 
ON DELETE CASCADE;

-- Add video storage columns
ALTER TABLE modules
ADD COLUMN IF NOT EXISTS video_url TEXT,
ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS video_storage_path TEXT;

-- Create function to handle video deletion
CREATE OR REPLACE FUNCTION handle_video_deletion()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete video from storage if exists
  IF OLD.video_storage_path IS NOT NULL THEN
    PERFORM storage.delete('videos', OLD.video_storage_path);
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for video deletion
DROP TRIGGER IF EXISTS delete_video_trigger ON lessons;
CREATE TRIGGER delete_video_trigger
  BEFORE DELETE ON lessons
  FOR EACH ROW
  EXECUTE FUNCTION handle_video_deletion();

-- Create storage bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('videos', 'videos', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies
DROP POLICY IF EXISTS "Users can upload videos" ON storage.objects;
DROP POLICY IF EXISTS "Public video access" ON storage.objects;
DROP POLICY IF EXISTS "Admin video deletion" ON storage.objects;

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

COMMIT;