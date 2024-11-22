-- Fix live events and instructor relationship
BEGIN;

-- Drop existing live_events table if exists
DROP TABLE IF EXISTS live_events CASCADE;

-- Create live_events table with correct relationships
CREATE TABLE live_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    instructor_id UUID NOT NULL,
    meeting_url TEXT NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    duration INTEGER NOT NULL,
    attendees_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT live_events_instructor_id_fkey 
        FOREIGN KEY (instructor_id) 
        REFERENCES auth.users(id) 
        ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX idx_live_events_instructor ON live_events(instructor_id);
CREATE INDEX idx_live_events_starts_at ON live_events(starts_at);

-- Enable RLS
ALTER TABLE live_events ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view live events"
    ON live_events FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage live events"
    ON live_events FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

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
    ORDER BY e.starts_at ASC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_next_live_event() TO authenticated;

-- Create function to get live event details
CREATE OR REPLACE FUNCTION get_live_event_details(event_uuid UUID)
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
        COALESCE(e.description, '')::TEXT,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email)::TEXT,
        u.email::TEXT,
        e.meeting_url::TEXT,
        e.starts_at,
        e.duration,
        COALESCE(e.attendees_count, 0)
    FROM live_events e
    JOIN auth.users u ON e.instructor_id = u.id
    WHERE e.id = event_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_live_event_details(UUID) TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;