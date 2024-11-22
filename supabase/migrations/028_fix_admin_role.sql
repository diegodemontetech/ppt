-- Reset and fix admin role
DO $$ 
BEGIN
  -- First, ensure the role exists in user_metadata
  UPDATE auth.users
  SET raw_user_meta_data = 
    CASE 
      WHEN email = 'diegodemontevpj@gmail.com' THEN 
        jsonb_set(
          COALESCE(raw_user_meta_data, '{}'::jsonb),
          '{role}',
          '"admin"'
        )
      ELSE 
        jsonb_set(
          COALESCE(raw_user_meta_data, '{}'::jsonb),
          '{role}',
          '"user"'
        )
    END;

  -- Create admin check function
  CREATE OR REPLACE FUNCTION is_admin()
  RETURNS BOOLEAN AS $$
  DECLARE
    is_admin BOOLEAN;
  BEGIN
    SELECT EXISTS (
      SELECT 1
      FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'admin'
    ) INTO is_admin;
    
    RETURN is_admin;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  -- Create admin policies
  DROP POLICY IF EXISTS "Admin access" ON courses;
  CREATE POLICY "Admin access" ON courses
    FOR ALL
    USING (is_admin() OR auth.role() = 'authenticated');

  DROP POLICY IF EXISTS "Admin manage courses" ON courses;
  CREATE POLICY "Admin manage courses" ON courses
    FOR INSERT UPDATE DELETE
    USING (is_admin());

  -- Same for lessons
  DROP POLICY IF EXISTS "Admin access" ON lessons;
  CREATE POLICY "Admin access" ON lessons
    FOR ALL
    USING (is_admin() OR auth.role() = 'authenticated');

  DROP POLICY IF EXISTS "Admin manage lessons" ON lessons;
  CREATE POLICY "Admin manage lessons" ON lessons
    FOR INSERT UPDATE DELETE
    USING (is_admin());

  -- Enable RLS
  ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
  ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
  ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
  ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;

  -- Create policies for quizzes
  DROP POLICY IF EXISTS "Admin access" ON quizzes;
  CREATE POLICY "Admin access" ON quizzes
    FOR ALL
    USING (is_admin() OR auth.role() = 'authenticated');

  DROP POLICY IF EXISTS "Admin manage quizzes" ON quizzes;
  CREATE POLICY "Admin manage quizzes" ON quizzes
    FOR INSERT UPDATE DELETE
    USING (is_admin());

  -- Create policies for lesson progress
  DROP POLICY IF EXISTS "Users manage own progress" ON lesson_progress;
  CREATE POLICY "Users manage own progress" ON lesson_progress
    FOR ALL
    USING (auth.uid() = user_id OR is_admin());

END $$;