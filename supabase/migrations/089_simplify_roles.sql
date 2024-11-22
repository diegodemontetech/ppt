-- Simplify roles and remove instructor requirement
BEGIN;

-- Update existing users to have simpler roles
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  raw_user_meta_data,
  '{role}',
  '"user"'
)
WHERE raw_user_meta_data->>'role' NOT IN ('admin', 'master_admin');

-- Set specific admin
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  raw_user_meta_data,
  '{role}',
  '"admin"'
)
WHERE email = 'diegodemontevpj@gmail.com';

-- Remove instructor_id constraint from live_events
ALTER TABLE live_events
DROP CONSTRAINT IF EXISTS live_events_instructor_id_fkey,
ALTER COLUMN instructor_id TYPE UUID
USING instructor_id::UUID;

-- Add new constraint referencing auth.users
ALTER TABLE live_events
ADD CONSTRAINT live_events_instructor_id_fkey
FOREIGN KEY (instructor_id)
REFERENCES auth.users(id)
ON DELETE CASCADE;

COMMIT;