-- Fix type mismatch and function return types
BEGIN;

-- Drop existing function to recreate with correct types
DROP FUNCTION IF EXISTS get_next_live_event();

-- Create function with explicit type casts
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
        (COALESCE(u.raw_user_meta_data->>'full_name', u.email))::TEXT as instructor_name,
        u.email::TEXT as instructor_email,
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

-- Create helper function for module statistics
CREATE OR REPLACE FUNCTION get_module_stats(module_uuid UUID)
RETURNS TABLE (
    enrolled_count BIGINT,
    average_rating NUMERIC,
    total_ratings BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT lp.user_id)::BIGINT as enrolled_count,
        ROUND(AVG(lr.rating)::NUMERIC, 1) as average_rating,
        COUNT(DISTINCT lr.id)::BIGINT as total_ratings
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