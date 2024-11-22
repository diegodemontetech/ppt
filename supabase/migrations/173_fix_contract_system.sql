-- Fix contract system with proper policies and constraints
BEGIN;

-- Drop existing tables to rebuild with correct relationships
DROP TABLE IF EXISTS contract_comments CASCADE;
DROP TABLE IF EXISTS contract_history CASCADE;
DROP TABLE IF EXISTS contract_signatories CASCADE;
DROP TABLE IF EXISTS contracts CASCADE;

-- Create contracts table
CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    content TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    metadata JSONB DEFAULT '{}',
    hash TEXT,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    CHECK (status IN ('draft', 'sent', 'pending_signatures', 'partially_signed', 'completed', 'archived', 'deleted'))
);

-- Create signatories table
CREATE TABLE contract_signatories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
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

-- Create history table
CREATE TABLE contract_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    details JSONB NOT NULL,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create comments table
CREATE TABLE contract_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_contracts_created_by ON contracts(created_by);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_signatories_contract ON contract_signatories(contract_id);
CREATE INDEX idx_signatories_user ON contract_signatories(user_id);
CREATE INDEX idx_signatories_email ON contract_signatories(email);
CREATE INDEX idx_history_contract ON contract_history(contract_id);
CREATE INDEX idx_comments_contract ON contract_comments(contract_id);

-- Enable RLS
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE contract_signatories ENABLE ROW LEVEL SECURITY;
ALTER TABLE contract_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE contract_comments ENABLE ROW LEVEL SECURITY;

-- Create base policies
CREATE POLICY "Users can view their contracts"
    ON contracts FOR SELECT
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM contract_signatories cs
            WHERE cs.contract_id = id
            AND (cs.user_id = auth.uid() OR cs.email = (SELECT email FROM auth.users WHERE id = auth.uid()))
        )
        OR is_admin()
    );

CREATE POLICY "Users can create contracts"
    ON contracts FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update their contracts"
    ON contracts FOR UPDATE
    USING (created_by = auth.uid() OR is_admin());

CREATE POLICY "Users can delete their contracts"
    ON contracts FOR DELETE
    USING (created_by = auth.uid() OR is_admin());

-- Create signatory policies
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

-- Create history policies
CREATE POLICY "Users can view history"
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
            )
        )
        OR is_admin()
    );

-- Create comment policies
CREATE POLICY "Users can view comments"
    ON contract_comments FOR SELECT
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
            )
        )
        OR is_admin()
    );

CREATE POLICY "Users can add comments"
    ON contract_comments FOR INSERT
    WITH CHECK (
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
            )
        )
        OR is_admin()
    );

-- Create storage bucket for signatures
INSERT INTO storage.buckets (id, name, public)
VALUES ('signatures', 'signatures', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies
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