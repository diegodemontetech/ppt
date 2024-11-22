import { supabase, handleSupabaseError } from './supabase';
import type { User } from '@supabase/supabase-js';
import toast from 'react-hot-toast';

// Get completed courses
export async function getCompletedCourses(userId: string) {
  try {
    const { data, error } = await supabase
      .from('modules')
      .select(`
        *,
        lessons(
          lesson_progress(completed, score)
        ),
        course_ratings(rating)
      `)
      .eq('lessons.lesson_progress.user_id', userId);

    if (error) throw error;

    // Filter only completed courses
    return data.filter(course => 
      course.lessons.every(lesson => 
        lesson.lesson_progress.some(p => p.completed)
      )
    );
  } catch (error) {
    handleSupabaseError(error);
    throw error;
  }
}

// User stats
export async function getUserStats(userId: string) {
  try {
    // Get certificates count
    const { data: certificates, error: certError } = await supabase
      .from('certificates')
      .select('id')
      .eq('user_id', userId);

    if (certError) throw certError;

    // Get courses progress
    const { data: progress, error: progError } = await supabase
      .from('lesson_progress')
      .select(`
        lesson_id,
        completed,
        lessons:lessons(
          module_id,
          duration
        )
      `)
      .eq('user_id', userId);

    if (progError) throw progError;

    // Calculate stats
    const completedHours = progress?.reduce((acc, curr) => {
      if (curr.completed) {
        return acc + (curr.lessons?.duration || 0);
      }
      return acc;
    }, 0) / 3600; // Convert seconds to hours

    const moduleIds = new Set(progress?.map(p => p.lessons?.module_id));
    const pendingCourses = moduleIds.size;

    return {
      certificatesCount: certificates?.length || 0,
      pendingCourses,
      completedHours: Math.round(completedHours)
    };
  } catch (error) {
    console.error('Error fetching user stats:', error);
    return {
      certificatesCount: 0,
      pendingCourses: 0,
      completedHours: 0
    };
  }
}

// Progress functions
export async function updateLessonProgress(lessonId: string, completed: boolean, score?: number) {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    // Use upsert instead of insert to handle duplicates
    const { error } = await supabase
      .from('lesson_progress')
      .upsert({
        user_id: user.id,
        lesson_id: lessonId,
        completed,
        score,
        updated_at: new Date().toISOString()
      }, {
        onConflict: 'user_id,lesson_id'
      });

    if (error) throw error;

    if (completed) {
      toast.success('Aula concluída com sucesso!');
    }
  } catch (error) {
    handleSupabaseError(error);
    throw error;
  }
}