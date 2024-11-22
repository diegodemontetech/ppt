-- Fix infinite recursion in contract policies
BEGIN;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view signatories" ON contract_signatories;
DROP POLICY IF EXISTS "Users can view their contracts" ON contracts;
DROP POLICY IF EXISTS "Contract creators can add signatories" ON contract_signatories;
DROP POLICY IF EXISTS "Contract creators can update signatories" ON contract_signatories;
DROP POLICY IF EXISTS "Contract creators can delete signatories" ON contract_signatories;

-- Create base policy for contracts first
CREATE POLICY "Users can view their contracts"
    ON contracts FOR SELECT
    USING (
        created_by = auth.uid()
        OR is_admin()
    );

-- Create policy for contract signatories that doesn't cause recursion
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

-- Create policy for signatory management
CREATE POLICY "Users can manage signatories"
    ON contract_signatories FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM contracts c
            WHERE c.id = contract_id
            AND c.created_by = auth.uid()
        )
        OR is_admin()
    );

-- Create function to check contract access
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
                AND (
                    cs.user_id = auth.uid()
                    OR cs.email = (SELECT email FROM auth.users WHERE id = auth.uid())
                )
            )
            OR is_admin()
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check signatory access
CREATE OR REPLACE FUNCTION can_manage_signatory(signatory_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM contract_signatories cs
        JOIN contracts c ON cs.contract_id = c.id
        WHERE cs.id = signatory_uuid
        AND (
            c.created_by = auth.uid()
            OR is_admin()
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;