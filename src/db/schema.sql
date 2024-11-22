-- Add categories table
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add user_groups table
CREATE TABLE IF NOT EXISTS user_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add user_group_members table
CREATE TABLE IF NOT EXISTS user_group_members (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    group_id UUID REFERENCES user_groups(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, group_id)
);

-- Add certificates table
CREATE TABLE IF NOT EXISTS certificates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    issued_at TIMESTAMPTZ DEFAULT NOW(),
    certificate_url TEXT,
    UNIQUE(user_id, course_id)
);

-- Add live_events table
CREATE TABLE IF NOT EXISTS live_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    instructor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    meeting_url TEXT,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add lesson_ratings table
CREATE TABLE IF NOT EXISTS lesson_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(lesson_id, user_id)
);

-- Modify existing tables

-- Add category_id to courses
ALTER TABLE courses 
ADD COLUMN category_id UUID REFERENCES categories(id),
ADD COLUMN total_duration INTEGER DEFAULT 0, -- in seconds
ADD COLUMN is_featured BOOLEAN DEFAULT false;

-- Add duration to lessons
ALTER TABLE lessons
ADD COLUMN duration INTEGER DEFAULT 0, -- in seconds
ADD COLUMN description TEXT,
ADD COLUMN is_live BOOLEAN DEFAULT false;

-- Add indexes
CREATE INDEX idx_courses_category ON courses(category_id);
CREATE INDEX idx_user_group_members_user ON user_group_members(user_id);
CREATE INDEX idx_user_group_members_group ON user_group_members(group_id);
CREATE INDEX idx_certificates_user ON certificates(user_id);
CREATE INDEX idx_lesson_ratings_lesson ON lesson_ratings(lesson_id);

-- Add trigger to update course total_duration
CREATE OR REPLACE FUNCTION update_course_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        UPDATE courses
        SET total_duration = (
            SELECT COALESCE(SUM(duration), 0)
            FROM lessons
            WHERE course_id = NEW.course_id
        )
        WHERE id = NEW.course_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE courses
        SET total_duration = (
            SELECT COALESCE(SUM(duration), 0)
            FROM lessons
            WHERE course_id = OLD.course_id
        )
        WHERE id = OLD.course_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_course_duration_trigger
    AFTER INSERT OR UPDATE OR DELETE ON lessons
    FOR EACH ROW
    EXECUTE FUNCTION update_course_duration();

-- Add function to check if category can be deleted
CREATE OR REPLACE FUNCTION can_delete_category(category_id UUID)
RETURNS TABLE(can_delete BOOLEAN, course_titles TEXT[]) AS $$
DECLARE
    courses_using_category TEXT[];
BEGIN
    SELECT ARRAY_AGG(title)
    INTO courses_using_category
    FROM courses
    WHERE courses.category_id = category_id;

    RETURN QUERY
    SELECT
        CASE WHEN courses_using_category IS NULL THEN true ELSE false END,
        courses_using_category;
END;
$$ LANGUAGE plpgsql;