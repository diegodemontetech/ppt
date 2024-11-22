import React, { useEffect, useState } from 'react';
import { Layout } from '../components/Layout';
import { LiveClass } from '../components/LiveClass';
import { Calendar } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useModuleStore } from '../store/moduleStore';
import toast from 'react-hot-toast';

export default function LiveClassesPage() {
  const [liveClasses, setLiveClasses] = useState([]);
  const [loading, setLoading] = useState(true);
  const { isSubscribed, subscribeToModule } = useModuleStore();

  useEffect(() => {
    fetchLiveClasses();
  }, []);

  const fetchLiveClasses = async () => {
    try {
      const { data, error } = await supabase.rpc('get_next_live_event');

      if (error) throw error;
      setLiveClasses(data || []);
    } catch (error) {
      console.error('Error fetching live classes:', error);
      toast.error('Erro ao carregar aulas ao vivo');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Layout title="Aulas ao Vivo">
      <div className="max-w-4xl mx-auto">
        {loading ? (
          <div className="flex justify-center items-center h-64">
            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
          </div>
        ) : liveClasses.length === 0 ? (
          <div className="text-center py-12">
            <Calendar className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900">Nenhuma aula ao vivo agendada</h3>
            <p className="mt-2 text-sm text-gray-500">
              Fique de olho nas notificações para saber quando novas aulas forem agendadas.
            </p>
          </div>
        ) : (
          <div className="space-y-6">
            {liveClasses.map((liveClass) => (
              <LiveClass
                key={liveClass.id}
                {...liveClass}
                isSubscribed={isSubscribed(liveClass.id)}
                onSubscribe={() => subscribeToModule(liveClass.id)}
              />
            ))}
          </div>
        )}
      </div>
    </Layout>
  );
}