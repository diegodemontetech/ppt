-- Create complete pipeline system
BEGIN;

-- Create pipeline tables
CREATE TABLE pipeline_departments (
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

CREATE TABLE pipelines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    color TEXT DEFAULT '#3B82F6',
    table_name TEXT NOT NULL, -- Name of the Supabase table to mirror
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pipeline_stages (
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

CREATE TABLE pipeline_fields (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID REFERENCES pipelines(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    label TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('text', 'textarea', 'number', 'date', 'select', 'multiselect', 'file', 'phone', 'email', 'cpf', 'cnpj', 'cep', 'money')),
    mask TEXT, -- For formatted fields like phone, CPF, etc
    options JSONB, -- For select/multiselect fields
    validation_rules JSONB, -- Required, min, max, regex, etc
    show_on_card BOOLEAN DEFAULT false,
    order_num INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pipeline_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID REFERENCES pipelines(id) ON DELETE CASCADE,
    stage_id UUID REFERENCES pipeline_stages(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    assigned_to UUID[] DEFAULT '{}',
    data JSONB NOT NULL DEFAULT '{}',
    order_num INTEGER NOT NULL,
    due_date TIMESTAMPTZ,
    priority TEXT CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    labels TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pipeline_card_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    card_id UUID REFERENCES pipeline_cards(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL, -- created, updated, moved, assigned, etc
    old_data JSONB,
    new_data JSONB,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pipeline_card_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    card_id UUID REFERENCES pipeline_cards(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    attachments JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pipeline_automations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID REFERENCES pipelines(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    trigger_type TEXT NOT NULL CHECK (trigger_type IN ('stage_change', 'field_update', 'sla_breach', 'due_date', 'comment_added', 'assigned', 'label_added')),
    trigger_config JSONB NOT NULL,
    action_type TEXT NOT NULL CHECK (action_type IN ('notify', 'update_field', 'move_stage', 'assign_user', 'add_comment', 'send_email', 'webhook')),
    action_config JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_pipeline_departments_dept ON pipeline_departments(department_id);
CREATE INDEX idx_pipelines_department ON pipelines(department_id);
CREATE INDEX idx_pipeline_stages_pipeline ON pipeline_stages(pipeline_id);
CREATE INDEX idx_pipeline_fields_pipeline ON pipeline_fields(pipeline_id);
CREATE INDEX idx_pipeline_cards_pipeline ON pipeline_cards(pipeline_id);
CREATE INDEX idx_pipeline_cards_stage ON pipeline_cards(stage_id);
CREATE INDEX idx_pipeline_cards_assigned ON pipeline_cards USING gin(assigned_to);
CREATE INDEX idx_pipeline_cards_labels ON pipeline_cards USING gin(labels);
CREATE INDEX idx_pipeline_cards_due_date ON pipeline_cards(due_date);
CREATE INDEX idx_pipeline_card_history_card ON pipeline_card_history(card_id);
CREATE INDEX idx_pipeline_card_comments_card ON pipeline_card_comments(card_id);
CREATE INDEX idx_pipeline_automations_pipeline ON pipeline_automations(pipeline_id);

-- Enable RLS
ALTER TABLE pipeline_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipelines ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_card_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_card_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_automations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view active pipeline departments"
    ON pipeline_departments FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage pipeline departments"
    ON pipeline_departments FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view active pipelines"
    ON pipelines FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage pipelines"
    ON pipelines FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view active stages"
    ON pipeline_stages FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage stages"
    ON pipeline_stages FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view active fields"
    ON pipeline_fields FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage fields"
    ON pipeline_fields FOR ALL
    USING (is_admin());

CREATE POLICY "Users can view assigned cards"
    ON pipeline_cards FOR SELECT
    USING (
        is_active = true 
        AND (
            auth.uid() = ANY(assigned_to)
            OR created_by = auth.uid()
            OR EXISTS (
                SELECT 1 FROM user_group_members ugm
                JOIN user_groups ug ON ugm.group_id = ug.id
                WHERE ugm.user_id = auth.uid()
                AND ug.permissions ? 'view_all_cards'
            )
            OR is_admin()
        )
    );

CREATE POLICY "Users can manage their cards"
    ON pipeline_cards FOR ALL
    USING (
        auth.uid() = ANY(assigned_to)
        OR created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM user_group_members ugm
            JOIN user_groups ug ON ugm.group_id = ug.id
            WHERE ugm.user_id = auth.uid()
            AND ug.permissions ? 'manage_all_cards'
        )
        OR is_admin()
    );

CREATE POLICY "Users can view card history"
    ON pipeline_card_history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM pipeline_cards pc
            WHERE pc.id = card_id
            AND (
                auth.uid() = ANY(pc.assigned_to)
                OR pc.created_by = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM user_group_members ugm
                    JOIN user_groups ug ON ugm.group_id = ug.id
                    WHERE ugm.user_id = auth.uid()
                    AND ug.permissions ? 'view_all_cards'
                )
                OR is_admin()
            )
        )
    );

CREATE POLICY "Users can view card comments"
    ON pipeline_card_comments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM pipeline_cards pc
            WHERE pc.id = card_id
            AND (
                auth.uid() = ANY(pc.assigned_to)
                OR pc.created_by = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM user_group_members ugm
                    JOIN user_groups ug ON ugm.group_id = ug.id
                    WHERE ugm.user_id = auth.uid()
                    AND ug.permissions ? 'view_all_cards'
                )
                OR is_admin()
            )
        )
    );

CREATE POLICY "Users can add comments"
    ON pipeline_card_comments FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM pipeline_cards pc
            WHERE pc.id = card_id
            AND (
                auth.uid() = ANY(pc.assigned_to)
                OR pc.created_by = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM user_group_members ugm
                    JOIN user_groups ug ON ugm.group_id = ug.id
                    WHERE ugm.user_id = auth.uid()
                    AND ug.permissions ? 'manage_all_cards'
                )
                OR is_admin()
            )
        )
    );

CREATE POLICY "Admin can manage automations"
    ON pipeline_automations FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view active automations"
    ON pipeline_automations FOR SELECT
    USING (is_active = true);

-- Create functions for pipeline operations
CREATE OR REPLACE FUNCTION move_pipeline_card(
    card_uuid UUID,
    new_stage_uuid UUID,
    new_order INTEGER
)
RETURNS void AS $$
BEGIN
    -- Update card position
    UPDATE pipeline_cards
    SET 
        stage_id = new_stage_uuid,
        order_num = new_order,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = card_uuid;

    -- Log the change
    INSERT INTO pipeline_card_history (
        card_id,
        user_id,
        action,
        old_data,
        new_data,
        ip_address,
        user_agent
    )
    SELECT
        card_uuid,
        auth.uid(),
        'moved',
        jsonb_build_object(
            'stage_id', stage_id,
            'order_num', order_num
        ),
        jsonb_build_object(
            'stage_id', new_stage_uuid,
            'order_num', new_order
        ),
        current_setting('request.headers', true)::json->>'x-real-ip',
        current_setting('request.headers', true)::json->>'user-agent'
    FROM pipeline_cards
    WHERE id = card_uuid;

    -- Execute automations
    PERFORM execute_pipeline_automation(card_uuid, 'stage_change');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION execute_pipeline_automation(
    card_uuid UUID,
    trigger_type TEXT,
    trigger_data JSONB DEFAULT '{}'
)
RETURNS void AS $$
DECLARE
    automation record;
BEGIN
    FOR automation IN
        SELECT *
        FROM pipeline_automations
        WHERE pipeline_id = (
            SELECT pipeline_id 
            FROM pipeline_cards 
            WHERE id = card_uuid
        )
        AND trigger_type = execute_pipeline_automation.trigger_type
        AND is_active = true
    LOOP
        CASE automation.action_type
            WHEN 'notify' THEN
                INSERT INTO notifications (
                    user_id,
                    title,
                    message
                )
                SELECT
                    unnest(assigned_to),
                    automation.action_config->>'title',
                    automation.action_config->>'message'
                FROM pipeline_cards
                WHERE id = card_uuid;
                
            WHEN 'move_stage' THEN
                PERFORM move_pipeline_card(
                    card_uuid,
                    (automation.action_config->>'stage_id')::uuid,
                    (
                        SELECT COALESCE(MAX(order_num), 0) + 1
                        FROM pipeline_cards
                        WHERE stage_id = (automation.action_config->>'stage_id')::uuid
                    )
                );
                
            WHEN 'assign_user' THEN
                UPDATE pipeline_cards
                SET 
                    assigned_to = array_append(
                        assigned_to,
                        (automation.action_config->>'user_id')::uuid
                    ),
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = card_uuid;
                
            WHEN 'add_comment' THEN
                INSERT INTO pipeline_card_comments (
                    card_id,
                    user_id,
                    content
                )
                VALUES (
                    card_uuid,
                    auth.uid(),
                    automation.action_config->>'content'
                );

            WHEN 'send_email' THEN
                -- Here you would integrate with your email service
                -- For now, we'll just log it
                INSERT INTO pipeline_card_history (
                    card_id,
                    user_id,
                    action,
                    details
                )
                VALUES (
                    card_uuid,
                    auth.uid(),
                    'email_sent',
                    automation.action_config
                );

            WHEN 'webhook' THEN
                -- Here you would make an HTTP request to the webhook URL
                -- For now, we'll just log it
                INSERT INTO pipeline_card_history (
                    card_id,
                    user_id,
                    action,
                    details
                )
                VALUES (
                    card_uuid,
                    auth.uid(),
                    'webhook_triggered',
                    automation.action_config
                );
        END CASE;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check SLA breaches
CREATE OR REPLACE FUNCTION check_pipeline_sla()
RETURNS void AS $$
DECLARE
    card record;
    stage record;
    breach_hours integer;
BEGIN
    FOR card IN
        SELECT pc.*, ps.sla_hours
        FROM pipeline_cards pc
        JOIN pipeline_stages ps ON pc.stage_id = ps.id
        WHERE pc.is_active = true
        AND ps.sla_hours IS NOT NULL
    LOOP
        breach_hours := EXTRACT(EPOCH FROM (NOW() - card.updated_at))/3600 - card.stage.sla_hours;
        
        IF breach_hours > 0 THEN
            -- Insert notification for each assigned user
            INSERT INTO notifications (
                user_id,
                title,
                message
            )
            SELECT
                unnest(assigned_to),
                'SLA Breach Alert',
                'Card ' || card.title || ' has breached SLA by ' || breach_hours || ' hours'
            FROM pipeline_cards
            WHERE id = card.id;
            
            -- Execute automation rules for SLA breach
            PERFORM execute_pipeline_automation(card.id, 'sla_breach');
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get pipeline statistics
CREATE OR REPLACE FUNCTION get_pipeline_stats(pipeline_uuid UUID)
RETURNS TABLE (
    total_cards BIGINT,
    cards_by_stage JSON,
    cards_by_priority JSON,
    avg_completion_time INTERVAL,
    sla_breach_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH stats AS (
        SELECT
            COUNT(*) as total,
            jsonb_object_agg(
                ps.name,
                COUNT(*) FILTER (WHERE pc.stage_id = ps.id)
            ) as by_stage,
            jsonb_object_agg(
                COALESCE(pc.priority, 'none'),
                COUNT(*)
            ) as by_priority,
            AVG(
                CASE 
                    WHEN pc.stage_id = (
                        SELECT id FROM pipeline_stages 
                        WHERE pipeline_id = pipeline_uuid 
                        ORDER BY order_num DESC 
                        LIMIT 1
                    )
                    THEN pc.updated_at - pc.created_at
                END
            ) as avg_time,
            COUNT(*) FILTER (
                WHERE EXISTS (
                    SELECT 1 FROM pipeline_stages ps
                    WHERE ps.id = pc.stage_id
                    AND ps.sla_hours IS NOT NULL
                    AND EXTRACT(EPOCH FROM (NOW() - pc.updated_at))/3600 > ps.sla_hours
                )
            ) as sla_breaches
        FROM pipeline_cards pc
        JOIN pipeline_stages ps ON pc.stage_id = ps.id
        WHERE pc.pipeline_id = pipeline_uuid
        AND pc.is_active = true
        GROUP BY pc.pipeline_id
    )
    SELECT
        total::BIGINT,
        by_stage::JSON,
        by_priority::JSON,
        avg_time,
        sla_breaches::BIGINT
    FROM stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add pipeline permissions to user_groups
ALTER TABLE user_groups
ADD COLUMN IF NOT EXISTS pipeline_permissions JSONB DEFAULT '{
    "departments": [],
    "view_all_cards": false,
    "manage_all_cards": false,
    "manage_automations": false
}'::jsonb;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;