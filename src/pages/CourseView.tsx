import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Layout } from '../components/Layout';
import VideoPlayer from '../components/VideoPlayer';
import { FileText } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { updateLessonProgress } from '../lib/db';
import QuizSection from '../components/QuizSection';
import toast from 'react-hot-toast';

export default function CourseView() {
  const { moduleId } = useParams();
  const navigate = useNavigate();
  const [module, setModule] = useState<any>(null);
  const [currentLesson, setCurrentLesson] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [videoCompleted, setVideoCompleted] = useState(false);
  const [showQuiz, setShowQuiz] = useState(false);

  useEffect(() => {
    if (moduleId) {
      fetchData();
    }
  }, [moduleId]);

  const fetchData = async () => {
    try {
      setLoading(true);

      // Get module details with quiz
      const { data: moduleData, error: moduleError } = await supabase
        .from('modules')
        .select(`
          *,
          quiz:quizzes(*),
          lessons(
            *,
            lesson_progress(completed, score, user_id),
            attachments:lesson_attachments(*)
          )
        `)
        .eq('id', moduleId)
        .single();

      if (moduleError) throw moduleError;

      // Sort lessons by order_num
      if (moduleData.lessons) {
        moduleData.lessons.sort((a: any, b: any) => a.order_num - b.order_num);
      }

      setModule(moduleData);

      // Get user's auth status
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      // Set first lesson as current if not showing quiz
      if (moduleData.lessons?.length > 0) {
        const firstLesson = moduleData.lessons[0];
        setCurrentLesson(firstLesson);
        
        // Check if lesson is already completed
        const isCompleted = firstLesson.lesson_progress?.some(
          (p: any) => p.user_id === user.id && p.completed
        );
        setVideoCompleted(isCompleted);
      }
    } catch (error) {
      console.error('Error fetching data:', error);
      toast.error('Erro ao carregar dados');
    } finally {
      setLoading(false);
    }
  };

  const handleLessonClick = async (lesson: any) => {
    setCurrentLesson(lesson);
    setShowQuiz(false);
    
    // Check if lesson is already completed
    const { data: { user } } = await supabase.auth.getUser();
    const isCompleted = lesson.lesson_progress?.some(
      (p: any) => p.user_id === user?.id && p.completed
    );
    setVideoCompleted(isCompleted);
  };

  const handleVideoComplete = async () => {
    if (!videoCompleted && currentLesson) {
      try {
        await updateLessonProgress(currentLesson.id, true);
        setVideoCompleted(true);
        fetchData(); // Refresh data to check if all lessons are completed
      } catch (error) {
        console.error('Error updating lesson progress:', error);
        toast.error('Erro ao atualizar progresso');
      }
    }
  };

  const handleQuizComplete = async (score: number) => {
    try {
      // Get last lesson to mark quiz completion
      const lastLesson = module.lessons[module.lessons.length - 1];
      await updateLessonProgress(lastLesson.id, true, score);
      toast.success('Quiz concluído com sucesso!');
      fetchData();
    } catch (error) {
      console.error('Error updating quiz progress:', error);
      toast.error('Erro ao salvar resultado do quiz');
    }
  };

  if (loading) {
    return (
      <Layout title="Carregando...">
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
        </div>
      </Layout>
    );
  }

  if (!module) {
    return (
      <Layout title="Erro">
        <div className="text-center py-12">
          <p className="text-red-500">Módulo não encontrado</p>
        </div>
      </Layout>
    );
  }

  return (
    <Layout title={module.title}>
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-3 space-y-6">
          {showQuiz && module.quiz?.[0] ? (
            <div className="bg-white rounded-lg shadow-sm p-6">
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Quiz do Módulo
              </h3>
              <QuizSection
                quiz={module.quiz[0]}
                onComplete={handleQuizComplete}
              />
            </div>
          ) : currentLesson && (
            <>
              <div className="bg-white rounded-lg shadow-sm overflow-hidden">
                <VideoPlayer 
                  videoUrl={currentLesson.video_url}
                  onComplete={handleVideoComplete}
                />
              </div>

              <div className="bg-white rounded-lg shadow-sm p-6">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h2 className="text-lg font-medium text-gray-900">
                      {currentLesson.title}
                    </h2>
                    <div 
                      className="mt-2 text-sm text-gray-600 prose max-w-none"
                      dangerouslySetInnerHTML={{ __html: currentLesson.description }}
                    />
                  </div>
                </div>

                {currentLesson.attachments?.length > 0 && (
                  <div className="mt-6 border-t pt-6">
                    <h3 className="text-sm font-medium text-gray-900 mb-4">
                      Arquivos Anexos
                    </h3>
                    <div className="space-y-3">
                      {currentLesson.attachments.map((attachment: any) => (
                        <a
                          key={attachment.id}
                          href={attachment.file_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex items-center p-3 text-sm text-gray-600 bg-gray-50 rounded-lg hover:bg-gray-100"
                        >
                          <FileText className="w-5 h-5 text-gray-400 mr-3" />
                          <span>{attachment.title}</span>
                        </a>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </>
          )}
        </div>

        {/* Sidebar */}
        <div className="bg-white rounded-lg shadow-sm p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">
            Conteúdo do Módulo
          </h3>
          <div className="space-y-2">
            {module.lessons?.map((lesson: any) => {
              const isCompleted = lesson.lesson_progress?.some((p: any) => p.completed);
              const isActive = currentLesson?.id === lesson.id;

              return (
                <button
                  key={lesson.id}
                  onClick={() => handleLessonClick(lesson)}
                  className={`w-full text-left p-3 rounded-lg transition-colors ${
                    isActive
                      ? 'bg-blue-50 text-blue-700'
                      : isCompleted
                      ? 'bg-green-50 text-green-700'
                      : 'hover:bg-gray-50'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium">
                      {lesson.order_num}. {lesson.title}
                    </span>
                    {isCompleted && (
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        Concluída
                      </span>
                    )}
                  </div>
                </button>
              );
            })}

            {/* Quiz button - always show as last item */}
            {module.quiz?.[0] && (
              <button
                onClick={() => setShowQuiz(true)}
                className={`w-full text-left p-3 rounded-lg transition-colors ${
                  showQuiz
                    ? 'bg-blue-50 text-blue-700'
                    : 'hover:bg-gray-50'
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium">
                    ★ Quiz do Módulo
                  </span>
                </div>
              </button>
            )}
          </div>
        </div>
      </div>
    </Layout>
  );
}