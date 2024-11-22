-- Fix E-Sign policies with simplified approach
BEGIN;

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view contracts" ON contracts;
DROP POLICY IF EXISTS "Users can create contracts" ON contracts;
DROP POLICY IF EXISTS "Users can update contracts" ON contracts;
DROP POLICY IF EXISTS "Users can delete contracts" ON contracts;
DROP POLICY IF EXISTS "View signatories" ON contract_signatories;
DROP POLICY IF EXISTS "Manage signatories" ON contract_signatories;

-- Create simple policy for contracts
CREATE POLICY "Contract access"
    ON contracts FOR ALL
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Create simple policy for signatories
CREATE POLICY "Signatory access"
    ON contract_signatories FOR ALL
    USING (
        user_id = auth.uid()
        OR email = (SELECT email FROM auth.users WHERE id = auth.uid())
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;