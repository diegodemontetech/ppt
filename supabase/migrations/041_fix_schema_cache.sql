-- Fix schema cache and course columns
BEGIN;

-- First, refresh the schema cache
NOTIFY pgrst, 'reload schema';

-- Ensure courses table has all required columns
ALTER TABLE courses 
ADD COLUMN IF NOT EXISTS thumbnail_url TEXT,
ADD COLUMN IF NOT EXISTS video_url TEXT,
ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES categories(id),
ADD COLUMN IF NOT EXISTS total_duration INTEGER DEFAULT 0;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_courses_video_url ON courses(video_url);
CREATE INDEX IF NOT EXISTS idx_courses_thumbnail_url ON courses(thumbnail_url);
CREATE INDEX IF NOT EXISTS idx_courses_category ON courses(category_id);

-- Update RLS policies to include new columns
DROP POLICY IF EXISTS "Admin full access" ON courses;
CREATE POLICY "Admin full access"
  ON courses FOR ALL
  USING (is_admin());

DROP POLICY IF EXISTS "Users view courses" ON courses;
CREATE POLICY "Users view courses"
  ON courses FOR SELECT
  USING (auth.role() = 'authenticated');

-- Function to handle file cleanup
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

-- Refresh materialized views if they exist
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM pg_matviews WHERE matviewname = 'courses_with_stats'
  ) THEN
    REFRESH MATERIALIZED VIEW courses_with_stats;
  END IF;
END $$;

COMMIT;