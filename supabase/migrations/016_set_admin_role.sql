-- Set your email as admin
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"admin"'
)
WHERE email = 'diegodemontec@gmail.com';

-- Create function to check admin role
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

-- Create policy for admin access
CREATE POLICY "Allow full access to admins"
ON public.courses
FOR ALL
USING (
  is_admin() 
  OR auth.uid() IN (
    SELECT user_id 
    FROM user_group_members 
    WHERE group_id IN (
      SELECT id 
      FROM user_groups 
      WHERE permissions ? 'admin'
    )
  )
);