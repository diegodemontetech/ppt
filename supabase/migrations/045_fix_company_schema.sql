-- Fix company schema and relations
BEGIN;

-- Create companies table if it doesn't exist
CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  cnpj TEXT UNIQUE NOT NULL,
  logo_url TEXT,
  favicon_url TEXT,
  domain TEXT,
  email TEXT,
  address TEXT,
  max_users INTEGER NOT NULL DEFAULT 10,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Add company_id to auth.users if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'auth' 
    AND table_name = 'users' 
    AND column_name = 'company_id'
  ) THEN
    ALTER TABLE auth.users ADD COLUMN company_id UUID REFERENCES companies(id);
  END IF;
END $$;

-- Add company_id to courses if it doesn't exist
ALTER TABLE courses 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id);

-- Create default company
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

-- Update existing courses to use default company
UPDATE courses
SET company_id = 'c0000000-0000-0000-0000-000000000000'
WHERE company_id IS NULL;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_company ON auth.users(company_id);
CREATE INDEX IF NOT EXISTS idx_courses_company ON courses(company_id);

-- Enable RLS
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- Create policies
DROP POLICY IF EXISTS "Users can view their company" ON companies;
CREATE POLICY "Users can view their company"
ON companies FOR SELECT
USING (id IN (
  SELECT company_id 
  FROM auth.users 
  WHERE auth.uid() = id
));

DROP POLICY IF EXISTS "Admin can manage companies" ON companies;
CREATE POLICY "Admin can manage companies"
ON companies FOR ALL
USING (
  EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'role' = 'admin'
  )
);

-- Update courses policies to include company check
DROP POLICY IF EXISTS "Admin full access" ON courses;
CREATE POLICY "Admin full access"
ON courses FOR ALL
USING (
  EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'role' = 'admin'
    AND users.company_id = courses.company_id
  )
);

DROP POLICY IF EXISTS "Users view courses" ON courses;
CREATE POLICY "Users view courses"
ON courses FOR SELECT
USING (
  EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE id = auth.uid() 
    AND users.company_id = courses.company_id
  )
);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;