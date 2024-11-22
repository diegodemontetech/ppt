-- Fix admin role and permissions
DO $$ 
DECLARE
  bucket_exists BOOLEAN;
BEGIN
  -- Check if videos bucket exists
  SELECT EXISTS (
    SELECT 1 FROM storage.buckets WHERE id = 'videos'
  ) INTO bucket_exists;

  -- Create videos bucket if it doesn't exist
  IF NOT bucket_exists THEN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('videos', 'videos', true);
  END IF;

  -- Update admin user
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"admin"'
  )
  WHERE email = 'diegodemontevpj@gmail.com';

  -- Create admin check function
  DROP FUNCTION IF EXISTS is_admin();
  CREATE FUNCTION is_admin()
  RETURNS BOOLEAN
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
  AS $func$
    BEGIN
      RETURN EXISTS (
        SELECT 1
        FROM auth.users
        WHERE id = auth.uid()
        AND raw_user_meta_data->>'role' = 'admin'
      );
    END;
  $func$;

  -- Create user creation trigger function
  DROP FUNCTION IF EXISTS handle_new_user();
  CREATE FUNCTION handle_new_user()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
  AS $func$
    BEGIN
      -- Set default role to 'user' if not specified
      IF NEW.raw_user_meta_data->>'role' IS NULL THEN
        NEW.raw_user_meta_data = jsonb_set(
          COALESCE(NEW.raw_user_meta_data, '{}'::jsonb),
          '{role}',
          '"user"'
        );
      END IF;

      -- Set email in metadata
      NEW.raw_user_meta_data = jsonb_set(
        NEW.raw_user_meta_data,
        '{email}',
        to_jsonb(NEW.email)
      );

      RETURN NEW;
    END;
  $func$;

  -- Create trigger for new users
  DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
  CREATE TRIGGER on_auth_user_created
    BEFORE INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

  -- Enable RLS on all tables
  ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
  ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
  ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
  ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;

  -- Drop existing policies
  DROP POLICY IF EXISTS "Admin full access" ON courses;
  DROP POLICY IF EXISTS "Users view courses" ON courses;
  DROP POLICY IF EXISTS "Admin full access" ON lessons;
  DROP POLICY IF EXISTS "Users view lessons" ON lessons;
  DROP POLICY IF EXISTS "Admin full access" ON quizzes;
  DROP POLICY IF EXISTS "Users view quizzes" ON quizzes;
  DROP POLICY IF EXISTS "Users manage progress" ON lesson_progress;

  -- Create new policies for courses
  CREATE POLICY "Admin full access"
    ON courses FOR ALL
    USING (is_admin());

  CREATE POLICY "Users view courses"
    ON courses FOR SELECT
    USING (auth.role() = 'authenticated');

  -- Create new policies for lessons
  CREATE POLICY "Admin full access"
    ON lessons FOR ALL
    USING (is_admin());

  CREATE POLICY "Users view lessons"
    ON lessons FOR SELECT
    USING (auth.role() = 'authenticated');

  -- Create new policies for quizzes
  CREATE POLICY "Admin full access"
    ON quizzes FOR ALL
    USING (is_admin());

  CREATE POLICY "Users view quizzes"
    ON quizzes FOR SELECT
    USING (auth.role() = 'authenticated');

  -- Create new policy for lesson progress
  CREATE POLICY "Users manage progress"
    ON lesson_progress FOR ALL
    USING (auth.uid() = user_id OR is_admin());

  -- Create function to update course timestamp
  DROP FUNCTION IF EXISTS update_course_timestamp();
  CREATE FUNCTION update_course_timestamp()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
  AS $func$
    BEGIN
      UPDATE courses
      SET updated_at = CURRENT_TIMESTAMP
      WHERE id = NEW.course_id;
      RETURN NEW;
    END;
  $func$;

  -- Create trigger for course timestamp
  DROP TRIGGER IF EXISTS update_course_timestamp ON lessons;
  CREATE TRIGGER update_course_timestamp
    AFTER INSERT OR UPDATE OR DELETE ON lessons
    FOR EACH ROW
    EXECUTE FUNCTION update_course_timestamp();

  -- Drop existing storage policies
  DROP POLICY IF EXISTS "Authenticated users can upload videos" ON storage.objects;
  DROP POLICY IF EXISTS "Anyone can view videos" ON storage.objects;
  DROP POLICY IF EXISTS "Admins can delete videos" ON storage.objects;

  -- Create new storage policies
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

END $$;