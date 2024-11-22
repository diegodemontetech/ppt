-- Fix contract policies with safe checks
BEGIN;

-- Function to check if policy exists
CREATE OR REPLACE FUNCTION policy_exists(
    policy_name TEXT,
    table_name TEXT,
    schema_name TEXT DEFAULT 'public'
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = schema_name
        AND tablename = table_name
        AND policyname = policy_name
    );
END;
$$ LANGUAGE plpgsql;

-- Drop existing policies safely
DO $$ 
BEGIN
    -- Contract policies
    DROP POLICY IF EXISTS "Users can view their contracts" ON contracts;
    DROP POLICY IF EXISTS "Users can create contracts" ON contracts;
    DROP POLICY IF EXISTS "Users can update their contracts" ON contracts;
    DROP POLICY IF EXISTS "Users can delete their contracts" ON contracts;

    -- Signatory policies
    DROP POLICY IF EXISTS "Users can view signatories" ON contract_signatories;
    DROP POLICY IF EXISTS "Contract creators can add signatories" ON contract_signatories;
    DROP POLICY IF EXISTS "Contract creators can update signatories" ON contract_signatories;
    DROP POLICY IF EXISTS "Contract creators can delete signatories" ON contract_signatories;
END $$;

-- Create new policies safely
DO $$ 
BEGIN
    -- Contract viewing policy
    IF NOT policy_exists('Users can view their contracts', 'contracts') THEN
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
    END IF;

    -- Contract creation policy
    IF NOT policy_exists('Users can create contracts', 'contracts') THEN
        CREATE POLICY "Users can create contracts"
        ON contracts FOR INSERT
        WITH CHECK (auth.uid() = created_by);
    END IF;

    -- Contract update policy
    IF NOT policy_exists('Users can update their contracts', 'contracts') THEN
        CREATE POLICY "Users can update their contracts"
        ON contracts FOR UPDATE
        USING (
            created_by = auth.uid()
            OR is_admin()
        );
    END IF;

    -- Contract deletion policy
    IF NOT policy_exists('Users can delete their contracts', 'contracts') THEN
        CREATE POLICY "Users can delete their contracts"
        ON contracts FOR DELETE
        USING (
            created_by = auth.uid()
            OR is_admin()
        );
    END IF;

    -- Signatory viewing policy
    IF NOT policy_exists('Users can view signatories', 'contract_signatories') THEN
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
    END IF;

    -- Signatory creation policy
    IF NOT policy_exists('Contract creators can add signatories', 'contract_signatories') THEN
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
    END IF;

    -- Signatory update policy
    IF NOT policy_exists('Contract creators can update signatories', 'contract_signatories') THEN
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
    END IF;

    -- Signatory deletion policy
    IF NOT policy_exists('Contract creators can delete signatories', 'contract_signatories') THEN
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
    END IF;
END $$;

-- Drop helper function
DROP FUNCTION policy_exists;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;