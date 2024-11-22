-- Fix quiz system aggressively
BEGIN;

-- Drop all quiz related tables and start fresh
DROP TABLE IF EXISTS certificates CASCADE;
DROP TABLE IF EXISTS lesson_progress CASCADE;
DROP TABLE IF EXISTS quizzes CASCADE;

-- Recreate quizzes table with correct relationship
CREATE TABLE quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    questions JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id)
);

-- Create index
CREATE INDEX idx_quizzes_module ON quizzes(module_id);

-- Create lesson progress table
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

-- Create certificates table
CREATE TABLE certificates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    score NUMERIC(4,2),
    issued_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, module_id)
);

-- Create empty quiz for each existing module
INSERT INTO quizzes (module_id, questions)
SELECT id, '[]'::jsonb
FROM modules
WHERE id NOT IN (SELECT module_id FROM quizzes);

-- Enable RLS
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view quizzes" ON quizzes FOR SELECT USING (true);
CREATE POLICY "Admin can manage quizzes" ON quizzes FOR ALL USING (is_admin());

CREATE POLICY "Users manage own progress" ON lesson_progress FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Admin view all progress" ON lesson_progress FOR SELECT USING (is_admin());

CREATE POLICY "Users view own certificates" ON certificates FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admin manage certificates" ON certificates FOR ALL USING (is_admin());

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;