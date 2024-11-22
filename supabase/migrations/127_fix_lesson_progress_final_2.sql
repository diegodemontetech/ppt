-- Fix lesson progress relationship aggressively - Final attempt 2
BEGIN;

-- Drop all related tables and start fresh
DROP TABLE IF EXISTS lesson_progress CASCADE;
DROP TABLE IF EXISTS lesson_ratings CASCADE;
DROP TABLE IF EXISTS quizzes CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS modules CASCADE;

-- Create modules table
CREATE TABLE modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    bg_color TEXT DEFAULT '#3B82F6',
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create lessons table
CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    video_url TEXT NOT NULL,
    order_num INTEGER NOT NULL,
    duration INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id, order_num)
);

-- Create lesson_progress table
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
CREATE INDEX idx_modules_category ON modules(category_id);
CREATE INDEX idx_lessons_module ON lessons(module_id);
CREATE INDEX idx_lesson_progress_user ON lesson_progress(user_id);
CREATE INDEX idx_lesson_progress_lesson ON lesson_progress(lesson_id);
CREATE INDEX idx_lesson_progress_completed ON lesson_progress(completed);

-- Enable RLS
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view modules"
    ON modules FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage modules"
    ON modules FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view lessons"
    ON lessons FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage lessons"
    ON lessons FOR ALL
    USING (is_admin());

CREATE POLICY "Users can manage their own progress"
    ON lesson_progress FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Admin can view all progress"
    ON lesson_progress FOR SELECT
    USING (is_admin());

-- Create function to update module timestamp
CREATE OR REPLACE FUNCTION update_module_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE modules
    SET updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.module_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for module timestamp
CREATE TRIGGER update_module_timestamp
    AFTER INSERT OR UPDATE ON lessons
    FOR EACH ROW
    EXECUTE FUNCTION update_module_timestamp();

-- Create function to handle progress updates
CREATE OR REPLACE FUNCTION handle_lesson_progress()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert completion notification
    IF NEW.completed AND (OLD IS NULL OR OLD.completed = FALSE) THEN
        INSERT INTO notifications (
            user_id,
            title,
            message
        )
        VALUES (
            NEW.user_id,
            'Aula concluída',
            'Você completou uma nova aula!'
        );

        -- Check if module is completed
        IF NOT EXISTS (
            SELECT 1
            FROM lessons l
            LEFT JOIN lesson_progress lp ON l.id = lp.lesson_id AND lp.user_id = NEW.user_id
            WHERE l.module_id = (SELECT module_id FROM lessons WHERE id = NEW.lesson_id)
            AND (lp.completed IS NULL OR lp.completed = FALSE)
        ) THEN
            -- Insert module completion notification
            INSERT INTO notifications (
                user_id,
                title,
                message
            )
            VALUES (
                NEW.user_id,
                'Módulo concluído',
                'Parabéns! Você completou todas as aulas do módulo!'
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for progress updates
CREATE TRIGGER handle_lesson_progress_trigger
    AFTER INSERT OR UPDATE ON lesson_progress
    FOR EACH ROW
    EXECUTE FUNCTION handle_lesson_progress();

-- Create function to get module stats
CREATE OR REPLACE FUNCTION get_module_stats(module_uuid UUID)
RETURNS TABLE (
    enrolled_count BIGINT,
    average_rating NUMERIC,
    total_ratings BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH stats AS (
        SELECT 
            COUNT(DISTINCT lp.user_id) as enrolled,
            ROUND(AVG(lp.score)::NUMERIC, 1) as avg_rating,
            COUNT(DISTINCT lp.id) as total_rating
        FROM modules m
        LEFT JOIN lessons l ON l.module_id = m.id
        LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id
        WHERE m.id = module_uuid
        GROUP BY m.id
    )
    SELECT
        COALESCE(enrolled, 0)::BIGINT as enrolled_count,
        COALESCE(avg_rating, 0.0)::NUMERIC as average_rating,
        COALESCE(total_rating, 0)::BIGINT as total_ratings
    FROM stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_module_stats(UUID) TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;