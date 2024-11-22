-- Fix type mismatch in functions
BEGIN;

-- Drop existing function
DROP FUNCTION IF EXISTS get_next_live_event();
DROP FUNCTION IF EXISTS get_module_stats(UUID);

-- Recreate function with explicit TEXT types
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
#variable_conflict use_column
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

-- Recreate module stats function with explicit types
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
        COALESCE(ROUND(AVG(lr.rating)::NUMERIC, 1), 0.0),
        COUNT(DISTINCT lr.id)::BIGINT
    FROM modules m
    LEFT JOIN lessons l ON l.module_id = m.id
    LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id
    LEFT JOIN lesson_ratings lr ON lr.lesson_id = l.id
    WHERE m.id = module_uuid
    GROUP BY m.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_next_live_event() TO authenticated;
GRANT EXECUTE ON FUNCTION get_module_stats(UUID) TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;