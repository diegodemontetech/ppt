-- Fix e-books schema and permissions
BEGIN;

-- Create ebooks table if not exists
CREATE TABLE IF NOT EXISTS ebooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    subtitle TEXT,
    author TEXT NOT NULL,
    description TEXT,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    pdf_url TEXT NOT NULL,
    cover_url TEXT,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create ebook_ratings table if not exists
CREATE TABLE IF NOT EXISTS ebook_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ebook_id UUID REFERENCES ebooks(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ebook_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_ebooks_category ON ebooks(category_id);
CREATE INDEX IF NOT EXISTS idx_ebook_ratings_ebook ON ebook_ratings(ebook_id);
CREATE INDEX IF NOT EXISTS idx_ebook_ratings_user ON ebook_ratings(user_id);

-- Enable RLS
ALTER TABLE ebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE ebook_ratings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view ebooks"
    ON ebooks FOR SELECT
    USING (true);

CREATE POLICY "Admin can manage ebooks"
    ON ebooks FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Users can rate ebooks"
    ON ebook_ratings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view all ratings"
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

-- Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION get_ebook_rating(UUID) TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;