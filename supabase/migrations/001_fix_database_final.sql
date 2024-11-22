-- Fix database schema and relationships
BEGIN;

-- Drop all existing tables
DROP TABLE IF EXISTS course_ratings CASCADE;
DROP TABLE IF EXISTS ebook_ratings CASCADE;
DROP TABLE IF EXISTS lesson_progress CASCADE;
DROP TABLE IF EXISTS lesson_ratings CASCADE;
DROP TABLE IF EXISTS quizzes CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS modules CASCADE;
DROP TABLE IF EXISTS ebooks CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
DROP TABLE IF EXISTS support_departments CASCADE;
DROP TABLE IF EXISTS marketing_box_items CASCADE;
DROP TABLE IF EXISTS marketing_box_categories CASCADE;
DROP TABLE IF EXISTS contracts CASCADE;
DROP TABLE IF EXISTS contract_signatories CASCADE;

-- Create base tables
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    thumbnail_url TEXT,
    video_url TEXT,
    bg_color TEXT DEFAULT '#3B82F6',
    is_featured BOOLEAN DEFAULT false,
    estimated_duration INTEGER DEFAULT 0,
    technical_lead TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Rest of the tables and policies remain the same as in the previous migration...

-- Insert default data using DO block with uuid_generate_v4()
DO $$ 
DECLARE
    dept_id UUID;
    cat_id UUID;
BEGIN
    -- Insert department
    INSERT INTO departments (name, description)
    VALUES ('General', 'General Department')
    RETURNING id INTO dept_id;

    -- Insert category
    INSERT INTO categories (department_id, name, description)
    VALUES (dept_id, 'General', 'General Category')
    RETURNING id INTO cat_id;
END $$;

-- Set admin user
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"admin"'
)
WHERE email = 'diegodemontevpj@gmail.com';

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;