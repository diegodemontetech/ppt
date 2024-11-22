import React, { useEffect, useState } from 'react';
import { Layout } from '../components/Layout';
import { Play, Calendar, Clock, User } from 'lucide-react';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import VideoPlayer from '../components/VideoPlayer';

export default function LiveRecordingsPage() {
  const [recordings, setRecordings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedRecording, setSelectedRecording] = useState(null);

  useEffect(() => {
    fetchRecordings();
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

  return (
    <Layout title="Gravações de Aulas">
      {loading ? (
        <div className="flex justify-center items-center h-64">
          <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
        </div>
      ) : recordings.length === 0 ? (
        <div className="text-center py-12">
          <Play className="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900">Nenhuma gravação disponível</h3>
          <p className="mt-2 text-sm text-gray-500">
            As gravações das aulas ao vivo aparecerão aqui após o término das transmissões.
          </p>
        </div>
      ) : (
        <div className="space-y-6">
          {selectedRecording ? (
            <div className="bg-white rounded-lg shadow-sm overflow-hidden">
              <div className="aspect-w-16 aspect-h-9">
                <VideoPlayer videoUrl={selectedRecording.video_url} />
              </div>
              <div className="p-6">
                <h2 className="text-xl font-semibold text-gray-900">{selectedRecording.title}</h2>
                <p className="mt-2 text-gray-600">{selectedRecording.description}</p>
                <div className="mt-4 flex flex-wrap gap-4 text-sm text-gray-500">
                  <div className="flex items-center">
                    <Calendar className="w-4 h-4 mr-2" />
                    {format(new Date(selectedRecording.event_date), "dd 'de' MMMM 'de' yyyy", { locale: ptBR })}
                  </div>
                  <div className="flex items-center">
                    <Clock className="w-4 h-4 mr-2" />
                    {Math.floor(selectedRecording.duration / 60)} minutos
                  </div>
                  <div className="flex items-center">
                    <User className="w-4 h-4 mr-2" />
                    {selectedRecording.instructor_name}
                  </div>
                </div>
                <button
                  onClick={() => setSelectedRecording(null)}
                  className="mt-4 text-blue-600 hover:text-blue-700 font-medium"
                >
                  Voltar para lista
                </button>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {recordings.map((recording) => (
                <div
                  key={recording.id}
                  className="bg-white rounded-lg shadow-sm overflow-hidden hover:shadow-md transition-shadow cursor-pointer"
                  onClick={() => setSelectedRecording(recording)}
                >
                  <div className="aspect-w-16 aspect-h-9 bg-gray-100">
                    {recording.thumbnail_url ? (
                      <img
                        src={recording.thumbnail_url}
                        alt={recording.title}
                        className="object-cover"
                      />
                    ) : (
                      <div className="flex items-center justify-center">
                        <Play className="w-12 h-12 text-gray-400" />
                      </div>
                    )}
                  </div>
                  <div className="p-4">
                    <h3 className="font-medium text-gray-900">{recording.title}</h3>
                    <p className="mt-1 text-sm text-gray-500 line-clamp-2">
                      {recording.description}
                    </p>
                    <div className="mt-4 flex flex-wrap gap-2 text-xs text-gray-500">
                      <div className="flex items-center">
                        <Calendar className="w-3 h-3 mr-1" />
                        {format(new Date(recording.event_date), "dd/MM/yyyy", { locale: ptBR })}
                      </div>
                      <div className="flex items-center">
                        <Clock className="w-3 h-3 mr-1" />
                        {Math.floor(recording.duration / 60)} min
                      </div>
                      <div className="flex items-center">
                        <User className="w-3 h-3 mr-1" />
                        {recording.instructor_name}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </Layout>
  );
}