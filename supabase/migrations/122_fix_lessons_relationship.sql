-- Fix lessons and modules relationship
BEGIN;

-- First backup lessons data
CREATE TEMP TABLE lessons_backup AS SELECT * FROM lessons;

-- Drop existing lessons table and recreate with correct relationship
DROP TABLE IF EXISTS lessons CASCADE;

CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    video_url TEXT NOT NULL,
    order_num INTEGER NOT NULL,
    duration INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id, order_num)
);

-- Create indexes
CREATE INDEX idx_lessons_module ON lessons(module_id);
CREATE INDEX idx_lessons_order ON lessons(module_id, order_num);

-- Restore lessons data
INSERT INTO lessons (
    id,
    module_id,
    title,
    description,
    video_url,
    order_num,
    duration,
    created_at,
    updated_at
)
SELECT 
    id,
    module_id,
    title,
    description,
    video_url,
    order_num,
    duration,
    created_at,
    updated_at
FROM lessons_backup;

-- Drop backup table
DROP TABLE lessons_backup;

-- Enable RLS
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Everyone can view lessons" ON lessons;
CREATE POLICY "Everyone can view lessons"
    ON lessons FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admin can manage lessons" ON lessons;
CREATE POLICY "Admin can manage lessons"
    ON lessons FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Create function to update module timestamp when lesson changes
CREATE OR REPLACE FUNCTION update_module_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE modules
    SET updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.module_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for module timestamp
DROP TRIGGER IF EXISTS update_module_timestamp ON lessons;
CREATE TRIGGER update_module_timestamp
    AFTER INSERT OR UPDATE OR DELETE ON lessons
    FOR EACH ROW
    EXECUTE FUNCTION update_module_timestamp();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;