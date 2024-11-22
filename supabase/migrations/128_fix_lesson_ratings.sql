-- Fix lesson ratings relationship
BEGIN;

-- Create lesson_ratings table
CREATE TABLE IF NOT EXISTS lesson_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(lesson_id, user_id)
);

-- Create indexes
CREATE INDEX idx_lesson_ratings_lesson ON lesson_ratings(lesson_id);
CREATE INDEX idx_lesson_ratings_user ON lesson_ratings(user_id);

-- Enable RLS
ALTER TABLE lesson_ratings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can rate lessons"
    ON lesson_ratings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their ratings"
    ON lesson_ratings FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Everyone can view ratings"
    ON lesson_ratings FOR SELECT
    USING (true);

-- Create function to calculate lesson rating
CREATE OR REPLACE FUNCTION get_lesson_rating(lesson_uuid UUID)
RETURNS TABLE (
    average_rating NUMERIC,
    total_ratings BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROUND(AVG(rating)::numeric, 1) as average_rating,
        COUNT(*)::bigint as total_ratings
    FROM lesson_ratings
    WHERE lesson_id = lesson_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to calculate module rating
CREATE OR REPLACE FUNCTION get_module_rating(module_uuid UUID)
RETURNS TABLE (
    average_rating NUMERIC,
    total_ratings BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROUND(AVG(lr.rating)::numeric, 1) as average_rating,
        COUNT(DISTINCT lr.id)::bigint as total_ratings
    FROM modules m
    JOIN lessons l ON l.module_id = m.id
    JOIN lesson_ratings lr ON lr.lesson_id = l.id
    WHERE m.id = module_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_lesson_rating(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_module_rating(UUID) TO authenticated;

-- Update get_module_stats function to include ratings
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
            ROUND(AVG(lr.rating)::NUMERIC, 1) as avg_rating,
            COUNT(DISTINCT lr.id) as total_rating
        FROM modules m
        LEFT JOIN lessons l ON l.module_id = m.id
        LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id
        LEFT JOIN lesson_ratings lr ON lr.lesson_id = l.id
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