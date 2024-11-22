-- Function to get course statistics
CREATE OR REPLACE FUNCTION get_course_statistics()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  WITH course_stats AS (
    SELECT
      c.id,
      c.title,
      COUNT(DISTINCT lp.user_id) as total_students,
      COUNT(DISTINCT CASE WHEN lp.completed THEN lp.user_id END) as completed_students,
      ROUND(
        COUNT(DISTINCT CASE WHEN lp.completed THEN lp.user_id END)::NUMERIC /
        NULLIF(COUNT(DISTINCT lp.user_id), 0) * 100,
        2
      ) as completion_rate
    FROM courses c
    LEFT JOIN lessons l ON l.course_id = c.id
    LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id
    GROUP BY c.id, c.title
  ),
  daily_progress AS (
    SELECT
      DATE_TRUNC('day', lp.created_at) as date,
      COUNT(*) as count
    FROM lesson_progress lp
    WHERE lp.created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE_TRUNC('day', lp.created_at)
    ORDER BY date
  )
  SELECT json_build_object(
    'courses', (SELECT json_agg(course_stats.*) FROM course_stats),
    'progression', (SELECT json_agg(daily_progress.*) FROM daily_progress)
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to get user statistics
CREATE OR REPLACE FUNCTION get_user_statistics()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  WITH user_stats AS (
    SELECT
      u.id,
      u.email,
      COUNT(DISTINCT lp.lesson_id) as completed_lessons,
      COUNT(DISTINCT c.id) as enrolled_courses,
      COALESCE(up.points, 0) as total_points,
      up.level
    FROM auth.users u
    LEFT JOIN lesson_progress lp ON lp.user_id = u.id
    LEFT JOIN lessons l ON l.id = lp.lesson_id
    LEFT JOIN courses c ON c.id = l.course_id
    LEFT JOIN user_progress up ON up.user_id = u.id
    GROUP BY u.id, u.email, up.points, up.level
  )
  SELECT json_build_object(
    'users', (SELECT json_agg(user_stats.*) FROM user_stats)
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql;