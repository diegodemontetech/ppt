-- Fix critical issues with courses and quiz system
BEGIN;

-- Add technical_lead to modules
ALTER TABLE modules
ADD COLUMN IF NOT EXISTS technical_lead TEXT,
ADD COLUMN IF NOT EXISTS estimated_duration INTEGER DEFAULT 0;

-- Set fixed seal URL
ALTER TABLE modules 
DROP COLUMN IF EXISTS seal_url;

-- Create constant for seal URL
CREATE OR REPLACE FUNCTION get_seal_url()
RETURNS TEXT AS $$
BEGIN
    RETURN 'https://materiaisst2023.lojazap.com/_core/_uploads/19281/2024/04/12042004240eicbg8hg1.webp';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Fix live events table
ALTER TABLE live_events
DROP CONSTRAINT IF EXISTS live_events_instructor_id_fkey;

ALTER TABLE live_events
DROP COLUMN IF EXISTS instructor_id,
ADD COLUMN IF NOT EXISTS streaming_responsible TEXT;

-- Update certificates view to include technical lead
CREATE OR REPLACE VIEW certificate_details AS
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

-- Create lesson attachments table
CREATE TABLE IF NOT EXISTS lesson_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    file_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS
ALTER TABLE lesson_attachments ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view attachments"
    ON lesson_attachments FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage attachments"
    ON lesson_attachments FOR ALL
    USING (is_admin());

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_lesson_attachments_lesson ON lesson_attachments(lesson_id);

-- Create storage bucket for attachments if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('attachments', 'attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for attachments
CREATE POLICY "Users can upload attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'attachments');

CREATE POLICY "Public attachment access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'attachments');

CREATE POLICY "Admin attachment deletion"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'attachments' 
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