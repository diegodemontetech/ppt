-- Fix complete system structure with correct relationships
BEGIN;

-- Drop existing tables to rebuild with correct relationships
DO $$ 
BEGIN
    DROP TABLE IF EXISTS certificates CASCADE;
    DROP TABLE IF EXISTS lesson_progress CASCADE;
    DROP TABLE IF EXISTS lesson_attachments CASCADE;
    DROP TABLE IF EXISTS quizzes CASCADE;
    DROP TABLE IF EXISTS lessons CASCADE;
    DROP TABLE IF EXISTS modules CASCADE;
    DROP TABLE IF EXISTS categories CASCADE;
    DROP TABLE IF EXISTS departments CASCADE;
    DROP TABLE IF EXISTS live_events CASCADE;
    DROP TABLE IF EXISTS notifications CASCADE;
EXCEPTION 
    WHEN OTHERS THEN 
        NULL;
END $$;

-- Create base tables
CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    thumbnail_url TEXT,
    video_url TEXT,
    bg_color TEXT DEFAULT '#3B82F6',
    is_featured BOOLEAN DEFAULT false,
    technical_lead TEXT,
    estimated_duration INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID REFERENCES modules(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    video_url TEXT NOT NULL,
    order_num INTEGER NOT NULL,
    duration INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id, order_num)
);

CREATE TABLE IF NOT EXISTS quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID REFERENCES modules(id) ON DELETE CASCADE,
    questions JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id)
);

CREATE TABLE IF NOT EXISTS lesson_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    completed BOOLEAN DEFAULT FALSE,
    score NUMERIC(4,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, lesson_id)
);

CREATE TABLE IF NOT EXISTS lesson_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    file_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS certificates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    module_id UUID REFERENCES modules(id) ON DELETE CASCADE,
    score NUMERIC(4,2),
    issued_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, module_id)
);

CREATE TABLE IF NOT EXISTS course_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID REFERENCES modules(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(course_id, user_id)
);

-- Create indexes if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_categories_department') THEN
        CREATE INDEX idx_categories_department ON categories(department_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_modules_category') THEN
        CREATE INDEX idx_modules_category ON modules(category_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_modules_featured') THEN
        CREATE INDEX idx_modules_featured ON modules(is_featured);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_lessons_module') THEN
        CREATE INDEX idx_lessons_module ON lessons(module_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_lessons_order') THEN
        CREATE INDEX idx_lessons_order ON lessons(module_id, order_num);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_quizzes_module') THEN
        CREATE INDEX idx_quizzes_module ON quizzes(module_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_progress_user') THEN
        CREATE INDEX idx_progress_user ON lesson_progress(user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_progress_lesson') THEN
        CREATE INDEX idx_progress_lesson ON lesson_progress(lesson_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_attachments_lesson') THEN
        CREATE INDEX idx_attachments_lesson ON lesson_attachments(lesson_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_certificates_user_module') THEN
        CREATE INDEX idx_certificates_user_module ON certificates(user_id, module_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_course_ratings_course') THEN
        CREATE INDEX idx_course_ratings_course ON course_ratings(course_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_course_ratings_user') THEN
        CREATE INDEX idx_course_ratings_user ON course_ratings(user_id);
    END IF;
END $$;

-- Enable RLS on all tables
DO $$ 
BEGIN
    ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
    ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
    ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
    ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
    ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
    ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
    ALTER TABLE lesson_attachments ENABLE ROW LEVEL SECURITY;
    ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;
    ALTER TABLE course_ratings ENABLE ROW LEVEL SECURITY;
EXCEPTION 
    WHEN OTHERS THEN 
        NULL;
END $$;

-- Create RLS policies
DO $$ 
BEGIN
    -- Drop existing policies first
    DROP POLICY IF EXISTS "Everyone can view departments" ON departments;
    DROP POLICY IF EXISTS "Admin can manage departments" ON departments;
    DROP POLICY IF EXISTS "Everyone can view categories" ON categories;
    DROP POLICY IF EXISTS "Admin can manage categories" ON categories;
    DROP POLICY IF EXISTS "Everyone can view modules" ON modules;
    DROP POLICY IF EXISTS "Admin can manage modules" ON modules;
    DROP POLICY IF EXISTS "Everyone can view lessons" ON lessons;
    DROP POLICY IF EXISTS "Admin can manage lessons" ON lessons;
    DROP POLICY IF EXISTS "Everyone can view quizzes" ON quizzes;
    DROP POLICY IF EXISTS "Admin can manage quizzes" ON quizzes;
    DROP POLICY IF EXISTS "Users can manage their own progress" ON lesson_progress;
    DROP POLICY IF EXISTS "Admin can view all progress" ON lesson_progress;
    DROP POLICY IF EXISTS "Everyone can view attachments" ON lesson_attachments;
    DROP POLICY IF EXISTS "Admin can manage attachments" ON lesson_attachments;
    DROP POLICY IF EXISTS "Users can view their own certificates" ON certificates;
    DROP POLICY IF EXISTS "Admin can manage certificates" ON certificates;
    DROP POLICY IF EXISTS "Users can rate courses" ON course_ratings;
    DROP POLICY IF EXISTS "Users can update their ratings" ON course_ratings;
    DROP POLICY IF EXISTS "Everyone can view ratings" ON course_ratings;

    -- Create new policies
    CREATE POLICY "Everyone can view departments" ON departments FOR SELECT USING (true);
    CREATE POLICY "Admin can manage departments" ON departments FOR ALL USING (is_admin());

    CREATE POLICY "Everyone can view categories" ON categories FOR SELECT USING (true);
    CREATE POLICY "Admin can manage categories" ON categories FOR ALL USING (is_admin());

    CREATE POLICY "Everyone can view modules" ON modules FOR SELECT USING (true);
    CREATE POLICY "Admin can manage modules" ON modules FOR ALL USING (is_admin());

    CREATE POLICY "Everyone can view lessons" ON lessons FOR SELECT USING (true);
    CREATE POLICY "Admin can manage lessons" ON lessons FOR ALL USING (is_admin());

    CREATE POLICY "Everyone can view quizzes" ON quizzes FOR SELECT USING (true);
    CREATE POLICY "Admin can manage quizzes" ON quizzes FOR ALL USING (is_admin());

    CREATE POLICY "Users can manage their own progress" ON lesson_progress FOR ALL USING (auth.uid() = user_id);
    CREATE POLICY "Admin can view all progress" ON lesson_progress FOR SELECT USING (is_admin());

    CREATE POLICY "Everyone can view attachments" ON lesson_attachments FOR SELECT USING (true);
    CREATE POLICY "Admin can manage attachments" ON lesson_attachments FOR ALL USING (is_admin());

    CREATE POLICY "Users can view their own certificates" ON certificates FOR SELECT USING (auth.uid() = user_id);
    CREATE POLICY "Admin can manage certificates" ON certificates FOR ALL USING (is_admin());

    CREATE POLICY "Users can rate courses" ON course_ratings FOR INSERT WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "Users can update their ratings" ON course_ratings FOR UPDATE USING (auth.uid() = user_id);
    CREATE POLICY "Everyone can view ratings" ON course_ratings FOR SELECT USING (true);
EXCEPTION 
    WHEN OTHERS THEN 
        NULL;
END $$;

-- Create storage buckets if not exist
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('attachments', 'attachments', true),
    ('images', 'images', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can upload attachments" ON storage.objects;
    DROP POLICY IF EXISTS "Public attachment access" ON storage.objects;
    DROP POLICY IF EXISTS "Admin attachment deletion" ON storage.objects;
    DROP POLICY IF EXISTS "Users can upload images" ON storage.objects;
    DROP POLICY IF EXISTS "Public image access" ON storage.objects;
    DROP POLICY IF EXISTS "Admin image deletion" ON storage.objects;

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

    CREATE POLICY "Users can upload images"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'images');

    CREATE POLICY "Public image access"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'images');

    CREATE POLICY "Admin image deletion"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'images' 
        AND EXISTS (
            SELECT 1 
            FROM auth.users 
            WHERE id = auth.uid() 
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );
EXCEPTION 
    WHEN OTHERS THEN 
        NULL;
END $$;

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
            ROUND(AVG(cr.rating)::NUMERIC, 1) as avg_rating,
            COUNT(DISTINCT cr.id) as total_rating
        FROM modules m
        LEFT JOIN lessons l ON l.module_id = m.id
        LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id
        LEFT JOIN course_ratings cr ON cr.course_id = m.id
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

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;