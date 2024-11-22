-- Create live events table
CREATE TABLE IF NOT EXISTS live_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  instructor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  meeting_url TEXT NOT NULL,
  starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
  duration INTEGER NOT NULL, -- in minutes
  attendees_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add RLS policies
ALTER TABLE live_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view live events"
  ON live_events FOR SELECT
  USING (true);

CREATE POLICY "Only admins can manage live events"
  ON live_events FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- Function to send notification when live event is created
CREATE OR REPLACE FUNCTION notify_live_event()
RETURNS TRIGGER AS $$
BEGIN
  -- Enviar notificação para todos os usuários
  INSERT INTO notifications (
    user_id,
    title,
    message
  )
  SELECT
    id,
    'Nova Aula ao Vivo: ' || NEW.title,
    'Uma nova aula ao vivo foi agendada para ' || 
    to_char(NEW.starts_at AT TIME ZONE 'UTC', 'DD/MM/YYYY às HH24:MI')
  FROM auth.users;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for live event notifications
CREATE TRIGGER notify_live_event_trigger
  AFTER INSERT ON live_events
  FOR EACH ROW
  EXECUTE FUNCTION notify_live_event();