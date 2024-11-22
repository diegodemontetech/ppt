import { create } from 'zustand';
import { supabase } from '../lib/supabase';

interface ProfileState {
  completedCourses: any[];
  certificates: any[];
  loading: boolean;
  error: string | null;
  fetchUserProfile: () => Promise<void>;
}

export const useProfileStore = create<ProfileState>((set) => ({
  completedCourses: [],
  certificates: [],
  loading: false,
  error: null,

  fetchUserProfile: async () => {
    try {
      set({ loading: true, error: null });
      
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Usuário não autenticado');

      // Buscar cursos concluídos
      const { data: courses, error: coursesError } = await supabase
        .from('courses')
        .select(`
          *,
          lessons(
            lesson_progress(completed, score)
          )
        `)
        .eq('lessons.lesson_progress.user_id', user.id);

      if (coursesError) throw coursesError;

      // Buscar certificados
      const { data: certificates, error: certificatesError } = await supabase
        .from('certificates')
        .select('*')
        .eq('user_id', user.id);

      if (certificatesError) throw certificatesError;

      // Filtrar cursos concluídos
      const completed = courses.filter(course => 
        course.lessons.every(lesson => 
          lesson.lesson_progress.some(p => p.completed)
        )
      );

      set({
        completedCourses: completed,
        certificates,
        loading: false
      });
    } catch (error: any) {
      console.error('Erro ao buscar perfil:', error);
      set({ error: error.message, loading: false });
    }
  }
}));