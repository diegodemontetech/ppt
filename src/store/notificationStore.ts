import { create } from 'zustand';
import { supabase, handleSupabaseError } from '../lib/supabase';
import toast from 'react-hot-toast';

interface Notification {
  id: string;
  title: string;
  message: string;
  read: boolean;
  created_at: string;
}

interface NotificationState {
  notifications: Notification[];
  unreadCount: number;
  loading: boolean;
  fetchNotifications: () => Promise<void>;
  markAsRead: (id: string) => Promise<void>;
  markAllAsRead: () => Promise<void>;
}

export const useNotifications = create<NotificationState>((set, get) => ({
  notifications: [],
  unreadCount: 0,
  loading: false,

  fetchNotifications: async () => {
    try {
      set({ loading: true });
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data, error } = await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (error) throw error;

      const unreadCount = data.filter(n => !n.read).length;
      set({ notifications: data, unreadCount });
    } catch (error) {
      handleSupabaseError(error);
    } finally {
      set({ loading: false });
    }
  },

  markAsRead: async (id: string) => {
    try {
      const { error } = await supabase
        .from('notifications')
        .update({ read: true })
        .eq('id', id);

      if (error) throw error;

      const { notifications } = get();
      const updatedNotifications = notifications.map(n =>
        n.id === id ? { ...n, read: true } : n
      );

      set({
        notifications: updatedNotifications,
        unreadCount: updatedNotifications.filter(n => !n.read).length
      });
    } catch (error) {
      handleSupabaseError(error);
    }
  },

  markAllAsRead: async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { error } = await supabase
        .from('notifications')
        .update({ read: true })
        .eq('user_id', user.id);

      if (error) throw error;

      const { notifications } = get();
      const updatedNotifications = notifications.map(n => ({ ...n, read: true }));

      set({ notifications: updatedNotifications, unreadCount: 0 });
      toast.success('Todas as notificações foram marcadas como lidas');
    } catch (error) {
      handleSupabaseError(error);
    }
  }
}));