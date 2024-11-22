-- Fix pipeline system
BEGIN;

-- Create pipeline tables
CREATE TABLE IF NOT EXISTS pipeline_departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(department_id)
);

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

CREATE TABLE IF NOT EXISTS pipeline_fields (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID REFERENCES pipelines(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    label TEXT NOT NULL,
    type TEXT NOT NULL, -- text, textarea, number, date, select, multiselect, file
    mask TEXT, -- CPF, CNPJ, phone, plate, etc
    options JSONB, -- For select/multiselect fields
    validation_rules JSONB, -- Required, min, max, regex, etc
    show_on_card BOOLEAN DEFAULT false,
    order_num INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pipeline_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID REFERENCES pipelines(id) ON DELETE CASCADE,
    stage_id UUID REFERENCES pipeline_stages(id) ON DELETE CASCADE,
    assigned_to UUID[] DEFAULT '{}',
    title TEXT NOT NULL,
    data JSONB NOT NULL DEFAULT '{}',
    order_num INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pipeline_card_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    card_id UUID REFERENCES pipeline_cards(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL, -- created, updated, moved, assigned, etc
    old_data JSONB,
    new_data JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pipeline_automations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID REFERENCES pipelines(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    trigger_type TEXT NOT NULL, -- stage_change, field_update, sla_breach, etc
    trigger_config JSONB NOT NULL,
    action_type TEXT NOT NULL, -- notify, update_field, move_stage, assign_user, etc
    action_config JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_pipeline_departments_dept ON pipeline_departments(department_id);
CREATE INDEX IF NOT EXISTS idx_pipelines_department ON pipelines(department_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_stages_pipeline ON pipeline_stages(pipeline_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_fields_pipeline ON pipeline_fields(pipeline_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_cards_pipeline ON pipeline_cards(pipeline_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_cards_stage ON pipeline_cards(stage_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_cards_assigned ON pipeline_cards USING gin(assigned_to);
CREATE INDEX IF NOT EXISTS idx_pipeline_card_history_card ON pipeline_card_history(card_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_automations_pipeline ON pipeline_automations(pipeline_id);

-- Add pipeline permissions to user_groups
ALTER TABLE user_groups
ADD COLUMN IF NOT EXISTS pipeline_permissions JSONB DEFAULT '{
    "departments": [],
    "view_all_cards": false,
    "manage_all_cards": false,
    "manage_automations": false
}'::jsonb;

-- Create function to check pipeline permissions
CREATE OR REPLACE FUNCTION check_pipeline_permission(
    user_id UUID,
    pipeline_id UUID,
    permission TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM user_group_members ugm
        JOIN user_groups ug ON ugm.group_id = ug.id
        WHERE ugm.user_id = check_pipeline_permission.user_id
        AND (
            ug.pipeline_permissions->>'view_all_cards' = 'true'
            OR pipeline_id = ANY(
                ARRAY(
                    SELECT jsonb_array_elements_text(ug.pipeline_permissions->'departments')::UUID
                )
            )
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle card history
CREATE OR REPLACE FUNCTION log_pipeline_card_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO pipeline_card_history (
        card_id,
        user_id,
        action,
        old_data,
        new_data
    ) VALUES (
        NEW.id,
        auth.uid(),
        CASE
            WHEN TG_OP = 'INSERT' THEN 'created'
            WHEN TG_OP = 'UPDATE' THEN 
                CASE
                    WHEN NEW.stage_id != OLD.stage_id THEN 'moved'
                    WHEN NEW.assigned_to != OLD.assigned_to THEN 'assigned'
                    ELSE 'updated'
                END
            ELSE TG_OP::text
        END,
        CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE row_to_json(OLD) END,
        row_to_json(NEW)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for card history
CREATE TRIGGER log_pipeline_card_changes
    AFTER INSERT OR UPDATE ON pipeline_cards
    FOR EACH ROW
    EXECUTE FUNCTION log_pipeline_card_change();

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

-- Create function to execute automations
CREATE OR REPLACE FUNCTION execute_pipeline_automation(
    card_id UUID,
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
            WHERE id = card_id
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
                WHERE id = card_id;
                
            WHEN 'move_stage' THEN
                UPDATE pipeline_cards
                SET stage_id = (automation.action_config->>'stage_id')::uuid
                WHERE id = card_id;
                
            WHEN 'assign_user' THEN
                UPDATE pipeline_cards
                SET assigned_to = array_append(
                    assigned_to,
                    (automation.action_config->>'user_id')::uuid
                )
                WHERE id = card_id;
                
            WHEN 'update_field' THEN
                UPDATE pipeline_cards
                SET data = jsonb_set(
                    data,
                    string_to_array(automation.action_config->>'field_path', ','),
                    automation.action_config->'field_value'
                )
                WHERE id = card_id;
        END CASE;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE pipeline_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipelines ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_card_history ENABLE ROW LEVEL SECURITY;
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

CREATE POLICY "Users can view cards"
    ON pipeline_cards FOR SELECT
    USING (
        is_active = true 
        AND (
            auth.uid() = ANY(assigned_to)
            OR EXISTS (
                SELECT 1 FROM user_group_members ugm
                JOIN user_groups ug ON ugm.group_id = ug.id
                WHERE ugm.user_id = auth.uid()
                AND ug.pipeline_permissions ? 'view_all_cards'
            )
        )
    );

CREATE POLICY "Users can manage their cards"
    ON pipeline_cards FOR ALL
    USING (
        auth.uid() = ANY(assigned_to)
        OR EXISTS (
            SELECT 1 FROM user_group_members ugm
            JOIN user_groups ug ON ugm.group_id = ug.id
            WHERE ugm.user_id = auth.uid()
            AND ug.pipeline_permissions ? 'manage_all_cards'
        )
    );

CREATE POLICY "Everyone can view card history"
    ON pipeline_card_history FOR SELECT
    USING (true);

CREATE POLICY "System can insert card history"
    ON pipeline_card_history FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Admin can manage automations"
    ON pipeline_automations FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view active automations"
    ON pipeline_automations FOR SELECT
    USING (is_active = true);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;