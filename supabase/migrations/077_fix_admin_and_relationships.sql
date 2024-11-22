-- Fix admin permissions and table relationships
BEGIN;

-- First ensure admin user exists and has correct role
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"admin"'
)
WHERE email = 'diegodemontevpj@gmail.com';

-- Create admin check function
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

-- Create function to get module stats
CREATE OR REPLACE FUNCTION get_module_stats(module_uuid UUID)
RETURNS TABLE (
    enrolled_count BIGINT,
    average_rating NUMERIC,
    total_ratings BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT lp.user_id)::BIGINT,
        ROUND(AVG(lr.rating)::NUMERIC, 1),
        COUNT(DISTINCT lr.id)::BIGINT
    FROM modules m
    LEFT JOIN lessons l ON l.module_id = m.id
    LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id
    LEFT JOIN lesson_ratings lr ON lr.lesson_id = l.id
    WHERE m.id = module_uuid
    GROUP BY m.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get next live event
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
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id,
        e.title::TEXT,
        e.description::TEXT,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email)::TEXT,
        u.email::TEXT,
        e.meeting_url::TEXT,
        e.starts_at,
        e.duration,
        e.attendees_count
    FROM live_events e
    JOIN auth.users u ON e.instructor_id = u.id
    WHERE e.starts_at >= NOW()
    ORDER BY e.starts_at ASC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
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
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
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

CREATE POLICY "Users manage own progress"
    ON lesson_progress FOR ALL
    USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Users manage own ratings"
    ON lesson_ratings FOR ALL
    USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Admin full access live events"
    ON live_events FOR ALL
    USING (is_admin());

CREATE POLICY "Users view live events"
    ON live_events FOR SELECT
    USING (true);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;