-- Fix schema and add multi-company features
BEGIN;

-- Drop existing tables to rebuild with correct relationships
DROP TABLE IF EXISTS lesson_progress CASCADE;
DROP TABLE IF EXISTS lesson_ratings CASCADE;
DROP TABLE IF EXISTS quizzes CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS modules CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS user_group_members CASCADE;
DROP TABLE IF EXISTS user_groups CASCADE;
DROP TABLE IF EXISTS companies CASCADE;
DROP TABLE IF EXISTS workflow_settings CASCADE;
DROP TABLE IF EXISTS email_templates CASCADE;
DROP TABLE IF EXISTS live_events CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;

-- Create companies table
CREATE TABLE companies (
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

-- Create departments table
CREATE TABLE departments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, name)
);

-- Create categories table
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(department_id, name)
);

-- Create modules table (formerly courses)
CREATE TABLE modules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  video_url TEXT,
  is_featured BOOLEAN DEFAULT false,
  order_num INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create lessons table
CREATE TABLE lessons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  module_id UUID REFERENCES modules(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  video_url TEXT NOT NULL,
  order_num INTEGER NOT NULL,
  duration INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(module_id, order_num)
);

-- Create quizzes table
CREATE TABLE quizzes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
  questions JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(lesson_id)
);

-- Create lesson_progress table
CREATE TABLE lesson_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
  completed BOOLEAN DEFAULT FALSE,
  score NUMERIC(4,2),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, lesson_id)
);

-- Create lesson_ratings table
CREATE TABLE lesson_ratings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(lesson_id, user_id)
);

-- Create user_groups table
CREATE TABLE user_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  permissions JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, name)
);

-- Create user_group_members table
CREATE TABLE user_group_members (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  group_id UUID REFERENCES user_groups(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, group_id)
);

-- Create live_events table
CREATE TABLE live_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  instructor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  meeting_url TEXT NOT NULL,
  starts_at TIMESTAMPTZ NOT NULL,
  duration INTEGER NOT NULL,
  attendees_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create email_templates table
CREATE TABLE email_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  subject TEXT NOT NULL,
  content TEXT NOT NULL,
  variables JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, name)
);

-- Create workflow_settings table
CREATE TABLE workflow_settings (
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

-- Add company_id to auth.users
ALTER TABLE auth.users 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id);

-- Create indexes
CREATE INDEX idx_users_company ON auth.users(company_id);
CREATE INDEX idx_departments_company ON departments(company_id);
CREATE INDEX idx_categories_department ON categories(department_id);
CREATE INDEX idx_modules_category ON modules(category_id);
CREATE INDEX idx_modules_company ON modules(company_id);
CREATE INDEX idx_lessons_module ON lessons(module_id);
CREATE INDEX idx_progress_user ON lesson_progress(user_id);
CREATE INDEX idx_progress_lesson ON lesson_progress(lesson_id);
CREATE INDEX idx_ratings_lesson ON lesson_ratings(lesson_id);
CREATE INDEX idx_groups_company ON user_groups(company_id);
CREATE INDEX idx_live_events_company ON live_events(company_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_templates_company ON email_templates(company_id);

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

-- Enable RLS on all tables
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_settings ENABLE ROW LEVEL SECURITY;

-- Create policies for all tables
CREATE POLICY "Master admin can manage companies"
ON companies FOR ALL
USING (is_master_admin());

CREATE POLICY "Company admins can view their company"
ON companies FOR SELECT
USING (id = get_user_company_id());

-- Department policies
CREATE POLICY "Company admins can manage departments"
ON departments FOR ALL
USING (
  company_id = get_user_company_id() 
  AND (is_company_admin() OR is_master_admin())
);

CREATE POLICY "Users can view departments"
ON departments FOR SELECT
USING (company_id = get_user_company_id());

-- Category policies
CREATE POLICY "Company admins can manage categories"
ON categories FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM departments d
    WHERE d.id = department_id
    AND d.company_id = get_user_company_id()
    AND (is_company_admin() OR is_master_admin())
  )
);

CREATE POLICY "Users can view categories"
ON categories FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM departments d
    WHERE d.id = department_id
    AND d.company_id = get_user_company_id()
  )
);

-- Module policies
CREATE POLICY "Company admins can manage modules"
ON modules FOR ALL
USING (
  company_id = get_user_company_id() 
  AND (is_company_admin() OR is_master_admin())
);

CREATE POLICY "Users can view modules"
ON modules FOR SELECT
USING (company_id = get_user_company_id());

-- Lesson policies
CREATE POLICY "Company admins can manage lessons"
ON lessons FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM modules m
    WHERE m.id = module_id
    AND m.company_id = get_user_company_id()
    AND (is_company_admin() OR is_master_admin())
  )
);

CREATE POLICY "Users can view lessons"
ON lessons FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM modules m
    WHERE m.id = module_id
    AND m.company_id = get_user_company_id()
  )
);

-- Quiz policies
CREATE POLICY "Company admins can manage quizzes"
ON quizzes FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM lessons l
    JOIN modules m ON l.module_id = m.id
    WHERE l.id = lesson_id
    AND m.company_id = get_user_company_id()
    AND (is_company_admin() OR is_master_admin())
  )
);

CREATE POLICY "Users can view quizzes"
ON quizzes FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM lessons l
    JOIN modules m ON l.module_id = m.id
    WHERE l.id = lesson_id
    AND m.company_id = get_user_company_id()
  )
);

-- Progress policies
CREATE POLICY "Users can manage their own progress"
ON lesson_progress FOR ALL
USING (
  auth.uid() = user_id
  OR is_company_admin()
  OR is_master_admin()
);

-- Rating policies
CREATE POLICY "Users can manage their own ratings"
ON lesson_ratings FOR ALL
USING (
  auth.uid() = user_id
  OR is_company_admin()
  OR is_master_admin()
);

-- Group policies
CREATE POLICY "Company admins can manage groups"
ON user_groups FOR ALL
USING (
  company_id = get_user_company_id() 
  AND (is_company_admin() OR is_master_admin())
);

CREATE POLICY "Users can view groups"
ON user_groups FOR SELECT
USING (company_id = get_user_company_id());

-- Group members policies
CREATE POLICY "Company admins can manage group members"
ON user_group_members FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_groups g
    WHERE g.id = group_id
    AND g.company_id = get_user_company_id()
    AND (is_company_admin() OR is_master_admin())
  )
);

-- Live events policies
CREATE POLICY "Company admins can manage live events"
ON live_events FOR ALL
USING (
  company_id = get_user_company_id() 
  AND (is_company_admin() OR is_master_admin())
);

CREATE POLICY "Users can view live events"
ON live_events FOR SELECT
USING (company_id = get_user_company_id());

-- Notification policies
CREATE POLICY "Users can manage their own notifications"
ON notifications FOR ALL
USING (auth.uid() = user_id);

-- Email template policies
CREATE POLICY "Company admins can manage email templates"
ON email_templates FOR ALL
USING (
  company_id = get_user_company_id() 
  AND (is_company_admin() OR is_master_admin())
);

-- Workflow settings policies
CREATE POLICY "Company admins can manage workflow settings"
ON workflow_settings FOR ALL
USING (
  company_id = get_user_company_id() 
  AND (is_company_admin() OR is_master_admin())
);

-- Create default company
INSERT INTO companies (id, name, cnpj, email)
VALUES (
  'c0000000-0000-0000-0000-000000000000',
  'Default Company',
  '00000000000000',
  'admin@example.com'
) ON CONFLICT (cnpj) DO NOTHING;

-- Set master admin
UPDATE auth.users
SET 
  raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"master_admin"'
  ),
  company_id = 'c0000000-0000-0000-0000-000000000000'
WHERE email = 'diegodemontevpj@gmail.com';

-- Update existing users
UPDATE auth.users
SET company_id = 'c0000000-0000-0000-0000-000000000000'
WHERE company_id IS NULL;

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Set default role to 'user' if not specified
  IF NEW.raw_user_meta_data->>'role' IS NULL THEN
    NEW.raw_user_meta_data = jsonb_set(
      COALESCE(NEW.raw_user_meta_data, '{}'::jsonb),
      '{role}',
      '"user"'
    );
  END IF;

  -- Set default company if not specified
  IF NEW.company_id IS NULL THEN
    NEW.company_id = 'c0000000-0000-0000-0000-000000000000';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;