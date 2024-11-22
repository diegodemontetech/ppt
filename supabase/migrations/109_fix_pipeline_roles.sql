-- Fix pipeline roles and permissions
BEGIN;

-- First create all tables if they don't exist
CREATE TABLE IF NOT EXISTS pipeline_departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(department_id)
);

CREATE TABLE IF NOT EXISTS pipelines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    color TEXT DEFAULT '#3B82F6',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pipeline_stages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID REFERENCES pipelines(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    order_num INTEGER NOT NULL,
    sla_hours INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(pipeline_id, order_num)
);

CREATE TABLE IF NOT EXISTS pipeline_fields (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID REFERENCES pipelines(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    label TEXT NOT NULL,
    type TEXT NOT NULL,
    mask TEXT,
    options JSONB,
    validation_rules JSONB,
    show_on_card BOOLEAN DEFAULT false,
    order_num INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pipeline_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID REFERENCES pipelines(id) ON DELETE CASCADE,
    stage_id UUID REFERENCES pipeline_stages(id) ON DELETE CASCADE,
    assigned_to UUID[] DEFAULT '{}',
    title TEXT NOT NULL,
    data JSONB NOT NULL DEFAULT '{}',
    order_num INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pipeline_card_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    card_id UUID REFERENCES pipeline_cards(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    old_data JSONB,
    new_data JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pipeline_automations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID REFERENCES pipelines(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    trigger_type TEXT NOT NULL,
    trigger_config JSONB NOT NULL,
    action_type TEXT NOT NULL,
    action_config JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_pipeline_departments_dept ON pipeline_departments(department_id);
CREATE INDEX IF NOT EXISTS idx_pipelines_department ON pipelines(department_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_stages_pipeline ON pipeline_stages(pipeline_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_fields_pipeline ON pipeline_fields(pipeline_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_cards_pipeline ON pipeline_cards(pipeline_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_cards_stage ON pipeline_cards(stage_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_cards_assigned ON pipeline_cards USING gin(assigned_to);
CREATE INDEX IF NOT EXISTS idx_pipeline_card_history_card ON pipeline_card_history(card_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_automations_pipeline ON pipeline_automations(pipeline_id);

-- Now create roles
DO $$ 
BEGIN
  -- Create pipeline_viewer role
  IF NOT EXISTS (
    SELECT FROM pg_roles WHERE rolname = 'pipeline_viewer'
  ) THEN
    CREATE ROLE pipeline_viewer;
  END IF;

  -- Create pipeline_user role
  IF NOT EXISTS (
    SELECT FROM pg_roles WHERE rolname = 'pipeline_user'
  ) THEN
    CREATE ROLE pipeline_user;
  END IF;

  -- Create pipeline_admin role
  IF NOT EXISTS (
    SELECT FROM pg_roles WHERE rolname = 'pipeline_admin'
  ) THEN
    CREATE ROLE pipeline_admin;
  END IF;
END $$;

-- Grant appropriate permissions to roles
DO $$ 
BEGIN
  -- Pipeline viewer permissions
  GRANT USAGE ON SCHEMA public TO pipeline_viewer;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO pipeline_viewer;
  
  -- Pipeline user permissions
  GRANT pipeline_viewer TO pipeline_user;
  GRANT INSERT, UPDATE ON pipeline_cards TO pipeline_user;
  GRANT INSERT ON pipeline_card_history TO pipeline_user;
  
  -- Pipeline admin permissions
  GRANT pipeline_user TO pipeline_admin;
  GRANT ALL ON ALL TABLES IN SCHEMA public TO pipeline_admin;
END $$;

-- Create function to check pipeline permissions
CREATE OR REPLACE FUNCTION check_pipeline_permission(
  user_id UUID,
  pipeline_id UUID,
  permission TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM user_groups ug
    JOIN user_group_members ugm ON ug.id = ugm.group_id
    WHERE ugm.user_id = check_pipeline_permission.user_id
    AND (
      ug.pipeline_permissions->>'view_all_cards' = 'true'
      OR pipeline_id = ANY(
        ARRAY(
          SELECT jsonb_array_elements_text(ug.pipeline_permissions->'departments')::UUID
        )
      )
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE pipeline_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipelines ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_card_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_automations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Pipeline department access"
ON pipeline_departments
FOR ALL
USING (
  is_active = true
  AND (
    is_admin()
    OR check_pipeline_permission(auth.uid(), department_id, 'view')
  )
);

CREATE POLICY "Pipeline access"
ON pipelines
FOR ALL
USING (
  is_active = true
  AND (
    is_admin()
    OR check_pipeline_permission(auth.uid(), id, 'view')
  )
);

CREATE POLICY "Pipeline stage access"
ON pipeline_stages
FOR ALL
USING (
  is_active = true
  AND (
    is_admin()
    OR check_pipeline_permission(auth.uid(), pipeline_id, 'view')
  )
);

CREATE POLICY "Pipeline field access"
ON pipeline_fields
FOR ALL
USING (
  is_active = true
  AND (
    is_admin()
    OR check_pipeline_permission(auth.uid(), pipeline_id, 'view')
  )
);

CREATE POLICY "Pipeline card access"
ON pipeline_cards
FOR ALL
USING (
  is_active = true
  AND (
    is_admin()
    OR auth.uid() = ANY(assigned_to)
    OR check_pipeline_permission(auth.uid(), pipeline_id, 'view_all_cards')
  )
);

CREATE POLICY "Pipeline card history access"
ON pipeline_card_history
FOR SELECT
USING (
  is_admin()
  OR EXISTS (
    SELECT 1 FROM pipeline_cards pc
    WHERE pc.id = card_id
    AND (
      auth.uid() = ANY(pc.assigned_to)
      OR check_pipeline_permission(auth.uid(), pc.pipeline_id, 'view_all_cards')
    )
  )
);

CREATE POLICY "Pipeline automation access"
ON pipeline_automations
FOR ALL
USING (
  is_active = true
  AND (
    is_admin()
    OR check_pipeline_permission(auth.uid(), pipeline_id, 'manage_automations')
  )
);

-- Add pipeline permissions to user_groups if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'user_groups' 
    AND column_name = 'pipeline_permissions'
  ) THEN
    ALTER TABLE user_groups
    ADD COLUMN pipeline_permissions JSONB DEFAULT '{
      "departments": [],
      "view_all_cards": false,
      "manage_all_cards": false,
      "manage_automations": false
    }'::jsonb;
  END IF;
END $$;

-- Create function to sync user roles
CREATE OR REPLACE FUNCTION sync_pipeline_roles()
RETURNS TRIGGER AS $$
BEGIN
  -- Revoke all pipeline roles first
  REVOKE pipeline_viewer, pipeline_user, pipeline_admin FROM NEW.id;
  
  -- Grant appropriate role based on permissions
  IF NEW.raw_user_meta_data->>'role' = 'admin' THEN
    GRANT pipeline_admin TO NEW.id;
  ELSIF EXISTS (
    SELECT 1 FROM user_groups ug
    JOIN user_group_members ugm ON ug.id = ugm.group_id
    WHERE ugm.user_id = NEW.id
    AND (
      ug.pipeline_permissions->>'manage_all_cards' = 'true'
      OR ug.pipeline_permissions->>'manage_automations' = 'true'
    )
  ) THEN
    GRANT pipeline_user TO NEW.id;
  ELSE
    GRANT pipeline_viewer TO NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for role sync
DROP TRIGGER IF EXISTS sync_pipeline_roles_trigger ON auth.users;
CREATE TRIGGER sync_pipeline_roles_trigger
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_pipeline_roles();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;