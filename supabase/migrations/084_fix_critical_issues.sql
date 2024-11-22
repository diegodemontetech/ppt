-- Fix critical database issues
BEGIN;

-- Drop existing tables to rebuild with correct relationships
DROP TABLE IF EXISTS live_events CASCADE;
DROP TABLE IF EXISTS user_group_members CASCADE;
DROP TABLE IF EXISTS user_groups CASCADE;

-- Create user_groups table
CREATE TABLE user_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    permissions TEXT[] DEFAULT '{}',
    modules UUID[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create user_group_members table
CREATE TABLE user_group_members (
    user_id UUID NOT NULL,
    group_id UUID REFERENCES user_groups(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, group_id),
    CONSTRAINT user_group_members_user_id_fkey 
        FOREIGN KEY (user_id) 
        REFERENCES auth.users(id) 
        ON DELETE CASCADE
);

-- Create live_events table
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
CREATE INDEX idx_user_group_members_user ON user_group_members(user_id);
CREATE INDEX idx_user_group_members_group ON user_group_members(group_id);

-- Enable RLS
ALTER TABLE live_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_group_members ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view live events"
    ON live_events FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage live events"
    ON live_events FOR ALL
    USING (
        EXISTS (
            SELECT 1 
            FROM auth.users 
            WHERE id = auth.uid() 
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admin can manage groups"
    ON user_groups FOR ALL
    USING (
        EXISTS (
            SELECT 1 
            FROM auth.users 
            WHERE id = auth.uid() 
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Everyone can view groups"
    ON user_groups FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage group members"
    ON user_group_members FOR ALL
    USING (
        EXISTS (
            SELECT 1 
            FROM auth.users 
            WHERE id = auth.uid() 
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Everyone can view group members"
    ON user_group_members FOR SELECT
    USING (true);

-- Create secure view for users with groups
CREATE OR REPLACE VIEW user_profiles AS
SELECT 
    u.id,
    u.email,
    u.raw_user_meta_data->>'full_name' as full_name,
    u.raw_user_meta_data->>'role' as role,
    array_agg(DISTINCT g.id) as group_ids,
    array_agg(DISTINCT g.name) as group_names
FROM auth.users u
LEFT JOIN user_group_members ugm ON u.id = ugm.user_id
LEFT JOIN user_groups g ON ugm.group_id = g.id
GROUP BY u.id, u.email, u.raw_user_meta_data;

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
GRANT SELECT ON user_profiles TO authenticated;
GRANT EXECUTE ON FUNCTION get_next_live_event() TO authenticated;

-- Create default admin group if it doesn't exist
INSERT INTO user_groups (name, description, permissions)
VALUES (
    'Administrators',
    'Full system access',
    ARRAY['view_all', 'create_content', 'manage_users', 'view_analytics']
) ON CONFLICT DO NOTHING;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;