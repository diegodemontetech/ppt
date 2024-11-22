-- Add Marketing Box system
BEGIN;

-- Create marketing_box_items table
CREATE TABLE IF NOT EXISTS marketing_box_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    thumbnail_url TEXT,
    file_type TEXT NOT NULL, -- PNG, MP4, etc
    media_type TEXT NOT NULL, -- Video, Image, etc
    resolution TEXT, -- HD, Full HD, 4K
    category TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    downloads INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create marketing_box_categories table
CREATE TABLE IF NOT EXISTS marketing_box_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create marketing_box_downloads table
CREATE TABLE IF NOT EXISTS marketing_box_downloads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_id UUID REFERENCES marketing_box_items(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    downloaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_marketing_box_items_type ON marketing_box_items(file_type);
CREATE INDEX IF NOT EXISTS idx_marketing_box_items_media ON marketing_box_items(media_type);
CREATE INDEX IF NOT EXISTS idx_marketing_box_items_category ON marketing_box_items(category);
CREATE INDEX IF NOT EXISTS idx_marketing_box_items_tags ON marketing_box_items USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_marketing_box_downloads_item ON marketing_box_downloads(item_id);
CREATE INDEX IF NOT EXISTS idx_marketing_box_downloads_user ON marketing_box_downloads(user_id);

-- Add marketing box permissions to user_groups
ALTER TABLE user_groups
ADD COLUMN IF NOT EXISTS marketing_box_access BOOLEAN DEFAULT false;

-- Create storage bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('marketingbox', 'marketingbox', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies
CREATE POLICY "Public marketingbox access"
ON storage.objects FOR SELECT
USING (bucket_id = 'marketingbox');

CREATE POLICY "Auth users can upload to marketingbox"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'marketingbox'
    AND (
        is_admin()
        OR EXISTS (
            SELECT 1 FROM user_groups ug
            JOIN user_group_members ugm ON ug.id = ugm.group_id
            WHERE ugm.user_id = auth.uid()
            AND ug.marketing_box_access = true
        )
    )
);

-- Enable RLS
ALTER TABLE marketing_box_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketing_box_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketing_box_downloads ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Public can view active items"
ON marketing_box_items FOR SELECT
USING (
    is_active = true
    AND EXISTS (
        SELECT 1 FROM user_groups ug
        JOIN user_group_members ugm ON ug.id = ugm.group_id
        WHERE ugm.user_id = auth.uid()
        AND ug.marketing_box_access = true
    )
);

CREATE POLICY "Admin can manage items"
ON marketing_box_items FOR ALL
USING (is_admin());

CREATE POLICY "Public can view categories"
ON marketing_box_categories FOR SELECT
USING (is_active = true);

CREATE POLICY "Admin can manage categories"
ON marketing_box_categories FOR ALL
USING (is_admin());

CREATE POLICY "Users can view their downloads"
ON marketing_box_downloads FOR SELECT
USING (
    auth.uid() = user_id
    OR is_admin()
);

CREATE POLICY "Users can create downloads"
ON marketing_box_downloads FOR INSERT
WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
        SELECT 1 FROM user_groups ug
        JOIN user_group_members ugm ON ug.id = ugm.group_id
        WHERE ugm.user_id = auth.uid()
        AND ug.marketing_box_access = true
    )
);

-- Create function to increment download count
CREATE OR REPLACE FUNCTION increment_marketing_box_downloads()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE marketing_box_items
    SET downloads = downloads + 1
    WHERE id = NEW.item_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for download count
CREATE TRIGGER increment_downloads_trigger
    AFTER INSERT ON marketing_box_downloads
    FOR EACH ROW
    EXECUTE FUNCTION increment_marketing_box_downloads();

-- Insert default categories
INSERT INTO marketing_box_categories (name, description) VALUES
    ('Banners', 'Banners e imagens para divulgação'),
    ('Vídeos', 'Vídeos institucionais e promocionais'),
    ('Logos', 'Logotipos e identidade visual'),
    ('Templates', 'Templates para documentos e apresentações'),
    ('Social Media', 'Conteúdo para redes sociais')
ON CONFLICT (name) DO NOTHING;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;