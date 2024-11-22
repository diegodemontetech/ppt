-- Fix live events table and relationships
BEGIN;

-- Create live_events table if not exists
CREATE TABLE IF NOT EXISTS live_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    instructor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    meeting_url TEXT NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    duration INTEGER NOT NULL,
    attendees_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_live_events_instructor ON live_events(instructor_id);
CREATE INDEX IF NOT EXISTS idx_live_events_starts_at ON live_events(starts_at);

-- Enable RLS
ALTER TABLE live_events ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view live events"
    ON live_events FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage live events"
    ON live_events FOR ALL
    USING (is_admin());

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
        e.title,
        e.description,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email) as instructor_name,
        u.email as instructor_email,
        e.meeting_url,
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_next_live_event() TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;