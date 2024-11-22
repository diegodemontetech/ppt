import { create } from 'zustand';
import { supabase, handleSupabaseError } from '../lib/supabase';
import type { Module } from '../types';
import toast from 'react-hot-toast';

interface ModuleState {
  modules: Module[];
  loading: boolean;
  error: string | null;
  fetchModules: () => Promise<void>;
  getModule: (id: string) => Promise<Module | null>;
}

export const useModuleStore = create<ModuleState>((set, get) => ({
  modules: [],
  loading: false,
  error: null,

  fetchModules: async () => {
    try {
      set({ loading: true, error: null });
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
            id,
            title,
            video_url,
            duration,
            order_num,
            lesson_progress(
              completed,
              score,
              user_id
            ),
            lesson_ratings(
              rating,
              user_id
            ),
            quizzes(*)
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      set({ modules: data || [] });
    } catch (error) {
      handleSupabaseError(error);
    } finally {
      set({ loading: false });
    }
  },

  getModule: async (id: string) => {
    try {
      set({ loading: true, error: null });
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
            id,
            title,
            video_url,
            duration,
            order_num,
            lesson_progress(
              completed,
              score,
              user_id
            ),
            lesson_ratings(
              rating,
              user_id
            ),
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
      return null;
    } finally {
      set({ loading: false });
    }
  }
}));