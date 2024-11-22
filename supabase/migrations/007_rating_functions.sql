-- Function to calculate average rating for a lesson
CREATE OR REPLACE FUNCTION calculate_lesson_rating(lesson_uuid UUID)
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
$$ LANGUAGE plpgsql;

-- Function to calculate average rating for a course
CREATE OR REPLACE FUNCTION calculate_course_rating(course_uuid UUID)
RETURNS TABLE (
  average_rating NUMERIC,
  total_ratings BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ROUND(AVG(lr.rating)::numeric, 1) as average_rating,
    COUNT(DISTINCT lr.user_id)::bigint as total_ratings
  FROM lessons l
  JOIN lesson_ratings lr ON l.id = lr.lesson_id
  WHERE l.course_id = course_uuid;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update course rating when a lesson is rated
CREATE OR REPLACE FUNCTION update_course_rating()
RETURNS TRIGGER AS $$
BEGIN
  -- Notify course subscribers about new rating
  INSERT INTO notifications (
    user_id,
    title,
    message
  )
  SELECT
    ugm.user_id,
    'Nova avaliação em curso',
    'Uma aula do curso foi avaliada com ' || NEW.rating || ' estrelas'
  FROM lessons l
  JOIN courses c ON l.course_id = c.id
  JOIN user_group_members ugm ON c.group_id = ugm.group_id
  WHERE l.id = NEW.lesson_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER lesson_rating_trigger
  AFTER INSERT OR UPDATE ON lesson_ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_course_rating();