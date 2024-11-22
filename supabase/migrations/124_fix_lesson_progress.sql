-- Fix lesson progress relationship
BEGIN;

-- First backup existing data
CREATE TEMP TABLE lesson_progress_backup AS 
SELECT * FROM lesson_progress;

-- Drop existing table and recreate with correct relationship
DROP TABLE IF EXISTS lesson_progress CASCADE;

CREATE TABLE lesson_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    completed BOOLEAN DEFAULT FALSE,
    score NUMERIC(4,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, lesson_id)
);

-- Create indexes
CREATE INDEX idx_lesson_progress_user ON lesson_progress(user_id);
CREATE INDEX idx_lesson_progress_lesson ON lesson_progress(lesson_id);
CREATE INDEX idx_lesson_progress_completed ON lesson_progress(completed);

-- Restore data
INSERT INTO lesson_progress (
    id,
    user_id,
    lesson_id,
    completed,
    score,
    created_at,
    updated_at
)
SELECT 
    id,
    user_id,
    lesson_id,
    completed,
    score,
    created_at,
    updated_at
FROM lesson_progress_backup;

-- Drop backup table
DROP TABLE lesson_progress_backup;

-- Enable RLS
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can manage their own progress"
    ON lesson_progress FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Admin can view all progress"
    ON lesson_progress FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

-- Create function to update module progress
CREATE OR REPLACE FUNCTION update_module_progress()
RETURNS TRIGGER AS $$
BEGIN
    -- If lesson is completed, check if all lessons in module are completed
    IF NEW.completed THEN
        -- Insert notification
        INSERT INTO notifications (
            user_id,
            title,
            message
        )
        SELECT
            NEW.user_id,
            'Aula concluída',
            'Você completou uma nova aula!'
        WHERE NOT EXISTS (
            SELECT 1 FROM notifications
            WHERE user_id = NEW.user_id
            AND title = 'Aula concluída'
            AND created_at > NOW() - INTERVAL '1 minute'
        );

        -- Check if all lessons are completed
        IF NOT EXISTS (
            SELECT 1
            FROM lessons l
            LEFT JOIN lesson_progress lp ON l.id = lp.lesson_id AND lp.user_id = NEW.user_id
            WHERE l.module_id = (SELECT module_id FROM lessons WHERE id = NEW.lesson_id)
            AND (lp.completed IS NULL OR lp.completed = false)
        ) THEN
            -- Insert module completion notification
            INSERT INTO notifications (
                user_id,
                title,
                message
            )
            SELECT
                NEW.user_id,
                'Módulo concluído',
                'Parabéns! Você completou todas as aulas do módulo!';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for progress updates
DROP TRIGGER IF EXISTS update_module_progress_trigger ON lesson_progress;
CREATE TRIGGER update_module_progress_trigger
    AFTER INSERT OR UPDATE ON lesson_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_module_progress();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;