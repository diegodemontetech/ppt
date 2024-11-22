-- Add E-Sign system with contract workflow
BEGIN;

-- Create contracts table
CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    content TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    metadata JSONB DEFAULT '{}',
    hash TEXT,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    CHECK (status IN ('draft', 'sent', 'pending_signatures', 'partially_signed', 'completed', 'archived', 'deleted'))
);

-- Create signatories table
CREATE TABLE contract_signatories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id UUID REFERENCES contracts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    order_num INTEGER NOT NULL,
    signature_url TEXT,
    signed_at TIMESTAMPTZ,
    sign_token TEXT UNIQUE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create contract history table
CREATE TABLE contract_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id UUID REFERENCES contracts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    details JSONB NOT NULL,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create contract comments table
CREATE TABLE contract_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id UUID REFERENCES contracts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_contracts_created_by ON contracts(created_by);
CREATE INDEX idx_signatories_contract ON contract_signatories(contract_id);
CREATE INDEX idx_signatories_user ON contract_signatories(user_id);
CREATE INDEX idx_signatories_email ON contract_signatories(email);
CREATE INDEX idx_signatories_token ON contract_signatories(sign_token);
CREATE INDEX idx_history_contract ON contract_history(contract_id);
CREATE INDEX idx_comments_contract ON contract_comments(contract_id);

-- Enable RLS
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE contract_signatories ENABLE ROW LEVEL SECURITY;
ALTER TABLE contract_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE contract_comments ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their contracts"
    ON contracts FOR SELECT
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM contract_signatories
            WHERE contract_id = contracts.id
            AND (user_id = auth.uid() OR email = (SELECT email FROM auth.users WHERE id = auth.uid()))
        )
        OR is_admin()
    );

CREATE POLICY "Users can create contracts"
    ON contracts FOR INSERT
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update their contracts"
    ON contracts FOR UPDATE
    USING (
        created_by = auth.uid()
        OR is_admin()
    );

CREATE POLICY "Users can view signatories"
    ON contract_signatories FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE id = contract_id
            AND (
                created_by = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM contract_signatories s2
                    WHERE s2.contract_id = contracts.id
                    AND (s2.user_id = auth.uid() OR s2.email = (SELECT email FROM auth.users WHERE id = auth.uid()))
                )
            )
        )
        OR is_admin()
    );

CREATE POLICY "Users can view history"
    ON contract_history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE id = contract_id
            AND (
                created_by = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM contract_signatories
                    WHERE contract_id = contracts.id
                    AND (user_id = auth.uid() OR email = (SELECT email FROM auth.users WHERE id = auth.uid()))
                )
            )
        )
        OR is_admin()
    );

CREATE POLICY "Users can view comments"
    ON contract_comments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM contracts
            WHERE id = contract_id
            AND (
                created_by = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM contract_signatories
                    WHERE contract_id = contracts.id
                    AND (user_id = auth.uid() OR email = (SELECT email FROM auth.users WHERE id = auth.uid()))
                )
            )
        )
        OR is_admin()
    );

-- Create function to generate sign token
CREATE OR REPLACE FUNCTION generate_sign_token()
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..32 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Create function to handle contract status changes
CREATE OR REPLACE FUNCTION handle_contract_status()
RETURNS TRIGGER AS $$
BEGIN
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
            COALESCE(user_id, created_by),
            'Contrato Enviado',
            'O contrato ' || NEW.title || ' foi enviado para assinatura'
        FROM contract_signatories
        WHERE contract_id = NEW.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for contract status changes
CREATE TRIGGER handle_contract_status_trigger
    AFTER UPDATE OF status ON contracts
    FOR EACH ROW
    EXECUTE FUNCTION handle_contract_status();

-- Create function to handle signatures
CREATE OR REPLACE FUNCTION handle_contract_signature()
RETURNS TRIGGER AS $$
BEGIN
    -- Update contract status based on signatures
    WITH signature_stats AS (
        SELECT
            COUNT(*) as total_signatories,
            COUNT(CASE WHEN signed_at IS NOT NULL THEN 1 END) as signed_count
        FROM contract_signatories
        WHERE contract_id = NEW.contract_id
    )
    UPDATE contracts
    SET status = 
        CASE 
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

-- Create trigger for signatures
CREATE TRIGGER handle_contract_signature_trigger
    AFTER UPDATE OF signed_at ON contract_signatories
    FOR EACH ROW
    WHEN (OLD.signed_at IS NULL AND NEW.signed_at IS NOT NULL)
    EXECUTE FUNCTION handle_contract_signature();

-- Create function to validate contract hash
CREATE OR REPLACE FUNCTION validate_contract_hash(contract_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    stored_hash TEXT;
    computed_hash TEXT;
BEGIN
    -- Get stored hash
    SELECT hash INTO stored_hash
    FROM contracts
    WHERE id = contract_uuid;

    -- Compute current hash
    WITH contract_data AS (
        SELECT 
            c.content,
            jsonb_agg(
                jsonb_build_object(
                    'name', cs.name,
                    'email', cs.email,
                    'role', cs.role,
                    'order', cs.order_num,
                    'signed_at', cs.signed_at
                ) ORDER BY cs.order_num
            ) as signatories
        FROM contracts c
        LEFT JOIN contract_signatories cs ON c.id = cs.contract_id
        WHERE c.id = contract_uuid
        GROUP BY c.id, c.content
    )
    SELECT encode(
        digest(
            content || signatories::text,
            'sha256'
        ),
        'hex'
    ) INTO computed_hash
    FROM contract_data;

    RETURN stored_hash = computed_hash;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get contract status
CREATE OR REPLACE FUNCTION get_contract_status(contract_uuid UUID)
RETURNS TABLE (
    status TEXT,
    total_signatories INTEGER,
    signed_count INTEGER,
    pending_count INTEGER,
    is_valid BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    WITH signature_stats AS (
        SELECT
            COUNT(*) as total,
            COUNT(CASE WHEN signed_at IS NOT NULL THEN 1 END) as signed,
            COUNT(CASE WHEN signed_at IS NULL THEN 1 END) as pending
        FROM contract_signatories
        WHERE contract_id = contract_uuid
    )
    SELECT
        c.status,
        s.total::INTEGER,
        s.signed::INTEGER,
        s.pending::INTEGER,
        validate_contract_hash(contract_uuid)
    FROM contracts c
    CROSS JOIN signature_stats s
    WHERE c.id = contract_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create storage bucket for signatures if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('signatures', 'signatures', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for signatures
CREATE POLICY "Users can upload signatures"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'signatures');

CREATE POLICY "Public signature access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'signatures');

CREATE POLICY "Admin signature deletion"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'signatures' 
  AND EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'role' = 'admin'
  )
);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;