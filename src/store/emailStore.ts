import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { EmailConfiguration, EmailTemplate, EmailLog } from '../types/email';
import toast from 'react-hot-toast';

interface EmailState {
  configurations: EmailConfiguration[];
  templates: EmailTemplate[];
  logs: EmailLog[];
  loading: boolean;
  error: string | null;
  fetchConfigurations: () => Promise<void>;
  fetchTemplates: () => Promise<void>;
  fetchLogs: () => Promise<void>;
  createConfiguration: (data: Partial<EmailConfiguration>) => Promise<void>;
  updateConfiguration: (id: string, data: Partial<EmailConfiguration>) => Promise<void>;
  createTemplate: (data: Partial<EmailTemplate>) => Promise<void>;
  updateTemplate: (id: string, data: Partial<EmailTemplate>) => Promise<void>;
  deleteTemplate: (id: string) => Promise<void>;
  sendTestEmail: (templateId: string, toEmail: string, variables?: Record<string, any>) => Promise<void>;
}

export const useEmailStore = create<EmailState>((set, get) => ({
  configurations: [],
  templates: [],
  logs: [],
  loading: false,
  error: null,

  fetchConfigurations: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('email_configurations')
        .select('*')
        .order('purpose');

      if (error) throw error;
      set({ configurations: data || [] });
    } catch (error) {
      console.error('Error fetching email configurations:', error);
      set({ error: 'Failed to fetch configurations' });
      toast.error('Erro ao carregar configurações de email');
    } finally {
      set({ loading: false });
    }
  },

  fetchTemplates: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('email_templates')
        .select('*')
        .order('name');

      if (error) throw error;
      set({ templates: data || [] });
    } catch (error) {
      console.error('Error fetching email templates:', error);
      set({ error: 'Failed to fetch templates' });
      toast.error('Erro ao carregar templates de email');
    } finally {
      set({ loading: false });
    }
  },

  fetchLogs: async () => {
    try {
      set({ loading: true, error: null });
      const { data, error } = await supabase
        .from('email_logs')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100);

      if (error) throw error;
      set({ logs: data || [] });
    } catch (error) {
      console.error('Error fetching email logs:', error);
      set({ error: 'Failed to fetch logs' });
      toast.error('Erro ao carregar logs de email');
    } finally {
      set({ loading: false });
    }
  },

  createConfiguration: async (data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('email_configurations')
        .insert([data]);

      if (error) throw error;
      toast.success('Configuração criada com sucesso!');
      get().fetchConfigurations();
    } catch (error) {
      console.error('Error creating configuration:', error);
      set({ error: 'Failed to create configuration' });
      toast.error('Erro ao criar configuração');
    } finally {
      set({ loading: false });
    }
  },

  updateConfiguration: async (id, data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('email_configurations')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      toast.success('Configuração atualizada com sucesso!');
      get().fetchConfigurations();
    } catch (error) {
      console.error('Error updating configuration:', error);
      set({ error: 'Failed to update configuration' });
      toast.error('Erro ao atualizar configuração');
    } finally {
      set({ loading: false });
    }
  },

  createTemplate: async (data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('email_templates')
        .insert([data]);

      if (error) throw error;
      toast.success('Template criado com sucesso!');
      get().fetchTemplates();
    } catch (error) {
      console.error('Error creating template:', error);
      set({ error: 'Failed to create template' });
      toast.error('Erro ao criar template');
    } finally {
      set({ loading: false });
    }
  },

  updateTemplate: async (id, data) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('email_templates')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      toast.success('Template atualizado com sucesso!');
      get().fetchTemplates();
    } catch (error) {
      console.error('Error updating template:', error);
      set({ error: 'Failed to update template' });
      toast.error('Erro ao atualizar template');
    } finally {
      set({ loading: false });
    }
  },

  deleteTemplate: async (id) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase
        .from('email_templates')
        .delete()
        .eq('id', id);

      if (error) throw error;
      toast.success('Template excluído com sucesso!');
      get().fetchTemplates();
    } catch (error) {
      console.error('Error deleting template:', error);
      set({ error: 'Failed to delete template' });
      toast.error('Erro ao excluir template');
    } finally {
      set({ loading: false });
    }
  },

  sendTestEmail: async (templateId: string, toEmail: string, variables?: Record<string, any>) => {
    try {
      set({ loading: true, error: null });
      const { error } = await supabase.rpc('send_email', {
        template_id: templateId,
        to_email: toEmail,
        variables: variables || {}
      });

      if (error) throw error;
      toast.success('Email de teste enviado com sucesso!');
    } catch (error) {
      console.error('Error sending test email:', error);
      set({ error: 'Failed to send test email' });
      toast.error('Erro ao enviar email de teste');
    } finally {
      set({ loading: false });
    }
  }
}));