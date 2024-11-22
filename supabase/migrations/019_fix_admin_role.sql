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
END $$;