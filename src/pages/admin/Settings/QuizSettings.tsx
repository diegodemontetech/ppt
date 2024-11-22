import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Plus, Edit, Trash2 } from 'lucide-react';
import { supabase } from '../../../lib/supabase';
import { QuizManager } from '../../../components/admin/QuizManager';
import toast from 'react-hot-toast';

export default function QuizSettings() {
  const [modules, setModules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedModule, setSelectedModule] = useState(null);

  useEffect(() => {
    fetchModules();
  }, []);

  const fetchModules = async () => {
    try {
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
          quiz:quizzes(*)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setModules(data || []);
    } catch (error) {
      console.error('Error fetching modules:', error);
      toast.error('Erro ao carregar módulos');
    } finally {
      setLoading(false);
    }
  };

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            Gerenciar Quiz
          </h1>
        </div>

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">
              Selecione um Módulo
            </h2>

            <div className="space-y-4">
              {modules.map((module) => (
                <div
                  key={module.id}
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                >
                  <div>
                    <h3 className="text-sm font-medium text-gray-900">
                      {module.title}
                    </h3>
                    {module.category && (
                      <p className="text-xs text-gray-500 mt-1">
                        {module.category.department.name} - {module.category.name}
                      </p>
                    )}
                    {module.quiz?.length > 0 && (
                      <span className="mt-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        Quiz Configurado
                      </span>
                    )}
                  </div>

                  <button
                    onClick={() => setSelectedModule(module)}
                    className="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                  >
                    {module.quiz?.length > 0 ? 'Editar Quiz' : 'Adicionar Quiz'}
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>

        {selectedModule && (
          <div className="bg-white shadow rounded-lg overflow-hidden">
            <div className="p-6">
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-lg font-medium text-gray-900">
                  Quiz: {selectedModule.title}
                </h2>
                <button
                  onClick={() => setSelectedModule(null)}
                  className="text-sm text-gray-500 hover:text-gray-700"
                >
                  Voltar para lista
                </button>
              </div>

              <QuizManager 
                module={selectedModule} 
                onUpdate={() => {
                  fetchModules();
                  setSelectedModule(null);
                }} 
              />
            </div>
          </div>
        )}
      </div>
    </SettingsLayout>
  );
}