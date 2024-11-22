-- Fix contract signatories RLS policy
BEGIN;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view signatories" ON contract_signatories;
DROP POLICY IF EXISTS "Users can manage signatories" ON contract_signatories;

-- Create new policies
CREATE POLICY "Users can view signatories"
    ON contract_signatories FOR SELECT
    USING (
        user_id = auth.uid()
        OR email = (SELECT email FROM auth.users WHERE id = auth.uid())
        OR EXISTS (
            SELECT 1 FROM contracts c
            WHERE c.id = contract_id
            AND c.created_by = auth.uid()
        )
        OR is_admin()
    );

CREATE POLICY "Users can manage signatories"
    ON contract_signatories FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM contracts c
            WHERE c.id = contract_id
            AND (
                c.created_by = auth.uid()
                OR is_admin()
            )
        )
    );

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;