-- Fix modules and lessons relationship
BEGIN;

-- First backup existing data
CREATE TEMP TABLE modules_backup AS SELECT * FROM modules;
CREATE TEMP TABLE lessons_backup AS SELECT * FROM lessons;

-- Drop existing tables and recreate with correct relationships
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS modules CASCADE;

-- Create modules table
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

-- Create lessons table with explicit relationship to modules
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
CREATE INDEX idx_modules_category ON modules(category_id);
CREATE INDEX idx_lessons_module ON lessons(module_id);
CREATE INDEX idx_lessons_order ON lessons(module_id, order_num);

-- Restore modules data
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

-- Drop backup tables
DROP TABLE modules_backup;
DROP TABLE lessons_backup;

-- Enable RLS
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view modules"
    ON modules FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage modules"
    ON modules FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Everyone can view lessons"
    ON lessons FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage lessons"
    ON lessons FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Create function to update module timestamp
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
    AFTER INSERT OR UPDATE ON lessons
    FOR EACH ROW
    EXECUTE FUNCTION update_module_timestamp();

-- Create function to generate module color
CREATE OR REPLACE FUNCTION generate_module_color()
RETURNS TEXT AS $$
DECLARE
    colors TEXT[] := ARRAY[
        '#3B82F6', -- blue
        '#10B981', -- green
        '#8B5CF6', -- purple
        '#F59E0B', -- yellow
        '#EF4444', -- red
        '#EC4899', -- pink
        '#6366F1'  -- indigo
    ];
BEGIN
    RETURN colors[floor(random() * array_length(colors, 1) + 1)];
END;
$$ LANGUAGE plpgsql;

-- Create trigger to set module color
CREATE OR REPLACE FUNCTION set_module_color()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.bg_color IS NULL THEN
        NEW.bg_color := generate_module_color();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_module_color_trigger
    BEFORE INSERT ON modules
    FOR EACH ROW
    EXECUTE FUNCTION set_module_color();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;