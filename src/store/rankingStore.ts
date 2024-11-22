import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';

interface RankingUser {
  id: string;
  full_name: string;
  points: number;
  level: number;
}

interface RankingState {
  users: RankingUser[];
  loading: boolean;
  error: string | null;
  fetchRanking: () => Promise<void>;
}

export const useRankingStore = create<RankingState>((set) => ({
  users: [],
  loading: false,
  error: null,

  fetchRanking: async () => {
    try {
      set({ loading: true, error: null });

      const { data, error } = await supabase
        .rpc('get_user_ranking', { limit_count: 10 });

      if (error) throw error;

      const formattedUsers = data.map(user => ({
        id: user.id,
        full_name: user.full_name || 'Usuário',
        points: user.points || 0,
        level: user.level || 1
      }));

      set({ users: formattedUsers });
    } catch (error) {
      console.error('Error fetching ranking:', error);
      toast.error('Erro ao carregar ranking');
      set({ error: 'Failed to fetch ranking' });
    } finally {
      set({ loading: false });
    }
  }
}));