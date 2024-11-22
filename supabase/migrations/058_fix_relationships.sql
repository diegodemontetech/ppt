-- Fix relationships between tables
BEGIN;

-- First, ensure we have the auth.users reference
ALTER TABLE live_events 
  DROP CONSTRAINT IF EXISTS live_events_instructor_id_fkey,
  ADD CONSTRAINT live_events_instructor_id_fkey 
  FOREIGN KEY (instructor_id) 
  REFERENCES auth.users(id) 
  ON DELETE CASCADE;

-- Add missing indexes
CREATE INDEX IF NOT EXISTS idx_live_events_instructor ON live_events(instructor_id);
CREATE INDEX IF NOT EXISTS idx_auth_users_id ON auth.users(id);

-- Refresh the schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;