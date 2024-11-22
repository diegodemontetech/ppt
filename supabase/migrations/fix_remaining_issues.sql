-- Fix remaining database issues
BEGIN;

-- Add missing columns to modules table
ALTER TABLE modules
ADD COLUMN IF NOT EXISTS estimated_duration INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS technical_lead TEXT;

-- Fix quizzes relationship with modules
DROP TABLE IF EXISTS quizzes CASCADE;
CREATE TABLE IF NOT EXISTS quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    questions JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id)
);

-- Create user_profiles view
DROP VIEW IF EXISTS user_profiles;
CREATE OR REPLACE VIEW user_profiles AS
SELECT 
    u.id,
    u.email,
    u.raw_user_meta_data->>'full_name' as full_name,
    u.raw_user_meta_data->>'role' as role,
    u.created_at,
    u.updated_at
FROM auth.users u;

-- Fix live events relationship
ALTER TABLE live_events
DROP CONSTRAINT IF EXISTS live_events_instructor_id_fkey;

ALTER TABLE live_events
ADD CONSTRAINT live_events_instructor_id_fkey 
FOREIGN KEY (instructor_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE;

-- Fix pipeline stages unique constraint
ALTER TABLE pipeline_stages
DROP CONSTRAINT IF EXISTS pipeline_stages_pipeline_id_order_num_key;

CREATE UNIQUE INDEX IF NOT EXISTS idx_pipeline_stages_order 
ON pipeline_stages(pipeline_id, order_num) 
WHERE is_active = true;

-- Fix storage policies for PDFs
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can upload pdfs" ON storage.objects;
    DROP POLICY IF EXISTS "Public pdf access" ON storage.objects;
    DROP POLICY IF EXISTS "Admin pdf deletion" ON storage.objects;

    CREATE POLICY "Users can upload pdfs"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'pdfs');

    CREATE POLICY "Public pdf access"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'pdfs');

    CREATE POLICY "Admin pdf deletion"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'pdfs' 
        AND EXISTS (
            SELECT 1 
            FROM auth.users 
            WHERE id = auth.uid() 
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );
END $$;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON user_profiles TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;