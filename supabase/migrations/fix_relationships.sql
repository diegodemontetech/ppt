-- Fix database relationships and missing tables with safety checks
BEGIN;

-- Drop existing indexes if they exist
DO $$ 
BEGIN
    DROP INDEX IF EXISTS idx_marketing_items_category;
    DROP INDEX IF EXISTS idx_contracts_created_by;
    DROP INDEX IF EXISTS idx_contracts_status;
    DROP INDEX IF EXISTS idx_signatories_contract;
    DROP INDEX IF EXISTS idx_support_tickets_department;
    DROP INDEX IF EXISTS idx_support_tickets_reason;
    DROP INDEX IF EXISTS idx_pipelines_department;
    DROP INDEX IF EXISTS idx_pipeline_stages_pipeline;
EXCEPTION 
    WHEN undefined_object THEN NULL;
END $$;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS pipeline_stages CASCADE;
DROP TABLE IF EXISTS pipelines CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
DROP TABLE IF EXISTS support_reasons CASCADE;
DROP TABLE IF EXISTS support_departments CASCADE;
DROP TABLE IF EXISTS contract_signatories CASCADE;
DROP TABLE IF EXISTS contracts CASCADE;
DROP TABLE IF EXISTS marketing_box_items CASCADE;
DROP TABLE IF EXISTS marketing_box_categories CASCADE;

-- Create marketing box tables
CREATE TABLE IF NOT EXISTS marketing_box_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS marketing_box_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID REFERENCES marketing_box_categories(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    thumbnail_url TEXT,
    file_type TEXT NOT NULL,
    media_type TEXT NOT NULL,
    resolution TEXT,
    tags TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    downloads INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create E-Sign tables
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

CREATE TABLE IF NOT EXISTS contract_signatories (
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

-- Create support system tables
CREATE TABLE IF NOT EXISTS support_departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS support_reasons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID REFERENCES support_departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    sla_response INTEGER NOT NULL,
    sla_resolution INTEGER NOT NULL,
    priority TEXT NOT NULL CHECK (priority IN ('urgent', 'medium', 'low')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID REFERENCES support_departments(id) ON DELETE CASCADE,
    reason_id UUID REFERENCES support_reasons(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES auth.users(id),
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

-- Create pipeline tables
CREATE TABLE IF NOT EXISTS pipelines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    color TEXT DEFAULT '#3B82F6',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pipeline_stages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID REFERENCES pipelines(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    order_num INTEGER NOT NULL,
    sla_hours INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(pipeline_id, order_num)
);

-- Create indexes with IF NOT EXISTS
CREATE INDEX IF NOT EXISTS idx_marketing_items_category ON marketing_box_items(category_id);
CREATE INDEX IF NOT EXISTS idx_contracts_created_by ON contracts(created_by);
CREATE INDEX IF NOT EXISTS idx_contracts_status ON contracts(status);
CREATE INDEX IF NOT EXISTS idx_signatories_contract ON contract_signatories(contract_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_department ON support_tickets(department_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_reason ON support_tickets(reason_id);
CREATE INDEX IF NOT EXISTS idx_pipelines_department ON pipelines(department_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_stages_pipeline ON pipeline_stages(pipeline_id);

-- Enable RLS safely
DO $$ 
BEGIN
    ALTER TABLE marketing_box_categories ENABLE ROW LEVEL SECURITY;
    ALTER TABLE marketing_box_items ENABLE ROW LEVEL SECURITY;
    ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
    ALTER TABLE contract_signatories ENABLE ROW LEVEL SECURITY;
    ALTER TABLE support_departments ENABLE ROW LEVEL SECURITY;
    ALTER TABLE support_reasons ENABLE ROW LEVEL SECURITY;
    ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
    ALTER TABLE pipelines ENABLE ROW LEVEL SECURITY;
    ALTER TABLE pipeline_stages ENABLE ROW LEVEL SECURITY;
EXCEPTION 
    WHEN undefined_object THEN NULL;
END $$;

-- Drop existing policies if they exist
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Everyone can view marketing box categories" ON marketing_box_categories;
    DROP POLICY IF EXISTS "Admin can manage marketing box categories" ON marketing_box_categories;
    DROP POLICY IF EXISTS "Everyone can view marketing box items" ON marketing_box_items;
    DROP POLICY IF EXISTS "Admin can manage marketing box items" ON marketing_box_items;
    DROP POLICY IF EXISTS "Users can view their contracts" ON contracts;
    DROP POLICY IF EXISTS "Users can create contracts" ON contracts;
    DROP POLICY IF EXISTS "Users can update their contracts" ON contracts;
    DROP POLICY IF EXISTS "Everyone can view support departments" ON support_departments;
    DROP POLICY IF EXISTS "Admin can manage support departments" ON support_departments;
    DROP POLICY IF EXISTS "Everyone can view support reasons" ON support_reasons;
    DROP POLICY IF EXISTS "Admin can manage support reasons" ON support_reasons;
    DROP POLICY IF EXISTS "Users can view support tickets" ON support_tickets;
    DROP POLICY IF EXISTS "Users can create support tickets" ON support_tickets;
    DROP POLICY IF EXISTS "Users can update support tickets" ON support_tickets;
    DROP POLICY IF EXISTS "Everyone can view pipelines" ON pipelines;
    DROP POLICY IF EXISTS "Admin can manage pipelines" ON pipelines;
    DROP POLICY IF EXISTS "Everyone can view pipeline stages" ON pipeline_stages;
    DROP POLICY IF EXISTS "Admin can manage pipeline stages" ON pipeline_stages;
EXCEPTION 
    WHEN undefined_object THEN NULL;
END $$;

-- Create RLS policies
CREATE POLICY "Everyone can view marketing box categories"
    ON marketing_box_categories FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage marketing box categories"
    ON marketing_box_categories FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view marketing box items"
    ON marketing_box_items FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage marketing box items"
    ON marketing_box_items FOR ALL
    USING (is_admin());

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
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update their contracts"
    ON contracts FOR UPDATE
    USING (created_by = auth.uid() OR is_admin());

CREATE POLICY "Everyone can view support departments"
    ON support_departments FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage support departments"
    ON support_departments FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view support reasons"
    ON support_reasons FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage support reasons"
    ON support_reasons FOR ALL
    USING (is_admin());

CREATE POLICY "Users can view support tickets"
    ON support_tickets FOR SELECT
    USING (
        created_by = auth.uid()
        OR assigned_to = auth.uid()
        OR is_admin()
    );

CREATE POLICY "Users can create support tickets"
    ON support_tickets FOR INSERT
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update support tickets"
    ON support_tickets FOR UPDATE
    USING (
        created_by = auth.uid()
        OR assigned_to = auth.uid()
        OR is_admin()
    );

CREATE POLICY "Everyone can view pipelines"
    ON pipelines FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage pipelines"
    ON pipelines FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view pipeline stages"
    ON pipeline_stages FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage pipeline stages"
    ON pipeline_stages FOR ALL
    USING (is_admin());

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;