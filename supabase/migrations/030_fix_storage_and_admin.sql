-- Fix storage bucket and policies
DO $$ 
BEGIN
  -- Drop existing policies
  DROP POLICY IF EXISTS "Authenticated users can upload videos" ON storage.objects;
  DROP POLICY IF EXISTS "Anyone can view videos" ON storage.objects;
  DROP POLICY IF EXISTS "Admins can delete videos" ON storage.objects;

  -- Create new policies
  CREATE POLICY "Authenticated users can upload videos"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'videos');

  CREATE POLICY "Anyone can view videos"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'videos');

  CREATE POLICY "Admins can delete videos"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'videos' 
    AND EXISTS (
      SELECT 1 
      FROM auth.users 
      WHERE id = auth.uid() 
      AND raw_user_meta_data->>'role' = 'admin'
    )
  );

  -- Fix admin role
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"admin"'
  )
  WHERE email = 'diegodemontevpj@gmail.com';

  -- Create or replace admin check function
  CREATE OR REPLACE FUNCTION is_admin()
  RETURNS BOOLEAN AS $$
  BEGIN
    RETURN EXISTS (
      SELECT 1
      FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'admin'
    );
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  -- Update RLS policies
  ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
  ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
  ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
  ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;

  -- Courses policies
  DROP POLICY IF EXISTS "Admin full access courses" ON courses;
  CREATE POLICY "Admin full access courses" ON courses
    FOR ALL
    USING (is_admin());

  DROP POLICY IF EXISTS "Users view courses" ON courses;
  CREATE POLICY "Users view courses" ON courses
    FOR SELECT
    USING (auth.role() = 'authenticated');

  -- Lessons policies
  DROP POLICY IF EXISTS "Admin full access lessons" ON lessons;
  CREATE POLICY "Admin full access lessons" ON lessons
    FOR ALL
    USING (is_admin());

  DROP POLICY IF EXISTS "Users view lessons" ON lessons;
  CREATE POLICY "Users view lessons" ON lessons
    FOR SELECT
    USING (auth.role() = 'authenticated');

  -- Quizzes policies
  DROP POLICY IF EXISTS "Admin full access quizzes" ON quizzes;
  CREATE POLICY "Admin full access quizzes" ON quizzes
    FOR ALL
    USING (is_admin());

  DROP POLICY IF EXISTS "Users view quizzes" ON quizzes;
  CREATE POLICY "Users view quizzes" ON quizzes
    FOR SELECT
    USING (auth.role() = 'authenticated');

  -- Progress policies
  DROP POLICY IF EXISTS "Users manage progress" ON lesson_progress;
  CREATE POLICY "Users manage progress" ON lesson_progress
    FOR ALL
    USING (auth.uid() = user_id OR is_admin());
END $$;