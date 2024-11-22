-- First, enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Update lesson_progress table
ALTER TABLE lesson_progress
  ALTER COLUMN user_id TYPE UUID USING user_id::UUID,
  ALTER COLUMN lesson_id TYPE UUID USING lesson_id::UUID,
  ALTER COLUMN completed SET DEFAULT FALSE,
  ALTER COLUMN score TYPE NUMERIC(4,2);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_lesson_progress_user_id ON lesson_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_lesson_progress_lesson_id ON lesson_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_lessons_course_id ON lessons(course_id);

-- Update foreign key constraints
ALTER TABLE lesson_progress
  DROP CONSTRAINT IF EXISTS lesson_progress_user_id_fkey,
  DROP CONSTRAINT IF EXISTS lesson_progress_lesson_id_fkey,
  ADD CONSTRAINT lesson_progress_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE,
  ADD CONSTRAINT lesson_progress_lesson_id_fkey 
    FOREIGN KEY (lesson_id) 
    REFERENCES lessons(id) 
    ON DELETE CASCADE;

-- Ensure RLS policies are correctly set
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;

-- Update or create RLS policies
DROP POLICY IF EXISTS "Users can view their own progress" ON lesson_progress;
DROP POLICY IF EXISTS "Users can insert their own progress" ON lesson_progress;
DROP POLICY IF EXISTS "Users can update their own progress" ON lesson_progress;

CREATE POLICY "Users can view their own progress" 
  ON lesson_progress FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress" 
  ON lesson_progress FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress" 
  ON lesson_progress FOR UPDATE 
  USING (auth.uid() = user_id);