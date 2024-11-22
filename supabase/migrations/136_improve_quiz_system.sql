-- Improve quiz system and course features
BEGIN;

-- Drop existing quiz tables and recreate with module relationship
DROP TABLE IF EXISTS quizzes CASCADE;

CREATE TABLE quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    questions JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id)
);

-- Add estimated_duration to modules
ALTER TABLE modules
ADD COLUMN IF NOT EXISTS estimated_duration INTEGER DEFAULT 0;

-- Add signature_name to modules
ALTER TABLE modules
ADD COLUMN IF NOT EXISTS signature_name TEXT;

-- Add seal_url to modules
ALTER TABLE modules
ADD COLUMN IF NOT EXISTS seal_url TEXT;

-- Create lesson_attachments table
CREATE TABLE lesson_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    file_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_quizzes_module ON quizzes(module_id);
CREATE INDEX idx_lesson_attachments_lesson ON lesson_attachments(lesson_id);

-- Enable RLS
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_attachments ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view quizzes"
    ON quizzes FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage quizzes"
    ON quizzes FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view attachments"
    ON lesson_attachments FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage attachments"
    ON lesson_attachments FOR ALL
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
DROP TRIGGER IF EXISTS validate_quiz_questions_trigger ON quizzes;
CREATE TRIGGER validate_quiz_questions_trigger
    BEFORE INSERT OR UPDATE ON quizzes
    FOR EACH ROW
    EXECUTE FUNCTION validate_quiz_questions();

-- Update module completion function to include quiz score
CREATE OR REPLACE FUNCTION handle_module_completion()
RETURNS TRIGGER AS $$
DECLARE
    module_id UUID;
    quiz_score NUMERIC;
BEGIN
    -- Get module_id from lesson
    SELECT l.module_id INTO module_id
    FROM lessons l
    WHERE l.id = NEW.lesson_id;

    -- If this is a quiz completion
    IF NEW.score IS NOT NULL THEN
        quiz_score := NEW.score;
    END IF;

    -- Check if all lessons are completed
    IF NOT EXISTS (
        SELECT 1
        FROM lessons l
        LEFT JOIN lesson_progress lp ON l.id = lp.lesson_id AND lp.user_id = NEW.user_id
        WHERE l.module_id = module_id
        AND (lp.completed IS NULL OR lp.completed = false)
    ) THEN
        -- Insert certificate with quiz score
        INSERT INTO certificates (
            user_id,
            module_id,
            score,
            issued_at
        ) VALUES (
            NEW.user_id,
            module_id,
            quiz_score,
            CURRENT_TIMESTAMP
        )
        ON CONFLICT (user_id, module_id) DO UPDATE
        SET score = EXCLUDED.score,
            issued_at = CURRENT_TIMESTAMP;

        -- Insert completion notification
        INSERT INTO notifications (
            user_id,
            title,
            message
        ) VALUES (
            NEW.user_id,
            'Módulo Concluído',
            'Parabéns! Você completou o módulo com nota ' || quiz_score::TEXT || '!'
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for module completion
DROP TRIGGER IF EXISTS handle_module_completion_trigger ON lesson_progress;
CREATE TRIGGER handle_module_completion_trigger
    AFTER INSERT OR UPDATE ON lesson_progress
    FOR EACH ROW
    EXECUTE FUNCTION handle_module_completion();

-- Add score column to certificates if not exists
ALTER TABLE certificates
ADD COLUMN IF NOT EXISTS score NUMERIC(4,2);

-- Create storage bucket for attachments if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('attachments', 'attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for attachments
CREATE POLICY "Users can upload attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'attachments');

CREATE POLICY "Public attachment access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'attachments');

CREATE POLICY "Admin attachment deletion"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'attachments' 
  AND EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'role' = 'admin'
  )
);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;