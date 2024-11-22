import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { User } from '../types';
import toast from 'react-hot-toast';

interface UserState {
  users: User[];
  loading: boolean;
  error: string | null;
  fetchUsers: () => Promise<void>;
  createUser: (email: string, password: string, fullName: string, role: string) => Promise<void>;
  updateUser: (id: string, data: Partial<User>) => Promise<void>;
  deleteUser: (id: string) => Promise<void>;
}

export const useUserStore = create<UserState>((set, get) => ({
  users: [],
  loading: false,
  error: null,

  fetchUsers: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      set({ users: data || [] });
    } catch (error: any) {
      console.error('Error fetching users:', error);
      set({ error: error.message });
      toast.error('Erro ao carregar usuários');
    } finally {
      set({ loading: false });
    }
  },

  createUser: async (email: string, password: string, fullName: string, role: string) => {
    try {
      set({ loading: true, error: null });
      
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: fullName,
            role
          }
        }
      });

      if (error) throw error;
      toast.success('Usuário criado com sucesso!');
      get().fetchUsers();
    } catch (error: any) {
      console.error('Error creating user:', error);
      set({ error: error.message });
      toast.error('Erro ao criar usuário');
    } finally {
      set({ loading: false });
    }
  },

  updateUser: async (id: string, data: Partial<User>) => {
    try {
      set({ loading: true, error: null });
      
      const { error } = await supabase
        .from('users')
        .update({
          email: data.email,
          raw_user_meta_data: {
            full_name: data.full_name,
            role: data.role
          }
        })
        .eq('id', id);

      if (error) throw error;
      toast.success('Usuário atualizado com sucesso!');
      get().fetchUsers();
    } catch (error: any) {
      console.error('Error updating user:', error);
      set({ error: error.message });
      toast.error('Erro ao atualizar usuário');
    } finally {
      set({ loading: false });
    }
  },

  deleteUser: async (id: string) => {
    try {
      set({ loading: true, error: null });
      
      const { error } = await supabase
        .from('users')
        .delete()
        .eq('id', id);

      if (error) throw error;
      toast.success('Usuário excluído com sucesso!');
      get().fetchUsers();
    } catch (error: any) {
      console.error('Error deleting user:', error);
      set({ error: error.message });
      toast.error('Erro ao excluir usuário');
    } finally {
      set({ loading: false });
    }
  }
}));