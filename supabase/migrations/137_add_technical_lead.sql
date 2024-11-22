-- Add technical lead field to modules
BEGIN;

-- Add technical_lead field to modules
ALTER TABLE modules
ADD COLUMN IF NOT EXISTS technical_lead TEXT;

-- Update existing modules to use instructor name as technical lead
UPDATE modules
SET technical_lead = 'Instrutor do Curso'
WHERE technical_lead IS NULL;

-- Update certificates view/function to use technical lead
CREATE OR REPLACE FUNCTION get_module_certificate(
    module_uuid UUID,
    user_uuid UUID
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    module_id UUID,
    score NUMERIC(4,2),
    technical_lead TEXT,
    seal_url TEXT,
    issued_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.user_id,
        c.module_id,
        c.score,
        m.technical_lead,
        m.seal_url,
        c.issued_at
    FROM certificates c
    JOIN modules m ON c.module_id = m.id
    WHERE c.module_id = module_uuid
    AND c.user_id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;