-- Fix schema and permissions
BEGIN;

-- Fix admin user permissions
DO $$ 
BEGIN
  -- Update admin user
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"admin"'
  )
  WHERE email = 'diegodemontevpj@gmail.com';

  -- Ensure user has company_id
  UPDATE auth.users
  SET company_id = (
    SELECT id FROM companies 
    WHERE cnpj = '00000000000000' 
    LIMIT 1
  )
  WHERE email = 'diegodemontevpj@gmail.com'
  AND company_id IS NULL;
END $$;

-- Fix RLS policies
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_recordings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Admin full access" ON modules;
DROP POLICY IF EXISTS "Users view modules" ON modules;
DROP POLICY IF EXISTS "Admin full access" ON lessons;
DROP POLICY IF EXISTS "Users view lessons" ON lessons;
DROP POLICY IF EXISTS "Admin full access" ON live_events;
DROP POLICY IF EXISTS "Users view live events" ON live_events;
DROP POLICY IF EXISTS "Admin full access" ON live_recordings;
DROP POLICY IF EXISTS "Users view recordings" ON live_recordings;

-- Create new policies
CREATE POLICY "Admin full access"
ON modules FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' = 'admin'
  )
);

CREATE POLICY "Users view modules"
ON modules FOR SELECT
USING (true);

CREATE POLICY "Admin full access"
ON lessons FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' = 'admin'
  )
);

CREATE POLICY "Users view lessons"
ON lessons FOR SELECT
USING (true);

CREATE POLICY "Admin full access"
ON live_events FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' = 'admin'
  )
);

CREATE POLICY "Users view live events"
ON live_events FOR SELECT
USING (true);

CREATE POLICY "Admin full access"
ON live_recordings FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' = 'admin'
  )
);

CREATE POLICY "Users view recordings"
ON live_recordings FOR SELECT
USING (true);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;