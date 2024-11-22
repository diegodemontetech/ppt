-- Fix module schema
BEGIN;

-- Drop existing foreign key if exists
ALTER TABLE modules
DROP CONSTRAINT IF EXISTS modules_department_id_fkey;

-- Drop department_id column if exists
ALTER TABLE modules
DROP COLUMN IF EXISTS department_id;

-- Add category_id if not exists
ALTER TABLE modules
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES categories(id);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_modules_category ON modules(category_id);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;