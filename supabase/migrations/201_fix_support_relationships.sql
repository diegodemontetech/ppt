-- Fix support tickets relationships
BEGIN;

-- Drop existing foreign key constraints
ALTER TABLE support_tickets 
DROP CONSTRAINT IF EXISTS support_tickets_created_by_fkey,
DROP CONSTRAINT IF EXISTS support_tickets_assigned_to_fkey;

-- Recreate foreign key constraints with correct schema reference
ALTER TABLE support_tickets
ADD CONSTRAINT support_tickets_created_by_fkey 
  FOREIGN KEY (created_by) 
  REFERENCES auth.users(id) 
  ON DELETE CASCADE,
ADD CONSTRAINT support_tickets_assigned_to_fkey 
  FOREIGN KEY (assigned_to) 
  REFERENCES auth.users(id) 
  ON DELETE SET NULL;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;