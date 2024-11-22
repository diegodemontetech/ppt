-- Complete system fix including all necessary changes
BEGIN;

-- Drop existing tables to rebuild with correct relationships
DROP TABLE IF EXISTS lesson_progress CASCADE;
DROP TABLE IF EXISTS lesson_ratings CASCADE;
DROP TABLE IF EXISTS quizzes CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS modules CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS live_events CASCADE;
DROP TABLE IF EXISTS live_recordings CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS module_subscriptions CASCADE;

-- Create base tables
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    thumbnail_url TEXT,
    video_url TEXT,
    bg_color TEXT DEFAULT '#3B82F6',
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lessons (
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

CREATE TABLE quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    questions JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(lesson_id)
);

CREATE TABLE lesson_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    completed BOOLEAN DEFAULT FALSE,
    score NUMERIC(4,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, lesson_id)
);

CREATE TABLE lesson_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(lesson_id, user_id)
);

CREATE TABLE live_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    instructor_id UUID NOT NULL,
    meeting_url TEXT NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    duration INTEGER NOT NULL,
    attendees_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT live_events_instructor_id_fkey 
        FOREIGN KEY (instructor_id) 
        REFERENCES auth.users(id) 
        ON DELETE CASCADE
);

CREATE TABLE live_recordings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    live_event_id UUID REFERENCES live_events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    video_url TEXT NOT NULL,
    duration INTEGER,
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE module_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID REFERENCES modules(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id, user_id)
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_categories_department ON categories(department_id);
CREATE INDEX idx_modules_category ON modules(category_id);
CREATE INDEX idx_modules_featured ON modules(is_featured);
CREATE INDEX idx_lessons_module ON lessons(module_id);
CREATE INDEX idx_lessons_order ON lessons(module_id, order_num);
CREATE INDEX idx_quizzes_lesson ON quizzes(lesson_id);
CREATE INDEX idx_progress_user ON lesson_progress(user_id);
CREATE INDEX idx_progress_lesson ON lesson_progress(lesson_id);
CREATE INDEX idx_ratings_lesson ON lesson_ratings(lesson_id);
CREATE INDEX idx_ratings_user ON lesson_ratings(user_id);
CREATE INDEX idx_live_events_instructor ON live_events(instructor_id);
CREATE INDEX idx_live_events_starts_at ON live_events(starts_at);
CREATE INDEX idx_recordings_live_event ON live_recordings(live_event_id);
CREATE INDEX idx_subscriptions_user ON module_subscriptions(user_id);
CREATE INDEX idx_subscriptions_module ON module_subscriptions(module_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, read);

-- Create admin check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' = 'admin'
  );
END;
$$;

-- Create function to generate random color for modules
CREATE OR REPLACE FUNCTION generate_module_color()
RETURNS TEXT AS $$
DECLARE
    colors TEXT[] := ARRAY[
        '#3B82F6', -- blue
        '#10B981', -- green
        '#8B5CF6', -- purple
        '#F59E0B', -- yellow
        '#EF4444', -- red
        '#EC4899', -- pink
        '#6366F1'  -- indigo
    ];
BEGIN
    RETURN colors[floor(random() * array_length(colors, 1) + 1)];
END;
$$ LANGUAGE plpgsql;

-- Create trigger to set random color on new modules
CREATE OR REPLACE FUNCTION set_module_color()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.bg_color IS NULL THEN
        NEW.bg_color := generate_module_color();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_module_color_trigger
    BEFORE INSERT ON modules
    FOR EACH ROW
    EXECUTE FUNCTION set_module_color();

-- Create function to get next live event
CREATE OR REPLACE FUNCTION get_next_live_event()
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    instructor_name TEXT,
    instructor_email TEXT,
    meeting_url TEXT,
    starts_at TIMESTAMPTZ,
    duration INTEGER,
    attendees_count INTEGER
) AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY
    SELECT 
        e.id,
        e.title::TEXT,
        COALESCE(e.description, '')::TEXT,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email)::TEXT,
        u.email::TEXT,
        e.meeting_url::TEXT,
        e.starts_at,
        e.duration,
        COALESCE(e.attendees_count, 0)
    FROM live_events e
    JOIN auth.users u ON e.instructor_id = u.id
    WHERE e.starts_at >= NOW()
    ORDER BY e.starts_at ASC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get live recordings
CREATE OR REPLACE FUNCTION get_live_recordings()
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    video_url TEXT,
    duration INTEGER,
    thumbnail_url TEXT,
    event_title TEXT,
    event_date TIMESTAMPTZ,
    instructor_name TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lr.id,
        lr.title,
        lr.description,
        lr.video_url,
        lr.duration,
        lr.thumbnail_url,
        le.title as event_title,
        le.starts_at as event_date,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email) as instructor_name,
        lr.created_at
    FROM live_recordings lr
    JOIN live_events le ON lr.live_event_id = le.id
    JOIN auth.users u ON le.instructor_id = u.id
    ORDER BY lr.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
            ROUND(AVG(lr.rating)::NUMERIC, 1) as avg_rating,
            COUNT(DISTINCT lr.id) as total_rating
        FROM modules m
        LEFT JOIN lessons l ON l.module_id = m.id
        LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id
        LEFT JOIN lesson_ratings lr ON lr.lesson_id = l.id
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

-- Enable RLS on all tables
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
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

CREATE POLICY "Users manage own progress" ON lesson_progress FOR ALL USING (auth.uid() = user_id OR is_admin());
CREATE POLICY "Users manage own ratings" ON lesson_ratings FOR ALL USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Everyone can view live events" ON live_events FOR SELECT USING (true);
CREATE POLICY "Admin can manage live events" ON live_events FOR ALL USING (is_admin());

CREATE POLICY "Everyone can view recordings" ON live_recordings FOR SELECT USING (true);
CREATE POLICY "Admin can manage recordings" ON live_recordings FOR ALL USING (is_admin());

CREATE POLICY "Users manage own subscriptions" ON module_subscriptions FOR ALL USING (auth.uid() = user_id OR is_admin());
CREATE POLICY "Users manage own notifications" ON notifications FOR ALL USING (auth.uid() = user_id OR is_admin());

-- Update admin user
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"admin"'
)
WHERE email = 'diegodemontevpj@gmail.com';

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Insert sample data
DO $$
DECLARE
    dept_id UUID;
    cat_id UUID;
    mod_id UUID;
BEGIN
    -- Insert department
    INSERT INTO departments (id, name, description)
    VALUES (uuid_generate_v4(), 'Tecnologia', 'Departamento de Tecnologia')
    RETURNING id INTO dept_id;

    -- Insert category
    INSERT INTO categories (id, department_id, name, description)
    VALUES (uuid_generate_v4(), dept_id, 'Programação', 'Cursos de programação')
    RETURNING id INTO cat_id;

    -- Insert module
    INSERT INTO modules (id, category_id, title, description, is_featured)
    VALUES (uuid_generate_v4(), cat_id, 'JavaScript Básico', 'Introdução ao JavaScript', true)
    RETURNING id INTO mod_id;

    -- Insert lesson
    INSERT INTO lessons (id, module_id, title, description, video_url, order_num)
    VALUES (uuid_generate_v4(), mod_id, 'Introdução', 'Primeira aula de JavaScript', 'xu3LXxQFLJk', 1);
END $$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;