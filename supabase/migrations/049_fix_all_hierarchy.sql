-- Fix all issues and implement complete hierarchy
BEGIN;

-- Create departments table
CREATE TABLE IF NOT EXISTS departments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, name)
);

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(department_id, name)
);

-- Modify courses table to be modules
ALTER TABLE courses 
  RENAME TO modules;

ALTER TABLE modules
  ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES categories(id),
  ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id),
  ADD COLUMN IF NOT EXISTS order_num INTEGER DEFAULT 0;

-- Rename courses references in other tables
ALTER TABLE lessons
  DROP CONSTRAINT IF EXISTS lessons_course_id_fkey,
  RENAME COLUMN course_id TO module_id;

ALTER TABLE lessons
  ADD CONSTRAINT lessons_module_id_fkey 
  FOREIGN KEY (module_id) 
  REFERENCES modules(id) 
  ON DELETE CASCADE;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_departments_company ON departments(company_id);
CREATE INDEX IF NOT EXISTS idx_categories_department ON categories(department_id);
CREATE INDEX IF NOT EXISTS idx_modules_category ON modules(category_id);
CREATE INDEX IF NOT EXISTS idx_modules_company ON modules(company_id);
CREATE INDEX IF NOT EXISTS idx_lessons_module ON lessons(module_id);

-- Enable RLS
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;

-- Create policies for departments
CREATE POLICY "Admin can manage departments"
  ON departments FOR ALL
  USING (
    company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'admin'
    )
  );

CREATE POLICY "Users can view departments"
  ON departments FOR SELECT
  USING (
    company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
  );

-- Create policies for categories
CREATE POLICY "Admin can manage categories"
  ON categories FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM departments d
      WHERE d.id = department_id
      AND d.company_id = (
        SELECT company_id 
        FROM auth.users 
        WHERE id = auth.uid()
      )
      AND EXISTS (
        SELECT 1 FROM auth.users
        WHERE id = auth.uid()
        AND raw_user_meta_data->>'role' = 'admin'
      )
    )
  );

CREATE POLICY "Users can view categories"
  ON categories FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM departments d
      WHERE d.id = department_id
      AND d.company_id = (
        SELECT company_id 
        FROM auth.users 
        WHERE id = auth.uid()
      )
    )
  );

-- Create policies for modules
CREATE POLICY "Admin can manage modules"
  ON modules FOR ALL
  USING (
    company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'admin'
    )
  );

CREATE POLICY "Users can view modules"
  ON modules FOR SELECT
  USING (
    company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
  );

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for timestamps
CREATE TRIGGER update_departments_timestamp
  BEFORE UPDATE ON departments
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_categories_timestamp
  BEFORE UPDATE ON categories
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_modules_timestamp
  BEFORE UPDATE ON modules
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

-- Fix ranking function
DROP FUNCTION IF EXISTS get_user_ranking(integer);
CREATE FUNCTION get_user_ranking(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
  id UUID,
  full_name TEXT,
  points INTEGER,
  level INTEGER,
  company_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    COALESCE(u.raw_user_meta_data->>'full_name', u.email) as full_name,
    COALESCE((u.raw_user_meta_data->>'points')::INTEGER, 0) as points,
    COALESCE((u.raw_user_meta_data->>'level')::INTEGER, 1) as level,
    u.company_id
  FROM auth.users u
  WHERE 
    u.company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
  ORDER BY (u.raw_user_meta_data->>'points')::INTEGER DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create default company if not exists
INSERT INTO companies (id, name, cnpj, email)
VALUES (
  'c0000000-0000-0000-0000-000000000000',
  'Default Company',
  '00000000000000',
  'admin@example.com'
) ON CONFLICT (cnpj) DO NOTHING;

-- Update existing users to use default company
UPDATE auth.users
SET company_id = 'c0000000-0000-0000-0000-000000000000'
WHERE company_id IS NULL;

-- Update existing modules to use default company
UPDATE modules
SET company_id = 'c0000000-0000-0000-0000-000000000000'
WHERE company_id IS NULL;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;