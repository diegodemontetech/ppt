-- Fix module relationships and constraints
BEGIN;

-- Drop existing foreign key constraints
ALTER TABLE lessons 
DROP CONSTRAINT IF EXISTS lessons_module_id_fkey;

-- Recreate with correct relationships
ALTER TABLE lessons
ADD CONSTRAINT lessons_module_id_fkey 
FOREIGN KEY (module_id) 
REFERENCES modules(id) 
ON DELETE CASCADE;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_lessons_module ON lessons(module_id);
CREATE INDEX IF NOT EXISTS idx_modules_featured ON modules(is_featured);

-- Create materialized view for module statistics
CREATE MATERIALIZED VIEW IF NOT EXISTS module_stats AS
SELECT 
    m.id as module_id,
    COUNT(DISTINCT lp.user_id) as enrolled_count,
    ROUND(AVG(lr.rating)::numeric, 1) as average_rating,
    COUNT(DISTINCT lr.id) as total_ratings
FROM modules m
LEFT JOIN lessons l ON l.module_id = m.id
LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id
LEFT JOIN lesson_ratings lr ON lr.lesson_id = l.id
GROUP BY m.id;

-- Create unique index on materialized view
CREATE UNIQUE INDEX IF NOT EXISTS idx_module_stats_id ON module_stats(module_id);

-- Create function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_module_stats()
RETURNS trigger AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY module_stats;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to refresh materialized view
DROP TRIGGER IF EXISTS refresh_module_stats_trigger ON lesson_progress;
CREATE TRIGGER refresh_module_stats_trigger
    AFTER INSERT OR UPDATE OR DELETE ON lesson_progress
    FOR EACH STATEMENT
    EXECUTE FUNCTION refresh_module_stats();

DROP TRIGGER IF EXISTS refresh_module_stats_ratings_trigger ON lesson_ratings;
CREATE TRIGGER refresh_module_stats_ratings_trigger
    AFTER INSERT OR UPDATE OR DELETE ON lesson_ratings
    FOR EACH STATEMENT
    EXECUTE FUNCTION refresh_module_stats();

-- Refresh materialized view
REFRESH MATERIALIZED VIEW CONCURRENTLY module_stats;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;