-- Fix contract history policies
BEGIN;

-- Drop existing policies
DROP POLICY IF EXISTS "Contract access" ON contracts;
DROP POLICY IF EXISTS "Signatory access" ON contract_signatories;
DROP POLICY IF EXISTS "History access" ON contract_history;

-- Create policy for contracts
CREATE POLICY "Contract access"
    ON contracts FOR ALL
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM contract_signatories cs
            WHERE cs.contract_id = id
            AND (cs.user_id = auth.uid() OR cs.email = (SELECT email FROM auth.users WHERE id = auth.uid()))
        )
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Create policy for signatories
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
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Create policies for contract history
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

CREATE POLICY "Insert contract history"
    ON contract_history FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM contracts c
            WHERE c.id = contract_id
            AND (
                c.created_by = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM auth.users
                    WHERE id = auth.uid()
                    AND raw_user_meta_data->>'role' = 'admin'
                )
            )
        )
    );

-- Create function to handle contract status changes
CREATE OR REPLACE FUNCTION handle_contract_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Only proceed if status has changed
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    -- Log status change with elevated privileges
    INSERT INTO contract_history (
        contract_id,
        user_id,
        action,
        details
    ) VALUES (
        NEW.id,
        COALESCE(auth.uid(), NEW.created_by),
        'status_changed',
        jsonb_build_object(
            'old_status', OLD.status,
            'new_status', NEW.status
        )
    );

    -- Send notifications based on status
    IF NEW.status = 'sent' THEN
        INSERT INTO notifications (
            user_id,
            title,
            message
        )
        SELECT
            COALESCE(cs.user_id, NEW.created_by),
            'Contrato Enviado',
            'O contrato ' || NEW.title || ' foi enviado para assinatura'
        FROM contract_signatories cs
        WHERE cs.contract_id = NEW.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger for contract status changes
DROP TRIGGER IF EXISTS handle_contract_status_trigger ON contracts;
CREATE TRIGGER handle_contract_status_trigger
    AFTER UPDATE OF status ON contracts
    FOR EACH ROW
    EXECUTE FUNCTION handle_contract_status();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;