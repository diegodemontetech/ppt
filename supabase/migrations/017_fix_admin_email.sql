-- Set correct admin email
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"admin"'
)
WHERE email = 'diegodemontevpj@gmail.com';

-- Ensure admin policies are correctly set
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (
    SELECT EXISTS (
      SELECT 1
      FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'admin'
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add admin-only tables policies
DO $$ 
BEGIN
  -- Courses
  DROP POLICY IF EXISTS "Admin manage courses" ON courses;
  CREATE POLICY "Admin manage courses" ON courses
    USING (is_admin());

  -- Lessons
  DROP POLICY IF EXISTS "Admin manage lessons" ON lessons;
  CREATE POLICY "Admin manage lessons" ON lessons
    USING (is_admin());

  -- Users
  DROP POLICY IF EXISTS "Admin manage users" ON auth.users;
  CREATE POLICY "Admin manage users" ON auth.users
    USING (is_admin());
END $$;