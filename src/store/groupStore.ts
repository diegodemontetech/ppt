import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { UserGroup } from '../types';

interface GroupState {
  groups: UserGroup[];
  loading: boolean;
  error: string | null;
  fetchGroups: () => Promise<void>;
  createGroup: (name: string, description: string, permissions: string[]) => Promise<void>;
  updateGroup: (id: string, name: string, description: string, permissions: string[]) => Promise<void>;
  deleteGroup: (id: string) => Promise<void>;
  addUserToGroup: (userId: string, groupId: string) => Promise<void>;
  removeUserFromGroup: (userId: string, groupId: string) => Promise<void>;
}

export const useGroupStore = create<GroupState>((set, get) => ({
  groups: [],
  loading: false,
  error: null,

  fetchGroups: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('user_groups')
        .select('*')
        .order('name');

      if (error) throw error;
      set({ groups: data });
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  },

  createGroup: async (name: string, description: string, permissions: string[]) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('user_groups')
        .insert([{ name, description, permissions }]);

      if (error) throw error;
      get().fetchGroups();
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  },

  updateGroup: async (id: string, name: string, description: string, permissions: string[]) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('user_groups')
        .update({ name, description, permissions })
        .eq('id', id);

      if (error) throw error;
      get().fetchGroups();
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  },

  deleteGroup: async (id: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('user_groups')
        .delete()
        .eq('id', id);

      if (error) throw error;
      get().fetchGroups();
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  },

  addUserToGroup: async (userId: string, groupId: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('user_group_members')
        .insert([{ user_id: userId, group_id: groupId }]);

      if (error) throw error;
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  },

  removeUserFromGroup: async (userId: string, groupId: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('user_group_members')
        .delete()
        .match({ user_id: userId, group_id: groupId });

      if (error) throw error;
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  }
}));