import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { MarketingBoxItem, MarketingBoxCategory } from '../types/marketingBox';
import JSZip from 'jszip';
import toast from 'react-hot-toast';

interface MarketingBoxState {
  items: MarketingBoxItem[];
  categories: MarketingBoxCategory[];
  loading: boolean;
  error: string | null;
  filters: {
    fileType: string[];
    mediaType: string[];
    resolution: string[];
    category: string[];
    search: string;
  };
  fetchItems: () => Promise<void>;
  fetchCategories: () => Promise<void>;
  createItem: (data: Partial<MarketingBoxItem>) => Promise<void>;
  updateItem: (id: string, data: Partial<MarketingBoxItem>) => Promise<void>;
  deleteItem: (id: string) => Promise<void>;
  downloadItems: (items: MarketingBoxItem[]) => Promise<void>;
  setFilters: (filters: Partial<MarketingBoxState['filters']>) => void;
}

export const useMarketingBoxStore = create<MarketingBoxState>((set, get) => ({
  items: [],
  categories: [],
  loading: false,
  error: null,
  filters: {
    fileType: [],
    mediaType: [],
    resolution: [],
    category: [],
    search: ''
  },

  fetchItems: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('marketing_box_items')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      set({ items: data || [] });
    } catch (error) {
      console.error('Error fetching marketing box items:', error);
      set({ error: 'Failed to fetch items' });
      toast.error('Erro ao carregar itens');
    } finally {
      set({ loading: false });
    }
  },

  fetchCategories: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('marketing_box_categories')
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

  createItem: async (data: Partial<MarketingBoxItem>) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('marketing_box_items')
        .insert([data]);

      if (error) throw error;
      toast.success('Item criado com sucesso!');
      get().fetchItems();
    } catch (error) {
      console.error('Error creating item:', error);
      set({ error: 'Failed to create item' });
      toast.error('Erro ao criar item');
    } finally {
      set({ loading: false });
    }
  },

  updateItem: async (id: string, data: Partial<MarketingBoxItem>) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('marketing_box_items')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      toast.success('Item atualizado com sucesso!');
      get().fetchItems();
    } catch (error) {
      console.error('Error updating item:', error);
      set({ error: 'Failed to update item' });
      toast.error('Erro ao atualizar item');
    } finally {
      set({ loading: false });
    }
  },

  deleteItem: async (id: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('marketing_box_items')
        .delete()
        .eq('id', id);

      if (error) throw error;
      toast.success('Item excluído com sucesso!');
      get().fetchItems();
    } catch (error) {
      console.error('Error deleting item:', error);
      set({ error: 'Failed to delete item' });
      toast.error('Erro ao excluir item');
    } finally {
      set({ loading: false });
    }
  },

  downloadItems: async (items: MarketingBoxItem[]) => {
    try {
      set({ loading: true, error: null });
      
      const zip = new JSZip();
      
      // Download each file and add to zip
      for (const item of items) {
        const response = await fetch(item.file_url);
        const blob = await response.blob();
        const fileName = item.file_url.split('/').pop() || 'file';
        zip.file(fileName, blob);
      }
      
      // Generate and download zip
      const content = await zip.generateAsync({ type: 'blob' });
      const url = window.URL.createObjectURL(content);
      const link = document.createElement('a');
      link.href = url;
      link.download = 'marketing-box-files.zip';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);

      // Log downloads
      await Promise.all(items.map(item => 
        supabase
          .from('marketing_box_downloads')
          .insert([{ item_id: item.id }])
      ));

      toast.success('Download iniciado!');
    } catch (error) {
      console.error('Error downloading items:', error);
      set({ error: 'Failed to download items' });
      toast.error('Erro ao baixar arquivos');
    } finally {
      set({ loading: false });
    }
  },

  setFilters: (filters) => {
    set(state => ({
      filters: {
        ...state.filters,
        ...filters
      }
    }));
  }
}));