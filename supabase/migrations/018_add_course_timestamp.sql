-- Add updated_at trigger for courses
CREATE OR REPLACE FUNCTION update_course_timestamp(lesson_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE courses
  SET updated_at = NOW()
  WHERE id IN (
    SELECT course_id
    FROM lessons
    WHERE id = lesson_id
  );
END;
$$ LANGUAGE plpgsql;

-- Add trigger to update course timestamp when lesson is modified
CREATE OR REPLACE FUNCTION trigger_update_course_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE courses
  SET updated_at = NOW()
  WHERE id = NEW.course_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_course_timestamp
  AFTER INSERT OR UPDATE OR DELETE ON lessons
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_course_timestamp();