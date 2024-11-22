-- Fix user groups and permissions
BEGIN;

-- Drop existing tables to rebuild with correct relationships
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
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    group_id UUID REFERENCES user_groups(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, group_id)
);

-- Create indexes
CREATE INDEX idx_user_groups_name ON user_groups(name);
CREATE INDEX idx_user_group_members_user ON user_group_members(user_id);
CREATE INDEX idx_user_group_members_group ON user_group_members(group_id);

-- Enable RLS
ALTER TABLE user_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_group_members ENABLE ROW LEVEL SECURITY;

-- Create policies
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

CREATE POLICY "Users can view groups"
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

CREATE POLICY "Users can view group members"
    ON user_group_members
    FOR SELECT
    USING (true);

-- Create function to check user's group permissions
CREATE OR REPLACE FUNCTION check_user_permissions(
    user_uuid UUID,
    required_permission TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM user_group_members ugm
        JOIN user_groups ug ON ugm.group_id = ug.id
        WHERE ugm.user_id = user_uuid
        AND required_permission = ANY(ug.permissions)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check module access
CREATE OR REPLACE FUNCTION check_module_access(
    user_uuid UUID,
    module_uuid UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM user_group_members ugm
        JOIN user_groups ug ON ugm.group_id = ug.id
        WHERE ugm.user_id = user_uuid
        AND (
            'view_all' = ANY(ug.permissions)
            OR module_uuid = ANY(ug.modules)
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION check_user_permissions(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION check_module_access(UUID, UUID) TO authenticated;

-- Create default admin group
INSERT INTO user_groups (name, description, permissions)
VALUES (
    'Administrators',
    'Full system access',
    ARRAY['view_all', 'create_content', 'manage_users', 'view_analytics']
);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;