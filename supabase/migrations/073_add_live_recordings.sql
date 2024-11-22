-- Add live recordings management
BEGIN;

-- Create live recordings table
CREATE TABLE live_recordings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    live_event_id UUID REFERENCES live_events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    video_url TEXT NOT NULL,
    duration INTEGER,
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes
CREATE INDEX idx_recordings_live_event ON live_recordings(live_event_id);

-- Enable RLS
ALTER TABLE live_recordings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view recordings"
    ON live_recordings FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage recordings"
    ON live_recordings FOR ALL
    USING (is_admin());

-- Create function to get live recordings with event details
CREATE OR REPLACE FUNCTION get_live_recordings()
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    video_url TEXT,
    duration INTEGER,
    thumbnail_url TEXT,
    event_title TEXT,
    event_date TIMESTAMPTZ,
    instructor_name TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lr.id,
        lr.title,
        lr.description,
        lr.video_url,
        lr.duration,
        lr.thumbnail_url,
        le.title as event_title,
        le.starts_at as event_date,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email) as instructor_name,
        lr.created_at
    FROM live_recordings lr
    JOIN live_events le ON lr.live_event_id = le.id
    JOIN auth.users u ON le.instructor_id = u.id
    ORDER BY lr.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_live_recordings() TO authenticated;

COMMIT;