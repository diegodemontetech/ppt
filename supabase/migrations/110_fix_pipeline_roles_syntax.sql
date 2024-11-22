-- Fix pipeline roles syntax
BEGIN;

-- Drop previous function if exists
DROP FUNCTION IF EXISTS sync_pipeline_roles();

-- Create function to sync user roles with correct syntax
CREATE OR REPLACE FUNCTION sync_pipeline_roles()
RETURNS TRIGGER AS $$
DECLARE
  role_cmd text;
BEGIN
  -- Build dynamic SQL for role management
  role_cmd := format(
    'DO $$ BEGIN ' ||
    'REVOKE pipeline_viewer, pipeline_user, pipeline_admin FROM %I; ' ||
    'IF EXISTS (SELECT 1 FROM auth.users WHERE id = %L AND raw_user_meta_data->>''role'' = ''admin'') THEN ' ||
    '  GRANT pipeline_admin TO %I; ' ||
    'ELSIF EXISTS (SELECT 1 FROM user_groups ug JOIN user_group_members ugm ON ug.id = ugm.group_id ' ||
    '             WHERE ugm.user_id = %L AND (ug.pipeline_permissions->>''manage_all_cards'' = ''true'' ' ||
    '             OR ug.pipeline_permissions->>''manage_automations'' = ''true'')) THEN ' ||
    '  GRANT pipeline_user TO %I; ' ||
    'ELSE ' ||
    '  GRANT pipeline_viewer TO %I; ' ||
    'END IF; END $$;',
    NEW.email,  -- Use email as it's guaranteed to be unique
    NEW.id,
    NEW.email,
    NEW.id,
    NEW.email,
    NEW.email
  );

  -- Execute the dynamic SQL
  EXECUTE role_cmd;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS sync_pipeline_roles_trigger ON auth.users;
CREATE TRIGGER sync_pipeline_roles_trigger
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_pipeline_roles();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;