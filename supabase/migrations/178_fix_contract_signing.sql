-- Fix contract signing and history
BEGIN;

-- Add IP and user agent columns to contract history
ALTER TABLE contract_history
ADD COLUMN IF NOT EXISTS ip_address TEXT,
ADD COLUMN IF NOT EXISTS user_agent TEXT;

-- Create function to handle contract signing with security definer
CREATE OR REPLACE FUNCTION sign_contract(
    contract_uuid UUID,
    signatory_uuid UUID,
    signature_url TEXT,
    ip_address TEXT,
    user_agent TEXT
)
RETURNS void AS $$
BEGIN
    -- Update signatory record
    UPDATE contract_signatories
    SET 
        signed_at = CURRENT_TIMESTAMP,
        signature_url = sign_contract.signature_url
    WHERE id = signatory_uuid;

    -- Insert history record with elevated privileges
    INSERT INTO contract_history (
        contract_id,
        user_id,
        action,
        details,
        ip_address,
        user_agent
    ) VALUES (
        contract_uuid,
        auth.uid(),
        'signed',
        jsonb_build_object(
            'signatory_id', signatory_uuid,
            'signature_url', signature_url
        ),
        ip_address,
        user_agent
    );

    -- Check if all signatories have signed
    IF NOT EXISTS (
        SELECT 1 FROM contract_signatories
        WHERE contract_id = contract_uuid
        AND signed_at IS NULL
    ) THEN
        -- Update contract status to completed
        UPDATE contracts
        SET status = 'completed'
        WHERE id = contract_uuid;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to update contract status with security definer
CREATE OR REPLACE FUNCTION update_contract_status(
    contract_uuid UUID,
    new_status TEXT
)
RETURNS void AS $$
BEGIN
    -- Update contract status
    UPDATE contracts
    SET status = new_status
    WHERE id = contract_uuid;

    -- Insert history record with elevated privileges
    INSERT INTO contract_history (
        contract_id,
        user_id,
        action,
        details,
        ip_address,
        user_agent
    ) VALUES (
        contract_uuid,
        auth.uid(),
        'status_changed',
        jsonb_build_object(
            'new_status', new_status
        ),
        current_setting('request.headers', true)::json->>'x-real-ip',
        current_setting('request.headers', true)::json->>'user-agent'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger
DROP TRIGGER IF EXISTS handle_contract_status_trigger ON contracts;

-- Create RLS policies for contract history
DROP POLICY IF EXISTS "View contract history" ON contract_history;
DROP POLICY IF EXISTS "Insert contract history" ON contract_history;

CREATE POLICY "View contract history"
    ON contract_history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM contracts c
            WHERE c.id = contract_id
            AND (
                c.created_by = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM contract_signatories cs
                    WHERE cs.contract_id = c.id
                    AND (cs.user_id = auth.uid() OR cs.email = (SELECT email FROM auth.users WHERE id = auth.uid()))
                )
                OR EXISTS (
                    SELECT 1 FROM auth.users
                    WHERE id = auth.uid()
                    AND raw_user_meta_data->>'role' = 'admin'
                )
            )
        )
    );

-- Allow system functions to insert history
CREATE POLICY "System insert contract history"
    ON contract_history FOR INSERT
    WITH CHECK (true);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;