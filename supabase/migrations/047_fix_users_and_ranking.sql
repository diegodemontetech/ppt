-- Fix users and ranking
BEGIN;

-- Add full_name to users metadata if missing
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{full_name}',
  to_jsonb(COALESCE(raw_user_meta_data->>'full_name', email))
)
WHERE raw_user_meta_data->>'full_name' IS NULL;

-- Create or replace ranking function with company filter
CREATE OR REPLACE FUNCTION get_user_ranking(limit_count INTEGER DEFAULT 10)
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

-- Create user groups table
CREATE TABLE IF NOT EXISTS user_groups (
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
CREATE TABLE IF NOT EXISTS user_group_members (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  group_id UUID REFERENCES user_groups(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, group_id)
);

-- Add RLS policies for groups
ALTER TABLE user_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_group_members ENABLE ROW LEVEL SECURITY;

-- Group policies
CREATE POLICY "Admin can manage groups"
  ON user_groups FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'admin'
      AND users.company_id = user_groups.company_id
    )
  );

CREATE POLICY "Users can view groups"
  ON user_groups FOR SELECT
  USING (
    company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
  );

-- Group members policies
CREATE POLICY "Admin can manage group members"
  ON user_group_members FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'admin'
    )
  );

CREATE POLICY "Users can view group members"
  ON user_group_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_groups g
      WHERE g.id = group_id
      AND g.company_id = (
        SELECT company_id 
        FROM auth.users 
        WHERE id = auth.uid()
      )
    )
  );

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_groups_company ON user_groups(company_id);
CREATE INDEX IF NOT EXISTS idx_user_group_members_user ON user_group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_user_group_members_group ON user_group_members(group_id);

COMMIT;