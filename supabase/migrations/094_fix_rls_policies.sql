-- Fix RLS policies and relationships
BEGIN;

-- Drop existing policies
DROP POLICY IF EXISTS "Admin can manage departments" ON departments;
DROP POLICY IF EXISTS "Users can view departments" ON departments;
DROP POLICY IF EXISTS "Admin can manage categories" ON categories;
DROP POLICY IF EXISTS "Users can view categories" ON categories;
DROP POLICY IF EXISTS "Admin can manage modules" ON modules;
DROP POLICY IF EXISTS "Users can view modules" ON modules;
DROP POLICY IF EXISTS "Admin can manage live events" ON live_events;
DROP POLICY IF EXISTS "Users can view live events" ON live_events;

-- Create new policies with correct permissions
CREATE POLICY "Admin can manage departments"
ON departments FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' IN ('admin', 'master_admin')
  )
);

CREATE POLICY "Users can view departments"
ON departments FOR SELECT
USING (true);

CREATE POLICY "Admin can manage categories"
ON categories FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' IN ('admin', 'master_admin')
  )
);

CREATE POLICY "Users can view categories"
ON categories FOR SELECT
USING (true);

CREATE POLICY "Admin can manage modules"
ON modules FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' IN ('admin', 'master_admin')
  )
);

CREATE POLICY "Users can view modules"
ON modules FOR SELECT
USING (true);

-- Fix live events table and relationships
ALTER TABLE live_events 
DROP CONSTRAINT IF EXISTS live_events_instructor_id_fkey;

ALTER TABLE live_events
ADD CONSTRAINT live_events_instructor_id_fkey 
FOREIGN KEY (instructor_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE;

CREATE POLICY "Admin can manage live events"
ON live_events FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' IN ('admin', 'master_admin')
  )
);

CREATE POLICY "Users can view live events"
ON live_events FOR SELECT
USING (true);

-- Create function to get live events with instructor details
CREATE OR REPLACE FUNCTION get_live_events_with_instructor()
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  instructor_id UUID,
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
    le.instructor_id,
    COALESCE(u.raw_user_meta_data->>'full_name', u.email) as instructor_name,
    u.email as instructor_email,
    le.meeting_url,
    le.starts_at,
    le.duration,
    le.attendees_count
  FROM live_events le
  JOIN auth.users u ON le.instructor_id = u.id
  ORDER BY le.starts_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;