-- Fix infinite recursion in contract policies
BEGIN;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view signatories" ON contract_signatories;
DROP POLICY IF EXISTS "Users can manage signatories" ON contract_signatories;
DROP POLICY IF EXISTS "Users can view their contracts" ON contracts;
DROP POLICY IF EXISTS "Users can create contracts" ON contracts;
DROP POLICY IF EXISTS "Users can update their contracts" ON contracts;

-- Create base policy for contracts first
CREATE POLICY "Contract access"
    ON contracts FOR ALL
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM contract_signatories cs
            WHERE cs.contract_id = id
            AND (cs.user_id = auth.uid() OR cs.email = (SELECT email FROM auth.users WHERE id = auth.uid()))
        )
        OR is_admin()
    );

-- Create simple policy for signatories
CREATE POLICY "Signatory access"
    ON contract_signatories FOR ALL
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

-- Create function to check contract access without recursion
CREATE OR REPLACE FUNCTION can_access_contract(contract_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM contracts c
        WHERE c.id = contract_uuid
        AND (
            c.created_by = auth.uid()
            OR EXISTS (
                SELECT 1 FROM contract_signatories cs
                WHERE cs.contract_id = c.id
                AND (cs.user_id = auth.uid() OR cs.email = (SELECT email FROM auth.users WHERE id = auth.uid()))
            )
            OR is_admin()
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;