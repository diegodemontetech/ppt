-- Fix company schema and add missing columns
BEGIN;

-- Add missing columns to companies table
ALTER TABLE companies
ADD COLUMN IF NOT EXISTS subdomain TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS domain TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS login_bg_url TEXT;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_companies_subdomain ON companies(subdomain);
CREATE INDEX IF NOT EXISTS idx_companies_domain ON companies(domain);

-- Update existing companies with default subdomain
UPDATE companies 
SET subdomain = LOWER(REGEXP_REPLACE(name, '[^a-zA-Z0-9]', '-', 'g'))
WHERE subdomain IS NULL;

-- Create function to generate subdomain
CREATE OR REPLACE FUNCTION generate_subdomain(name TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN LOWER(REGEXP_REPLACE(name, '[^a-zA-Z0-9]', '-', 'g'));
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate subdomain
CREATE OR REPLACE FUNCTION set_company_subdomain()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.subdomain IS NULL THEN
    NEW.subdomain := generate_subdomain(NEW.name);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_company_subdomain_trigger
  BEFORE INSERT ON companies
  FOR EACH ROW
  EXECUTE FUNCTION set_company_subdomain();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;