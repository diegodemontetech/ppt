import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { 
  Pipeline, 
  PipelineStage, 
  PipelineField, 
  PipelineCard,
  PipelineCardHistory,
  PipelineCardComment,
  PipelineAutomation,
  PipelineStats 
} from '../types/pipeline';
import toast from 'react-hot-toast';

interface PipelineState {
  pipelines: Pipeline[];
  stages: PipelineStage[];
  fields: PipelineField[];
  cards: PipelineCard[];
  history: PipelineCardHistory[];
  comments: PipelineCardComment[];
  automations: PipelineAutomation[];
  stats: PipelineStats | null;
  loading: boolean;
  error: string | null;
  fetchPipelines: () => Promise<void>;
  fetchStages: (pipelineId: string) => Promise<void>;
  fetchFields: (pipelineId: string) => Promise<void>;
  fetchCards: (pipelineId: string) => Promise<void>;
  fetchHistory: (cardId: string) => Promise<void>;
  fetchComments: (cardId: string) => Promise<void>;
  fetchAutomations: (pipelineId: string) => Promise<void>;
  fetchStats: (pipelineId: string) => Promise<void>;
  createPipeline: (data: Partial<Pipeline>) => Promise<void>;
  updatePipeline: (id: string, data: Partial<Pipeline>) => Promise<void>;
  deletePipeline: (id: string) => Promise<void>;
  createStage: (data: Partial<PipelineStage>) => Promise<void>;
  updateStage: (id: string, data: Partial<PipelineStage>) => Promise<void>;
  deleteStage: (id: string) => Promise<void>;
  createField: (data: Partial<PipelineField>) => Promise<void>;
  updateField: (id: string, data: Partial<PipelineField>) => Promise<void>;
  deleteField: (id: string) => Promise<void>;
  createCard: (data: Partial<PipelineCard>) => Promise<void>;
  updateCard: (id: string, data: Partial<PipelineCard>) => Promise<void>;
  deleteCard: (id: string) => Promise<void>;
  moveCard: (cardId: string, stageId: string, newOrder: number) => Promise<void>;
  addComment: (cardId: string, content: string, attachments?: File[]) => Promise<void>;
  createAutomation: (data: Partial<PipelineAutomation>) => Promise<void>;
  updateAutomation: (id: string, data: Partial<PipelineAutomation>) => Promise<void>;
  deleteAutomation: (id: string) => Promise<void>;
}

export const usePipelineStore = create<PipelineState>((set, get) => ({
  pipelines: [],
  stages: [],
  fields: [],
  cards: [],
  history: [],
  comments: [],
  automations: [],
  stats: null,
  loading: false,
  error: null,

  fetchPipelines: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('pipelines')
        .select(`
          *,
          department:departments(
            id,
            name
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      set({ pipelines: data || [] });
    } catch (error) {
      console.error('Error fetching pipelines:', error);
      set({ error: 'Failed to fetch pipelines' });
      toast.error('Erro ao carregar pipelines');
    } finally {
      set({ loading: false });
    }
  },

  fetchStages: async (pipelineId) => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('pipeline_stages')
        .select('*')
        .eq('pipeline_id', pipelineId)
        .order('order_num');

      if (error) throw error;
      set({ stages: data || [] });
    } catch (error) {
      console.error('Error fetching stages:', error);
      set({ error: 'Failed to fetch stages' });
      toast.error('Erro ao carregar etapas');
    } finally {
      set({ loading: false });
    }
  },

  fetchFields: async (pipelineId) => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('pipeline_fields')
        .select('*')
        .eq('pipeline_id', pipelineId)
        .order('order_num');

      if (error) throw error;
      set({ fields: data || [] });
    } catch (error) {
      console.error('Error fetching fields:', error);
      set({ error: 'Failed to fetch fields' });
      toast.error('Erro ao carregar campos');
    } finally {
      set({ loading: false });
    }
  },

  fetchCards: async (pipelineId) => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('pipeline_cards')
        .select(`
          *,
          created_by:created_by(
            id,
            email,
            raw_user_meta_data->full_name
          )
        `)
        .eq('pipeline_id', pipelineId)
        .order('order_num');

      if (error) throw error;
      set({ cards: data || [] });
    } catch (error) {
      console.error('Error fetching cards:', error);
      set({ error: 'Failed to fetch cards' });
      toast.error('Erro ao carregar cards');
    } finally {
      set({ loading: false });
    }
  },

  fetchHistory: async (cardId) => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('pipeline_card_history')
        .select(`
          *,
          user:user_id(
            id,
            email,
            raw_user_meta_data->full_name
          )
        `)
        .eq('card_id', cardId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      set({ history: data || [] });
    } catch (error) {
      console.error('Error fetching history:', error);
      set({ error: 'Failed to fetch history' });
      toast.error('Erro ao carregar histórico');
    } finally {
      set({ loading: false });
    }
  },

  fetchComments: async (cardId) => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('pipeline_card_comments')
        .select(`
          *,
          user:user_id(
            id,
            email,
            raw_user_meta_data->full_name
          )
        `)
        .eq('card_id', cardId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      set({ comments: data || [] });
    } catch (error) {
      console.error('Error fetching comments:', error);
      set({ error: 'Failed to fetch comments' });
      toast.error('Erro ao carregar comentários');
    } finally {
      set({ loading: false });
    }
  },

  fetchAutomations: async (pipelineId) => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('pipeline_automations')
        .select('*')
        .eq('pipeline_id', pipelineId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      set({ automations: data || [] });
    } catch (error) {
      console.error('Error fetching automations:', error);
      set({ error: 'Failed to fetch automations' });
      toast.error('Erro ao carregar automações');
    } finally {
      set({ loading: false });
    }
  },

  fetchStats: async (pipelineId) => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase.rpc(
        'get_pipeline_stats',
        { pipeline_uuid: pipelineId }
      );

      if (error) throw error;
      set({ stats: data });
    } catch (error) {
      console.error('Error fetching stats:', error);
      set({ error: 'Failed to fetch stats' });
      toast.error('Erro ao carregar estatísticas');
    } finally {
      set({ loading: false });
    }
  },

  createPipeline: async (data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipelines')
        .insert([data]);

      if (error) throw error;
      toast.success('Pipeline criado com sucesso!');
      get().fetchPipelines();
    } catch (error) {
      console.error('Error creating pipeline:', error);
      set({ error: 'Failed to create pipeline' });
      toast.error('Erro ao criar pipeline');
    } finally {
      set({ loading: false });
    }
  },

  updatePipeline: async (id, data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipelines')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      toast.success('Pipeline atualizado com sucesso!');
      get().fetchPipelines();
    } catch (error) {
      console.error('Error updating pipeline:', error);
      set({ error: 'Failed to update pipeline' });
      toast.error('Erro ao atualizar pipeline');
    } finally {
      set({ loading: false });
    }
  },

  deletePipeline: async (id) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipelines')
        .delete()
        .eq('id', id);

      if (error) throw error;
      toast.success('Pipeline excluído com sucesso!');
      get().fetchPipelines();
    } catch (error) {
      console.error('Error deleting pipeline:', error);
      set({ error: 'Failed to delete pipeline' });
      toast.error('Erro ao excluir pipeline');
    } finally {
      set({ loading: false });
    }
  },

  createStage: async (data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipeline_stages')
        .insert([data]);

      if (error) throw error;
      toast.success('Etapa criada com sucesso!');
      get().fetchStages(data.pipeline_id);
    } catch (error) {
      console.error('Error creating stage:', error);
      set({ error: 'Failed to create stage' });
      toast.error('Erro ao criar etapa');
    } finally {
      set({ loading: false });
    }
  },

  updateStage: async (id, data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipeline_stages')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      toast.success('Etapa atualizada com sucesso!');
      get().fetchStages(data.pipeline_id);
    } catch (error) {
      console.error('Error updating stage:', error);
      set({ error: 'Failed to update stage' });
      toast.error('Erro ao atualizar etapa');
    } finally {
      set({ loading: false });
    }
  },

  deleteStage: async (id) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipeline_stages')
        .delete()
        .eq('id', id);

      if (error) throw error;
      toast.success('Etapa excluída com sucesso!');
      get().fetchStages(id);
    } catch (error) {
      console.error('Error deleting stage:', error);
      set({ error: 'Failed to delete stage' });
      toast.error('Erro ao excluir etapa');
    } finally {
      set({ loading: false });
    }
  },

  createField: async (data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipeline_fields')
        .insert([data]);

      if (error) throw error;
      toast.success('Campo criado com sucesso!');
      get().fetchFields(data.pipeline_id);
    } catch (error) {
      console.error('Error creating field:', error);
      set({ error: 'Failed to create field' });
      toast.error('Erro ao criar campo');
    } finally {
      set({ loading: false });
    }
  },

  updateField: async (id, data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipeline_fields')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      toast.success('Campo atualizado com sucesso!');
      get().fetchFields(data.pipeline_id);
    } catch (error) {
      console.error('Error updating field:', error);
      set({ error: 'Failed to update field' });
      toast.error('Erro ao atualizar campo');
    } finally {
      set({ loading: false });
    }
  },

  deleteField: async (id) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipeline_fields')
        .delete()
        .eq('id', id);

      if (error) throw error;
      toast.success('Campo excluído com sucesso!');
      get().fetchFields(id);
    } catch (error) {
      console.error('Error deleting field:', error);
      set({ error: 'Failed to delete field' });
      toast.error('Erro ao excluir campo');
    } finally {
      set({ loading: false });
    }
  },

  createCard: async (data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipeline_cards')
        .insert([{
          ...data,
          created_by: (await supabase.auth.getUser()).data.user?.id
        }]);

      if (error) throw error;
      toast.success('Card criado com sucesso!');
      get().fetchCards(data.pipeline_id);
    } catch (error) {
      console.error('Error creating card:', error);
      set({ error: 'Failed to create card' });
      toast.error('Erro ao criar card');
    } finally {
      set({ loading: false });
    }
  },

  updateCard: async (id, data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipeline_cards')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      toast.success('Card atualizado com sucesso!');
      get().fetchCards(data.pipeline_id);
    } catch (error) {
      console.error('Error updating card:', error);
      set({ error: 'Failed to update card' });
      toast.error('Erro ao atualizar card');
    } finally {
      set({ loading: false });
    }
  },

  deleteCard: async (id) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipeline_cards')
        .delete()
        .eq('id', id);

      if (error) throw error;
      toast.success('Card excluído com sucesso!');
      get().fetchCards(id);
    } catch (error) {
      console.error('Error deleting card:', error);
      set({ error: 'Failed to delete card' });
      toast.error('Erro ao excluir card');
    } finally {
      set({ loading: false });
    }
  },

  moveCard: async (cardId, stageId, newOrder) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase.rpc(
        'move_pipeline_card',
        {
          card_uuid: cardId,
          new_stage_uuid: stageId,
          new_order: newOrder
        }
      );

      if (error) throw error;
      
      const card = get().cards.find(c => c.id === cardId);
      if (card) {
        get().fetchCards(card.pipeline_id);
      }
    } catch (error) {
      console.error('Error moving card:', error);
      set({ error: 'Failed to move card' });
      toast.error('Erro ao mover card');
    } finally {
      set({ loading: false });
    }
  },

  addComment: async (cardId, content, attachments = []) => {
    try {
      set({ loading: true, error: null });

      // First upload any attachments
      const uploadedAttachments = [];
      for (const file of attachments) {
        const fileExt = file.name.split('.').pop();
        const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
        
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('attachments')
          .upload(fileName, file);

        if (uploadError) throw uploadError;

        const { data: { publicUrl } } = supabase.storage
          .from('attachments')
          .getPublicUrl(fileName);

        uploadedAttachments.push({
          name: file.name,
          url: publicUrl,
          type: file.type
        });
      }

      // Then create the comment
      const { error } = await supabase
        .from('pipeline_card_comments')
        .insert([{
          card_id: cardId,
          content,
          attachments: uploadedAttachments
        }]);

      if (error) throw error;
      toast.success('Comentário adicionado com sucesso!');
      get().fetchComments(cardId);
    } catch (error) {
      console.error('Error adding comment:', error);
      set({ error: 'Failed to add comment' });
      toast.error('Erro ao adicionar comentário');
    } finally {
      set({ loading: false });
    }
  },

  createAutomation: async (data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipeline_automations')
        .insert([data]);

      if (error) throw error;
      toast.success('Automação criada com sucesso!');
      get().fetchAutomations(data.pipeline_id);
    } catch (error) {
      console.error('Error creating automation:', error);
      set({ error: 'Failed to create automation' });
      toast.error('Erro ao criar automação');
    } finally {
      set({ loading: false });
    }
  },

  updateAutomation: async (id, data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipeline_automations')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      toast.success('Automação atualizada com sucesso!');
      get().fetchAutomations(data.pipeline_id);
    } catch (error) {
      console.error('Error updating automation:', error);
      set({ error: 'Failed to update automation' });
      toast.error('Erro ao atualizar automação');
    } finally {
      set({ loading: false });
    }
  },

  deleteAutomation: async (id) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('pipeline_automations')
        .delete()
        .eq('id', id);

      if (error) throw error;
      toast.success('Automação excluída com sucesso!');
      get().fetchAutomations(id);
    } catch (error) {
      console.error('Error deleting automation:', error);
      set({ error: 'Failed to delete automation' });
      toast.error('Erro ao excluir automação');
    } finally {
      set({ loading: false });
    }
  }
}));