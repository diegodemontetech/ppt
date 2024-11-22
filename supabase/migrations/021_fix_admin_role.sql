-- Fix admin role for specific user
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"admin"'
)
WHERE email = 'diegodemontevpj@gmail.com';

-- Create or replace admin check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (
    SELECT EXISTS (
      SELECT 1
      FROM auth.users
      WHERE 
        id = auth.uid() AND
        raw_user_meta_data->>'role' = 'admin'
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update policies for all relevant tables
DO $$ 
BEGIN
  -- Courses
  DROP POLICY IF EXISTS "Admin full access" ON courses;
  CREATE POLICY "Admin full access" ON courses
    FOR ALL
    USING (is_admin());

  DROP POLICY IF EXISTS "Users can view courses" ON courses;
  CREATE POLICY "Users can view courses" ON courses
    FOR SELECT
    USING (auth.role() = 'authenticated');

  -- Lessons
  DROP POLICY IF EXISTS "Admin full access" ON lessons;
  CREATE POLICY "Admin full access" ON lessons
    FOR ALL
    USING (is_admin());

  DROP POLICY IF EXISTS "Users can view lessons" ON lessons;
  CREATE POLICY "Users can view lessons" ON lessons
    FOR SELECT
    USING (auth.role() = 'authenticated');

  -- Quizzes
  DROP POLICY IF EXISTS "Admin full access" ON quizzes;
  CREATE POLICY "Admin full access" ON quizzes
    FOR ALL
    USING (is_admin());

  DROP POLICY IF EXISTS "Users can view quizzes" ON quizzes;
  CREATE POLICY "Users can view quizzes" ON quizzes
    FOR SELECT
    USING (auth.role() = 'authenticated');

  -- Progress
  DROP POLICY IF EXISTS "Users manage their own progress" ON lesson_progress;
  CREATE POLICY "Users manage their own progress" ON lesson_progress
    FOR ALL
    USING (auth.uid() = user_id);
END $$;