-- Fix module statistics function
BEGIN;

-- Drop existing function
DROP FUNCTION IF EXISTS get_module_stats(UUID);

-- Create function with explicit types and better NULL handling
CREATE OR REPLACE FUNCTION get_module_stats(module_uuid UUID)
RETURNS TABLE (
    enrolled_count BIGINT,
    average_rating NUMERIC,
    total_ratings BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH lesson_stats AS (
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
    FROM lesson_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_module_stats(UUID) TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;