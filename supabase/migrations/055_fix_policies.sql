-- Fix policies
BEGIN;

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

-- Create admin check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' IN ('admin', 'master_admin')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing policies
DROP POLICY IF EXISTS "Admin full access" ON companies;
DROP POLICY IF EXISTS "Users view companies" ON companies;
DROP POLICY IF EXISTS "Admin full access" ON departments;
DROP POLICY IF EXISTS "Users view departments" ON departments;
DROP POLICY IF EXISTS "Admin full access" ON categories;
DROP POLICY IF EXISTS "Users view categories" ON categories;
DROP POLICY IF EXISTS "Admin full access" ON modules;
DROP POLICY IF EXISTS "Users view modules" ON modules;
DROP POLICY IF EXISTS "Admin full access" ON lessons;
DROP POLICY IF EXISTS "Users view lessons" ON lessons;
DROP POLICY IF EXISTS "Admin full access" ON quizzes;
DROP POLICY IF EXISTS "Users view quizzes" ON quizzes;
DROP POLICY IF EXISTS "Users manage own progress" ON lesson_progress;
DROP POLICY IF EXISTS "Users manage own ratings" ON lesson_ratings;
DROP POLICY IF EXISTS "Admin full access" ON user_groups;
DROP POLICY IF EXISTS "Users view groups" ON user_groups;
DROP POLICY IF EXISTS "Admin full access" ON user_group_members;
DROP POLICY IF EXISTS "Admin full access" ON live_events;
DROP POLICY IF EXISTS "Users view live events" ON live_events;
DROP POLICY IF EXISTS "Users manage own notifications" ON notifications;
DROP POLICY IF EXISTS "Admin full access" ON email_templates;
DROP POLICY IF EXISTS "Admin full access" ON workflow_settings;

-- Create policies for all tables
CREATE POLICY "Admin full access"
ON companies FOR ALL
USING (is_admin());

CREATE POLICY "Users view companies"
ON companies FOR SELECT
USING (id = (
  SELECT company_id 
  FROM auth.users 
  WHERE id = auth.uid()
));

-- Department policies
CREATE POLICY "Admin full access"
ON departments FOR ALL
USING (is_admin());

CREATE POLICY "Users view departments"
ON departments FOR SELECT
USING (company_id = (
  SELECT company_id 
  FROM auth.users 
  WHERE id = auth.uid()
));

-- Category policies
CREATE POLICY "Admin full access"
ON categories FOR ALL
USING (is_admin());

CREATE POLICY "Users view categories"
ON categories FOR SELECT
USING (EXISTS (
  SELECT 1 FROM departments d
  WHERE d.id = department_id
  AND d.company_id = (
    SELECT company_id 
    FROM auth.users 
    WHERE id = auth.uid()
  )
));

-- Module policies
CREATE POLICY "Admin full access"
ON modules FOR ALL
USING (is_admin());

CREATE POLICY "Users view modules"
ON modules FOR SELECT
USING (company_id = (
  SELECT company_id 
  FROM auth.users 
  WHERE id = auth.uid()
));

-- Lesson policies
CREATE POLICY "Admin full access"
ON lessons FOR ALL
USING (is_admin());

CREATE POLICY "Users view lessons"
ON lessons FOR SELECT
USING (EXISTS (
  SELECT 1 FROM modules m
  WHERE m.id = module_id
  AND m.company_id = (
    SELECT company_id 
    FROM auth.users 
    WHERE id = auth.uid()
  )
));

-- Quiz policies
CREATE POLICY "Admin full access"
ON quizzes FOR ALL
USING (is_admin());

CREATE POLICY "Users view quizzes"
ON quizzes FOR SELECT
USING (EXISTS (
  SELECT 1 FROM lessons l
  JOIN modules m ON l.module_id = m.id
  WHERE l.id = lesson_id
  AND m.company_id = (
    SELECT company_id 
    FROM auth.users 
    WHERE id = auth.uid()
  )
));

-- Progress policies
CREATE POLICY "Users manage own progress"
ON lesson_progress FOR ALL
USING (auth.uid() = user_id OR is_admin());

-- Rating policies
CREATE POLICY "Users manage own ratings"
ON lesson_ratings FOR ALL
USING (auth.uid() = user_id OR is_admin());

-- Group policies
CREATE POLICY "Admin full access"
ON user_groups FOR ALL
USING (is_admin());

CREATE POLICY "Users view groups"
ON user_groups FOR SELECT
USING (company_id = (
  SELECT company_id 
  FROM auth.users 
  WHERE id = auth.uid()
));

-- Group members policies
CREATE POLICY "Admin full access"
ON user_group_members FOR ALL
USING (is_admin());

-- Live events policies
CREATE POLICY "Admin full access"
ON live_events FOR ALL
USING (is_admin());

CREATE POLICY "Users view live events"
ON live_events FOR SELECT
USING (company_id = (
  SELECT company_id 
  FROM auth.users 
  WHERE id = auth.uid()
));

-- Notification policies
CREATE POLICY "Users manage own notifications"
ON notifications FOR ALL
USING (auth.uid() = user_id);

-- Email template policies
CREATE POLICY "Admin full access"
ON email_templates FOR ALL
USING (is_admin());

-- Workflow settings policies
CREATE POLICY "Admin full access"
ON workflow_settings FOR ALL
USING (is_admin());

COMMIT;