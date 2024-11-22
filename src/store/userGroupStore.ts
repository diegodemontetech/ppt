import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { UserGroup } from '../types';
import toast from 'react-hot-toast';

interface UserGroupState {
  groups: UserGroup[];
  loading: boolean;
  error: string | null;
  fetchGroups: () => Promise<void>;
  createGroup: (name: string, description: string, permissions: string[], modules: string[]) => Promise<void>;
  updateGroup: (id: string, name: string, description: string, permissions: string[], modules: string[]) => Promise<void>;
  deleteGroup: (id: string) => Promise<void>;
  addUserToGroup: (userId: string, groupId: string) => Promise<void>;
  removeUserFromGroup: (userId: string, groupId: string) => Promise<void>;
}

export const useUserGroupStore = create<UserGroupState>((set, get) => ({
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
      set({ groups: data || [] });
    } catch (error: any) {
      console.error('Error fetching groups:', error);
      set({ error: error.message });
      toast.error('Erro ao carregar grupos');
    } finally {
      set({ loading: false });
    }
  },

  createGroup: async (name: string, description: string, permissions: string[], modules: string[]) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('user_groups')
        .insert([{
          name,
          description,
          permissions,
          modules
        }]);

      if (error) throw error;
      toast.success('Grupo criado com sucesso!');
      get().fetchGroups();
    } catch (error: any) {
      console.error('Error creating group:', error);
      set({ error: error.message });
      toast.error('Erro ao criar grupo');
    } finally {
      set({ loading: false });
    }
  },

  updateGroup: async (id: string, name: string, description: string, permissions: string[], modules: string[]) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('user_groups')
        .update({
          name,
          description,
          permissions,
          modules
        })
        .eq('id', id);

      if (error) throw error;
      toast.success('Grupo atualizado com sucesso!');
      get().fetchGroups();
    } catch (error: any) {
      console.error('Error updating group:', error);
      set({ error: error.message });
      toast.error('Erro ao atualizar grupo');
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
      toast.success('Grupo excluído com sucesso!');
      get().fetchGroups();
    } catch (error: any) {
      console.error('Error deleting group:', error);
      set({ error: error.message });
      toast.error('Erro ao excluir grupo');
    } finally {
      set({ loading: false });
    }
  },

  addUserToGroup: async (userId: string, groupId: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('user_group_members')
        .insert([{
          user_id: userId,
          group_id: groupId
        }]);

      if (error) throw error;
      toast.success('Usuário adicionado ao grupo!');
    } catch (error: any) {
      console.error('Error adding user to group:', error);
      set({ error: error.message });
      toast.error('Erro ao adicionar usuário ao grupo');
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
      toast.success('Usuário removido do grupo!');
    } catch (error: any) {
      console.error('Error removing user from group:', error);
      set({ error: error.message });
      toast.error('Erro ao remover usuário do grupo');
    } finally {
      set({ loading: false });
    }
  }
}));