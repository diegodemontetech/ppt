-- Fix relationships and permissions
BEGIN;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Admin full access" ON modules;
DROP POLICY IF EXISTS "Users view modules" ON modules;
DROP POLICY IF EXISTS "Admin full access" ON lessons;
DROP POLICY IF EXISTS "Users view lessons" ON lessons;
DROP POLICY IF EXISTS "Admin full access" ON live_events;
DROP POLICY IF EXISTS "Users view live events" ON live_events;

-- Create secure view for user profiles
DROP VIEW IF EXISTS user_profiles;
CREATE VIEW user_profiles AS
SELECT 
  id,
  email,
  raw_user_meta_data->>'full_name' as full_name,
  raw_user_meta_data->>'role' as role,
  company_id
FROM auth.users
WHERE (
  auth.uid() = id OR 
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' IN ('admin', 'master_admin')
  )
);

-- Update live events query function
CREATE OR REPLACE FUNCTION get_next_live_event()
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  instructor_name TEXT,
  instructor_email TEXT,
  meeting_url TEXT,
  starts_at TIMESTAMPTZ,
  duration INTEGER,
  attendees_count INTEGER
) SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    le.id,
    le.title::TEXT,
    COALESCE(le.description, '')::TEXT,
    COALESCE(u.raw_user_meta_data->>'full_name', u.email)::TEXT,
    u.email::TEXT,
    le.meeting_url::TEXT,
    le.starts_at,
    le.duration,
    COALESCE(le.attendees_count, 0)
  FROM live_events le
  JOIN auth.users u ON le.instructor_id = u.id
  WHERE le.starts_at >= NOW()
  ORDER BY le.starts_at ASC
  LIMIT 1;
END;
$$;

-- Create new policies
CREATE POLICY "Admin full access"
  ON modules FOR ALL
  USING (is_admin());

CREATE POLICY "Users view modules"
  ON modules FOR SELECT
  USING (true);

CREATE POLICY "Admin full access"
  ON lessons FOR ALL
  USING (is_admin());

CREATE POLICY "Users view lessons"
  ON lessons FOR SELECT
  USING (true);

CREATE POLICY "Admin full access"
  ON live_events FOR ALL
  USING (is_admin());

CREATE POLICY "Users view live events"
  ON live_events FOR SELECT
  USING (true);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON user_profiles TO authenticated;
GRANT EXECUTE ON FUNCTION get_next_live_event() TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;