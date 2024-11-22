-- Increase stack depth (must be outside transaction)
ALTER SYSTEM SET max_stack_depth = '4MB';
SELECT pg_reload_conf();