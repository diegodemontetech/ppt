-- Fix lesson ratings schema
BEGIN;

-- Add updated_at column to lesson_ratings
ALTER TABLE lesson_ratings
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- Create trigger to automatically update updated_at
CREATE OR REPLACE FUNCTION update_lesson_rating_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for lesson_ratings
DROP TRIGGER IF EXISTS update_lesson_rating_timestamp ON lesson_ratings;
CREATE TRIGGER update_lesson_rating_timestamp
  BEFORE UPDATE ON lesson_ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_lesson_rating_timestamp();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

-- Update RLS policies
DROP POLICY IF EXISTS "Users can rate lessons" ON lesson_ratings;
CREATE POLICY "Users can rate lessons"
  ON lesson_ratings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their ratings" ON lesson_ratings;
CREATE POLICY "Users can update their ratings"
  ON lesson_ratings FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Anyone can view ratings" ON lesson_ratings;
CREATE POLICY "Anyone can view ratings"
  ON lesson_ratings FOR SELECT
  USING (true);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_lesson_ratings_user_lesson 
ON lesson_ratings(user_id, lesson_id);

COMMIT;