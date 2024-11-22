-- Fix admin permissions and access
BEGIN;

-- First, ensure admin user exists and has correct role
DO $$ 
BEGIN
  -- Update admin user with correct role and metadata
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"admin"'
  )
  WHERE email = 'diegodemontevpj@gmail.com';
END $$;

-- Create admin policies function
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

-- Grant permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Enable RLS on all tables
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Admin full access" ON modules;
DROP POLICY IF EXISTS "Users view modules" ON modules;
DROP POLICY IF EXISTS "Admin full access" ON lessons;
DROP POLICY IF EXISTS "Users view lessons" ON lessons;
DROP POLICY IF EXISTS "Admin full access" ON quizzes;
DROP POLICY IF EXISTS "Users view quizzes" ON quizzes;
DROP POLICY IF EXISTS "Admin full access" ON live_events;
DROP POLICY IF EXISTS "Users view live events" ON live_events;
DROP POLICY IF EXISTS "Admin full access" ON live_recordings;
DROP POLICY IF EXISTS "Users view recordings" ON live_recordings;

-- Create new policies with proper admin access
CREATE POLICY "Admin full access modules"
ON modules FOR ALL
USING (is_admin());

CREATE POLICY "Users view modules"
ON modules FOR SELECT
USING (true);

CREATE POLICY "Admin full access lessons"
ON lessons FOR ALL
USING (is_admin());

CREATE POLICY "Users view lessons"
ON lessons FOR SELECT
USING (true);

CREATE POLICY "Admin full access quizzes"
ON quizzes FOR ALL
USING (is_admin());

CREATE POLICY "Users view quizzes"
ON quizzes FOR SELECT
USING (true);

CREATE POLICY "Admin full access live events"
ON live_events FOR ALL
USING (is_admin());

CREATE POLICY "Users view live events"
ON live_events FOR SELECT
USING (true);

CREATE POLICY "Admin full access recordings"
ON live_recordings FOR ALL
USING (is_admin());

CREATE POLICY "Users view recordings"
ON live_recordings FOR SELECT
USING (true);

-- Create policy for lesson progress
CREATE POLICY "Users manage own progress"
ON lesson_progress FOR ALL
USING (auth.uid() = user_id OR is_admin());

-- Create policy for lesson ratings
CREATE POLICY "Users manage own ratings"
ON lesson_ratings FOR ALL
USING (auth.uid() = user_id OR is_admin());

-- Create policy for notifications
CREATE POLICY "Users manage own notifications"
ON notifications FOR ALL
USING (auth.uid() = user_id OR is_admin());

-- Grant access to auth schema for admin functions
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON auth.users TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;