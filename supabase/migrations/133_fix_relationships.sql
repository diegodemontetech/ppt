-- Fix database relationships and auth issues
BEGIN;

-- Drop existing tables to rebuild with correct relationships
DROP TABLE IF EXISTS live_events CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Create live_events table with correct relationship
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
    USING (is_admin());

-- Create secure view for user profiles
CREATE OR REPLACE VIEW user_profiles AS
SELECT 
    u.id,
    u.email,
    u.raw_user_meta_data->>'full_name' as full_name,
    u.raw_user_meta_data->>'role' as role,
    u.raw_user_meta_data->>'department_id' as department_id,
    u.created_at,
    u.updated_at
FROM auth.users u;

-- Enable RLS on the view
ALTER VIEW user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policy for the view
CREATE POLICY "Users can view profiles"
    ON user_profiles FOR SELECT
    USING (
        is_admin() OR 
        id = auth.uid()
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

-- Create function to sync user metadata
CREATE OR REPLACE FUNCTION sync_user_metadata()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure metadata exists
    IF NEW.raw_user_meta_data IS NULL THEN
        NEW.raw_user_meta_data := '{}'::jsonb;
    END IF;

    -- Set default role if not set
    IF NEW.raw_user_meta_data->>'role' IS NULL THEN
        NEW.raw_user_meta_data := jsonb_set(
            NEW.raw_user_meta_data,
            '{role}',
            '"user"'
        );
    END IF;

    -- Set full_name if not set
    IF NEW.raw_user_meta_data->>'full_name' IS NULL THEN
        NEW.raw_user_meta_data := jsonb_set(
            NEW.raw_user_meta_data,
            '{full_name}',
            to_jsonb(split_part(NEW.email, '@', 1))
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for user metadata sync
DROP TRIGGER IF EXISTS sync_user_metadata_trigger ON auth.users;
CREATE TRIGGER sync_user_metadata_trigger
    BEFORE INSERT OR UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION sync_user_metadata();

-- Update existing users with default metadata
UPDATE auth.users
SET raw_user_meta_data = 
    CASE 
        WHEN raw_user_meta_data IS NULL THEN 
            jsonb_build_object(
                'role', 'user',
                'full_name', split_part(email, '@', 1)
            )
        ELSE
            raw_user_meta_data || 
            jsonb_build_object(
                'role', COALESCE(raw_user_meta_data->>'role', 'user'),
                'full_name', COALESCE(raw_user_meta_data->>'full_name', split_part(email, '@', 1))
            )
    END;

-- Set admin user
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"admin"'
)
WHERE email = 'diegodemontevpj@gmail.com';

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON user_profiles TO authenticated;
GRANT EXECUTE ON FUNCTION get_next_live_event() TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;