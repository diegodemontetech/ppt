import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { 
  SupportDepartment, 
  SupportReason, 
  SupportTicket,
  SupportTicketComment,
  SupportTicketAttachment,
  SupportTicketHistory 
} from '../types/support';
import toast from 'react-hot-toast';

interface SupportState {
  departments: SupportDepartment[];
  reasons: SupportReason[];
  tickets: SupportTicket[];
  loading: boolean;
  error: string | null;
  fetchDepartments: () => Promise<void>;
  fetchReasons: (departmentId: string) => Promise<void>;
  fetchTickets: () => Promise<void>;
  createTicket: (data: Partial<SupportTicket>) => Promise<void>;
  updateTicket: (id: string, data: Partial<SupportTicket>) => Promise<void>;
  deleteTicket: (id: string, reason: string) => Promise<void>;
  addComment: (ticketId: string, content: string) => Promise<void>;
  addAttachment: (ticketId: string, file: File) => Promise<void>;
  getTicketHistory: (ticketId: string) => Promise<SupportTicketHistory[]>;
}

export const useSupportStore = create<SupportState>((set, get) => ({
  departments: [],
  reasons: [],
  tickets: [],
  loading: false,
  error: null,

  fetchDepartments: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('support_departments')
        .select('*')
        .order('name');

      if (error) throw error;
      set({ departments: data || [] });
    } catch (error) {
      console.error('Error fetching departments:', error);
      set({ error: 'Failed to fetch departments' });
      toast.error('Erro ao carregar departamentos');
    } finally {
      set({ loading: false });
    }
  },

  fetchReasons: async (departmentId: string) => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('support_reasons')
        .select('*')
        .eq('department_id', departmentId)
        .order('name');

      if (error) throw error;
      set({ reasons: data || [] });
    } catch (error) {
      console.error('Error fetching reasons:', error);
      set({ error: 'Failed to fetch reasons' });
      toast.error('Erro ao carregar motivos');
    } finally {
      set({ loading: false });
    }
  },

  fetchTickets: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('support_tickets')
        .select(`
          *,
          department:support_departments(name),
          reason:support_reasons(name),
          creator:created_by(
            email,
            raw_user_meta_data->full_name
          ),
          assignee:assigned_to(
            email,
            raw_user_meta_data->full_name
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      set({ tickets: data || [] });
    } catch (error) {
      console.error('Error fetching tickets:', error);
      set({ error: 'Failed to fetch tickets' });
      toast.error('Erro ao carregar tickets');
    } finally {
      set({ loading: false });
    }
  },

  createTicket: async (data: Partial<SupportTicket>) => {
    try {
      set({ loading: true, error: null });
      
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      const { error } = await supabase
        .from('support_tickets')
        .insert([{
          ...data,
          created_by: user.id
        }]);

      if (error) throw error;
      toast.success('Ticket criado com sucesso!');
      get().fetchTickets();
    } catch (error) {
      console.error('Error creating ticket:', error);
      set({ error: 'Failed to create ticket' });
      toast.error('Erro ao criar ticket');
    } finally {
      set({ loading: false });
    }
  },

  updateTicket: async (id: string, data: Partial<SupportTicket>) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('support_tickets')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      toast.success('Ticket atualizado com sucesso!');
      get().fetchTickets();
    } catch (error) {
      console.error('Error updating ticket:', error);
      set({ error: 'Failed to update ticket' });
      toast.error('Erro ao atualizar ticket');
    } finally {
      set({ loading: false });
    }
  },

  deleteTicket: async (id: string, reason: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('support_tickets')
        .update({ 
          status: 'deleted',
          deletion_reason: reason 
        })
        .eq('id', id);

      if (error) throw error;
      toast.success('Ticket excluído com sucesso!');
      get().fetchTickets();
    } catch (error) {
      console.error('Error deleting ticket:', error);
      set({ error: 'Failed to delete ticket' });
      toast.error('Erro ao excluir ticket');
    } finally {
      set({ loading: false });
    }
  },

  addComment: async (ticketId: string, content: string) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('support_ticket_comments')
        .insert([{
          ticket_id: ticketId,
          content
        }]);

      if (error) throw error;
      toast.success('Comentário adicionado com sucesso!');
    } catch (error) {
      console.error('Error adding comment:', error);
      set({ error: 'Failed to add comment' });
      toast.error('Erro ao adicionar comentário');
    } finally {
      set({ loading: false });
    }
  },

  addAttachment: async (ticketId: string, file: File) => {
    try {
      set({ loading: true, error: null });

      // Upload file to storage
      const fileExt = file.name.split('.').pop();
      const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
      
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('support-attachments')
        .upload(fileName, file);

      if (uploadError) throw uploadError;

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('support-attachments')
        .getPublicUrl(fileName);

      // Create database entry
      const { error: dbError } = await supabase
        .from('support_ticket_attachments')
        .insert([{
          ticket_id: ticketId,
          file_url: publicUrl,
          file_name: file.name,
          file_type: file.type,
          file_size: file.size
        }]);

      if (dbError) throw dbError;
      toast.success('Arquivo anexado com sucesso!');
    } catch (error) {
      console.error('Error adding attachment:', error);
      set({ error: 'Failed to add attachment' });
      toast.error('Erro ao anexar arquivo');
    } finally {
      set({ loading: false });
    }
  },

  getTicketHistory: async (ticketId: string) => {
    try {
      const { data, error } = await supabase
        .from('support_ticket_history')
        .select(`
          *,
          user:user_id(
            email,
            raw_user_meta_data->full_name
          )
        `)
        .eq('ticket_id', ticketId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching ticket history:', error);
      toast.error('Erro ao carregar histórico do ticket');
      return [];
    }
  }
}));