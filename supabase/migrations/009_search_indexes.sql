-- Adicionar índices de busca para melhor performance
CREATE INDEX IF NOT EXISTS idx_courses_title_search ON courses USING gin(to_tsvector('portuguese', title));
CREATE INDEX IF NOT EXISTS idx_courses_description_search ON courses USING gin(to_tsvector('portuguese', description));
CREATE INDEX IF NOT EXISTS idx_lessons_title_search ON lessons USING gin(to_tsvector('portuguese', title));
CREATE INDEX IF NOT EXISTS idx_lessons_description_search ON lessons USING gin(to_tsvector('portuguese', description));

-- Função para busca full-text
CREATE OR REPLACE FUNCTION search_content(search_query TEXT)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  type TEXT,
  course_id UUID
) AS $$
BEGIN
  RETURN QUERY
  -- Buscar cursos
  SELECT 
    c.id,
    c.title,
    c.description,
    'course' as type,
    NULL::UUID as course_id
  FROM courses c
  WHERE 
    to_tsvector('portuguese', c.title || ' ' || c.description) @@ to_tsquery('portuguese', search_query)
  
  UNION ALL
  
  -- Buscar aulas
  SELECT 
    l.id,
    l.title,
    l.description,
    'lesson' as type,
    l.course_id
  FROM lessons l
  WHERE 
    to_tsvector('portuguese', l.title || ' ' || l.description) @@ to_tsquery('portuguese', search_query)
  
  ORDER BY title
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;