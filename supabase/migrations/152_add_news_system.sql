-- Add news system tables and relationships
BEGIN;

-- Create news categories table
CREATE TABLE IF NOT EXISTS news_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create news articles table
CREATE TABLE IF NOT EXISTS news_articles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    video_url TEXT,
    category UUID REFERENCES news_categories(id) ON DELETE SET NULL,
    is_featured BOOLEAN DEFAULT false,
    is_published BOOLEAN DEFAULT false,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_news_articles_category ON news_articles(category);
CREATE INDEX idx_news_articles_published ON news_articles(published_at);
CREATE INDEX idx_news_articles_featured ON news_articles(is_featured);

-- Enable RLS
ALTER TABLE news_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_articles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view active categories"
    ON news_categories FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage categories"
    ON news_categories FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view published articles"
    ON news_articles FOR SELECT
    USING (is_published = true);

CREATE POLICY "Admin can manage articles"
    ON news_articles FOR ALL
    USING (is_admin());

-- Create function to handle article publishing
CREATE OR REPLACE FUNCTION handle_article_publishing()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_published AND OLD.is_published = false THEN
        NEW.published_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for article publishing
CREATE TRIGGER handle_article_publishing_trigger
    BEFORE UPDATE ON news_articles
    FOR EACH ROW
    EXECUTE FUNCTION handle_article_publishing();

-- Insert default categories
INSERT INTO news_categories (name, description) VALUES
    ('Geral', 'Notícias gerais e comunicados'),
    ('Eventos', 'Eventos e acontecimentos'),
    ('Treinamentos', 'Novos treinamentos e cursos'),
    ('Comunicados', 'Comunicados importantes')
ON CONFLICT (name) DO NOTHING;

-- Create function to notify users about new articles
CREATE OR REPLACE FUNCTION notify_new_article()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notifications (
        user_id,
        title,
        message
    )
    SELECT
        u.id,
        'Nova notícia publicada: ' || NEW.title,
        substring(NEW.content from 1 for 100) || '...'
    FROM auth.users u;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new article notifications
CREATE TRIGGER notify_new_article_trigger
    AFTER INSERT ON news_articles
    FOR EACH ROW
    WHEN (NEW.is_published = true)
    EXECUTE FUNCTION notify_new_article();

-- Create function to get latest news
CREATE OR REPLACE FUNCTION get_latest_news(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    title TEXT,
    content TEXT,
    image_url TEXT,
    video_url TEXT,
    category_name TEXT,
    is_featured BOOLEAN,
    published_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        na.id,
        na.title,
        na.content,
        na.image_url,
        na.video_url,
        nc.name as category_name,
        na.is_featured,
        na.published_at
    FROM news_articles na
    LEFT JOIN news_categories nc ON na.category = nc.id
    WHERE na.is_published = true
    ORDER BY 
        na.is_featured DESC,
        na.published_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION get_latest_news(INTEGER) TO authenticated;

-- Create storage bucket for news images if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('news', 'news', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies
CREATE POLICY "Public news access"
ON storage.objects FOR SELECT
USING (bucket_id = 'news');

CREATE POLICY "Auth users can upload to news"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'news'
    AND (
        is_admin()
        OR EXISTS (
            SELECT 1 FROM user_groups ug
            JOIN user_group_members ugm ON ug.id = ugm.group_id
            WHERE ugm.user_id = auth.uid()
            AND ug.news_access = true
        )
    )
);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;