-- Fix all database errors
BEGIN;

-- First, increase max_stack_depth
ALTER SYSTEM SET max_stack_depth = '4MB';
SELECT pg_reload_conf();

-- Drop all existing tables
DROP TABLE IF EXISTS course_ratings CASCADE;
DROP TABLE IF EXISTS ebook_ratings CASCADE;
DROP TABLE IF EXISTS lesson_progress CASCADE;
DROP TABLE IF EXISTS lesson_ratings CASCADE;
DROP TABLE IF EXISTS quizzes CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS modules CASCADE;
DROP TABLE IF EXISTS ebooks CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
DROP TABLE IF EXISTS support_departments CASCADE;
DROP TABLE IF EXISTS marketing_box_items CASCADE;
DROP TABLE IF EXISTS marketing_box_categories CASCADE;
DROP TABLE IF EXISTS contracts CASCADE;
DROP TABLE IF EXISTS contract_signatories CASCADE;

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
    department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    thumbnail_url TEXT,
    video_url TEXT,
    bg_color TEXT DEFAULT '#3B82F6',
    is_featured BOOLEAN DEFAULT false,
    estimated_duration INTEGER DEFAULT 0,
    technical_lead TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE course_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id, user_id)
);

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

CREATE TABLE quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    questions JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id)
);

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

CREATE TABLE lesson_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(lesson_id, user_id)
);

CREATE TABLE ebooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    subtitle TEXT,
    author TEXT NOT NULL,
    description TEXT,
    pdf_url TEXT NOT NULL,
    cover_url TEXT,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ebook_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ebook_id UUID NOT NULL REFERENCES ebooks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ebook_id, user_id)
);

CREATE TABLE support_departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES support_departments(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES auth.users(id),
    status TEXT NOT NULL DEFAULT 'open',
    priority TEXT NOT NULL DEFAULT 'medium',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE marketing_box_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE marketing_box_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES marketing_box_categories(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    thumbnail_url TEXT,
    file_type TEXT NOT NULL,
    media_type TEXT NOT NULL,
    resolution TEXT,
    tags TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    downloads INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    content TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE contract_signatories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    signed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_categories_department ON categories(department_id);
CREATE INDEX idx_modules_category ON modules(category_id);
CREATE INDEX idx_course_ratings_module ON course_ratings(module_id);
CREATE INDEX idx_lessons_module ON lessons(module_id);
CREATE INDEX idx_quizzes_module ON quizzes(module_id);
CREATE INDEX idx_progress_user ON lesson_progress(user_id);
CREATE INDEX idx_progress_lesson ON lesson_progress(lesson_id);
CREATE INDEX idx_ratings_lesson ON lesson_ratings(lesson_id);
CREATE INDEX idx_ebooks_category ON ebooks(category_id);
CREATE INDEX idx_ebook_ratings_ebook ON ebook_ratings(ebook_id);
CREATE INDEX idx_support_tickets_department ON support_tickets(department_id);
CREATE INDEX idx_marketing_items_category ON marketing_box_items(category_id);
CREATE INDEX idx_contracts_created_by ON contracts(created_by);

-- Enable RLS
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE ebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE ebook_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketing_box_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketing_box_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE contract_signatories ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view departments" ON departments FOR SELECT USING (true);
CREATE POLICY "Admin can manage departments" ON departments FOR ALL USING (is_admin());

CREATE POLICY "Everyone can view categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Admin can manage categories" ON categories FOR ALL USING (is_admin());

CREATE POLICY "Everyone can view modules" ON modules FOR SELECT USING (true);
CREATE POLICY "Admin can manage modules" ON modules FOR ALL USING (is_admin());

CREATE POLICY "Users can rate courses" ON course_ratings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Everyone can view course ratings" ON course_ratings FOR SELECT USING (true);

CREATE POLICY "Everyone can view lessons" ON lessons FOR SELECT USING (true);
CREATE POLICY "Admin can manage lessons" ON lessons FOR ALL USING (is_admin());

CREATE POLICY "Everyone can view quizzes" ON quizzes FOR SELECT USING (true);
CREATE POLICY "Admin can manage quizzes" ON quizzes FOR ALL USING (is_admin());

CREATE POLICY "Users manage own progress" ON lesson_progress FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Admin view all progress" ON lesson_progress FOR SELECT USING (is_admin());

CREATE POLICY "Users manage own ratings" ON lesson_ratings FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Everyone can view ratings" ON lesson_ratings FOR SELECT USING (true);

CREATE POLICY "Everyone can view ebooks" ON ebooks FOR SELECT USING (true);
CREATE POLICY "Admin can manage ebooks" ON ebooks FOR ALL USING (is_admin());

CREATE POLICY "Users can rate ebooks" ON ebook_ratings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Everyone can view ebook ratings" ON ebook_ratings FOR SELECT USING (true);

CREATE POLICY "Everyone can view support departments" ON support_departments FOR SELECT USING (true);
CREATE POLICY "Admin can manage support departments" ON support_departments FOR ALL USING (is_admin());

CREATE POLICY "Users can view their tickets" ON support_tickets FOR SELECT USING (created_by = auth.uid() OR assigned_to = auth.uid() OR is_admin());
CREATE POLICY "Users can create tickets" ON support_tickets FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Users can update their tickets" ON support_tickets FOR UPDATE USING (created_by = auth.uid() OR assigned_to = auth.uid() OR is_admin());

CREATE POLICY "Everyone can view marketing categories" ON marketing_box_categories FOR SELECT USING (true);
CREATE POLICY "Admin can manage marketing categories" ON marketing_box_categories FOR ALL USING (is_admin());

CREATE POLICY "Everyone can view marketing items" ON marketing_box_items FOR SELECT USING (true);
CREATE POLICY "Admin can manage marketing items" ON marketing_box_items FOR ALL USING (is_admin());

CREATE POLICY "Users can manage contracts" ON contracts FOR ALL USING (auth.uid() = created_by OR is_admin());
CREATE POLICY "Users can view contracts" ON contracts FOR SELECT USING (true);

CREATE POLICY "Users can manage signatories" ON contract_signatories FOR ALL USING (
    EXISTS (
        SELECT 1 FROM contracts c
        WHERE c.id = contract_id
        AND (c.created_by = auth.uid() OR is_admin())
    )
);

-- Insert default data using DO block
DO $$ 
DECLARE
    dept_id UUID;
    cat_id UUID;
    support_dept_id UUID;
    mkt_cat_id UUID;
BEGIN
    -- Insert department
    INSERT INTO departments (name, description)
    VALUES ('General', 'General Department')
    RETURNING id INTO dept_id;

    -- Insert category
    INSERT INTO categories (department_id, name, description)
    VALUES (dept_id, 'General', 'General Category')
    RETURNING id INTO cat_id;

    -- Insert support department
    INSERT INTO support_departments (name, description)
    VALUES ('General Support', 'General Support Department')
    RETURNING id INTO support_dept_id;

    -- Insert marketing category
    INSERT INTO marketing_box_categories (name, description)
    VALUES ('General', 'General Marketing Category')
    RETURNING id INTO mkt_cat_id;
END $$;

-- Set admin user
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"admin"'
)
WHERE email = 'diegodemontevpj@gmail.com';

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('videos', 'videos', true),
    ('images', 'images', true),
    ('pdfs', 'pdfs', true),
    ('attachments', 'attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can upload videos" ON storage.objects;
    DROP POLICY IF EXISTS "Public video access" ON storage.objects;
    DROP POLICY IF EXISTS "Admin video deletion" ON storage.objects;
    DROP POLICY IF EXISTS "Users can upload images" ON storage.objects;
    DROP POLICY IF EXISTS "Public image access" ON storage.objects;
    DROP POLICY IF EXISTS "Admin image deletion" ON storage.objects;
    DROP POLICY IF EXISTS "Users can upload pdfs" ON storage.objects;
    DROP POLICY IF EXISTS "Public pdf access" ON storage.objects;
    DROP POLICY IF EXISTS "Admin pdf deletion" ON storage.objects;
    DROP POLICY IF EXISTS "Users can upload attachments" ON storage.objects;
    DROP POLICY IF EXISTS "Public attachment access" ON storage.objects;
    DROP POLICY IF EXISTS "Admin attachment deletion" ON storage.objects;

    CREATE POLICY "Users can upload videos"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'videos');

    CREATE POLICY "Public video access"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'videos');

    CREATE POLICY "Admin video deletion"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'videos' 
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

    CREATE POLICY "Users can upload pdfs"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'pdfs');

    CREATE POLICY "Public pdf access"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'pdfs');

    CREATE POLICY "Admin pdf deletion"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'pdfs' 
        AND EXISTS (
            SELECT 1 
            FROM auth.users 
            WHERE id = auth.uid() 
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

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
END $$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;