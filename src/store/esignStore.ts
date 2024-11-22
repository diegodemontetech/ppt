import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { 
  Contract, 
  ContractSignatory, 
  ContractHistory, 
  ContractComment 
} from '../types/esign';
import toast from 'react-hot-toast';

interface ESignState {
  contracts: Contract[];
  signatories: ContractSignatory[];
  history: ContractHistory[];
  comments: ContractComment[];
  loading: boolean;
  error: string | null;
  fetchContracts: () => Promise<void>;
  createContract: (data: Partial<Contract>) => Promise<void>;
  updateContract: (id: string, data: Partial<Contract>) => Promise<void>;
  deleteContract: (id: string) => Promise<void>;
  addSignatory: (contractId: string, data: Partial<ContractSignatory>) => Promise<void>;
  removeSignatory: (id: string) => Promise<void>;
  addComment: (contractId: string, content: string) => Promise<void>;
}

export const useESignStore = create<ESignState>((set, get) => ({
  contracts: [],
  signatories: [],
  history: [],
  comments: [],
  loading: false,
  error: null,

  fetchContracts: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('contracts')
        .select(`
          *,
          signatories:contract_signatories(*)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      set({ contracts: data || [] });
    } catch (error) {
      console.error('Error fetching contracts:', error);
      set({ error: 'Failed to fetch contracts' });
      toast.error('Erro ao carregar contratos');
    } finally {
      set({ loading: false });
    }
  },

  createContract: async (data: Partial<Contract>) => {
    try {
      set({ loading: true, error: null });

      // Get current user
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      // Create contract with user as creator
      const { error } = await supabase
        .from('contracts')
        .insert([{
          ...data,
          created_by: user.id
        }]);

      if (error) throw error;
      toast.success('Contrato criado com sucesso!');
      get().fetchContracts();
    } catch (error) {
      console.error('Error creating contract:', error);
      set({ error: 'Failed to create contract' });
      toast.error('Erro ao criar contrato');
    } finally {
      set({ loading: false });
    }
  },

  updateContract: async (id: string, data: Partial<Contract>) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('contracts')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      toast.success('Contrato atualizado com sucesso!');
      get().fetchContracts();
    } catch (error) {
      console.error('Error updating contract:', error);
      set({ error: 'Failed to update contract' });
      toast.error('Erro ao atualizar contrato');
    } finally {
      set({ loading: false });
    }
  },

  deleteContract: async (id: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('contracts')
        .delete()
        .eq('id', id);

      if (error) throw error;
      toast.success('Contrato excluído com sucesso!');
      get().fetchContracts();
    } catch (error) {
      console.error('Error deleting contract:', error);
      set({ error: 'Failed to delete contract' });
      toast.error('Erro ao excluir contrato');
    } finally {
      set({ loading: false });
    }
  },

  addSignatory: async (contractId: string, data: Partial<ContractSignatory>) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('contract_signatories')
        .insert([{
          ...data,
          contract_id: contractId
        }]);

      if (error) throw error;
      toast.success('Signatário adicionado com sucesso!');
      get().fetchContracts();
    } catch (error) {
      console.error('Error adding signatory:', error);
      set({ error: 'Failed to add signatory' });
      toast.error('Erro ao adicionar signatário');
    } finally {
      set({ loading: false });
    }
  },

  removeSignatory: async (id: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('contract_signatories')
        .delete()
        .eq('id', id);

      if (error) throw error;
      toast.success('Signatário removido com sucesso!');
      get().fetchContracts();
    } catch (error) {
      console.error('Error removing signatory:', error);
      set({ error: 'Failed to remove signatory' });
      toast.error('Erro ao remover signatário');
    } finally {
      set({ loading: false });
    }
  },

  addComment: async (contractId: string, content: string) => {
    try {
      set({ loading: true, error: null });

      // Get current user
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      const { error } = await supabase
        .from('contract_comments')
        .insert([{
          contract_id: contractId,
          user_id: user.id,
          content
        }]);

      if (error) throw error;
      toast.success('Comentário adicionado com sucesso!');
      get().fetchContracts();
    } catch (error) {
      console.error('Error adding comment:', error);
      set({ error: 'Failed to add comment' });
      toast.error('Erro ao adicionar comentário');
    } finally {
      set({ loading: false });
    }
  }
}));