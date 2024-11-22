import { supabase, handleSupabaseError } from './supabase';
import type { Course, Lesson, Quiz } from '../types';

// Course functions
export async function getCourses(): Promise<Course[]> {
  try {
    const { data, error } = await supabase
      .from('modules')
      .select(`
        *,
        category:categories(
          id,
          name,
          department:departments(
            id,
            name
          )
        ),
        lessons(
          *,
          lesson_progress(*),
          lesson_ratings(*),
          quizzes(*)
        )
      `)
      .order('created_at', { ascending: true });

    if (error) throw error;
    return data || [];
  } catch (error) {
    handleSupabaseError(error);
    throw error;
  }
}

export async function getCourse(id: string): Promise<Course> {
  try {
    const { data, error } = await supabase
      .from('modules')
      .select(`
        *,
        category:categories(
          id,
          name,
          department:departments(
            id,
            name
          )
        ),
        lessons(
          *,
          lesson_progress(*),
          lesson_ratings(*),
          quizzes(*)
        )
      `)
      .eq('id', id)
      .single();

    if (error) throw error;

    // Get module statistics
    const { data: stats, error: statsError } = await supabase
      .rpc('get_module_stats', { module_uuid: id });

    if (statsError) throw statsError;

    return {
      ...data,
      enrolled_count: stats?.[0]?.enrolled_count || 0,
      average_rating: stats?.[0]?.average_rating || 0,
      total_ratings: stats?.[0]?.total_ratings || 0
    };
  } catch (error) {
    handleSupabaseError(error);
    throw error;
  }
}

export async function createCourse(title: string, description: string): Promise<Course> {
  try {
    const { data, error } = await supabase
      .from('modules')
      .insert([{ title, description }])
      .select()
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    handleSupabaseError(error);
    throw error;
  }
}

export async function updateCourse(id: string, title: string, description: string): Promise<Course> {
  try {
    const { data, error } = await supabase
      .from('modules')
      .update({ title, description })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    handleSupabaseError(error);
    throw error;
  }
}

export async function deleteCourse(id: string): Promise<void> {
  try {
    const { error } = await supabase
      .from('modules')
      .delete()
      .eq('id', id);

    if (error) throw error;
  } catch (error) {
    handleSupabaseError(error);
    throw error;
  }
}

// Lesson functions
export async function createLesson(
  courseId: string,
  title: string,
  videoUrl: string,
  pdfUrl: string | null,
  orderNum: number
): Promise<Lesson> {
  try {
    const { data, error } = await supabase
      .from('lessons')
      .insert([{
        module_id: courseId,
        title,
        video_url: videoUrl,
        pdf_url: pdfUrl,
        order_num: orderNum
      }])
      .select()
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    handleSupabaseError(error);
    throw error;
  }
}

export async function deleteLesson(id: string): Promise<void> {
  try {
    const { error } = await supabase
      .from('lessons')
      .delete()
      .eq('id', id);

    if (error) throw error;
  } catch (error) {
    handleSupabaseError(error);
    throw error;
  }
}

// Quiz functions
export async function getQuiz(lessonId: string): Promise<Quiz | null> {
  try {
    const { data, error } = await supabase
      .from('quizzes')
      .select('*')
      .eq('lesson_id', lessonId)
      .single();

    if (error && error.code !== 'PGRST116') throw error;
    return data;
  } catch (error) {
    handleSupabaseError(error);
    throw error;
  }
}

export async function saveQuiz(lessonId: string, questions: any[]): Promise<Quiz> {
  try {
    const { data, error } = await supabase
      .from('quizzes')
      .upsert({
        lesson_id: lessonId,
        questions,
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    handleSupabaseError(error);
    throw error;
  }
}