-- Fix support tickets relationship
BEGIN;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS support_ticket_comments CASCADE;
DROP TABLE IF EXISTS support_ticket_attachments CASCADE;
DROP TABLE IF EXISTS support_ticket_history CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
DROP TABLE IF EXISTS support_reasons CASCADE;
DROP TABLE IF EXISTS support_departments CASCADE;

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

-- Create support tickets table with explicit references
CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES support_departments(id) ON DELETE CASCADE,
    reason_id UUID NOT NULL REFERENCES support_reasons(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
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

-- Create support ticket comments table
CREATE TABLE IF NOT EXISTS support_ticket_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create support ticket attachments table
CREATE TABLE IF NOT EXISTS support_ticket_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    file_url TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create support ticket history table
CREATE TABLE IF NOT EXISTS support_ticket_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    details JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_support_tickets_department ON support_tickets(department_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_reason ON support_tickets(reason_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_by ON support_tickets(created_by);
CREATE INDEX IF NOT EXISTS idx_support_tickets_assigned_to ON support_tickets(assigned_to);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_reasons_department ON support_reasons(department_id);
CREATE INDEX IF NOT EXISTS idx_support_ticket_comments_ticket ON support_ticket_comments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_support_ticket_attachments_ticket ON support_ticket_attachments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_support_ticket_history_ticket ON support_ticket_history(ticket_id);

-- Enable RLS
DO $$ 
BEGIN
    ALTER TABLE support_departments ENABLE ROW LEVEL SECURITY;
    ALTER TABLE support_reasons ENABLE ROW LEVEL SECURITY;
    ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
    ALTER TABLE support_ticket_comments ENABLE ROW LEVEL SECURITY;
    ALTER TABLE support_ticket_attachments ENABLE ROW LEVEL SECURITY;
    ALTER TABLE support_ticket_history ENABLE ROW LEVEL SECURITY;
EXCEPTION 
    WHEN undefined_object THEN NULL;
END $$;

-- Drop existing policies if they exist
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Everyone can view departments" ON support_departments;
    DROP POLICY IF EXISTS "Admin can manage departments" ON support_departments;
    DROP POLICY IF EXISTS "Everyone can view reasons" ON support_reasons;
    DROP POLICY IF EXISTS "Admin can manage reasons" ON support_reasons;
    DROP POLICY IF EXISTS "Users can view tickets" ON support_tickets;
    DROP POLICY IF EXISTS "Users can create tickets" ON support_tickets;
    DROP POLICY IF EXISTS "Users can update tickets" ON support_tickets;
EXCEPTION 
    WHEN undefined_object THEN NULL;
END $$;

-- Create RLS policies
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
        created_by = auth.uid()
        OR assigned_to = auth.uid()
        OR is_admin()
    );

CREATE POLICY "Users can create tickets"
    ON support_tickets FOR INSERT
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update tickets"
    ON support_tickets FOR UPDATE
    USING (
        created_by = auth.uid()
        OR assigned_to = auth.uid()
        OR is_admin()
    );

-- Create function to calculate SLA deadlines
CREATE OR REPLACE FUNCTION calculate_ticket_sla()
RETURNS TRIGGER AS $$
BEGIN
    -- Get SLA times from reason
    SELECT 
        CURRENT_TIMESTAMP + (sla_response || ' minutes')::interval,
        CURRENT_TIMESTAMP + (sla_resolution || ' minutes')::interval
    INTO 
        NEW.sla_response_at,
        NEW.sla_resolution_at
    FROM support_reasons
    WHERE id = NEW.reason_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for SLA calculation
DROP TRIGGER IF EXISTS calculate_ticket_sla_trigger ON support_tickets;
CREATE TRIGGER calculate_ticket_sla_trigger
    BEFORE INSERT ON support_tickets
    FOR EACH ROW
    EXECUTE FUNCTION calculate_ticket_sla();

-- Create storage bucket for attachments if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('support-attachments', 'support-attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can upload support attachments" ON storage.objects;
    DROP POLICY IF EXISTS "Public support attachment access" ON storage.objects;
    DROP POLICY IF EXISTS "Admin support attachment deletion" ON storage.objects;

    CREATE POLICY "Users can upload support attachments"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'support-attachments');

    CREATE POLICY "Public support attachment access"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'support-attachments');

    CREATE POLICY "Admin support attachment deletion"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'support-attachments' 
        AND EXISTS (
            SELECT 1 
            FROM auth.users 
            WHERE id = auth.uid() 
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );
EXCEPTION 
    WHEN undefined_object THEN NULL;
END $$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;