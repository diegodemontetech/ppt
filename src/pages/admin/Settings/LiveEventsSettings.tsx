import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Plus, Edit, Trash2, Video } from 'lucide-react';
import { supabase } from '../../../lib/supabase';
import toast from 'react-hot-toast';

export default function LiveEventsSettings() {
  const [events, setEvents] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    instructor_id: '',
    meeting_url: '',
    starts_at: '',
    duration: 60
  });
  const [isEditing, setIsEditing] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState(null);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);

      // Get live events
      const { data: eventsData, error: eventsError } = await supabase
        .from('live_events')
        .select(`
          *,
          instructor:instructor_id (
            id,
            email,
            raw_user_meta_data->full_name
          )
        `)
        .order('starts_at', { ascending: true });

      if (eventsError) throw eventsError;
      setEvents(eventsData || []);

      // Get users for instructor selection
      const { data: usersData, error: usersError } = await supabase
        .from('user_profiles')
        .select('*')
        .order('full_name');

      if (usersError) throw usersError;
      setUsers(usersData || []);
    } catch (error) {
      console.error('Error fetching data:', error);
      toast.error('Erro ao carregar dados');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setLoading(true);

      if (isEditing && selectedEvent) {
        const { error } = await supabase
          .from('live_events')
          .update(formData)
          .eq('id', selectedEvent.id);

        if (error) throw error;
        toast.success('Evento atualizado com sucesso!');
      } else {
        const { error } = await supabase
          .from('live_events')
          .insert([formData]);

        if (error) throw error;
        toast.success('Evento criado com sucesso!');
      }

      setFormData({
        title: '',
        description: '',
        instructor_id: '',
        meeting_url: '',
        starts_at: '',
        duration: 60
      });
      setIsEditing(false);
      setSelectedEvent(null);
      fetchData();
    } catch (error) {
      console.error('Error saving event:', error);
      toast.error('Erro ao salvar evento');
    } finally {
      setLoading(false);
    }
  };

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            Transmissões ao Vivo
          </h1>
        </div>

        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <label htmlFor="title" className="block text-sm font-medium text-gray-700">
                    Título
                  </label>
                  <input
                    type="text"
                    id="title"
                    value={formData.title}
                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    required
                  />
                </div>

                <div>
                  <label htmlFor="instructor" className="block text-sm font-medium text-gray-700">
                    Instrutor
                  </label>
                  <select
                    id="instructor"
                    value={formData.instructor_id}
                    onChange={(e) => setFormData({ ...formData, instructor_id: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    required
                  >
                    <option value="">Selecione um instrutor</option>
                    {users.map((user: any) => (
                      <option key={user.id} value={user.id}>
                        {user.full_name || user.email}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label htmlFor="description" className="block text-sm font-medium text-gray-700">
                  Descrição
                </label>
                <textarea
                  id="description"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  rows={3}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-6">
                <div>
                  <label htmlFor="starts_at" className="block text-sm font-medium text-gray-700">
                    Data e Hora
                  </label>
                  <input
                    type="datetime-local"
                    id="starts_at"
                    value={formData.starts_at}
                    onChange={(e) => setFormData({ ...formData, starts_at: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    required
                  />
                </div>

                <div>
                  <label htmlFor="duration" className="block text-sm font-medium text-gray-700">
                    Duração (minutos)
                  </label>
                  <input
                    type="number"
                    id="duration"
                    value={formData.duration}
                    onChange={(e) => setFormData({ ...formData, duration: parseInt(e.target.value) })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    required
                    min="15"
                    step="15"
                  />
                </div>
              </div>

              <div>
                <label htmlFor="meeting_url" className="block text-sm font-medium text-gray-700">
                  URL da Reunião
                </label>
                <input
                  type="url"
                  id="meeting_url"
                  value={formData.meeting_url}
                  onChange={(e) => setFormData({ ...formData, meeting_url: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                  placeholder="https://meet.google.com/..."
                />
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setFormData({
                      title: '',
                      description: '',
                      instructor_id: '',
                      meeting_url: '',
                      starts_at: '',
                      duration: 60
                    });
                    setIsEditing(false);
                    setSelectedEvent(null);
                  }}
                  className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  {loading ? 'Salvando...' : isEditing ? 'Atualizar' : 'Criar Evento'}
                </button>
              </div>
            </form>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">
              Eventos Agendados
            </h2>

            <div className="space-y-4">
              {events.map((event: any) => (
                <div
                  key={event.id}
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                >
                  <div>
                    <h3 className="text-sm font-medium text-gray-900">
                      {event.title}
                    </h3>
                    <p className="text-sm text-gray-500 mt-1">
                      {event.description}
                    </p>
                    <div className="mt-2 flex items-center text-sm text-gray-500">
                      <Video className="w-4 h-4 mr-1" />
                      {event.instructor?.raw_user_meta_data?.full_name || event.instructor?.email}
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => {
                        setSelectedEvent(event);
                        setFormData({
                          title: event.title,
                          description: event.description || '',
                          instructor_id: event.instructor_id,
                          meeting_url: event.meeting_url,
                          starts_at: event.starts_at,
                          duration: event.duration
                        });
                        setIsEditing(true);
                      }}
                      className="p-2 text-gray-400 hover:text-gray-500"
                    >
                      <Edit className="w-5 h-5" />
                    </button>
                    <button
                      onClick={async () => {
                        if (window.confirm('Tem certeza que deseja excluir este evento?')) {
                          try {
                            const { error } = await supabase
                              .from('live_events')
                              .delete()
                              .eq('id', event.id);

                            if (error) throw error;
                            toast.success('Evento excluído com sucesso!');
                            fetchData();
                          } catch (error) {
                            console.error('Error deleting event:', error);
                            toast.error('Erro ao excluir evento');
                          }
                        }
                      }}
                      className="p-2 text-gray-400 hover:text-red-500"
                    >
                      <Trash2 className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </SettingsLayout>
  );
}