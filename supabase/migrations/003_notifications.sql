-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add RLS policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Create function to send notification
CREATE OR REPLACE FUNCTION send_notification(
  user_uuid UUID,
  notification_title TEXT,
  notification_message TEXT
) RETURNS UUID AS $$
DECLARE
  notification_id UUID;
BEGIN
  INSERT INTO notifications (user_id, title, message)
  VALUES (user_uuid, notification_title, notification_message)
  RETURNING id INTO notification_id;
  
  RETURN notification_id;
END;
$$ LANGUAGE plpgsql;

-- Create function to send notification to all users in a group
CREATE OR REPLACE FUNCTION send_group_notification(
  group_uuid UUID,
  notification_title TEXT,
  notification_message TEXT
) RETURNS SETOF UUID AS $$
DECLARE
  user_uuid UUID;
BEGIN
  FOR user_uuid IN
    SELECT user_id FROM user_group_members WHERE group_id = group_uuid
  LOOP
    RETURN NEXT send_notification(user_uuid, notification_title, notification_message);
  END LOOP;
  RETURN;
END;
$$ LANGUAGE plpgsql;