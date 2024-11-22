-- Create certificates table
CREATE TABLE IF NOT EXISTS certificates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  issued_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  certificate_url TEXT,
  UNIQUE(user_id, course_id)
);

-- Add RLS policies
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own certificates"
  ON certificates FOR SELECT
  USING (auth.uid() = user_id);

-- Function to automatically generate certificate when course is completed
CREATE OR REPLACE FUNCTION generate_certificate()
RETURNS TRIGGER AS $$
DECLARE
  course_lessons INT;
  completed_lessons INT;
BEGIN
  -- Get total number of lessons for the course
  SELECT COUNT(*) INTO course_lessons
  FROM lessons
  WHERE course_id = NEW.course_id;

  -- Get number of completed lessons for the user
  SELECT COUNT(*) INTO completed_lessons
  FROM lessons l
  JOIN lesson_progress lp ON l.id = lp.lesson_id
  WHERE l.course_id = NEW.course_id
  AND lp.user_id = NEW.user_id
  AND lp.completed = true;

  -- If all lessons are completed, generate certificate
  IF completed_lessons = course_lessons THEN
    INSERT INTO certificates (user_id, course_id)
    VALUES (NEW.user_id, NEW.course_id)
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for certificate generation
CREATE TRIGGER generate_certificate_trigger
  AFTER INSERT OR UPDATE ON lesson_progress
  FOR EACH ROW
  EXECUTE FUNCTION generate_certificate();