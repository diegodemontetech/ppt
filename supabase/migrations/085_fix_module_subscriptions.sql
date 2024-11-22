-- Fix module subscriptions and relationships
BEGIN;

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

-- Create function to check subscription
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

-- Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION is_subscribed_to_module(UUID, UUID) TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;