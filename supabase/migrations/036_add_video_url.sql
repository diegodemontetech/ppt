-- Add video_url column to courses table
ALTER TABLE courses
ADD COLUMN IF NOT EXISTS video_url TEXT;

-- Update existing policies to include new column
DROP POLICY IF EXISTS "Admin full access" ON courses;
CREATE POLICY "Admin full access"
  ON courses FOR ALL
  USING (is_admin());

DROP POLICY IF EXISTS "Users view courses" ON courses;
CREATE POLICY "Users view courses"
  ON courses FOR SELECT
  USING (auth.role() = 'authenticated');

-- Create index for video_url
CREATE INDEX IF NOT EXISTS idx_courses_video_url ON courses(video_url);

-- Add trigger to clean up storage when course is deleted
CREATE OR REPLACE FUNCTION handle_course_deletion()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete video from storage if exists
  IF OLD.video_url IS NOT NULL THEN
    -- Extract filename from URL
    PERFORM storage.delete('videos', split_part(OLD.video_url, '/', -1));
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for course deletion
DROP TRIGGER IF EXISTS delete_course_video_trigger ON courses;
CREATE TRIGGER delete_course_video_trigger
  BEFORE DELETE ON courses
  FOR EACH ROW
  EXECUTE FUNCTION handle_course_deletion();