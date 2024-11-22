-- Add enhanced company settings
BEGIN;

-- Modify companies table with new fields
ALTER TABLE companies
ADD COLUMN IF NOT EXISTS max_users INTEGER NOT NULL DEFAULT 10,
ADD COLUMN IF NOT EXISTS max_admins INTEGER NOT NULL DEFAULT 2,
ADD COLUMN IF NOT EXISTS logo_expanded_url TEXT,
ADD COLUMN IF NOT EXISTS logo_collapsed_url TEXT,
ADD COLUMN IF NOT EXISTS login_bg_url TEXT,
ADD COLUMN IF NOT EXISTS favicon_url TEXT,
ADD COLUMN IF NOT EXISTS custom_domain TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS dns_settings JSONB DEFAULT '{
  "a_record": null,
  "cname_record": null,
  "txt_record": null,
  "dns_provider": null,
  "is_verified": false,
  "last_verification": null
}'::jsonb,
ADD COLUMN IF NOT EXISTS theme_settings JSONB DEFAULT '{
  "primary_color": "#3B82F6",
  "secondary_color": "#1E40AF",
  "accent_color": "#60A5FA"
}'::jsonb,
ADD COLUMN IF NOT EXISTS settings JSONB DEFAULT '{
  "allow_registration": true,
  "require_email_verification": true,
  "show_ranking": true
}'::jsonb;

-- Create company_domains table for domain verification
CREATE TABLE company_domains (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    domain TEXT NOT NULL UNIQUE,
    verification_token TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create function to generate domain verification token
CREATE OR REPLACE FUNCTION generate_domain_verification_token()
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

-- Create function to verify domain
CREATE OR REPLACE FUNCTION verify_company_domain(domain_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    domain_record company_domains;
BEGIN
    SELECT * INTO domain_record
    FROM company_domains
    WHERE id = domain_id;

    IF NOT FOUND THEN
        RETURN false;
    END IF;

    -- Here you would implement actual DNS verification logic
    -- For now, we'll just mark it as verified
    UPDATE company_domains
    SET 
        is_verified = true,
        verified_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = domain_id;

    -- Update company's custom domain
    UPDATE companies
    SET 
        custom_domain = domain_record.domain,
        dns_settings = jsonb_set(
            dns_settings,
            '{is_verified}',
            'true'
        )
    WHERE id = domain_record.company_id;

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check if user is master admin
CREATE OR REPLACE FUNCTION is_master_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM auth.users
        WHERE id = auth.uid()
        AND raw_user_meta_data->>'role' = 'master_admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_domains ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Master admin can manage companies"
    ON companies FOR ALL
    USING (is_master_admin());

CREATE POLICY "Company admins can view their company"
    ON companies FOR SELECT
    USING (id = (
        SELECT company_id 
        FROM auth.users 
        WHERE id = auth.uid()
    ));

CREATE POLICY "Master admin can manage domains"
    ON company_domains FOR ALL
    USING (is_master_admin());

-- Create indexes
CREATE INDEX idx_company_domains_company ON company_domains(company_id);
CREATE INDEX idx_company_domains_domain ON company_domains(domain);
CREATE INDEX idx_company_domains_verified ON company_domains(is_verified);

-- Set master admin
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"master_admin"'
)
WHERE email = 'diegodemontevpj@gmail.com';

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;