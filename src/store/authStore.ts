import { create } from 'zustand';
import { supabase, handleSupabaseError } from '../lib/supabase';
import type { User } from '@supabase/supabase-js';
import toast from 'react-hot-toast';

interface AuthState {
  user: User | null;
  isAdmin: boolean;
  isMasterAdmin: boolean;
  loading: boolean;
  error: string | null;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, role?: string) => Promise<void>;
  signOut: () => Promise<void>;
  checkAuth: () => Promise<void>;
  clearError: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isAdmin: false,
  isMasterAdmin: false,
  loading: true,
  error: null,

  signIn: async (email: string, password: string) => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      
      if (error) throw error;

      const isAdmin = data.user?.user_metadata?.role === 'admin';
      const isMasterAdmin = data.user?.user_metadata?.role === 'master_admin';
      set({ user: data.user, isAdmin, isMasterAdmin });
      toast.success('Login realizado com sucesso!');
    } catch (error) {
      handleSupabaseError(error);
      throw error;
    } finally {
      set({ loading: false });
    }
  },

  signUp: async (email: string, password: string, role = 'user') => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { 
            role,
            full_name: email.split('@')[0],
            points: 0,
            level: 1
          }
        }
      });
      
      if (error) throw error;
      
      const isAdmin = data.user?.user_metadata?.role === 'admin';
      const isMasterAdmin = data.user?.user_metadata?.role === 'master_admin';
      set({ user: data.user, isAdmin, isMasterAdmin });
      toast.success('Cadastro realizado com sucesso!');
    } catch (error) {
      handleSupabaseError(error);
      throw error;
    } finally {
      set({ loading: false });
    }
  },

  signOut: async () => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      set({ user: null, isAdmin: false, isMasterAdmin: false });
      window.location.href = '/login';
    } catch (error) {
      handleSupabaseError(error);
      throw error;
    } finally {
      set({ loading: false });
    }
  },

  checkAuth: async () => {
    try {
      set({ loading: true, error: null });
      const { data: { session } } = await supabase.auth.getSession();
      
      if (session?.user) {
        const isAdmin = session.user.user_metadata?.role === 'admin';
        const isMasterAdmin = session.user.user_metadata?.role === 'master_admin';
        set({ user: session.user, isAdmin, isMasterAdmin });
      }

      supabase.auth.onAuthStateChange((_event, session) => {
        const isAdmin = session?.user?.user_metadata?.role === 'admin';
        const isMasterAdmin = session?.user?.user_metadata?.role === 'master_admin';
        set({ 
          user: session?.user || null, 
          isAdmin: isAdmin || false,
          isMasterAdmin: isMasterAdmin || false
        });
      });
    } catch (error) {
      handleSupabaseError(error);
      console.error('Error checking auth:', error);
    } finally {
      set({ loading: false });
    }
  },

  clearError: () => set({ error: null })
}));