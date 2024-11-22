-- Add E-Books support
BEGIN;

-- Create ebooks table
CREATE TABLE ebooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    subtitle TEXT,
    author TEXT NOT NULL,
    description TEXT,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    pdf_url TEXT NOT NULL,
    cover_url TEXT,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create ebook_ratings table
CREATE TABLE ebook_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ebook_id UUID REFERENCES ebooks(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ebook_id, user_id)
);

-- Create indexes
CREATE INDEX idx_ebooks_category ON ebooks(category_id);
CREATE INDEX idx_ebooks_company ON ebooks(company_id);
CREATE INDEX idx_ebook_ratings_ebook ON ebook_ratings(ebook_id);
CREATE INDEX idx_ebook_ratings_user ON ebook_ratings(user_id);

-- Enable RLS
ALTER TABLE ebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE ebook_ratings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Admin can manage ebooks"
    ON ebooks FOR ALL
    USING (is_admin());

CREATE POLICY "Users can view ebooks"
    ON ebooks FOR SELECT
    USING (true);

CREATE POLICY "Users can rate ebooks once"
    ON ebook_ratings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view all ratings"
    ON ebook_ratings FOR SELECT
    USING (true);

-- Add ebooks permission to user_groups
ALTER TABLE user_groups
ADD COLUMN IF NOT EXISTS allowed_ebooks UUID[] DEFAULT '{}';

-- Create function to check ebook access
CREATE OR REPLACE FUNCTION can_access_ebook(ebook_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM user_group_members ugm
        JOIN user_groups ug ON ugm.group_id = ug.id
        WHERE ugm.user_id = auth.uid()
        AND (
            ebook_uuid = ANY(ug.allowed_ebooks)
            OR 'view_all' = ANY(ug.permissions)
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert sample ebooks
INSERT INTO ebooks (
    title,
    subtitle,
    author,
    description,
    pdf_url,
    cover_url,
    is_featured
) VALUES 
(
    'Clean Code',
    'A Handbook of Agile Software Craftsmanship',
    'Robert C. Martin',
    E'Even bad code can function. But if code isn\'t clean, it can bring a development organization to its knees.',
    'https://raw.githubusercontent.com/SaikrishnaReddy1919/MyBooks/master/Clean%20Code_%20A%20Handbook%20of%20Agile%20Software%20Craftsmanship%20-%20Robert%20C.%20Martin.pdf',
    'https://images.unsplash.com/photo-1555066931-4365d14bab8c',
    true
),
(
    'Design Patterns',
    'Elements of Reusable Object-Oriented Software',
    'Gang of Four',
    'Capturing a wealth of experience about the design of object-oriented software.',
    'https://raw.githubusercontent.com/SaikrishnaReddy1919/MyBooks/master/Head%20First%20Design%20Patterns%20-%20Eric%20Freeman%20%26%20Elisabeth%20Freeman.pdf',
    'https://images.unsplash.com/photo-1516259762381-22954d7d3ad2',
    true
),
(
    'Pragmatic Programmer',
    'Your Journey to Mastery',
    'Dave Thomas, Andy Hunt',
    'Written as a series of self-contained sections and filled with classic and fresh anecdotes, thoughtful examples, and interesting analogies.',
    'https://raw.githubusercontent.com/SaikrishnaReddy1919/MyBooks/master/The%20Pragmatic%20Programmer.pdf',
    'https://images.unsplash.com/photo-1542831371-29b0f74f9713',
    true
);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;