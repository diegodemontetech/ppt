-- Create lesson ratings table
CREATE TABLE IF NOT EXISTS lesson_ratings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(lesson_id, user_id)
);

-- Add RLS policies
ALTER TABLE lesson_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all ratings"
  ON lesson_ratings FOR SELECT
  USING (true);

CREATE POLICY "Users can rate lessons once"
  ON lesson_ratings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own ratings"
  ON lesson_ratings FOR UPDATE
  USING (auth.uid() = user_id);

-- Add function to calculate average rating
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
$$ LANGUAGE plpgsql;