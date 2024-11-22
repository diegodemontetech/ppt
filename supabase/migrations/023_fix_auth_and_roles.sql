-- Fix user roles and permissions
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

  -- Update RLS policies
  ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
  ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
  ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
  ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;

  -- Courses policies
  DROP POLICY IF EXISTS "Admin full access courses" ON courses;
  CREATE POLICY "Admin full access courses" ON courses
    FOR ALL
    USING (is_admin());

  DROP POLICY IF EXISTS "Users view courses" ON courses;
  CREATE POLICY "Users view courses" ON courses
    FOR SELECT
    USING (auth.role() = 'authenticated');

  -- Lessons policies
  DROP POLICY IF EXISTS "Admin full access lessons" ON lessons;
  CREATE POLICY "Admin full access lessons" ON lessons
    FOR ALL
    USING (is_admin());

  DROP POLICY IF EXISTS "Users view lessons" ON lessons;
  CREATE POLICY "Users view lessons" ON lessons
    FOR SELECT
    USING (auth.role() = 'authenticated');

  -- Quizzes policies
  DROP POLICY IF EXISTS "Admin full access quizzes" ON quizzes;
  CREATE POLICY "Admin full access quizzes" ON quizzes
    FOR ALL
    USING (is_admin());

  DROP POLICY IF EXISTS "Users view quizzes" ON quizzes;
  CREATE POLICY "Users view quizzes" ON quizzes
    FOR SELECT
    USING (auth.role() = 'authenticated');

  -- Progress policies
  DROP POLICY IF EXISTS "Users manage progress" ON lesson_progress;
  CREATE POLICY "Users manage progress" ON lesson_progress
    FOR ALL
    USING (auth.uid() = user_id OR is_admin());

  -- Create trigger to update user role
  CREATE OR REPLACE FUNCTION sync_user_role()
  RETURNS TRIGGER AS $$
  BEGIN
    NEW.raw_user_meta_data = jsonb_set(
      COALESCE(NEW.raw_user_meta_data, '{}'::jsonb),
      '{role}',
      COALESCE(NEW.raw_user_meta_data->'role', '"user"'::jsonb)
    );
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql;

  DROP TRIGGER IF EXISTS sync_user_role_trigger ON auth.users;
  CREATE TRIGGER sync_user_role_trigger
    BEFORE INSERT OR UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION sync_user_role();
END $$;