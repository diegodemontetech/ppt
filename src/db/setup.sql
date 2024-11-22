-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables
CREATE TABLE IF NOT EXISTS courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    video_url TEXT NOT NULL,
    pdf_url TEXT,
    order_num INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(course_id, order_num)
);

CREATE TABLE IF NOT EXISTS quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    questions JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(lesson_id)
);

CREATE TABLE IF NOT EXISTS lesson_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    completed BOOLEAN DEFAULT FALSE,
    score NUMERIC(4,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, lesson_id)
);

-- Disable RLS temporarily
ALTER TABLE courses DISABLE ROW LEVEL SECURITY;
ALTER TABLE lessons DISABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes DISABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress DISABLE ROW LEVEL SECURITY;

-- Insert sample data
INSERT INTO courses (id, title, description) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Introduction to Web Development', 'Learn the basics of web development including HTML, CSS, and JavaScript.');

INSERT INTO lessons (id, course_id, title, video_url, order_num) VALUES
    ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'HTML Basics', 'W6NZfCO5SIk', 1),
    ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'CSS Fundamentals', '1PnVor36_40', 2);

INSERT INTO quizzes (id, lesson_id, questions) VALUES
    ('44444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', '[
        {
            "text": "What does HTML stand for?",
            "options": [
                "Hyper Text Markup Language",
                "High Tech Modern Language",
                "Hyper Transfer Markup Logic",
                "Home Tool Markup Language"
            ],
            "correctOption": 0
        },
        {
            "text": "Which tag is used for the largest heading in HTML?",
            "options": [
                "<head>",
                "<h6>",
                "<heading>",
                "<h1>"
            ],
            "correctOption": 3
        }
    ]'),
    ('55555555-5555-5555-5555-555555555555', '33333333-3333-3333-3333-333333333333', '[
        {
            "text": "What does CSS stand for?",
            "options": [
                "Computer Style Sheets",
                "Creative Style Sheets",
                "Cascading Style Sheets",
                "Colorful Style Sheets"
            ],
            "correctOption": 2
        },
        {
            "text": "Which property is used to change the background color?",
            "options": [
                "color",
                "bgcolor",
                "background-color",
                "background"
            ],
            "correctOption": 2
        }
    ]');