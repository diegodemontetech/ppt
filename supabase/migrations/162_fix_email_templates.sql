-- Fix email templates table conflict
BEGIN;

-- Drop existing email-related tables if they exist
DROP TABLE IF EXISTS email_logs CASCADE;
DROP TABLE IF EXISTS email_templates CASCADE;
DROP TABLE IF EXISTS email_configurations CASCADE;

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

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;