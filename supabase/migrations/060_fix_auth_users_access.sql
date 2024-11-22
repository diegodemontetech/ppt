-- Fix auth.users access and relationships
BEGIN;

-- Grant necessary permissions to access auth.users
GRANT USAGE ON SCHEMA auth TO postgres;
GRANT SELECT ON auth.users TO postgres;
GRANT SELECT ON ALL TABLES IN SCHEMA auth TO postgres;

-- Create a secure view for accessing user data
CREATE OR REPLACE VIEW public.user_profiles AS
SELECT 
  id,
  email,
  raw_user_meta_data->>'full_name' as full_name,
  raw_user_meta_data->>'role' as role,
  company_id
FROM auth.users;

-- Enable RLS on the view
ALTER VIEW public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policy for the view
CREATE POLICY "Users can view profiles in same company"
  ON public.user_profiles
  FOR SELECT
  USING (
    company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
  );

-- Update live events query function
CREATE OR REPLACE FUNCTION get_live_event_with_instructor(event_id UUID)
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
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    le.id,
    le.title,
    le.description,
    up.full_name as instructor_name,
    up.email as instructor_email,
    le.meeting_url,
    le.starts_at,
    le.duration,
    le.attendees_count
  FROM live_events le
  JOIN user_profiles up ON le.instructor_id = up.id
  WHERE le.id = event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;