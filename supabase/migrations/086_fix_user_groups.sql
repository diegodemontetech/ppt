-- Fix user groups and permissions
BEGIN;

-- Drop existing tables and views
DROP VIEW IF EXISTS user_profiles;
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

-- Create indexes
CREATE INDEX idx_user_groups_name ON user_groups(name);
CREATE INDEX idx_user_group_members_user ON user_group_members(user_id);
CREATE INDEX idx_user_group_members_group ON user_group_members(group_id);

-- Enable RLS
ALTER TABLE user_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_group_members ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Admin can manage groups"
    ON user_groups
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Everyone can view groups"
    ON user_groups
    FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage group members"
    ON user_group_members
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Everyone can view group members"
    ON user_group_members
    FOR SELECT
    USING (true);

-- Create user profiles view
CREATE VIEW user_profiles AS
SELECT 
    u.id,
    u.email,
    u.raw_user_meta_data->>'full_name' as full_name,
    u.raw_user_meta_data->>'role' as role,
    array_remove(array_agg(DISTINCT g.id), NULL) as group_ids,
    array_remove(array_agg(DISTINCT g.name), NULL) as group_names,
    u.created_at
FROM auth.users u
LEFT JOIN user_group_members ugm ON u.id = ugm.user_id
LEFT JOIN user_groups g ON ugm.group_id = g.id
GROUP BY u.id, u.email, u.raw_user_meta_data, u.created_at;

-- Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON user_profiles TO authenticated;

-- Create default admin group
INSERT INTO user_groups (name, description, permissions)
VALUES (
    'Administrators',
    'Full system access',
    ARRAY['view_all', 'create_content', 'manage_users', 'view_analytics']
) ON CONFLICT DO NOTHING;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;