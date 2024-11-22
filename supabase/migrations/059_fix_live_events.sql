-- Fix live events relationship with auth.users
BEGIN;

-- First drop existing constraint if it exists
ALTER TABLE live_events 
DROP CONSTRAINT IF EXISTS live_events_instructor_id_fkey;

-- Recreate the table with correct relationships
DROP TABLE IF EXISTS live_events CASCADE;
CREATE TABLE live_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  instructor_id UUID NOT NULL,
  meeting_url TEXT NOT NULL,
  starts_at TIMESTAMPTZ NOT NULL,
  duration INTEGER NOT NULL,
  attendees_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT live_events_instructor_id_fkey 
    FOREIGN KEY (instructor_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE
);

-- Add indexes for better performance
CREATE INDEX idx_live_events_instructor ON live_events(instructor_id);
CREATE INDEX idx_live_events_company ON live_events(company_id);
CREATE INDEX idx_live_events_starts_at ON live_events(starts_at);

-- Enable RLS
ALTER TABLE live_events ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view live events"
  ON live_events FOR SELECT
  USING (company_id = (
    SELECT company_id 
    FROM auth.users 
    WHERE id = auth.uid()
  ));

CREATE POLICY "Admin can manage live events"
  ON live_events FOR ALL
  USING (
    EXISTS (
      SELECT 1 
      FROM auth.users 
      WHERE id = auth.uid() 
      AND raw_user_meta_data->>'role' = 'admin'
      AND users.company_id = live_events.company_id
    )
  );

-- Insert sample data for testing
INSERT INTO live_events (
  company_id,
  title,
  description,
  instructor_id,
  meeting_url,
  starts_at,
  duration
) VALUES (
  'c0000000-0000-0000-0000-000000000000',
  'Aula Inaugural',
  'Introdução ao curso e apresentação da plataforma',
  (SELECT id FROM auth.users WHERE email = 'diegodemontevpj@gmail.com' LIMIT 1),
  'https://meet.example.com/aula-inaugural',
  NOW() + interval '1 day',
  60
);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;