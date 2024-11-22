-- Add live events and email settings
BEGIN;

-- Create live_events table
CREATE TABLE IF NOT EXISTS live_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  instructor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  meeting_url TEXT NOT NULL,
  starts_at TIMESTAMPTZ NOT NULL,
  duration INTEGER NOT NULL, -- in minutes
  attendees_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create email_templates table
CREATE TABLE IF NOT EXISTS email_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  subject TEXT NOT NULL,
  content TEXT NOT NULL,
  variables JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, name)
);

-- Create workflow_settings table
CREATE TABLE IF NOT EXISTS workflow_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  smtp_host TEXT NOT NULL,
  smtp_port INTEGER NOT NULL,
  smtp_user TEXT NOT NULL,
  smtp_pass TEXT NOT NULL,
  from_email TEXT NOT NULL,
  from_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id)
);

-- Enable RLS
ALTER TABLE live_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_settings ENABLE ROW LEVEL SECURITY;

-- Create policies for live events
CREATE POLICY "Admin can manage live events"
  ON live_events FOR ALL
  USING (
    company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'admin'
    )
  );

CREATE POLICY "Users can view live events"
  ON live_events FOR SELECT
  USING (
    company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
  );

-- Create policies for email templates
CREATE POLICY "Admin can manage email templates"
  ON email_templates FOR ALL
  USING (
    company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'admin'
    )
  );

-- Create policies for workflow settings
CREATE POLICY "Admin can manage workflow settings"
  ON workflow_settings FOR ALL
  USING (
    company_id = (
      SELECT company_id 
      FROM auth.users 
      WHERE id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'admin'
    )
  );

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_live_events_company ON live_events(company_id);
CREATE INDEX IF NOT EXISTS idx_live_events_instructor ON live_events(instructor_id);
CREATE INDEX IF NOT EXISTS idx_live_events_starts_at ON live_events(starts_at);
CREATE INDEX IF NOT EXISTS idx_email_templates_company ON email_templates(company_id);
CREATE INDEX IF NOT EXISTS idx_workflow_settings_company ON workflow_settings(company_id);

-- Create function to notify users about new live events
CREATE OR REPLACE FUNCTION notify_live_event()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notifications (
    user_id,
    title,
    message
  )
  SELECT
    u.id,
    'Nova Aula ao Vivo: ' || NEW.title,
    'Uma nova aula ao vivo foi agendada para ' || 
    to_char(NEW.starts_at AT TIME ZONE 'UTC', 'DD/MM/YYYY às HH24:MI')
  FROM auth.users u
  WHERE u.company_id = NEW.company_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for live event notifications
DROP TRIGGER IF EXISTS notify_live_event_trigger ON live_events;
CREATE TRIGGER notify_live_event_trigger
  AFTER INSERT ON live_events
  FOR EACH ROW
  EXECUTE FUNCTION notify_live_event();

COMMIT;