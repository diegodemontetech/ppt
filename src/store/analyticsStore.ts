import { create } from 'zustand';
import { supabase } from '../lib/supabase';

interface AnalyticsState {
  courseStats: any;
  userStats: any;
  loading: boolean;
  error: string | null;
  fetchCourseStats: () => Promise<void>;
  fetchUserStats: () => Promise<void>;
}

export const useAnalyticsStore = create<AnalyticsState>((set) => ({
  courseStats: null,
  userStats: null,
  loading: false,
  error: null,

  fetchCourseStats: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .rpc('get_course_statistics');

      if (error) throw error;
      set({ courseStats: data });
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  },

  fetchUserStats: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .rpc('get_user_statistics');

      if (error) throw error;
      set({ userStats: data });
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  }
}));