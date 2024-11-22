import { create } from 'zustand';
import { supabase } from '../lib/supabase';

interface ProcessState {
  processes: Record<string, {
    id: string;
    type: 'course_generation' | 'video_processing';
    status: 'pending' | 'processing' | 'completed' | 'failed';
    progress: number;
    currentStep: string;
    result?: any;
    error?: string;
  }>;
  subscribeToProcesses: () => void;
  unsubscribeFromProcesses: () => void;
  startProcess: (type: 'course_generation' | 'video_processing', data: any) => Promise<string>;
  updateProcess: (id: string, updates: Partial<ProcessState['processes'][string]>) => Promise<void>;
}

export const useProcessStore = create<ProcessState>((set, get) => ({
  processes: {},

  subscribeToProcesses: () => {
    const { data: { user } } = supabase.auth.getUser();
    if (!user) return;

    // Subscribe to process updates
    const subscription = supabase
      .channel('process_updates')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'processes',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          const { new: process } = payload;
          set((state) => ({
            processes: {
              ...state.processes,
              [process.id]: process
            }
          }));
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  },

  unsubscribeFromProcesses: () => {
    supabase.removeAllChannels();
  },

  startProcess: async (type, data) => {
    const { data: process, error } = await supabase
      .from('processes')
      .insert({
        type,
        status: 'pending',
        progress: 0,
        data
      })
      .select()
      .single();

    if (error) throw error;

    set((state) => ({
      processes: {
        ...state.processes,
        [process.id]: process
      }
    }));

    return process.id;
  },

  updateProcess: async (id, updates) => {
    const { error } = await supabase
      .from('processes')
      .update(updates)
      .eq('id', id);

    if (error) throw error;
  }
}));