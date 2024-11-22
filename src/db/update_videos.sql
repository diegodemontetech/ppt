-- Update all video URLs to use the test video ID
UPDATE lessons 
SET 
  video_url = 'xu3LXxQFLJk',
  updated_at = CURRENT_TIMESTAMP 
WHERE video_url IS NOT NULL;

-- Add index to improve video URL queries
CREATE INDEX IF NOT EXISTS idx_lessons_video_url ON lessons(video_url);

-- Verify the update
SELECT id, title, video_url 
FROM lessons 
WHERE video_url IS NOT NULL 
ORDER BY created_at;