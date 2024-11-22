-- Aggressive fix for modules table
BEGIN;

-- Backup existing data
CREATE TEMP TABLE modules_backup AS SELECT * FROM modules;

-- Drop existing table and all dependencies
DROP TABLE IF EXISTS modules CASCADE;

-- Recreate modules table with correct structure
CREATE TABLE modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    bg_color TEXT DEFAULT '#3B82F6',
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create index
CREATE INDEX idx_modules_category ON modules(category_id);

-- Restore data
INSERT INTO modules (
    id,
    category_id,
    title,
    description,
    bg_color,
    is_featured,
    created_at,
    updated_at
)
SELECT 
    id,
    category_id,
    title,
    description,
    COALESCE(bg_color, '#3B82F6'),
    COALESCE(is_featured, false),
    created_at,
    updated_at
FROM modules_backup;

-- Drop backup table
DROP TABLE modules_backup;

-- Recreate trigger function
CREATE OR REPLACE FUNCTION set_module_color()
RETURNS TRIGGER AS $$
BEGIN
    -- Set color if not provided
    IF NEW.bg_color IS NULL THEN
        NEW.bg_color := (
            CASE floor(random() * 7)
                WHEN 0 THEN '#3B82F6' -- blue
                WHEN 1 THEN '#10B981' -- green  
                WHEN 2 THEN '#8B5CF6' -- purple
                WHEN 3 THEN '#F59E0B' -- yellow
                WHEN 4 THEN '#EF4444' -- red
                WHEN 5 THEN '#EC4899' -- pink
                ELSE '#6366F1' -- indigo
            END
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS set_module_color_trigger ON modules;
CREATE TRIGGER set_module_color_trigger
    BEFORE INSERT ON modules
    FOR EACH ROW
    EXECUTE FUNCTION set_module_color();

-- Enable RLS
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Everyone can view modules" ON modules;
CREATE POLICY "Everyone can view modules"
    ON modules FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admin can manage modules" ON modules;
CREATE POLICY "Admin can manage modules"
    ON modules FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;