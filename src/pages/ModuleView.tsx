import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Layout } from '../components/Layout';
import VideoPlayer from '../components/VideoPlayer';
import { Book, Play, Users, Star, Clock } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { formatDuration } from '../utils/format';
import { useQuery } from '../hooks/useQuery';
import toast from 'react-hot-toast';

export default function ModuleView() {
  const { moduleId } = useParams();
  const navigate = useNavigate();

  const { data: module, isLoading, error } = useQuery(
    ['module', moduleId],
    async () => {
      const { data, error } = await supabase
        .from('modules')
        .select(`
          *,
          category:categories(
            id,
            name,
            department:departments(
              id,
              name
            )
          ),
          lessons(
            id,
            title,
            duration,
            order_num,
            lesson_progress(
              completed,
              score,
              user_id
            ),
            quizzes(*)
          )
        `)
        .eq('id', moduleId)
        .single();

      if (error) throw error;

      // Get module statistics
      const { data: stats, error: statsError } = await supabase
        .rpc('get_module_stats', { module_uuid: moduleId });

      if (statsError) throw statsError;

      // Sort lessons by order_num
      const sortedLessons = data.lessons?.sort((a: any, b: any) => a.order_num - b.order_num);

      // Calculate total duration (doubled to account for exercises)
      const totalDuration = sortedLessons?.reduce((acc: number, lesson: any) => {
        return acc + (lesson.duration || 0) * 2;
      }, 0) || 0;

      return {
        ...data,
        lessons: sortedLessons,
        total_duration: totalDuration,
        enrolled_count: stats?.[0]?.enrolled_count || 0,
        average_rating: stats?.[0]?.average_rating || 0,
        total_ratings: stats?.[0]?.total_ratings || 0
      };
    }
  );

  const handleStartModule = () => {
    if (module?.lessons?.length > 0) {
      navigate(`/course/${moduleId}`);
    } else {
      toast.error('Este módulo ainda não possui aulas');
    }
  };

  if (isLoading) {
    return (
      <Layout title="Carregando...">
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
        </div>
      </Layout>
    );
  }

  if (error || !module) {
    return (
      <Layout title="Módulo não encontrado">
        <div className="text-center py-12">
          <p className="text-gray-500">O módulo solicitado não foi encontrado.</p>
          <button
            onClick={() => navigate('/')}
            className="mt-4 inline-flex items-center text-blue-600 hover:text-blue-700"
          >
            <Book className="w-4 h-4 mr-2" />
            Voltar para Módulos
          </button>
        </div>
      </Layout>
    );
  }

  return (
    <Layout title={module.title}>
      <div className="max-w-4xl mx-auto">
        <div className="bg-white rounded-lg shadow-lg overflow-hidden">
          {module.video_url ? (
            <div className="aspect-w-16 aspect-h-9">
              <VideoPlayer 
                videoUrl={module.video_url} 
                title={module.title}
                onError={() => toast.error('Erro ao carregar vídeo de apresentação')}
              />
            </div>
          ) : (
            <div className="aspect-w-16 aspect-h-9 bg-gray-100 flex items-center justify-center">
              <Play className="w-16 h-16 text-gray-400" />
            </div>
          )}

          <div className="p-8">
            <div className="flex items-start justify-between">
              <div>
                <h1 className="text-3xl font-bold text-gray-900">{module.title}</h1>
                {module.category && (
                  <p className="mt-2 text-sm text-gray-500">
                    {module.category.department.name} &gt; {module.category.name}
                  </p>
                )}
              </div>
              <button
                onClick={handleStartModule}
                className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
              >
                <Play className="w-5 h-5 mr-2" />
                Iniciar Módulo
              </button>
            </div>

            <div className="mt-6 prose prose-blue max-w-none">
              <p>{module.description}</p>
            </div>

            <div className="mt-8 grid grid-cols-4 gap-6">
              <div className="flex items-center">
                <Book className="w-5 h-5 text-gray-400 mr-2" />
                <span className="text-sm text-gray-600">
                  {module.lessons?.length || 0} aulas
                </span>
              </div>
              <div className="flex items-center">
                <Users className="w-5 h-5 text-gray-400 mr-2" />
                <span className="text-sm text-gray-600">
                  {module.enrolled_count || 0} alunos
                </span>
              </div>
              <div className="flex items-center">
                <Star className="w-5 h-5 text-gray-400 mr-2" />
                <span className="text-sm text-gray-600">
                  {module.average_rating?.toFixed(1) || '0.0'} ({module.total_ratings || 0} avaliações)
                </span>
              </div>
              <div className="flex items-center">
                <Clock className="w-5 h-5 text-gray-400 mr-2" />
                <span className="text-sm text-gray-600">
                  {formatDuration(module.total_duration)}
                </span>
              </div>
            </div>

            {module.lessons?.length > 0 && (
              <div className="mt-8">
                <h2 className="text-xl font-semibold text-gray-900 mb-4">Conteúdo do Módulo</h2>
                <div className="space-y-4">
                  {module.lessons.map((lesson: any, index: number) => (
                    <div
                      key={lesson.id}
                      className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                    >
                      <div className="flex items-center">
                        <span className="w-8 text-center text-gray-500">{index + 1}</span>
                        <div className="ml-4">
                          <h3 className="text-sm font-medium text-gray-900">{lesson.title}</h3>
                          {lesson.duration && (
                            <p className="text-sm text-gray-500">
                              {formatDuration(lesson.duration * 2)} {/* Double duration for exercises */}
                            </p>
                          )}
                        </div>
                      </div>
                      <div className="flex items-center space-x-2">
                        {lesson.quizzes?.length > 0 && (
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                            Quiz
                          </span>
                        )}
                        {lesson.lesson_progress?.[0]?.completed && (
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                            Concluída
                          </span>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </Layout>
  );
}