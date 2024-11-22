-- Fix course ratings column name
BEGIN;

-- Drop existing table and recreate with correct column name
DROP TABLE IF EXISTS course_ratings CASCADE;

CREATE TABLE course_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id, user_id)
);

-- Create indexes
CREATE INDEX idx_course_ratings_module ON course_ratings(module_id);
CREATE INDEX idx_course_ratings_user ON course_ratings(user_id);

-- Enable RLS
ALTER TABLE course_ratings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can rate courses"
    ON course_ratings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their ratings"
    ON course_ratings FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Everyone can view ratings"
    ON course_ratings FOR SELECT
    USING (true);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;