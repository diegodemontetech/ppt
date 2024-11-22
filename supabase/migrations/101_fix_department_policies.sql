-- Fix department RLS policies
BEGIN;

-- Drop existing policies
DROP POLICY IF EXISTS "Admin can manage departments" ON departments;
DROP POLICY IF EXISTS "Users can view departments" ON departments;

-- Create new policies with proper permissions
CREATE POLICY "Admin can manage departments"
ON departments FOR ALL
USING (
  EXISTS (
    SELECT 1 
    FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' IN ('admin', 'master_admin')
  )
);

CREATE POLICY "Users can view departments"
ON departments FOR SELECT
USING (true);

-- Create helper function to check admin status if not exists
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

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;