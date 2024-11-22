-- Fix infinite recursion in contract policies
BEGIN;

-- Drop existing policies to recreate them without recursion
DROP POLICY IF EXISTS "Users can view signatories" ON contract_signatories;
DROP POLICY IF EXISTS "Users can view their contracts" ON contracts;

-- Create new non-recursive policies
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

CREATE POLICY "Users can view their contracts"
    ON contracts FOR SELECT
    USING (
        created_by = auth.uid()
        OR id IN (
            SELECT contract_id 
            FROM contract_signatories 
            WHERE user_id = auth.uid()
            OR email = (SELECT email FROM auth.users WHERE id = auth.uid())
        )
        OR is_admin()
    );

-- Create policy for contract creation
CREATE POLICY "Users can create contracts"
    ON contracts FOR INSERT
    WITH CHECK (auth.uid() = created_by);

-- Create policy for contract updates
CREATE POLICY "Users can update their contracts"
    ON contracts FOR UPDATE
    USING (
        created_by = auth.uid()
        OR is_admin()
    );

-- Create policy for contract deletion
CREATE POLICY "Users can delete their contracts"
    ON contracts FOR DELETE
    USING (
        created_by = auth.uid()
        OR is_admin()
    );

-- Create policy for signatory creation
CREATE POLICY "Contract creators can add signatories"
    ON contract_signatories FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE id = contract_id
            AND created_by = auth.uid()
        )
        OR is_admin()
    );

-- Create policy for signatory updates
CREATE POLICY "Contract creators can update signatories"
    ON contract_signatories FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE id = contract_id
            AND created_by = auth.uid()
        )
        OR is_admin()
    );

-- Create policy for signatory deletion
CREATE POLICY "Contract creators can delete signatories"
    ON contract_signatories FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE id = contract_id
            AND created_by = auth.uid()
        )
        OR is_admin()
    );

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;