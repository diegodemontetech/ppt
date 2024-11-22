-- Fix live events query
BEGIN;

-- Drop existing function
DROP FUNCTION IF EXISTS get_next_live_event();

-- Create function with better error handling and explicit types
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
        COALESCE(e.description, '')::TEXT,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email)::TEXT,
        u.email::TEXT,
        e.meeting_url::TEXT,
        e.starts_at,
        e.duration,
        COALESCE(e.attendees_count, 0)
    FROM live_events e
    JOIN auth.users u ON e.instructor_id = u.id
    WHERE e.starts_at >= NOW()
    ORDER BY e.starts_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_next_live_event() TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;