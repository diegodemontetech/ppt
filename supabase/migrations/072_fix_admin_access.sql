-- Fix admin access for specific user
BEGIN;

-- Update admin user
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"admin"'
)
WHERE email = 'diegodemontevpj@gmail.com';

-- Create or replace admin check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' = 'admin'
  );
END;
$$;

-- Update RLS policies to use is_admin() function
DO $$
BEGIN
  -- Modules
  DROP POLICY IF EXISTS "Admin can manage modules" ON modules;
  CREATE POLICY "Admin can manage modules"
    ON modules FOR ALL
    USING (is_admin());

  -- Lessons
  DROP POLICY IF EXISTS "Admin can manage lessons" ON lessons;
  CREATE POLICY "Admin can manage lessons"
    ON lessons FOR ALL
    USING (is_admin());

  -- Live Events
  DROP POLICY IF EXISTS "Admin can manage live events" ON live_events;
  CREATE POLICY "Admin can manage live events"
    ON live_events FOR ALL
    USING (is_admin());

  -- Categories
  DROP POLICY IF EXISTS "Admin can manage categories" ON categories;
  CREATE POLICY "Admin can manage categories"
    ON categories FOR ALL
    USING (is_admin());

  -- Departments
  DROP POLICY IF EXISTS "Admin can manage departments" ON departments;
  CREATE POLICY "Admin can manage departments"
    ON departments FOR ALL
    USING (is_admin());

  -- Quizzes
  DROP POLICY IF EXISTS "Admin can manage quizzes" ON quizzes;
  CREATE POLICY "Admin can manage quizzes"
    ON quizzes FOR ALL
    USING (is_admin());
END $$;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;