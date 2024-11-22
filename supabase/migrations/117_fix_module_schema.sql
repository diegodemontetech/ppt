-- Fix module schema and remove all department_id references
BEGIN;

-- Drop any existing department_id references
ALTER TABLE modules
DROP COLUMN IF EXISTS department_id CASCADE;

-- Make sure category_id exists and is required
ALTER TABLE modules
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES categories(id) NOT NULL;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_modules_category ON modules(category_id);

-- Add bg_color column if not exists
ALTER TABLE modules
ADD COLUMN IF NOT EXISTS bg_color TEXT DEFAULT '#3B82F6';

-- Create function to generate random color
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

-- Create trigger to set random color on new modules
CREATE OR REPLACE FUNCTION set_module_color()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.bg_color IS NULL THEN
        NEW.bg_color := generate_module_color();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS set_module_color_trigger ON modules;

-- Create new trigger
CREATE TRIGGER set_module_color_trigger
    BEFORE INSERT ON modules
    FOR EACH ROW
    EXECUTE FUNCTION set_module_color();

-- Set colors for existing modules
UPDATE modules 
SET bg_color = generate_module_color()
WHERE bg_color IS NULL;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;