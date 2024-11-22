import React, { useState } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Wand2, Loader2 } from 'lucide-react';
import { generateCourseContent } from '../../../lib/ai';
import { supabase } from '../../../lib/supabase';
import { useProcessStore } from '../../../store/processStore';
import toast from 'react-hot-toast';

interface GenerationOptions {
  generateTitle: boolean;
  generateDescription: boolean;
  generateThumbnail: boolean;
  addWatermark: boolean;
  addCaptions: boolean;
}

export default function MagicLearningSettings() {
  const [topic, setTopic] = useState('');
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [currentStep, setCurrentStep] = useState('');
  const { startProcess } = useProcessStore();
  const [options, setOptions] = useState<GenerationOptions>({
    generateTitle: true,
    generateDescription: true,
    generateThumbnail: true,
    addWatermark: true,
    addCaptions: true
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      // Inicia o processo em background
      const processId = await startProcess('course_generation', {
        topic,
        options
      });

      toast.success('Geração do curso iniciada! Você pode acompanhar o progresso no canto inferior direito da tela.');
      
      // Limpa o formulário
      setTopic('');
    } catch (error: any) {
      console.error('Error starting course generation:', error);
      toast.error(error.message || 'Erro ao iniciar geração do curso');
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
                <p className="mt-1 text-xs text-gray-500">
                  Digite o tema do curso que você deseja gerar. Seja específico para melhores resultados.
                </p>
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