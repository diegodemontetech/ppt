-- Fix all permissions and relationships
BEGIN;

-- Create a function to get the next live event with instructor details
CREATE OR REPLACE FUNCTION get_next_live_event_with_instructor()
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
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    le.id,
    le.title,
    le.description,
    u.raw_user_meta_data->>'full_name' as instructor_name,
    u.email as instructor_email,
    le.meeting_url,
    le.starts_at,
    le.duration,
    le.attendees_count
  FROM live_events le
  JOIN auth.users u ON le.instructor_id = u.id
  WHERE le.starts_at >= NOW()
  AND le.company_id = (
    SELECT company_id 
    FROM auth.users 
    WHERE id = auth.uid()
  )
  ORDER BY le.starts_at ASC
  LIMIT 1;
END;
$$;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_next_live_event_with_instructor() TO authenticated;

-- Create a secure view for user profiles
CREATE OR REPLACE VIEW user_profiles AS
SELECT 
  id,
  email,
  raw_user_meta_data->>'full_name' as full_name,
  raw_user_meta_data->>'role' as role,
  company_id
FROM auth.users;

-- Enable RLS on the view
ALTER VIEW user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policy for the view
CREATE POLICY "Users can view profiles in same company"
  ON user_profiles
  FOR SELECT
  USING (
    company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
  );

-- Update modules table policies
DROP POLICY IF EXISTS "Users can view modules" ON modules;
CREATE POLICY "Users can view modules"
  ON modules
  FOR SELECT
  USING (
    company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
  );

-- Update live_events table policies
DROP POLICY IF EXISTS "Users can view live events" ON live_events;
CREATE POLICY "Users can view live events"
  ON live_events
  FOR SELECT
  USING (
    company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
  );

-- Create function to sync user metadata
CREATE OR REPLACE FUNCTION sync_user_metadata()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  NEW.raw_user_meta_data = jsonb_set(
    COALESCE(NEW.raw_user_meta_data, '{}'::jsonb),
    '{full_name}',
    COALESCE(NEW.raw_user_meta_data->'full_name', to_jsonb(NEW.email))
  );
  
  NEW.raw_user_meta_data = jsonb_set(
    NEW.raw_user_meta_data,
    '{role}',
    COALESCE(NEW.raw_user_meta_data->'role', '"user"')
  );
  
  RETURN NEW;
END;
$$;

-- Create trigger for user metadata sync
DROP TRIGGER IF EXISTS sync_user_metadata_trigger ON auth.users;
CREATE TRIGGER sync_user_metadata_trigger
  BEFORE INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_metadata();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;