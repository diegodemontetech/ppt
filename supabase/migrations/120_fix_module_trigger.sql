-- Fix module trigger to remove department_id reference
BEGIN;

-- Drop existing trigger and functions
DROP TRIGGER IF EXISTS set_module_color_trigger ON modules;
DROP FUNCTION IF EXISTS set_module_color();
DROP FUNCTION IF EXISTS generate_module_color();

-- Recreate color generation function
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

-- Recreate trigger function without department_id reference
CREATE OR REPLACE FUNCTION set_module_color()
RETURNS TRIGGER AS $$
BEGIN
    -- Only set color if not provided
    IF NEW.bg_color IS NULL THEN
        NEW.bg_color := generate_module_color();
    END IF;
    
    -- Ensure category_id is provided
    IF NEW.category_id IS NULL THEN
        RAISE EXCEPTION 'category_id is required';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger
CREATE TRIGGER set_module_color_trigger
    BEFORE INSERT OR UPDATE ON modules
    FOR EACH ROW
    EXECUTE FUNCTION set_module_color();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;