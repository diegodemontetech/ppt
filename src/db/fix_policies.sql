-- Drop existing policies first
DROP POLICY IF EXISTS "Courses are viewable by everyone" ON courses;
DROP POLICY IF EXISTS "Only admins can insert courses" ON courses;
DROP POLICY IF EXISTS "Only admins can update courses" ON courses;
DROP POLICY IF EXISTS "Only admins can delete courses" ON courses;

DROP POLICY IF EXISTS "Lessons are viewable by everyone" ON lessons;
DROP POLICY IF EXISTS "Only admins can insert lessons" ON lessons;
DROP POLICY IF EXISTS "Only admins can update lessons" ON lessons;
DROP POLICY IF EXISTS "Only admins can delete lessons" ON lessons;

DROP POLICY IF EXISTS "Quizzes are viewable by everyone" ON quizzes;
DROP POLICY IF EXISTS "Only admins can insert quizzes" ON quizzes;
DROP POLICY IF EXISTS "Only admins can update quizzes" ON quizzes;
DROP POLICY IF EXISTS "Only admins can delete quizzes" ON quizzes;

DROP POLICY IF EXISTS "Users can view their own progress" ON lesson_progress;
DROP POLICY IF EXISTS "Users can insert their own progress" ON lesson_progress;
DROP POLICY IF EXISTS "Users can update their own progress" ON lesson_progress;

-- Re-create policies
CREATE POLICY "Courses are viewable by everyone" 
  ON courses FOR SELECT 
  USING (true);

CREATE POLICY "Only admins can insert courses" 
  ON courses FOR INSERT 
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Only admins can update courses" 
  ON courses FOR UPDATE 
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Only admins can delete courses" 
  ON courses FOR DELETE 
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Lessons are viewable by everyone" 
  ON lessons FOR SELECT 
  USING (true);

CREATE POLICY "Only admins can insert lessons" 
  ON lessons FOR INSERT 
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Only admins can update lessons" 
  ON lessons FOR UPDATE 
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Only admins can delete lessons" 
  ON lessons FOR DELETE 
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Quizzes are viewable by everyone" 
  ON quizzes FOR SELECT 
  USING (true);

CREATE POLICY "Only admins can insert quizzes" 
  ON quizzes FOR INSERT 
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Only admins can update quizzes" 
  ON quizzes FOR UPDATE 
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Only admins can delete quizzes" 
  ON quizzes FOR DELETE 
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Users can view their own progress" 
  ON lesson_progress FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress" 
  ON lesson_progress FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress" 
  ON lesson_progress FOR UPDATE 
  USING (auth.uid() = user_id);