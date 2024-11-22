-- Add email configuration system
BEGIN;

-- Create email configurations table
CREATE TABLE email_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    purpose TEXT NOT NULL,
    from_name TEXT NOT NULL,
    from_email TEXT NOT NULL,
    reply_to TEXT,
    smtp_host TEXT NOT NULL,
    smtp_port INTEGER NOT NULL,
    smtp_user TEXT NOT NULL,
    smtp_pass TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, purpose)
);

-- Create email templates table
CREATE TABLE email_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    purpose TEXT NOT NULL,
    name TEXT NOT NULL,
    subject TEXT NOT NULL,
    content TEXT NOT NULL,
    variables JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, name)
);

-- Create email logs table
CREATE TABLE email_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    template_id UUID REFERENCES email_templates(id),
    from_email TEXT NOT NULL,
    to_email TEXT NOT NULL,
    subject TEXT NOT NULL,
    content TEXT NOT NULL,
    status TEXT NOT NULL,
    error TEXT,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_email_config_company ON email_configurations(company_id);
CREATE INDEX idx_email_config_purpose ON email_configurations(purpose);
CREATE INDEX idx_email_templates_company ON email_templates(company_id);
CREATE INDEX idx_email_templates_purpose ON email_templates(purpose);
CREATE INDEX idx_email_logs_company ON email_logs(company_id);
CREATE INDEX idx_email_logs_template ON email_logs(template_id);
CREATE INDEX idx_email_logs_status ON email_logs(status);

-- Enable RLS
ALTER TABLE email_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Admin can manage email configurations"
    ON email_configurations FOR ALL
    USING (
        company_id = (
            SELECT company_id 
            FROM auth.users 
            WHERE id = auth.uid()
        )
        AND is_admin()
    );

CREATE POLICY "Admin can manage email templates"
    ON email_templates FOR ALL
    USING (
        company_id = (
            SELECT company_id 
            FROM auth.users 
            WHERE id = auth.uid()
        )
        AND is_admin()
    );

CREATE POLICY "Admin can view email logs"
    ON email_logs FOR SELECT
    USING (
        company_id = (
            SELECT company_id 
            FROM auth.users 
            WHERE id = auth.uid()
        )
        AND is_admin()
    );

-- Insert default email purposes
INSERT INTO email_configurations (company_id, purpose, from_name, from_email, smtp_host, smtp_port, smtp_user, smtp_pass)
SELECT 
    c.id as company_id,
    purpose,
    c.name as from_name,
    c.email as from_email,
    'smtp.gmail.com' as smtp_host,
    587 as smtp_port,
    '' as smtp_user,
    '' as smtp_pass
FROM companies c
CROSS JOIN (
    VALUES 
        ('contracts', 'Contratos'),
        ('notifications', 'Notificações'),
        ('marketing', 'Marketing'),
        ('support', 'Suporte'),
        ('billing', 'Financeiro')
) AS p(purpose, description)
ON CONFLICT DO NOTHING;

-- Create function to send email
CREATE OR REPLACE FUNCTION send_email(
    template_id UUID,
    to_email TEXT,
    variables JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    template email_templates;
    config email_configurations;
    content TEXT;
    subject TEXT;
    log_id UUID;
BEGIN
    -- Get template
    SELECT * INTO template
    FROM email_templates
    WHERE id = template_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Template not found';
    END IF;

    -- Get configuration
    SELECT * INTO config
    FROM email_configurations
    WHERE company_id = template.company_id
    AND purpose = template.purpose
    AND is_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Email configuration not found';
    END IF;

    -- Replace variables in content and subject
    content := template.content;
    subject := template.subject;

    FOR key, value IN SELECT * FROM jsonb_each_text(variables) LOOP
        content := replace(content, '{{' || key || '}}', value);
        subject := replace(subject, '{{' || key || '}}', value);
    END LOOP;

    -- Create log entry
    INSERT INTO email_logs (
        company_id,
        template_id,
        from_email,
        to_email,
        subject,
        content,
        status
    ) VALUES (
        template.company_id,
        template_id,
        config.from_email,
        to_email,
        subject,
        content,
        'pending'
    ) RETURNING id INTO log_id;

    -- Here you would integrate with your email service
    -- For now, we'll just mark it as sent
    UPDATE email_logs
    SET 
        status = 'sent',
        sent_at = CURRENT_TIMESTAMP
    WHERE id = log_id;

    RETURN log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get email configuration
CREATE OR REPLACE FUNCTION get_email_config(purpose TEXT)
RETURNS email_configurations AS $$
BEGIN
    RETURN (
        SELECT *
        FROM email_configurations
        WHERE company_id = (
            SELECT company_id 
            FROM auth.users 
            WHERE id = auth.uid()
        )
        AND purpose = get_email_config.purpose
        AND is_active = true
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;