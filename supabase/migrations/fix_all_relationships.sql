-- Fix all database relationships and tables
BEGIN;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS course_ratings CASCADE;
DROP TABLE IF EXISTS ebook_ratings CASCADE;
DROP TABLE IF EXISTS ebooks CASCADE;
DROP TABLE IF EXISTS live_events CASCADE;
DROP TABLE IF EXISTS live_recordings CASCADE;
DROP TABLE IF EXISTS marketing_box_items CASCADE;
DROP TABLE IF EXISTS marketing_box_categories CASCADE;
DROP TABLE IF EXISTS contract_signatories CASCADE;
DROP TABLE IF EXISTS contracts CASCADE;
DROP TABLE IF EXISTS support_ticket_comments CASCADE;
DROP TABLE IF EXISTS support_ticket_attachments CASCADE;
DROP TABLE IF EXISTS support_ticket_history CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
DROP TABLE IF EXISTS support_reasons CASCADE;
DROP TABLE IF EXISTS support_departments CASCADE;
DROP TABLE IF EXISTS pipeline_stages CASCADE;
DROP TABLE IF EXISTS pipelines CASCADE;

-- Create course ratings table
CREATE TABLE IF NOT EXISTS course_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(module_id, user_id)
);

-- Create ebooks tables
CREATE TABLE IF NOT EXISTS ebooks (
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

CREATE TABLE IF NOT EXISTS ebook_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ebook_id UUID NOT NULL REFERENCES ebooks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ebook_id, user_id)
);

-- Create live events tables
CREATE TABLE IF NOT EXISTS live_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    instructor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    meeting_url TEXT NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    duration INTEGER NOT NULL,
    attendees_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS live_recordings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    live_event_id UUID NOT NULL REFERENCES live_events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    video_url TEXT NOT NULL,
    duration INTEGER,
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create marketing box tables
CREATE TABLE IF NOT EXISTS marketing_box_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS marketing_box_items (
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

-- Create support system tables
CREATE TABLE IF NOT EXISTS support_departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS support_reasons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES support_departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    sla_response INTEGER NOT NULL,
    sla_resolution INTEGER NOT NULL,
    priority TEXT NOT NULL CHECK (priority IN ('urgent', 'medium', 'low')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES support_departments(id) ON DELETE CASCADE,
    reason_id UUID NOT NULL REFERENCES support_reasons(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES auth.users(id),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('open', 'in_progress', 'partially_resolved', 'resolved', 'finished', 'deleted')),
    priority TEXT NOT NULL CHECK (priority IN ('urgent', 'medium', 'low')),
    sla_response_at TIMESTAMPTZ,
    sla_resolution_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    deletion_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create pipeline tables
CREATE TABLE IF NOT EXISTS pipelines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    color TEXT DEFAULT '#3B82F6',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pipeline_stages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID NOT NULL REFERENCES pipelines(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    order_num INTEGER NOT NULL,
    sla_hours INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(pipeline_id, order_num)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_course_ratings_module ON course_ratings(module_id);
CREATE INDEX IF NOT EXISTS idx_course_ratings_user ON course_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_ebooks_category ON ebooks(category_id);
CREATE INDEX IF NOT EXISTS idx_ebook_ratings_ebook ON ebook_ratings(ebook_id);
CREATE INDEX IF NOT EXISTS idx_live_events_instructor ON live_events(instructor_id);
CREATE INDEX IF NOT EXISTS idx_live_recordings_event ON live_recordings(live_event_id);
CREATE INDEX IF NOT EXISTS idx_marketing_items_category ON marketing_box_items(category_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_department ON support_tickets(department_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_reason ON support_tickets(reason_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_by ON support_tickets(created_by);
CREATE INDEX IF NOT EXISTS idx_pipelines_department ON pipelines(department_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_stages_pipeline ON pipeline_stages(pipeline_id);

-- Enable RLS
ALTER TABLE course_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE ebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE ebook_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketing_box_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketing_box_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_reasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipelines ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_stages ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can rate modules"
    ON course_ratings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Everyone can view ebooks"
    ON ebooks FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage ebooks"
    ON ebooks FOR ALL
    USING (is_admin());

CREATE POLICY "Users can rate ebooks"
    ON ebook_ratings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Everyone can view live events"
    ON live_events FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage live events"
    ON live_events FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view recordings"
    ON live_recordings FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage recordings"
    ON live_recordings FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view marketing categories"
    ON marketing_box_categories FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage marketing categories"
    ON marketing_box_categories FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view marketing items"
    ON marketing_box_items FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage marketing items"
    ON marketing_box_items FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view support departments"
    ON support_departments FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage support departments"
    ON support_departments FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view support reasons"
    ON support_reasons FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage support reasons"
    ON support_reasons FOR ALL
    USING (is_admin());

CREATE POLICY "Users can view support tickets"
    ON support_tickets FOR SELECT
    USING (
        created_by = auth.uid()
        OR assigned_to = auth.uid()
        OR is_admin()
    );

CREATE POLICY "Users can create support tickets"
    ON support_tickets FOR INSERT
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update support tickets"
    ON support_tickets FOR UPDATE
    USING (
        created_by = auth.uid()
        OR assigned_to = auth.uid()
        OR is_admin()
    );

CREATE POLICY "Everyone can view pipelines"
    ON pipelines FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage pipelines"
    ON pipelines FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view pipeline stages"
    ON pipeline_stages FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage pipeline stages"
    ON pipeline_stages FOR ALL
    USING (is_admin());

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;