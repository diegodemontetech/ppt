-- Fix certificate view and relationships
BEGIN;

-- First check if certificates table exists and has correct columns
CREATE TABLE IF NOT EXISTS certificates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    score NUMERIC(4,2),
    issued_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, module_id)
);

-- Drop existing view if exists
DROP VIEW IF EXISTS certificate_details;

-- Create view with correct column references
CREATE VIEW certificate_details AS
SELECT 
    c.id,
    c.user_id,
    c.module_id,
    c.score,
    m.technical_lead,
    m.estimated_duration,
    get_seal_url() as seal_url,
    c.issued_at
FROM certificates c
JOIN modules m ON c.module_id = m.id;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_certificates_user_module 
ON certificates(user_id, module_id);

-- Enable RLS on certificates
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for certificates
CREATE POLICY "Users can view their own certificates"
    ON certificates FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admin can manage certificates"
    ON certificates FOR ALL
    USING (is_admin());

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;