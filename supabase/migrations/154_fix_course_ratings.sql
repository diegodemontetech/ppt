-- Fix course ratings relationship
BEGIN;

-- Drop existing course_ratings table and recreate with correct relationship
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

-- Update get_module_stats function to use correct relationship
CREATE OR REPLACE FUNCTION get_module_stats(module_uuid UUID)
RETURNS TABLE (
    enrolled_count BIGINT,
    average_rating NUMERIC,
    total_ratings BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH stats AS (
        SELECT 
            COUNT(DISTINCT lp.user_id) as enrolled,
            ROUND(AVG(cr.rating)::NUMERIC, 1) as avg_rating,
            COUNT(DISTINCT cr.id) as total_rating
        FROM modules m
        LEFT JOIN lessons l ON l.module_id = m.id
        LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id
        LEFT JOIN course_ratings cr ON cr.module_id = m.id
        WHERE m.id = module_uuid
        GROUP BY m.id
    )
    SELECT
        COALESCE(enrolled, 0)::BIGINT as enrolled_count,
        COALESCE(avg_rating, 0.0)::NUMERIC as average_rating,
        COALESCE(total_rating, 0)::BIGINT as total_ratings
    FROM stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;