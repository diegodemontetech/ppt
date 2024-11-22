-- Fix users table and metadata
CREATE OR REPLACE FUNCTION get_user_metadata(user_row auth.users)
RETURNS jsonb AS $$
  SELECT COALESCE(user_row.raw_user_meta_data, '{}'::jsonb)
$$ LANGUAGE sql STABLE;

-- Fix live events instructor reference
ALTER TABLE live_events DROP CONSTRAINT IF EXISTS live_events_instructor_id_fkey;
ALTER TABLE live_events 
  ADD CONSTRAINT live_events_instructor_id_fkey 
  FOREIGN KEY (instructor_id) 
  REFERENCES auth.users(id) ON DELETE CASCADE;

-- Fix course ratings
CREATE OR REPLACE FUNCTION update_course_rating()
RETURNS TRIGGER AS $$
BEGIN
  -- Notify course subscribers about new rating
  INSERT INTO notifications (
    user_id,
    title,
    message
  )
  SELECT DISTINCT
    lp.user_id,
    'Nova avaliação em curso',
    'Uma aula do curso foi avaliada com ' || NEW.rating || ' estrelas'
  FROM lessons l
  JOIN lesson_progress lp ON l.id = lp.lesson_id
  WHERE l.id = NEW.lesson_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Fix ranking function
CREATE OR REPLACE FUNCTION get_user_ranking(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
  id UUID,
  full_name TEXT,
  points INTEGER,
  rank BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    (u.raw_user_meta_data->>'full_name')::TEXT as full_name,
    (u.raw_user_meta_data->>'points')::INTEGER as points,
    ROW_NUMBER() OVER (ORDER BY (u.raw_user_meta_data->>'points')::INTEGER DESC) as rank
  FROM auth.users u
  WHERE u.raw_user_meta_data->>'points' IS NOT NULL
  ORDER BY (u.raw_user_meta_data->>'points')::INTEGER DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;