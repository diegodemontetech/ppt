-- Fix duplicate policies and add thumbnail colors
BEGIN;

-- Drop existing policies first
DROP POLICY IF EXISTS "Users view modules" ON modules;
DROP POLICY IF EXISTS "Admin full access modules" ON modules;

-- Create new policies
CREATE POLICY "Admin full access modules"
    ON modules FOR ALL
    USING (is_admin());

CREATE POLICY "Users view modules"
    ON modules FOR SELECT
    USING (true);

-- Add color field to modules
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

-- Set random colors for existing modules
UPDATE modules 
SET bg_color = generate_module_color()
WHERE bg_color IS NULL;

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

CREATE TRIGGER set_module_color_trigger
    BEFORE INSERT ON modules
    FOR EACH ROW
    EXECUTE FUNCTION set_module_color();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;