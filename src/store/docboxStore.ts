import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { DocCategory, Document } from '../types/docbox';
import toast from 'react-hot-toast';

interface DocBoxState {
  categories: DocCategory[];
  documents: Document[];
  loading: boolean;
  error: string | null;
  filters: {
    search: string;
    category: string[];
    fileType: string[];
  };
  fetchCategories: () => Promise<void>;
  fetchDocuments: () => Promise<void>;
  createDocument: (data: Partial<Document>) => Promise<void>;
  updateDocument: (id: string, data: Partial<Document>) => Promise<void>;
  deleteDocument: (id: string) => Promise<void>;
  downloadDocument: (document: Document) => Promise<void>;
  setFilters: (filters: Partial<DocBoxState['filters']>) => void;
}

export const useDocBoxStore = create<DocBoxState>((set, get) => ({
  categories: [],
  documents: [],
  loading: false,
  error: null,
  filters: {
    search: '',
    category: [],
    fileType: []
  },

  fetchCategories: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('doc_categories')
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

  fetchDocuments: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('documents')
        .select(`
          *,
          category:doc_categories(
            id,
            name,
            parent_id
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      set({ documents: data || [] });
    } catch (error) {
      console.error('Error fetching documents:', error);
      set({ error: 'Failed to fetch documents' });
      toast.error('Erro ao carregar documentos');
    } finally {
      set({ loading: false });
    }
  },

  createDocument: async (data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('documents')
        .insert([data]);

      if (error) throw error;
      toast.success('Documento criado com sucesso!');
      get().fetchDocuments();
    } catch (error) {
      console.error('Error creating document:', error);
      set({ error: 'Failed to create document' });
      toast.error('Erro ao criar documento');
    } finally {
      set({ loading: false });
    }
  },

  updateDocument: async (id, data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('documents')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      toast.success('Documento atualizado com sucesso!');
      get().fetchDocuments();
    } catch (error) {
      console.error('Error updating document:', error);
      set({ error: 'Failed to update document' });
      toast.error('Erro ao atualizar documento');
    } finally {
      set({ loading: false });
    }
  },

  deleteDocument: async (id) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('documents')
        .delete()
        .eq('id', id);

      if (error) throw error;
      toast.success('Documento excluído com sucesso!');
      get().fetchDocuments();
    } catch (error) {
      console.error('Error deleting document:', error);
      set({ error: 'Failed to delete document' });
      toast.error('Erro ao excluir documento');
    } finally {
      set({ loading: false });
    }
  },

  downloadDocument: async (document) => {
    try {
      // Download file
      const response = await fetch(document.file_url);
      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = document.title;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);

      // Log download
      const { error } = await supabase
        .from('document_downloads')
        .insert([{ document_id: document.id }]);

      if (error) throw error;
      toast.success('Download iniciado!');
    } catch (error) {
      console.error('Error downloading document:', error);
      toast.error('Erro ao baixar documento');
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