-- Fix admin role and policies in correct order
DO $$ 
BEGIN
  -- First drop all dependent policies
  DROP POLICY IF EXISTS "Admin manage courses" ON courses;
  DROP POLICY IF EXISTS "Users view courses" ON courses;
  DROP POLICY IF EXISTS "Admin manage lessons" ON lessons;
  DROP POLICY IF EXISTS "Users view lessons" ON lessons;
  DROP POLICY IF EXISTS "Admin manage users" ON auth.users;
  DROP POLICY IF EXISTS "Admin full access" ON courses;
  DROP POLICY IF EXISTS "Admin full access" ON lessons;
  DROP POLICY IF EXISTS "Admin full access" ON quizzes;
  DROP POLICY IF EXISTS "Users manage progress" ON lesson_progress;

  -- Now we can safely drop and recreate the is_admin function
  DROP FUNCTION IF EXISTS is_admin();
  CREATE OR REPLACE FUNCTION is_admin()
  RETURNS BOOLEAN
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
  AS $func$
    BEGIN
      RETURN EXISTS (
        SELECT 1
        FROM auth.users
        WHERE id = auth.uid()
        AND raw_user_meta_data->>'role' = 'admin'
      );
    END;
  $func$;

  -- Update admin user
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"admin"'
  )
  WHERE email = 'diegodemontevpj@gmail.com';

  -- Enable RLS
  ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
  ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
  ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
  ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;

  -- Recreate policies
  CREATE POLICY "Admin full access"
    ON courses FOR ALL
    USING (is_admin());

  CREATE POLICY "Users view courses"
    ON courses FOR SELECT
    USING (auth.role() = 'authenticated');

  CREATE POLICY "Admin full access"
    ON lessons FOR ALL
    USING (is_admin());

  CREATE POLICY "Users view lessons"
    ON lessons FOR SELECT
    USING (auth.role() = 'authenticated');

  CREATE POLICY "Admin full access"
    ON quizzes FOR ALL
    USING (is_admin());

  CREATE POLICY "Users view quizzes"
    ON quizzes FOR SELECT
    USING (auth.role() = 'authenticated');

  CREATE POLICY "Users manage progress"
    ON lesson_progress FOR ALL
    USING (auth.uid() = user_id OR is_admin());

  -- Create policy for auth.users
  CREATE POLICY "Admin manage users"
    ON auth.users
    FOR ALL
    USING (is_admin());

END $$;