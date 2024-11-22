-- Add missing indexes and optimize queries
BEGIN;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_modules_featured ON modules(is_featured);
CREATE INDEX IF NOT EXISTS idx_modules_company_featured ON modules(company_id, is_featured);
CREATE INDEX IF NOT EXISTS idx_live_events_company_starts ON live_events(company_id, starts_at);
CREATE INDEX IF NOT EXISTS idx_lesson_progress_user_lesson ON lesson_progress(user_id, lesson_id);
CREATE INDEX IF NOT EXISTS idx_lesson_ratings_lesson ON lesson_ratings(lesson_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, read);

-- Create materialized view for course statistics
CREATE MATERIALIZED VIEW IF NOT EXISTS module_stats AS
SELECT 
  m.id,
  m.title,
  COUNT(DISTINCT lp.user_id) as enrolled_count,
  ROUND(AVG(lr.rating)::numeric, 1) as average_rating,
  COUNT(DISTINCT lr.id) as total_ratings
FROM modules m
LEFT JOIN lessons l ON l.module_id = m.id
LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id
LEFT JOIN lesson_ratings lr ON lr.lesson_id = l.id
GROUP BY m.id, m.title;

-- Create index on materialized view
CREATE UNIQUE INDEX IF NOT EXISTS idx_module_stats_id ON module_stats(id);

-- Create function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_module_stats()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY module_stats;
  RETURN NULL;
END;
$$;

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

COMMIT;