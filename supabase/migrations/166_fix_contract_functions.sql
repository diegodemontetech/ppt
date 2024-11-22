-- Fix contract functions and triggers
BEGIN;

-- Create function to check if user can access contract
CREATE OR REPLACE FUNCTION can_access_contract(contract_uuid UUID, user_uuid UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM contracts c
        WHERE c.id = contract_uuid
        AND (
            c.created_by = user_uuid
            OR EXISTS (
                SELECT 1 FROM contract_signatories cs
                WHERE cs.contract_id = c.id
                AND (
                    cs.user_id = user_uuid
                    OR cs.email = (SELECT email FROM auth.users WHERE id = user_uuid)
                )
            )
            OR EXISTS (
                SELECT 1 FROM auth.users
                WHERE id = user_uuid
                AND raw_user_meta_data->>'role' = 'admin'
            )
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle contract status changes
CREATE OR REPLACE FUNCTION handle_contract_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Only proceed if status has changed
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    -- Log status change
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
$$ LANGUAGE plpgsql;

-- Create function to handle signatures
CREATE OR REPLACE FUNCTION handle_contract_signature()
RETURNS TRIGGER AS $$
BEGIN
    -- Only proceed if signature has been added
    IF OLD.signed_at IS NOT NULL OR NEW.signed_at IS NULL THEN
        RETURN NEW;
    END IF;

    -- Update contract status based on signatures
    WITH signature_stats AS (
        SELECT
            COUNT(*) as total_signatories,
            COUNT(CASE WHEN signed_at IS NOT NULL THEN 1 END) as signed_count
        FROM contract_signatories
        WHERE contract_id = NEW.contract_id
    )
    UPDATE contracts
    SET 
        status = CASE 
            WHEN signed_count = total_signatories THEN 'completed'
            WHEN signed_count > 0 THEN 'partially_signed'
            ELSE status
        END,
        updated_at = CURRENT_TIMESTAMP
    FROM signature_stats
    WHERE id = NEW.contract_id;

    -- Log signature
    INSERT INTO contract_history (
        contract_id,
        user_id,
        action,
        details
    ) VALUES (
        NEW.contract_id,
        COALESCE(NEW.user_id, auth.uid()),
        'signed',
        jsonb_build_object(
            'signatory_name', NEW.name,
            'signatory_email', NEW.email,
            'signature_url', NEW.signature_url
        )
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate triggers
DROP TRIGGER IF EXISTS handle_contract_status_trigger ON contracts;
CREATE TRIGGER handle_contract_status_trigger
    AFTER UPDATE OF status ON contracts
    FOR EACH ROW
    EXECUTE FUNCTION handle_contract_status();

DROP TRIGGER IF EXISTS handle_contract_signature_trigger ON contract_signatories;
CREATE TRIGGER handle_contract_signature_trigger
    AFTER UPDATE OF signed_at ON contract_signatories
    FOR EACH ROW
    WHEN (OLD.signed_at IS NULL AND NEW.signed_at IS NOT NULL)
    EXECUTE FUNCTION handle_contract_signature();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;