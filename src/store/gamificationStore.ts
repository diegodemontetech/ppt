import { create } from 'zustand';
import { supabase } from '../lib/supabase';

interface GamificationState {
  userPoints: number;
  userBadges: any[];
  userLevel: number;
  loading: boolean;
  error: string | null;
  fetchUserProgress: () => Promise<void>;
  awardPoints: (points: number, reason: string) => Promise<void>;
  checkAchievements: () => Promise<void>;
}

export const useGamificationStore = create<GamificationState>((set, get) => ({
  userPoints: 0,
  userBadges: [],
  userLevel: 1,
  loading: false,
  error: null,

  fetchUserProgress: async () => {
    try {
      set({ loading: true, error: null });
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      const { data: progress, error } = await supabase
        .from('user_progress')
        .select('points, badges, level')
        .eq('user_id', user.id)
        .single();

      if (error) throw error;
      
      set({
        userPoints: progress?.points || 0,
        userBadges: progress?.badges || [],
        userLevel: progress?.level || 1
      });
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  },

  awardPoints: async (points: number, reason: string) => {
    try {
      set({ loading: true, error: null });
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      const { error } = await supabase.rpc('award_points', {
        user_uuid: user.id,
        points_amount: points,
        points_reason: reason
      });

      if (error) throw error;
      
      await get().fetchUserProgress();
      await get().checkAchievements();
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  },

  checkAchievements: async () => {
    try {
      set({ loading: true, error: null });
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      const { error } = await supabase.rpc('check_achievements', {
        user_uuid: user.id
      });

      if (error) throw error;
      
      await get().fetchUserProgress();
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  }
}));