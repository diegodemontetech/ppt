-- Fix ranking function
CREATE OR REPLACE FUNCTION get_user_ranking(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
  id UUID,
  full_name TEXT,
  points INTEGER,
  level INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    COALESCE(u.raw_user_meta_data->>'full_name', 'Usuário') as full_name,
    COALESCE((u.raw_user_meta_data->>'points')::INTEGER, 0) as points,
    COALESCE((u.raw_user_meta_data->>'level')::INTEGER, 1) as level
  FROM auth.users u
  WHERE (u.raw_user_meta_data->>'points')::INTEGER > 0
  ORDER BY (u.raw_user_meta_data->>'points')::INTEGER DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;