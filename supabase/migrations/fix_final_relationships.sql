-- Fix final database relationships and recursion issues
BEGIN;

-- Drop existing tables to rebuild with correct relationships
DROP TABLE IF EXISTS contract_comments CASCADE;
DROP TABLE IF EXISTS contract_history CASCADE;
DROP TABLE IF EXISTS contract_signatories CASCADE;
DROP TABLE IF EXISTS contracts CASCADE;
DROP TABLE IF EXISTS support_ticket_comments CASCADE;
DROP TABLE IF EXISTS support_ticket_attachments CASCADE;
DROP TABLE IF EXISTS support_ticket_history CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
DROP TABLE IF EXISTS support_reasons CASCADE;
DROP TABLE IF EXISTS support_departments CASCADE;

-- Create contracts table
CREATE TABLE IF NOT EXISTS contracts (
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

-- Create contract signatories table
CREATE TABLE IF NOT EXISTS contract_signatories (
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

-- Create support departments table
CREATE TABLE IF NOT EXISTS support_departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create support reasons table
CREATE TABLE IF NOT EXISTS support_reasons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES support_departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    sla_response INTEGER NOT NULL,
    sla_resolution INTEGER NOT NULL,
    priority TEXT NOT NULL CHECK (priority IN ('urgent', 'medium', 'low')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create support tickets table with explicit auth.users reference
CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES support_departments(id) ON DELETE CASCADE,
    reason_id UUID NOT NULL REFERENCES support_reasons(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('open', 'in_progress', 'partially_resolved', 'resolved', 'finished', 'deleted')),
    priority TEXT NOT NULL CHECK (priority IN ('urgent', 'medium', 'low')),
    sla_response_at TIMESTAMPTZ,
    sla_resolution_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    deletion_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_contracts_created_by ON contracts(created_by);
CREATE INDEX IF NOT EXISTS idx_contracts_status ON contracts(status);
CREATE INDEX IF NOT EXISTS idx_signatories_contract ON contract_signatories(contract_id);
CREATE INDEX IF NOT EXISTS idx_signatories_user ON contract_signatories(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_department ON support_tickets(department_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_reason ON support_tickets(reason_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_user ON support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_assigned ON support_tickets(assigned_to);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);

-- Enable RLS
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE contract_signatories ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_reasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Create non-recursive RLS policies
CREATE POLICY "Contract access"
    ON contracts FOR ALL
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM contract_signatories cs
            WHERE cs.contract_id = id
            AND (cs.user_id = auth.uid() OR cs.email = (SELECT email FROM auth.users WHERE id = auth.uid()))
        )
        OR is_admin()
    );

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
        OR is_admin()
    );

CREATE POLICY "Everyone can view departments"
    ON support_departments FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage departments"
    ON support_departments FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view reasons"
    ON support_reasons FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage reasons"
    ON support_reasons FOR ALL
    USING (is_admin());

CREATE POLICY "Users can view tickets"
    ON support_tickets FOR SELECT
    USING (
        user_id = auth.uid()
        OR assigned_to = auth.uid()
        OR is_admin()
    );

CREATE POLICY "Users can create tickets"
    ON support_tickets FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update tickets"
    ON support_tickets FOR UPDATE
    USING (
        user_id = auth.uid()
        OR assigned_to = auth.uid()
        OR is_admin()
    );

-- Insert default support departments and reasons
INSERT INTO support_departments (id, name, description) VALUES
    ('d1000000-0000-0000-0000-000000000001', 'Technical Support', 'Technical issues and platform support'),
    ('d2000000-0000-0000-0000-000000000002', 'Course Support', 'Questions about courses and content'),
    ('d3000000-0000-0000-0000-000000000003', 'Billing Support', 'Payment and subscription issues')
ON CONFLICT (id) DO NOTHING;

INSERT INTO support_reasons (
    department_id,
    name,
    description,
    sla_response,
    sla_resolution,
    priority
) VALUES
    ('d1000000-0000-0000-0000-000000000001', 'Platform Access', 'Issues accessing the platform', 30, 120, 'urgent'),
    ('d1000000-0000-0000-0000-000000000001', 'Technical Error', 'Platform errors or bugs', 60, 240, 'medium'),
    ('d2000000-0000-0000-0000-000000000002', 'Course Content', 'Questions about course materials', 120, 480, 'low'),
    ('d2000000-0000-0000-0000-000000000002', 'Certificate Issue', 'Problems with course certificates', 60, 240, 'medium'),
    ('d3000000-0000-0000-0000-000000000003', 'Payment Failed', 'Payment processing issues', 30, 120, 'urgent'),
    ('d3000000-0000-0000-0000-000000000003', 'Refund Request', 'Request for refund', 60, 240, 'medium')
ON CONFLICT DO NOTHING;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;</content>