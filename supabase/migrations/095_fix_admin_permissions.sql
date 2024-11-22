-- Fix admin permissions and RLS policies
BEGIN;

-- First ensure admin user exists with correct role
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
    AND raw_user_meta_data->>'role' IN ('admin', 'master_admin')
  );
END;
$$;

-- Drop existing policies
DROP POLICY IF EXISTS "Admin can manage departments" ON departments;
DROP POLICY IF EXISTS "Users can view departments" ON departments;
DROP POLICY IF EXISTS "Admin can manage categories" ON categories;
DROP POLICY IF EXISTS "Users can view categories" ON categories;
DROP POLICY IF EXISTS "Admin can manage modules" ON modules;
DROP POLICY IF EXISTS "Users can view modules" ON modules;
DROP POLICY IF EXISTS "Admin can manage lessons" ON lessons;
DROP POLICY IF EXISTS "Users can view lessons" ON lessons;

-- Create new policies with simpler conditions
CREATE POLICY "Admin can manage departments"
ON departments FOR ALL
USING (is_admin());

CREATE POLICY "Users can view departments"
ON departments FOR SELECT
USING (true);

CREATE POLICY "Admin can manage categories"
ON categories FOR ALL
USING (is_admin());

CREATE POLICY "Users can view categories"
ON categories FOR SELECT
USING (true);

CREATE POLICY "Admin can manage modules"
ON modules FOR ALL
USING (is_admin());

CREATE POLICY "Users can view modules"
ON modules FOR SELECT
USING (true);

CREATE POLICY "Admin can manage lessons"
ON lessons FOR ALL
USING (is_admin());

CREATE POLICY "Users can view lessons"
ON lessons FOR SELECT
USING (true);

-- Create policy for quizzes
CREATE POLICY "Admin can manage quizzes"
ON quizzes FOR ALL
USING (is_admin());

CREATE POLICY "Users can view quizzes"
ON quizzes FOR SELECT
USING (true);

-- Enable RLS on all tables
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;