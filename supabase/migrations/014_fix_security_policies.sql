-- Fix notifications table policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON notifications;

CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (true);

-- Fix lesson progress trigger
CREATE OR REPLACE FUNCTION update_lesson_progress()
RETURNS TRIGGER AS $$
BEGIN
  -- Get course_id from lesson
  WITH course_info AS (
    SELECT course_id
    FROM lessons
    WHERE id = NEW.lesson_id
  )
  -- Insert notification
  INSERT INTO notifications (
    user_id,
    title,
    message
  )
  SELECT
    NEW.user_id,
    CASE
      WHEN NEW.completed THEN 'Aula concluída'
      ELSE 'Progresso atualizado'
    END,
    CASE
      WHEN NEW.completed THEN 'Você completou uma nova aula!'
      ELSE 'Seu progresso foi atualizado'
    END;

  -- Award points if completed
  IF NEW.completed THEN
    PERFORM award_points(
      NEW.user_id,
      CASE
        WHEN NEW.score IS NOT NULL THEN (NEW.score * 10)::INTEGER
        ELSE 50
      END,
      'Aula concluída'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix users table and policies
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  points INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view all profiles" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;

CREATE POLICY "Users can view all profiles"
  ON public.users FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- Fix live events table and relationships
ALTER TABLE live_events DROP CONSTRAINT IF EXISTS live_events_instructor_id_fkey;

ALTER TABLE live_events
  ADD CONSTRAINT live_events_instructor_id_fkey
  FOREIGN KEY (instructor_id)
  REFERENCES public.users(id)
  ON DELETE CASCADE;

-- Fix user sync trigger
CREATE OR REPLACE FUNCTION sync_user_data()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (
    id,
    full_name,
    points,
    level
  )
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    COALESCE((NEW.raw_user_meta_data->>'points')::INTEGER, 0),
    COALESCE((NEW.raw_user_meta_data->>'level')::INTEGER, 1)
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    points = EXCLUDED.points,
    level = EXCLUDED.level,
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION sync_user_data();

-- Fix ranking function to use public.users
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
    u.full_name,
    u.points,
    ROW_NUMBER() OVER (ORDER BY u.points DESC) as rank
  FROM public.users u
  ORDER BY u.points DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;