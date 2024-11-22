-- Fix admin permissions and role
DO $$ 
BEGIN
  -- Update specific user to admin
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"admin"'
  )
  WHERE email = 'diegodemontevpj@gmail.com';

  -- Ensure RLS is enabled
  ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
  ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
  ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
  ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;

  -- Create admin check function
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

  -- Update policies
  DROP POLICY IF EXISTS "Admin full access" ON courses;
  CREATE POLICY "Admin full access" ON courses
    FOR ALL
    USING (is_admin());

  DROP POLICY IF EXISTS "Admin full access" ON lessons;
  CREATE POLICY "Admin full access" ON lessons
    FOR ALL
    USING (is_admin());

  DROP POLICY IF EXISTS "Admin full access" ON quizzes;
  CREATE POLICY "Admin full access" ON quizzes
    FOR ALL
    USING (is_admin());

  -- Allow regular users to view content
  DROP POLICY IF EXISTS "Users can view courses" ON courses;
  CREATE POLICY "Users can view courses" ON courses
    FOR SELECT
    USING (auth.role() = 'authenticated');

  DROP POLICY IF EXISTS "Users can view lessons" ON lessons;
  CREATE POLICY "Users can view lessons" ON lessons
    FOR SELECT
    USING (auth.role() = 'authenticated');

  DROP POLICY IF EXISTS "Users can view quizzes" ON quizzes;
  CREATE POLICY "Users can view quizzes" ON quizzes
    FOR SELECT
    USING (auth.role() = 'authenticated');
END $$;