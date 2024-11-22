-- Add processes table for background tasks
CREATE TABLE processes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    progress INTEGER DEFAULT 0,
    current_step TEXT,
    data JSONB DEFAULT '{}',
    result JSONB,
    error TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes
CREATE INDEX idx_processes_user ON processes(user_id);
CREATE INDEX idx_processes_status ON processes(status);

-- Enable RLS
ALTER TABLE processes ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own processes"
    ON processes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own processes"
    ON processes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own processes"
    ON processes FOR UPDATE
    USING (auth.uid() = user_id);

-- Create function to update process
CREATE OR REPLACE FUNCTION update_process(
    process_id UUID,
    new_status TEXT DEFAULT NULL,
    new_progress INTEGER DEFAULT NULL,
    new_step TEXT DEFAULT NULL,
    new_result JSONB DEFAULT NULL,
    new_error TEXT DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    UPDATE processes
    SET
        status = COALESCE(new_status, status),
        progress = COALESCE(new_progress, progress),
        current_step = COALESCE(new_step, current_step),
        result = COALESCE(new_result, result),
        error = COALESCE(new_error, error),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = process_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;