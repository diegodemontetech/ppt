-- Add module subscriptions and calendar features
BEGIN;

-- Create module_subscriptions table
CREATE TABLE module_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID REFERENCES modules(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id, user_id)
);

-- Create index for better performance
CREATE INDEX idx_module_subscriptions_user ON module_subscriptions(user_id);
CREATE INDEX idx_module_subscriptions_module ON module_subscriptions(module_id);

-- Enable RLS
ALTER TABLE module_subscriptions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can manage their own subscriptions"
    ON module_subscriptions
    FOR ALL
    USING (auth.uid() = user_id);

-- Create function to get user's calendar events
CREATE OR REPLACE FUNCTION get_user_calendar_events(
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    event_type TEXT,
    module_id UUID,
    live_event_id UUID
) AS $$
BEGIN
    RETURN QUERY
    -- Get live events the user is subscribed to
    SELECT 
        le.id,
        le.title,
        le.description,
        le.starts_at,
        le.starts_at + (le.duration * interval '1 minute') as ends_at,
        'live_event'::TEXT as event_type,
        NULL::UUID as module_id,
        le.id as live_event_id
    FROM live_events le
    WHERE le.starts_at BETWEEN start_date AND end_date
    AND EXISTS (
        SELECT 1 
        FROM module_subscriptions ms 
        WHERE ms.user_id = auth.uid()
    )
    
    UNION ALL
    
    -- Get module start dates
    SELECT
        m.id,
        m.title,
        m.description,
        ms.created_at as starts_at,
        ms.created_at + interval '1 year' as ends_at,
        'module'::TEXT as event_type,
        m.id as module_id,
        NULL::UUID as live_event_id
    FROM modules m
    JOIN module_subscriptions ms ON ms.module_id = m.id
    WHERE ms.user_id = auth.uid()
    AND ms.created_at BETWEEN start_date AND end_date
    
    ORDER BY starts_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_calendar_events(TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;