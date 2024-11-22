-- Fix contract RLS policies to properly allow creation
BEGIN;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their contracts" ON contracts;
DROP POLICY IF EXISTS "Users can create contracts" ON contracts;
DROP POLICY IF EXISTS "Users can update their contracts" ON contracts;
DROP POLICY IF EXISTS "Users can delete their contracts" ON contracts;

-- Enable RLS
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;

-- Create new policies with proper checks
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

-- Allow any authenticated user to create contracts
CREATE POLICY "Users can create contracts"
    ON contracts FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
    );

-- Only allow contract creator or admin to update
CREATE POLICY "Users can update their contracts"
    ON contracts FOR UPDATE
    USING (
        created_by = auth.uid()
        OR is_admin()
    );

-- Only allow contract creator or admin to delete
CREATE POLICY "Users can delete their contracts"
    ON contracts FOR DELETE
    USING (
        created_by = auth.uid()
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

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;