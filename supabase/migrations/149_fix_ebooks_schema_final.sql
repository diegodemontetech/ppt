-- Fix ebooks schema and relationships - Final
BEGIN;

-- Drop existing tables to rebuild with correct relationships
DROP TABLE IF EXISTS ebook_ratings CASCADE;
DROP TABLE IF EXISTS ebooks CASCADE;

-- Create ebooks table with correct relationships
CREATE TABLE ebooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    subtitle TEXT,
    author TEXT NOT NULL,
    description TEXT,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    pdf_url TEXT NOT NULL,
    cover_url TEXT,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create ebook_ratings table
CREATE TABLE ebook_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ebook_id UUID NOT NULL REFERENCES ebooks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ebook_id, user_id)
);

-- Create indexes
CREATE INDEX idx_ebooks_category ON ebooks(category_id);
CREATE INDEX idx_ebooks_featured ON ebooks(is_featured);
CREATE INDEX idx_ebook_ratings_ebook ON ebook_ratings(ebook_id);
CREATE INDEX idx_ebook_ratings_user ON ebook_ratings(user_id);

-- Enable RLS
ALTER TABLE ebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE ebook_ratings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view ebooks"
    ON ebooks FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage ebooks"
    ON ebooks FOR ALL
    USING (is_admin());

CREATE POLICY "Users can rate ebooks"
    ON ebook_ratings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their ratings"
    ON ebook_ratings FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Everyone can view ratings"
    ON ebook_ratings FOR SELECT
    USING (true);

-- Create function to get ebook rating
CREATE OR REPLACE FUNCTION get_ebook_rating(ebook_uuid UUID)
RETURNS TABLE (
    average_rating NUMERIC,
    total_ratings BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROUND(AVG(rating)::numeric, 1) as average_rating,
        COUNT(*)::bigint as total_ratings
    FROM ebook_ratings
    WHERE ebook_id = ebook_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle file deletion
CREATE OR REPLACE FUNCTION handle_ebook_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete PDF from storage if exists
    IF OLD.pdf_url IS NOT NULL THEN
        PERFORM storage.delete('pdfs', split_part(OLD.pdf_url, '/', -1));
    END IF;
    -- Delete cover from storage if exists
    IF OLD.cover_url IS NOT NULL THEN
        PERFORM storage.delete('images', split_part(OLD.cover_url, '/', -1));
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for ebook deletion
DROP TRIGGER IF EXISTS delete_ebook_files_trigger ON ebooks;
CREATE TRIGGER delete_ebook_files_trigger
    BEFORE DELETE ON ebooks
    FOR EACH ROW
    EXECUTE FUNCTION handle_ebook_deletion();

-- Create storage buckets if not exist
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('pdfs', 'pdfs', true),
    ('images', 'images', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies
DROP POLICY IF EXISTS "Users can upload pdfs" ON storage.objects;
DROP POLICY IF EXISTS "Public pdf access" ON storage.objects;
DROP POLICY IF EXISTS "Admin pdf deletion" ON storage.objects;

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

-- Insert sample data
INSERT INTO ebooks (
    title,
    subtitle,
    author,
    description,
    category_id,
    pdf_url,
    cover_url,
    is_featured
) VALUES 
(
    'Clean Code',
    'A Handbook of Agile Software Craftsmanship',
    'Robert C. Martin',
    'Even bad code can function. But if code isn''t clean, it can bring a development organization to its knees.',
    (SELECT id FROM categories WHERE name = 'Programação' LIMIT 1),
    'clean-code.pdf',
    'https://images.unsplash.com/photo-1555066931-4365d14bab8c',
    true
),
(
    'Design Patterns',
    'Elements of Reusable Object-Oriented Software',
    'Gang of Four',
    'Capturing a wealth of experience about the design of object-oriented software.',
    (SELECT id FROM categories WHERE name = 'Programação' LIMIT 1),
    'design-patterns.pdf',
    'https://images.unsplash.com/photo-1516259762381-22954d7d3ad2',
    true
);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION get_ebook_rating(UUID) TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;