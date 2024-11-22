-- Fix DocBox tables and relationships
BEGIN;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS document_downloads CASCADE;
DROP TABLE IF EXISTS documents CASCADE;
DROP TABLE IF EXISTS doc_categories CASCADE;

-- Create document categories table
CREATE TABLE doc_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    parent_id UUID REFERENCES doc_categories(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create documents table
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    category_id UUID REFERENCES doc_categories(id) ON DELETE CASCADE,
    file_url TEXT NOT NULL,
    file_type TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    downloads INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create document downloads table
CREATE TABLE document_downloads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    downloaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_doc_categories_parent ON doc_categories(parent_id);
CREATE INDEX idx_documents_category ON documents(category_id);
CREATE INDEX idx_documents_type ON documents(file_type);
CREATE INDEX idx_document_downloads_doc ON document_downloads(document_id);
CREATE INDEX idx_document_downloads_user ON document_downloads(user_id);

-- Enable RLS
ALTER TABLE doc_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_downloads ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Everyone can view active categories"
    ON doc_categories FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage categories"
    ON doc_categories FOR ALL
    USING (is_admin());

CREATE POLICY "Everyone can view active documents"
    ON documents FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admin can manage documents"
    ON documents FOR ALL
    USING (is_admin());

CREATE POLICY "Users can view their downloads"
    ON document_downloads FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create downloads"
    ON document_downloads FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Insert default categories
INSERT INTO doc_categories (name, description) VALUES
    ('Contratos', 'Documentos contratuais'),
    ('Manuais', 'Manuais e guias'),
    ('Distratos', 'Documentos de rescisão'),
    ('Processos', 'Documentação de processos'),
    ('Notificações', 'Comunicados oficiais')
ON CONFLICT (name) DO NOTHING;

-- Insert subcategories for Contratos
WITH contratos AS (
    SELECT id FROM doc_categories WHERE name = 'Contratos'
)
INSERT INTO doc_categories (name, description, parent_id) VALUES
    ('Prestador', 'Contratos de prestação de serviços', (SELECT id FROM contratos)),
    ('Franquia', 'Contratos de franquia', (SELECT id FROM contratos)),
    ('Imobiliário', 'Contratos imobiliários', (SELECT id FROM contratos)),
    ('Trabalho', 'Contratos trabalhistas', (SELECT id FROM contratos)),
    ('Parceria', 'Contratos de parceria', (SELECT id FROM contratos))
ON CONFLICT (name) DO NOTHING;

-- Create storage bucket for documents if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies
CREATE POLICY "Users can upload documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'documents');

CREATE POLICY "Public document access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'documents');

CREATE POLICY "Admin document deletion"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'documents' 
  AND EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'role' = 'admin'
  )
);

-- Create function to handle document deletion
CREATE OR REPLACE FUNCTION handle_document_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete file from storage if exists
    IF OLD.file_url IS NOT NULL THEN
        PERFORM storage.delete('documents', split_part(OLD.file_url, '/', -1));
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for document deletion
DROP TRIGGER IF EXISTS delete_document_trigger ON documents;
CREATE TRIGGER delete_document_trigger
    BEFORE DELETE ON documents
    FOR EACH ROW
    EXECUTE FUNCTION handle_document_deletion();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;