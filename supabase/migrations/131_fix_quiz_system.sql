-- Fix quiz system aggressively
BEGIN;

-- Drop existing quiz tables
DROP TABLE IF EXISTS quizzes CASCADE;

-- Create quizzes table with proper constraints
CREATE TABLE quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    questions JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(lesson_id)
);

-- Create index
CREATE INDEX idx_quizzes_lesson ON quizzes(lesson_id);

-- Enable RLS
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view quizzes"
    ON quizzes FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage quizzes"
    ON quizzes FOR ALL
    USING (is_admin());

-- Create function to validate quiz questions
CREATE OR REPLACE FUNCTION validate_quiz_questions()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure questions is an array
    IF NOT jsonb_typeof(NEW.questions) = 'array' THEN
        RAISE EXCEPTION 'questions must be an array';
    END IF;

    -- Validate each question
    FOR i IN 0..jsonb_array_length(NEW.questions) - 1 LOOP
        -- Check required fields
        IF NOT (
            NEW.questions->i ? 'text' AND
            NEW.questions->i ? 'options' AND
            NEW.questions->i ? 'correctOption'
        ) THEN
            RAISE EXCEPTION 'Each question must have text, options, and correctOption';
        END IF;

        -- Validate options array
        IF NOT jsonb_typeof(NEW.questions->i->'options') = 'array' THEN
            RAISE EXCEPTION 'options must be an array';
        END IF;

        -- Validate correctOption
        IF NOT (
            (NEW.questions->i->>'correctOption')::int >= 0 AND
            (NEW.questions->i->>'correctOption')::int < jsonb_array_length(NEW.questions->i->'options')
        ) THEN
            RAISE EXCEPTION 'correctOption must be a valid index in options array';
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for quiz validation
CREATE TRIGGER validate_quiz_questions_trigger
    BEFORE INSERT OR UPDATE ON quizzes
    FOR EACH ROW
    EXECUTE FUNCTION validate_quiz_questions();

-- Create function to update lesson progress when quiz is completed
CREATE OR REPLACE FUNCTION update_lesson_progress_on_quiz()
RETURNS TRIGGER AS $$
BEGIN
    -- Update lesson progress
    INSERT INTO lesson_progress (
        user_id,
        lesson_id,
        completed,
        score
    )
    VALUES (
        auth.uid(),
        NEW.lesson_id,
        true,
        NEW.score
    )
    ON CONFLICT (user_id, lesson_id)
    DO UPDATE SET
        completed = true,
        score = EXCLUDED.score,
        updated_at = CURRENT_TIMESTAMP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;