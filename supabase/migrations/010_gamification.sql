-- Create user progress table
CREATE TABLE IF NOT EXISTS user_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  points INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  badges JSONB DEFAULT '[]',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

-- Create points history table
CREATE TABLE IF NOT EXISTS points_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  points INTEGER NOT NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Function to award points
CREATE OR REPLACE FUNCTION award_points(
  user_uuid UUID,
  points_amount INTEGER,
  points_reason TEXT
) RETURNS void AS $$
BEGIN
  -- Add points to user progress
  INSERT INTO user_progress (user_id, points)
  VALUES (user_uuid, points_amount)
  ON CONFLICT (user_id)
  DO UPDATE SET
    points = user_progress.points + points_amount,
    updated_at = CURRENT_TIMESTAMP;

  -- Record points history
  INSERT INTO points_history (user_id, points, reason)
  VALUES (user_uuid, points_amount, points_reason);

  -- Check if user should level up
  UPDATE user_progress
  SET level = FLOOR(SQRT(points / 100)) + 1
  WHERE user_id = user_uuid;
END;
$$ LANGUAGE plpgsql;

-- Function to check achievements
CREATE OR REPLACE FUNCTION check_achievements(user_uuid UUID)
RETURNS void AS $$
DECLARE
  current_points INTEGER;
  current_badges JSONB;
  new_badges JSONB = '[]'::JSONB;
BEGIN
  -- Get current user progress
  SELECT points, badges INTO current_points, current_badges
  FROM user_progress
  WHERE user_id = user_uuid;

  -- Check point milestones
  IF current_points >= 1000 AND NOT current_badges ? 'points_1000' THEN
    new_badges = new_badges || '{"id": "points_1000", "name": "Milha Extra", "description": "Alcançou 1000 pontos"}'::JSONB;
  END IF;

  IF current_points >= 5000 AND NOT current_badges ? 'points_5000' THEN
    new_badges = new_badges || '{"id": "points_5000", "name": "Dedicação Total", "description": "Alcançou 5000 pontos"}'::JSONB;
  END IF;

  -- Update badges if new ones were earned
  IF jsonb_array_length(new_badges) > 0 THEN
    UPDATE user_progress
    SET badges = badges || new_badges
    WHERE user_id = user_uuid;

    -- Notify user about new badges
    INSERT INTO notifications (user_id, title, message)
    SELECT
      user_uuid,
      'Nova Conquista Desbloqueada!',
      b->>'name' || ' - ' || b->>'description'
    FROM jsonb_array_elements(new_badges) AS b;
  END IF;
END;
$$ LANGUAGE plpgsql;