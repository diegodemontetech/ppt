import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { Category } from '../types';

interface CategoryState {
  categories: Category[];
  loading: boolean;
  error: string | null;
  fetchCategories: () => Promise<void>;
  createCategory: (name: string, description: string) => Promise<void>;
  updateCategory: (id: string, name: string, description: string) => Promise<void>;
  deleteCategory: (id: string) => Promise<void>;
}

export const useCategoryStore = create<CategoryState>((set, get) => ({
  categories: [],
  loading: false,
  error: null,

  fetchCategories: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('categories')
        .select('*')
        .order('name');

      if (error) throw error;
      set({ categories: data });
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  },

  createCategory: async (name: string, description: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('categories')
        .insert([{ name, description }]);

      if (error) throw error;
      get().fetchCategories();
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  },

  updateCategory: async (id: string, name: string, description: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('categories')
        .update({ name, description })
        .eq('id', id);

      if (error) throw error;
      get().fetchCategories();
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  },

  deleteCategory: async (id: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('categories')
        .delete()
        .eq('id', id);

      if (error) throw error;
      get().fetchCategories();
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ loading: false });
    }
  }
}));