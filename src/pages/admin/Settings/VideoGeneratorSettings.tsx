import React, { useState } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Wand2, Loader2 } from 'lucide-react';
import { generateCourseContent, generateVideo, generateImage } from '../../../lib/ai';
import { supabase } from '../../../lib/supabase';
import toast from 'react-hot-toast';

interface GenerationOptions {
  generateTitle: boolean;
  generateDescription: boolean;
  generateThumbnail: boolean;
  generateDemoVideo: boolean;
  generateLessons: boolean;
  addWatermark: boolean;
  addCaptions: boolean;
}

export default function VideoGeneratorSettings() {
  const [topic, setTopic] = useState('');
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [options, setOptions] = useState<GenerationOptions>({
    generateTitle: true,
    generateDescription: true,
    generateThumbnail: true,
    generateDemoVideo: true,
    generateLessons: true,
    addWatermark: true,
    addCaptions: true
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setLoading(true);
      setProgress(0);

      // Generate course content
      const content = await generateCourseContent(topic);
      setProgress(20);

      // Generate thumbnail if needed
      let thumbnailUrl = '';
      if (options.generateThumbnail) {
        thumbnailUrl = await generateImage(`Course thumbnail for ${content.title}`);
        setProgress(40);
      }

      // Generate demo video if needed
      let demoVideoUrl = '';
      if (options.generateDemoVideo) {
        demoVideoUrl = await generateVideo(content.description, 45);
        setProgress(60);
      }

      // Create course in database
      const { data: course, error: courseError } = await supabase
        .from('modules')
        .insert({
          title: content.title,
          description: content.description,
          thumbnail_url: thumbnailUrl,
          video_url: demoVideoUrl,
          is_featured: true
        })
        .select()
        .single();

      if (courseError) throw courseError;
      setProgress(80);

      // Generate lessons if needed
      if (options.generateLessons) {
        for (const lesson of content.lessons) {
          const videoUrl = await generateVideo(lesson.description);
          
          const { error: lessonError } = await supabase
            .from('lessons')
            .insert({
              module_id: course.id,
              title: lesson.title,
              description: lesson.description,
              video_url: videoUrl,
              order_num: content.lessons.indexOf(lesson) + 1
            });

          if (lessonError) throw lessonError;
        }
      }

      setProgress(100);
      toast.success('Curso gerado com sucesso!');
    } catch (error) {
      console.error('Error generating course:', error);
      toast.error('Erro ao gerar curso');
    } finally {
      setLoading(false);
    }
  };

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            Magic Learning
          </h1>
        </div>

        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <label htmlFor="topic" className="block text-sm font-medium text-gray-700">
                  Tema do Curso
                </label>
                <input
                  type="text"
                  id="topic"
                  value={topic}
                  onChange={(e) => setTopic(e.target.value)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
                  placeholder="Ex: JavaScript para iniciantes"
                  required
                />
              </div>

              <div className="space-y-4">
                <h3 className="text-sm font-medium text-gray-700">Opções de Geração</h3>
                
                <div className="grid grid-cols-2 gap-4">
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={options.generateTitle}
                      onChange={(e) => setOptions({ ...options, generateTitle: e.target.checked })}
                      className="rounded border-gray-300 text-red-600 focus:ring-red-500"
                    />
                    <span className="ml-2 text-sm text-gray-600">Gerar título</span>
                  </label>

                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={options.generateDescription}
                      onChange={(e) => setOptions({ ...options, generateDescription: e.target.checked })}
                      className="rounded border-gray-300 text-red-600 focus:ring-red-500"
                    />
                    <span className="ml-2 text-sm text-gray-600">Gerar descrição</span>
                  </label>

                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={options.generateThumbnail}
                      onChange={(e) => setOptions({ ...options, generateThumbnail: e.target.checked })}
                      className="rounded border-gray-300 text-red-600 focus:ring-red-500"
                    />
                    <span className="ml-2 text-sm text-gray-600">Gerar thumbnail</span>
                  </label>

                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={options.generateDemoVideo}
                      onChange={(e) => setOptions({ ...options, generateDemoVideo: e.target.checked })}
                      className="rounded border-gray-300 text-red-600 focus:ring-red-500"
                    />
                    <span className="ml-2 text-sm text-gray-600">Gerar vídeo demo</span>
                  </label>

                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={options.generateLessons}
                      onChange={(e) => setOptions({ ...options, generateLessons: e.target.checked })}
                      className="rounded border-gray-300 text-red-600 focus:ring-red-500"
                    />
                    <span className="ml-2 text-sm text-gray-600">Gerar aulas</span>
                  </label>

                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={options.addWatermark}
                      onChange={(e) => setOptions({ ...options, addWatermark: e.target.checked })}
                      className="rounded border-gray-300 text-red-600 focus:ring-red-500"
                    />
                    <span className="ml-2 text-sm text-gray-600">Adicionar marca d'água</span>
                  </label>

                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={options.addCaptions}
                      onChange={(e) => setOptions({ ...options, addCaptions: e.target.checked })}
                      className="rounded border-gray-300 text-red-600 focus:ring-red-500"
                    />
                    <span className="ml-2 text-sm text-gray-600">Adicionar legendas</span>
                  </label>
                </div>
              </div>

              {loading && (
                <div className="mt-4">
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-red-600 h-2 rounded-full transition-all duration-500"
                      style={{ width: `${progress}%` }}
                    />
                  </div>
                  <p className="mt-2 text-sm text-gray-500 text-center">
                    Gerando curso... {progress}%
                  </p>
                </div>
              )}

              <div className="flex justify-end">
                <button
                  type="submit"
                  disabled={loading}
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50"
                >
                  {loading ? (
                    <>
                      <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                      Gerando...
                    </>
                  ) : (
                    <>
                      <Wand2 className="w-4 h-4 mr-2" />
                      Gerar Curso
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </SettingsLayout>
  );
}