-- Fix E-Sign policies to prevent recursion
BEGIN;

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view their contracts" ON contracts;
DROP POLICY IF EXISTS "Users can create contracts" ON contracts;
DROP POLICY IF EXISTS "Users can update their contracts" ON contracts;
DROP POLICY IF EXISTS "Users can delete their contracts" ON contracts;
DROP POLICY IF EXISTS "Users can view signatories" ON contract_signatories;
DROP POLICY IF EXISTS "Users can manage signatories" ON contract_signatories;

-- Create simplified base policies for contracts
CREATE POLICY "Users can view contracts"
    ON contracts FOR SELECT
    USING (
        created_by = auth.uid()
        OR id IN (
            SELECT contract_id 
            FROM contract_signatories 
            WHERE user_id = auth.uid()
            OR email = (SELECT email FROM auth.users WHERE id = auth.uid())
        )
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Users can create contracts"
    ON contracts FOR INSERT
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update contracts"
    ON contracts FOR UPDATE
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Users can delete contracts"
    ON contracts FOR DELETE
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Create simplified policies for signatories
CREATE POLICY "View signatories"
    ON contract_signatories FOR SELECT
    USING (
        user_id = auth.uid()
        OR email = (SELECT email FROM auth.users WHERE id = auth.uid())
        OR EXISTS (
            SELECT 1 FROM contracts
            WHERE id = contract_id
            AND created_by = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Manage signatories"
    ON contract_signatories FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE id = contract_id
            AND created_by = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;