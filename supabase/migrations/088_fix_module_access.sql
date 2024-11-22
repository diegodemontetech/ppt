-- Fix module access and subscriptions
BEGIN;

-- Drop existing policies first
DROP POLICY IF EXISTS "Users can manage their own subscriptions" ON module_subscriptions;

-- Create module_subscriptions table if not exists
CREATE TABLE IF NOT EXISTS module_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID REFERENCES modules(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_module_subscriptions_user ON module_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_module_subscriptions_module ON module_subscriptions(module_id);

-- Enable RLS
ALTER TABLE module_subscriptions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can manage their own subscriptions"
    ON module_subscriptions
    FOR ALL
    USING (auth.uid() = user_id);

-- Create function to check if user can access module
CREATE OR REPLACE FUNCTION can_access_module(
    module_uuid UUID,
    user_uuid UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM module_subscriptions ms
        WHERE ms.module_id = module_uuid
        AND ms.user_id = user_uuid
    ) OR EXISTS (
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

-- Create function to check if user is subscribed
CREATE OR REPLACE FUNCTION is_subscribed_to_module(
    module_uuid UUID,
    user_uuid UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM module_subscriptions
        WHERE module_id = module_uuid
        AND user_id = user_uuid
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS check_user_permissions(UUID, TEXT);
DROP FUNCTION IF EXISTS check_module_access(UUID, UUID);

-- Create function to check user permissions
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
GRANT EXECUTE ON FUNCTION can_access_module(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_subscribed_to_module(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION check_user_permissions(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION check_module_access(UUID, UUID) TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;