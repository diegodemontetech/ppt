-- Add company and enhanced features
BEGIN;

-- Create companies table
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

-- Add company_id to users
ALTER TABLE auth.users
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id);

-- Create user_groups table
CREATE TABLE IF NOT EXISTS user_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  permissions JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, name)
);

-- Create user_group_members table
CREATE TABLE IF NOT EXISTS user_group_members (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  group_id UUID REFERENCES user_groups(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, group_id)
);

-- Create news table
CREATE TABLE IF NOT EXISTS news (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_published BOOLEAN DEFAULT false,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create email_templates table
CREATE TABLE IF NOT EXISTS email_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  subject TEXT NOT NULL,
  content TEXT NOT NULL,
  variables JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, name)
);

-- Create workflow_settings table
CREATE TABLE IF NOT EXISTS workflow_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  smtp_host TEXT NOT NULL,
  smtp_port INTEGER NOT NULL,
  smtp_user TEXT NOT NULL,
  smtp_pass TEXT NOT NULL,
  from_email TEXT NOT NULL,
  from_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id)
);

-- Add company_id to existing tables
ALTER TABLE courses
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id),
ADD COLUMN IF NOT EXISTS group_ids UUID[] DEFAULT '{}';

ALTER TABLE live_events
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id);

-- Create function to check if user is master admin
CREATE OR REPLACE FUNCTION is_master_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' = 'master_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check if user is company admin
CREATE OR REPLACE FUNCTION is_company_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get user's company_id
CREATE OR REPLACE FUNCTION get_user_company_id()
RETURNS UUID AS $$
BEGIN
  RETURN (
    SELECT company_id
    FROM auth.users
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create policies for companies
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Master admins can manage companies"
ON companies FOR ALL
USING (is_master_admin());

CREATE POLICY "Company admins can view their company"
ON companies FOR SELECT
USING (id = get_user_company_id());

-- Create policies for user groups
ALTER TABLE user_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company admins can manage groups"
ON user_groups FOR ALL
USING (company_id = get_user_company_id() AND is_company_admin());

CREATE POLICY "Users can view their company's groups"
ON user_groups FOR SELECT
USING (company_id = get_user_company_id());

-- Create policies for news
ALTER TABLE news ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company admins can manage news"
ON news FOR ALL
USING (company_id = get_user_company_id() AND is_company_admin());

CREATE POLICY "Users can view published news"
ON news FOR SELECT
USING (
  company_id = get_user_company_id() 
  AND (is_published = true OR is_company_admin())
);

-- Create policies for email templates
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company admins can manage templates"
ON email_templates FOR ALL
USING (company_id = get_user_company_id() AND is_company_admin());

-- Create policies for workflow settings
ALTER TABLE workflow_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company admins can manage workflow"
ON workflow_settings FOR ALL
USING (company_id = get_user_company_id() AND is_company_admin());

-- Update existing policies for courses
DROP POLICY IF EXISTS "Admin full access" ON courses;
CREATE POLICY "Company admins can manage courses"
ON courses FOR ALL
USING (
  company_id = get_user_company_id() 
  AND (is_company_admin() OR is_master_admin())
);

CREATE POLICY "Users can view allowed courses"
ON courses FOR SELECT
USING (
  company_id = get_user_company_id()
  AND (
    cardinality(group_ids) = 0 
    OR EXISTS (
      SELECT 1 FROM user_group_members ugm
      WHERE ugm.user_id = auth.uid()
      AND ugm.group_id = ANY(courses.group_ids)
    )
  )
);

-- Create indexes for better performance
CREATE INDEX idx_users_company ON auth.users(company_id);
CREATE INDEX idx_courses_company ON courses(company_id);
CREATE INDEX idx_groups_company ON user_groups(company_id);
CREATE INDEX idx_news_company ON news(company_id);
CREATE INDEX idx_templates_company ON email_templates(company_id);

-- Set master admin
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"master_admin"'
)
WHERE email = 'diegodemontevpj@gmail.com';

COMMIT;