-- Fix all database relationships
BEGIN;

-- Drop existing tables to rebuild with correct relationships
DROP TABLE IF EXISTS ebook_ratings CASCADE;
DROP TABLE IF EXISTS ebooks CASCADE;
DROP TABLE IF EXISTS live_events CASCADE;
DROP TABLE IF EXISTS live_recordings CASCADE;

-- Create ebooks table with correct relationship
CREATE TABLE ebooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    subtitle TEXT,
    author TEXT NOT NULL,
    description TEXT,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    pdf_url TEXT NOT NULL,
    cover_url TEXT,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create ebook ratings table
CREATE TABLE ebook_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ebook_id UUID NOT NULL REFERENCES ebooks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ebook_id, user_id)
);

-- Create live events table with correct relationship
CREATE TABLE live_events (
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

-- Create live recordings table
CREATE TABLE live_recordings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    live_event_id UUID NOT NULL REFERENCES live_events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    video_url TEXT NOT NULL,
    duration INTEGER,
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_ebooks_category ON ebooks(category_id);
CREATE INDEX idx_ebook_ratings_ebook ON ebook_ratings(ebook_id);
CREATE INDEX idx_ebook_ratings_user ON ebook_ratings(user_id);
CREATE INDEX idx_live_events_instructor ON live_events(instructor_id);
CREATE INDEX idx_live_events_starts_at ON live_events(starts_at);
CREATE INDEX idx_live_recordings_event ON live_recordings(live_event_id);

-- Enable RLS
ALTER TABLE ebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE ebook_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_recordings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view ebooks"
    ON ebooks FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage ebooks"
    ON ebooks FOR ALL
    USING (is_admin());

CREATE POLICY "Users can rate ebooks"
    ON ebook_ratings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their ratings"
    ON ebook_ratings FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Everyone can view ratings"
    ON ebook_ratings FOR SELECT
    USING (true);

CREATE POLICY "Everyone can view live events"
    ON live_events FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage live events"
    ON live_events FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view recordings"
    ON live_recordings FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage recordings"
    ON live_recordings FOR ALL
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

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION get_next_live_event() TO authenticated;

-- Insert sample data
INSERT INTO ebooks (
    title,
    author,
    description,
    category_id,
    pdf_url,
    is_featured
) VALUES (
    'JavaScript Fundamentals',
    'John Doe',
    'Learn the basics of JavaScript programming',
    (SELECT id FROM categories WHERE name = 'Programação' LIMIT 1),
    'javascript-fundamentals.pdf',
    true
);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;