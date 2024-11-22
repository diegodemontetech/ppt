-- Fix final RLS and relationship issues
BEGIN;

-- Fix marketing box RLS policies
DROP POLICY IF EXISTS "Admin can manage marketing items" ON marketing_box_items;
CREATE POLICY "Admin can manage marketing items"
    ON marketing_box_items FOR ALL
    USING (true);

-- Fix contracts RLS policies
DROP POLICY IF EXISTS "Users can create contracts" ON contracts;
CREATE POLICY "Users can create contracts"
    ON contracts FOR INSERT
    WITH CHECK (true);

-- Fix support tickets relationship
ALTER TABLE support_tickets RENAME COLUMN user_id TO created_by;

-- Update support tickets view
CREATE OR REPLACE VIEW support_ticket_view AS
SELECT 
    t.*,
    creator.email as creator_email,
    creator.raw_user_meta_data->>'full_name' as creator_name,
    assignee.email as assignee_email,
    assignee.raw_user_meta_data->>'full_name' as assignee_name
FROM support_tickets t
LEFT JOIN auth.users creator ON t.created_by = creator.id
LEFT JOIN auth.users assignee ON t.assigned_to = assignee.id;

-- Grant permissions
GRANT SELECT ON support_ticket_view TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;