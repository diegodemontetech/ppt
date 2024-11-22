-- Create support system tables
BEGIN;

-- Create support departments table
CREATE TABLE support_departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create support reasons table
CREATE TABLE support_reasons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID REFERENCES support_departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    sla_response INTEGER NOT NULL, -- in minutes
    sla_resolution INTEGER NOT NULL, -- in minutes
    priority TEXT NOT NULL CHECK (priority IN ('urgent', 'medium', 'low')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create support tickets table
CREATE TABLE support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    department_id UUID REFERENCES support_departments(id) ON DELETE CASCADE,
    reason_id UUID REFERENCES support_reasons(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
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

-- Create support ticket comments table
CREATE TABLE support_ticket_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID REFERENCES support_tickets(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create support ticket attachments table
CREATE TABLE support_ticket_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID REFERENCES support_tickets(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    file_url TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create support ticket history table
CREATE TABLE support_ticket_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID REFERENCES support_tickets(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    details JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_support_departments_company ON support_departments(company_id);
CREATE INDEX idx_support_reasons_department ON support_reasons(department_id);
CREATE INDEX idx_support_tickets_company ON support_tickets(company_id);
CREATE INDEX idx_support_tickets_department ON support_tickets(department_id);
CREATE INDEX idx_support_tickets_reason ON support_tickets(reason_id);
CREATE INDEX idx_support_tickets_created_by ON support_tickets(created_by);
CREATE INDEX idx_support_tickets_assigned_to ON support_tickets(assigned_to);
CREATE INDEX idx_support_tickets_status ON support_tickets(status);
CREATE INDEX idx_support_tickets_priority ON support_tickets(priority);
CREATE INDEX idx_support_ticket_comments_ticket ON support_ticket_comments(ticket_id);
CREATE INDEX idx_support_ticket_attachments_ticket ON support_ticket_attachments(ticket_id);
CREATE INDEX idx_support_ticket_history_ticket ON support_ticket_history(ticket_id);

-- Enable RLS
ALTER TABLE support_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_reasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_ticket_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_ticket_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_ticket_history ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view support departments"
    ON support_departments FOR SELECT
    USING (
        company_id = (
            SELECT company_id 
            FROM auth.users 
            WHERE id = auth.uid()
        )
    );

CREATE POLICY "Admin can manage support departments"
    ON support_departments FOR ALL
    USING (is_admin());

CREATE POLICY "Users can view support reasons"
    ON support_reasons FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM support_departments d
            WHERE d.id = department_id
            AND d.company_id = (
                SELECT company_id 
                FROM auth.users 
                WHERE id = auth.uid()
            )
        )
    );

CREATE POLICY "Admin can manage support reasons"
    ON support_reasons FOR ALL
    USING (is_admin());

CREATE POLICY "Users can view support tickets"
    ON support_tickets FOR SELECT
    USING (
        company_id = (
            SELECT company_id 
            FROM auth.users 
            WHERE id = auth.uid()
        )
        AND (
            created_by = auth.uid()
            OR assigned_to = auth.uid()
            OR is_admin()
            OR EXISTS (
                SELECT 1 FROM user_groups ug
                JOIN user_group_members ugm ON ug.id = ugm.group_id
                WHERE ugm.user_id = auth.uid()
                AND jsonb_array_elements(ug.permissions::jsonb) ? 'view_all_tickets'
            )
        )
    );

CREATE POLICY "Users can create support tickets"
    ON support_tickets FOR INSERT
    WITH CHECK (
        company_id = (
            SELECT company_id 
            FROM auth.users 
            WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can update support tickets"
    ON support_tickets FOR UPDATE
    USING (
        company_id = (
            SELECT company_id 
            FROM auth.users 
            WHERE id = auth.uid()
        )
        AND (
            created_by = auth.uid()
            OR assigned_to = auth.uid()
            OR is_admin()
            OR EXISTS (
                SELECT 1 FROM user_groups ug
                JOIN user_group_members ugm ON ug.id = ugm.group_id
                WHERE ugm.user_id = auth.uid()
                AND jsonb_array_elements(ug.permissions::jsonb) ? 'manage_tickets'
            )
        )
    );

CREATE POLICY "Users can view ticket comments"
    ON support_ticket_comments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM support_tickets t
            WHERE t.id = ticket_id
            AND t.company_id = (
                SELECT company_id 
                FROM auth.users 
                WHERE id = auth.uid()
            )
            AND (
                t.created_by = auth.uid()
                OR t.assigned_to = auth.uid()
                OR is_admin()
                OR EXISTS (
                    SELECT 1 FROM user_groups ug
                    JOIN user_group_members ugm ON ug.id = ugm.group_id
                    WHERE ugm.user_id = auth.uid()
                    AND jsonb_array_elements(ug.permissions::jsonb) ? 'view_all_tickets'
                )
            )
        )
    );

CREATE POLICY "Users can add ticket comments"
    ON support_ticket_comments FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM support_tickets t
            WHERE t.id = ticket_id
            AND t.company_id = (
                SELECT company_id 
                FROM auth.users 
                WHERE id = auth.uid()
            )
            AND (
                t.created_by = auth.uid()
                OR t.assigned_to = auth.uid()
                OR is_admin()
            )
        )
    );

CREATE POLICY "Users can view ticket attachments"
    ON support_ticket_attachments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM support_tickets t
            WHERE t.id = ticket_id
            AND t.company_id = (
                SELECT company_id 
                FROM auth.users 
                WHERE id = auth.uid()
            )
            AND (
                t.created_by = auth.uid()
                OR t.assigned_to = auth.uid()
                OR is_admin()
                OR EXISTS (
                    SELECT 1 FROM user_groups ug
                    JOIN user_group_members ugm ON ug.id = ugm.group_id
                    WHERE ugm.user_id = auth.uid()
                    AND jsonb_array_elements(ug.permissions::jsonb) ? 'view_all_tickets'
                )
            )
        )
    );

CREATE POLICY "Users can add ticket attachments"
    ON support_ticket_attachments FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM support_tickets t
            WHERE t.id = ticket_id
            AND t.company_id = (
                SELECT company_id 
                FROM auth.users 
                WHERE id = auth.uid()
            )
            AND (
                t.created_by = auth.uid()
                OR t.assigned_to = auth.uid()
                OR is_admin()
            )
        )
    );

CREATE POLICY "Users can view ticket history"
    ON support_ticket_history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM support_tickets t
            WHERE t.id = ticket_id
            AND t.company_id = (
                SELECT company_id 
                FROM auth.users 
                WHERE id = auth.uid()
            )
            AND (
                t.created_by = auth.uid()
                OR t.assigned_to = auth.uid()
                OR is_admin()
                OR EXISTS (
                    SELECT 1 FROM user_groups ug
                    JOIN user_group_members ugm ON ug.id = ugm.group_id
                    WHERE ugm.user_id = auth.uid()
                    AND jsonb_array_elements(ug.permissions::jsonb) ? 'view_all_tickets'
                )
            )
        )
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
CREATE TRIGGER calculate_ticket_sla_trigger
    BEFORE INSERT ON support_tickets
    FOR EACH ROW
    EXECUTE FUNCTION calculate_ticket_sla();

-- Create function to handle ticket status changes
CREATE OR REPLACE FUNCTION handle_ticket_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Update timestamps based on status
    CASE NEW.status
        WHEN 'in_progress' THEN
            IF OLD.status = 'open' THEN
                NEW.responded_at = CURRENT_TIMESTAMP;
            END IF;
        WHEN 'resolved' THEN
            NEW.resolved_at = CURRENT_TIMESTAMP;
        WHEN 'finished' THEN
            NEW.finished_at = CURRENT_TIMESTAMP;
        WHEN 'deleted' THEN
            NEW.deleted_at = CURRENT_TIMESTAMP;
        ELSE
            NULL;
    END CASE;

    -- Insert history record
    INSERT INTO support_ticket_history (
        ticket_id,
        user_id,
        action,
        details
    ) VALUES (
        NEW.id,
        auth.uid(),
        'status_changed',
        jsonb_build_object(
            'old_status', OLD.status,
            'new_status', NEW.status
        )
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for status changes
CREATE TRIGGER handle_ticket_status_change_trigger
    BEFORE UPDATE OF status ON support_tickets
    FOR EACH ROW
    EXECUTE FUNCTION handle_ticket_status_change();

-- Create storage bucket for attachments if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('support-attachments', 'support-attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for attachments
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

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;