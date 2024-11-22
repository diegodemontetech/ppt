import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Plus, Edit, Trash2, Video } from 'lucide-react';
import { supabase } from '../../../lib/supabase';
import { VideoUploader } from '../../../components/admin/VideoUploader';
import { ImageUploader } from '../../../components/admin/ImageUploader';
import { uploadVideo, uploadImage } from '../../../lib/storage';
import toast from 'react-hot-toast';

export default function LiveRecordingsSettings() {
  const [recordings, setRecordings] = useState([]);
  const [liveEvents, setLiveEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    live_event_id: '',
    video_url: '',
    thumbnail_url: '',
    duration: 0
  });
  const [isEditing, setIsEditing] = useState(false);
  const [selectedRecording, setSelectedRecording] = useState(null);

  useEffect(() => {
    fetchRecordings();
    fetchLiveEvents();
  }, []);

  const fetchRecordings = async () => {
    try {
      const { data, error } = await supabase.rpc('get_live_recordings');

      if (error) throw error;
      setRecordings(data || []);
    } catch (error) {
      console.error('Error fetching recordings:', error);
      toast.error('Erro ao carregar gravações');
    } finally {
      setLoading(false);
    }
  };

  const fetchLiveEvents = async () => {
    try {
      const { data, error } = await supabase
        .from('live_events')
        .select('*')
        .order('starts_at', { ascending: false });

      if (error) throw error;
      setLiveEvents(data || []);
    } catch (error) {
      console.error('Error fetching live events:', error);
      toast.error('Erro ao carregar eventos');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
      setLoading(true);

      if (isEditing && selectedRecording) {
        const { error } = await supabase
          .from('live_recordings')
          .update(formData)
          .eq('id', selectedRecording.id);

        if (error) throw error;
        toast.success('Gravação atualizada com sucesso!');
      } else {
        const { error } = await supabase
          .from('live_recordings')
          .insert([formData]);

        if (error) throw error;
        toast.success('Gravação adicionada com sucesso!');
      }

      setFormData({
        title: '',
        description: '',
        live_event_id: '',
        video_url: '',
        thumbnail_url: '',
        duration: 0
      });
      setIsEditing(false);
      setSelectedRecording(null);
      fetchRecordings();
    } catch (error) {
      console.error('Error saving recording:', error);
      toast.error('Erro ao salvar gravação');
    } finally {
      setLoading(false);
    }
  };

  const handleVideoUpload = async (file) => {
    try {
      setLoading(true);
      const videoUrl = await uploadVideo(file);
      setFormData(prev => ({ ...prev, video_url: videoUrl }));
      toast.success('Vídeo enviado com sucesso!');
    } catch (error) {
      console.error('Error uploading video:', error);
      toast.error('Erro ao enviar vídeo');
    } finally {
      setLoading(false);
    }
  };

  const handleImageUpload = async (file) => {
    try {
      setLoading(true);
      const thumbnailUrl = await uploadImage(file);
      setFormData(prev => ({ ...prev, thumbnail_url: thumbnailUrl }));
      toast.success('Thumbnail enviada com sucesso!');
    } catch (error) {
      console.error('Error uploading image:', error);
      toast.error('Erro ao enviar thumbnail');
    } finally {
      setLoading(false);
    }
  };

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            Gerenciar Gravações
          </h1>
          <button
            onClick={() => {
              setFormData({
                title: '',
                description: '',
                live_event_id: '',
                video_url: '',
                thumbnail_url: '',
                duration: 0
              });
              setIsEditing(false);
              setSelectedRecording(null);
            }}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
          >
            <Plus className="w-4 h-4 mr-2" />
            Nova Gravação
          </button>
        </div>

        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <label htmlFor="live_event" className="block text-sm font-medium text-gray-700">
                  Aula ao Vivo
                </label>
                <select
                  id="live_event"
                  value={formData.live_event_id}
                  onChange={(e) => setFormData({ ...formData, live_event_id: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                >
                  <option value="">Selecione uma aula</option>
                  {liveEvents.map(event => (
                    <option key={event.id} value={event.id}>
                      {event.title} ({new Date(event.starts_at).toLocaleDateString()})
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label htmlFor="title" className="block text-sm font-medium text-gray-700">
                  Título da Gravação
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

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Vídeo da Gravação
                </label>
                <VideoUploader onUpload={handleVideoUpload} />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Thumbnail
                </label>
                <ImageUploader onUpload={handleImageUpload} />
              </div>

              <div>
                <label htmlFor="duration" className="block text-sm font-medium text-gray-700">
                  Duração (minutos)
                </label>
                <input
                  type="number"
                  id="duration"
                  value={formData.duration}
                  onChange={(e) => setFormData({ ...formData, duration: parseInt(e.target.value) * 60 })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                  min="1"
                />
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setFormData({
                      title: '',
                      description: '',
                      live_event_id: '',
                      video_url: '',
                      thumbnail_url: '',
                      duration: 0
                    });
                    setIsEditing(false);
                    setSelectedRecording(null);
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
                  {loading ? 'Salvando...' : isEditing ? 'Atualizar' : 'Criar Gravação'}
                </button>
              </div>
            </form>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">
              Gravações Cadastradas
            </h2>

            <div className="space-y-4">
              {recordings.map((recording) => (
                <div
                  key={recording.id}
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                >
                  <div>
                    <h3 className="text-sm font-medium text-gray-900">
                      {recording.title}
                    </h3>
                    <p className="text-sm text-gray-500 mt-1">
                      {recording.description}
                    </p>
                    <div className="mt-2 text-xs text-gray-500">
                      Aula: {recording.event_title} ({new Date(recording.event_date).toLocaleDateString()})
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => {
                        setSelectedRecording(recording);
                        setFormData({
                          title: recording.title,
                          description: recording.description,
                          live_event_id: recording.live_event_id,
                          video_url: recording.video_url,
                          thumbnail_url: recording.thumbnail_url,
                          duration: recording.duration
                        });
                        setIsEditing(true);
                      }}
                      className="p-2 text-gray-400 hover:text-gray-500"
                    >
                      <Edit className="w-5 h-5" />
                    </button>
                    <button
                      onClick={async () => {
                        if (window.confirm('Tem certeza que deseja excluir esta gravação?')) {
                          try {
                            const { error } = await supabase
                              .from('live_recordings')
                              .delete()
                              .eq('id', recording.id);

                            if (error) throw error;
                            toast.success('Gravação excluída com sucesso!');
                            fetchRecordings();
                          } catch (error) {
                            console.error('Error deleting recording:', error);
                            toast.error('Erro ao excluir gravação');
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