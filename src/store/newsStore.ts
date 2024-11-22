import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { NewsArticle, NewsCategory } from '../types/news';
import toast from 'react-hot-toast';

interface NewsState {
  articles: NewsArticle[];
  categories: NewsCategory[];
  loading: boolean;
  error: string | null;
  fetchArticles: () => Promise<void>;
  fetchCategories: () => Promise<void>;
  createArticle: (data: Partial<NewsArticle>) => Promise<void>;
  updateArticle: (id: string, data: Partial<NewsArticle>) => Promise<void>;
  deleteArticle: (id: string) => Promise<void>;
  createCategory: (data: Partial<NewsCategory>) => Promise<void>;
  updateCategory: (id: string, data: Partial<NewsCategory>) => Promise<void>;
  deleteCategory: (id: string) => Promise<void>;
}

export const useNewsStore = create<NewsState>((set, get) => ({
  articles: [],
  categories: [],
  loading: false,
  error: null,

  fetchArticles: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('news_articles')
        .select('*')
        .order('published_at', { ascending: false });

      if (error) throw error;
      set({ articles: data || [] });
    } catch (error) {
      console.error('Error fetching articles:', error);
      set({ error: 'Failed to fetch articles' });
      toast.error('Erro ao carregar notícias');
    } finally {
      set({ loading: false });
    }
  },

  fetchCategories: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('news_categories')
        .select('*')
        .order('name');

      if (error) throw error;
      set({ categories: data || [] });
    } catch (error) {
      console.error('Error fetching categories:', error);
      set({ error: 'Failed to fetch categories' });
      toast.error('Erro ao carregar categorias');
    } finally {
      set({ loading: false });
    }
  },

  createArticle: async (data: Partial<NewsArticle>) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('news_articles')
        .insert([data]);

      if (error) throw error;
      toast.success('Notícia criada com sucesso!');
      get().fetchArticles();
    } catch (error) {
      console.error('Error creating article:', error);
      set({ error: 'Failed to create article' });
      toast.error('Erro ao criar notícia');
    } finally {
      set({ loading: false });
    }
  },

  updateArticle: async (id: string, data: Partial<NewsArticle>) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('news_articles')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      toast.success('Notícia atualizada com sucesso!');
      get().fetchArticles();
    } catch (error) {
      console.error('Error updating article:', error);
      set({ error: 'Failed to update article' });
      toast.error('Erro ao atualizar notícia');
    } finally {
      set({ loading: false });
    }
  },

  deleteArticle: async (id: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('news_articles')
        .delete()
        .eq('id', id);

      if (error) throw error;
      toast.success('Notícia excluída com sucesso!');
      get().fetchArticles();
    } catch (error) {
      console.error('Error deleting article:', error);
      set({ error: 'Failed to delete article' });
      toast.error('Erro ao excluir notícia');
    } finally {
      set({ loading: false });
    }
  },

  createCategory: async (data: Partial<NewsCategory>) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('news_categories')
        .insert([data]);

      if (error) throw error;
      toast.success('Categoria criada com sucesso!');
      get().fetchCategories();
    } catch (error) {
      console.error('Error creating category:', error);
      set({ error: 'Failed to create category' });
      toast.error('Erro ao criar categoria');
    } finally {
      set({ loading: false });
    }
  },

  updateCategory: async (id: string, data: Partial<NewsCategory>) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('news_categories')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      toast.success('Categoria atualizada com sucesso!');
      get().fetchCategories();
    } catch (error) {
      console.error('Error updating category:', error);
      set({ error: 'Failed to update category' });
      toast.error('Erro ao atualizar categoria');
    } finally {
      set({ loading: false });
    }
  },

  deleteCategory: async (id: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('news_categories')
        .delete()
        .eq('id', id);

      if (error) throw error;
      toast.success('Categoria excluída com sucesso!');
      get().fetchCategories();
    } catch (error) {
      console.error('Error deleting category:', error);
      set({ error: 'Failed to delete category' });
      toast.error('Erro ao excluir categoria');
    } finally {
      set({ loading: false });
    }
  }
}));