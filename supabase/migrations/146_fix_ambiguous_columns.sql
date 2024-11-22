-- Fix ambiguous column references in functions
BEGIN;

-- Fix handle_module_completion function
CREATE OR REPLACE FUNCTION handle_module_completion()
RETURNS TRIGGER AS $$
DECLARE
    _module_id UUID;
    _quiz_score NUMERIC;
BEGIN
    -- Get module_id from lesson using explicit table alias
    SELECT l.module_id INTO _module_id 
    FROM lessons l 
    WHERE l.id = NEW.lesson_id;
    
    IF NEW.score IS NOT NULL THEN
        _quiz_score := NEW.score;
    END IF;

    -- Check if all lessons are completed using explicit aliases
    IF NOT EXISTS (
        SELECT 1 
        FROM lessons l2
        LEFT JOIN lesson_progress lp2 ON l2.id = lp2.lesson_id AND lp2.user_id = NEW.user_id
        WHERE l2.module_id = _module_id
        AND (lp2.completed IS NULL OR lp2.completed = false)
    ) THEN
        -- Insert or update certificate
        INSERT INTO certificates (
            user_id,
            module_id,
            score,
            issued_at
        ) VALUES (
            NEW.user_id,
            _module_id,
            _quiz_score,
            CURRENT_TIMESTAMP
        )
        ON CONFLICT (user_id, module_id) 
        DO UPDATE SET 
            score = EXCLUDED.score,
            issued_at = CURRENT_TIMESTAMP;

        -- Insert completion notification
        INSERT INTO notifications (
            user_id,
            title,
            message
        ) VALUES (
            NEW.user_id,
            'Módulo Concluído',
            'Parabéns! Você completou o módulo' || 
            CASE 
                WHEN _quiz_score IS NOT NULL THEN ' com nota ' || _quiz_score::TEXT || '!'
                ELSE '!'
            END
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Fix get_module_stats function
CREATE OR REPLACE FUNCTION get_module_stats(module_uuid UUID)
RETURNS TABLE (
    enrolled_count BIGINT,
    average_rating NUMERIC,
    total_ratings BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH stats AS (
        SELECT 
            COUNT(DISTINCT lp.user_id) as enrolled,
            ROUND(AVG(lp.score)::NUMERIC, 1) as avg_rating,
            COUNT(DISTINCT lp.id) as total_rating
        FROM modules m
        LEFT JOIN lessons l ON l.module_id = m.id
        LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id
        WHERE m.id = module_uuid
        GROUP BY m.id
    )
    SELECT
        COALESCE(enrolled, 0)::BIGINT as enrolled_count,
        COALESCE(avg_rating, 0.0)::NUMERIC as average_rating,
        COALESCE(total_rating, 0)::BIGINT as total_ratings
    FROM stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix certificate_details view
DROP VIEW IF EXISTS certificate_details;
CREATE VIEW certificate_details AS
SELECT 
    c.id,
    c.user_id,
    c.module_id,
    c.score,
    m.technical_lead,
    m.estimated_duration,
    'https://materiaisst2023.lojazap.com/_core/_uploads/19281/2024/04/12042004240eicbg8hg1.webp' as seal_url,
    c.issued_at
FROM certificates c
JOIN modules m ON c.module_id = m.id;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;