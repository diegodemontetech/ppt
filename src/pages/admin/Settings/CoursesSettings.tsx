import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Plus, Edit, Trash2, ChevronRight } from 'lucide-react';
import { supabase } from '../../../lib/supabase';
import { useNavigate } from 'react-router-dom';
import { ImageUploader } from '../../../components/admin/ImageUploader';
import { uploadImage } from '../../../lib/storage';
import { QuizManager } from '../../../components/admin/QuizManager';
import toast from 'react-hot-toast';

export default function CoursesSettings() {
  const navigate = useNavigate();
  const [modules, setModules] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category_id: '',
    technical_lead: '',
    estimated_duration: 0,
    thumbnail_url: '',
    is_featured: false
  });
  const [isEditing, setIsEditing] = useState(false);
  const [selectedModule, setSelectedModule] = useState(null);
  const [showQuiz, setShowQuiz] = useState(false);
  const [showForm, setShowForm] = useState(false);

  useEffect(() => {
    fetchModules();
    fetchCategories();
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

  const fetchCategories = async () => {
    try {
      const { data, error } = await supabase
        .from('categories')
        .select(`
          id,
          name,
          department:departments(
            id,
            name
          )
        `)
        .order('name');

      if (error) throw error;
      setCategories(data || []);
    } catch (error) {
      console.error('Error fetching categories:', error);
      toast.error('Erro ao carregar categorias');
    }
  };

  const handleImageUpload = async (file: File) => {
    try {
      setLoading(true);
      const imageUrl = await uploadImage(file);
      setFormData(prev => ({ ...prev, thumbnail_url: imageUrl }));
      toast.success('Imagem enviada com sucesso!');
    } catch (error) {
      console.error('Error uploading image:', error);
      toast.error('Erro ao enviar imagem');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setLoading(true);

      const moduleData = {
        title: formData.title,
        description: formData.description,
        category_id: formData.category_id,
        technical_lead: formData.technical_lead,
        estimated_duration: formData.estimated_duration,
        thumbnail_url: formData.thumbnail_url,
        is_featured: formData.is_featured
      };

      if (isEditing && selectedModule) {
        const { error } = await supabase
          .from('modules')
          .update(moduleData)
          .eq('id', selectedModule.id);

        if (error) throw error;
        toast.success('Módulo atualizado com sucesso!');
      } else {
        const { data, error } = await supabase
          .from('modules')
          .insert([moduleData])
          .select()
          .single();

        if (error) throw error;

        // Create empty quiz for the module
        const { error: quizError } = await supabase
          .from('quizzes')
          .insert([{
            module_id: data.id,
            questions: []
          }]);

        if (quizError) throw quizError;

        toast.success('Módulo criado com sucesso!');
      }

      setFormData({
        title: '',
        description: '',
        category_id: '',
        technical_lead: '',
        estimated_duration: 0,
        thumbnail_url: '',
        is_featured: false
      });
      setIsEditing(false);
      setSelectedModule(null);
      setShowForm(false);
      fetchModules();
    } catch (error) {
      console.error('Error saving module:', error);
      toast.error('Erro ao salvar módulo');
    } finally {
      setLoading(false);
    }
  };

  const handleManageLessons = (moduleId: string) => {
    navigate(`/admin/settings/courses/${moduleId}/lessons`);
  };

  const handleManageQuiz = (module: any) => {
    setSelectedModule(module);
    setShowQuiz(true);
  };

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            Gerenciar Cursos
          </h1>
          <button
            onClick={() => {
              setFormData({
                title: '',
                description: '',
                category_id: '',
                technical_lead: '',
                estimated_duration: 0,
                thumbnail_url: '',
                is_featured: false
              });
              setIsEditing(false);
              setSelectedModule(null);
              setShowForm(true);
            }}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700"
          >
            <Plus className="w-4 h-4 mr-2" />
            Novo Curso
          </button>
        </div>

        {showForm && (
          <div className="bg-white shadow rounded-lg">
            <div className="p-6">
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid grid-cols-2 gap-6">
                  <div>
                    <label htmlFor="title" className="block text-sm font-medium text-gray-700">
                      Título do Curso
                    </label>
                    <input
                      type="text"
                      id="title"
                      value={formData.title}
                      onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
                      required
                    />
                  </div>

                  <div>
                    <label htmlFor="category" className="block text-sm font-medium text-gray-700">
                      Categoria
                    </label>
                    <select
                      id="category"
                      value={formData.category_id}
                      onChange={(e) => setFormData({ ...formData, category_id: e.target.value })}
                      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
                      required
                    >
                      <option value="">Selecione uma categoria</option>
                      {categories.map(category => (
                        <option key={category.id} value={category.id}>
                          {category.department.name} - {category.name}
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
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Imagem de Capa
                  </label>
                  <ImageUploader onUpload={handleImageUpload} />
                </div>

                <div className="grid grid-cols-2 gap-6">
                  <div>
                    <label htmlFor="technical_lead" className="block text-sm font-medium text-gray-700">
                      Responsável Técnico do Curso
                    </label>
                    <input
                      type="text"
                      id="technical_lead"
                      value={formData.technical_lead}
                      onChange={(e) => setFormData({ ...formData, technical_lead: e.target.value })}
                      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
                      required
                    />
                  </div>

                  <div>
                    <label htmlFor="estimated_duration" className="block text-sm font-medium text-gray-700">
                      Duração Estimada (horas)
                    </label>
                    <input
                      type="number"
                      id="estimated_duration"
                      value={formData.estimated_duration}
                      onChange={(e) => setFormData({ ...formData, estimated_duration: parseInt(e.target.value) })}
                      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
                      required
                      min="1"
                    />
                  </div>
                </div>

                <div className="flex items-center">
                  <input
                    type="checkbox"
                    id="is_featured"
                    checked={formData.is_featured}
                    onChange={(e) => setFormData({ ...formData, is_featured: e.target.checked })}
                    className="h-4 w-4 text-red-600 focus:ring-red-500 border-gray-300 rounded"
                  />
                  <label htmlFor="is_featured" className="ml-2 block text-sm text-gray-900">
                    Destacar curso
                  </label>
                </div>

                <div className="flex justify-end space-x-3">
                  <button
                    type="button"
                    onClick={() => {
                      setFormData({
                        title: '',
                        description: '',
                        category_id: '',
                        technical_lead: '',
                        estimated_duration: 0,
                        thumbnail_url: '',
                        is_featured: false
                      });
                      setIsEditing(false);
                      setSelectedModule(null);
                      setShowForm(false);
                    }}
                    className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                  >
                    Cancelar
                  </button>
                  <button
                    type="submit"
                    disabled={loading}
                    className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                  >
                    {loading ? 'Salvando...' : isEditing ? 'Atualizar' : 'Criar Curso'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">
              Cursos Cadastrados
            </h2>

            <div className="space-y-4">
              {modules.map((module) => (
                <div
                  key={module.id}
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                >
                  <div className="flex items-center space-x-4">
                    {module.thumbnail_url ? (
                      <img
                        src={module.thumbnail_url}
                        alt={module.title}
                        className="w-24 h-16 object-cover rounded"
                        crossOrigin="anonymous"
                      />
                    ) : (
                      <div 
                        className="w-24 h-16 rounded flex items-center justify-center text-white text-xl font-bold"
                        style={{ backgroundColor: module.bg_color }}
                      >
                        {module.title[0]}
                      </div>
                    )}
                    <div>
                      <h3 className="text-sm font-medium text-gray-900">
                        {module.title}
                      </h3>
                      <p className="text-sm text-gray-500 mt-1">
                        {module.description}
                      </p>
                      {module.category && (
                        <p className="text-xs text-gray-400 mt-1">
                          {module.category.department.name} - {module.category.name}
                        </p>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center space-x-4">
                    <button
                      onClick={() => handleManageQuiz(module)}
                      className="text-sm text-red-600 hover:text-red-700"
                    >
                      {module.quiz?.length > 0 ? 'Editar Quiz' : 'Adicionar Quiz'}
                    </button>
                    <button
                      onClick={() => handleManageLessons(module.id)}
                      className="text-sm text-red-600 hover:text-red-700"
                    >
                      Gerenciar Aulas
                      <ChevronRight className="w-4 h-4 inline ml-1" />
                    </button>
                    <button
                      onClick={() => {
                        setSelectedModule(module);
                        setFormData({
                          title: module.title,
                          description: module.description || '',
                          category_id: module.category_id,
                          technical_lead: module.technical_lead || '',
                          estimated_duration: module.estimated_duration || 0,
                          thumbnail_url: module.thumbnail_url || '',
                          is_featured: module.is_featured
                        });
                        setIsEditing(true);
                        setShowForm(true);
                      }}
                      className="p-2 text-gray-400 hover:text-gray-500"
                    >
                      <Edit className="w-5 h-5" />
                    </button>
                    <button
                      onClick={async () => {
                        if (window.confirm('Tem certeza que deseja excluir este curso?')) {
                          try {
                            const { error } = await supabase
                              .from('modules')
                              .delete()
                              .eq('id', module.id);

                            if (error) throw error;
                            toast.success('Curso excluído com sucesso!');
                            fetchModules();
                          } catch (error) {
                            console.error('Error deleting module:', error);
                            toast.error('Erro ao excluir curso');
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

        {showQuiz && selectedModule && (
          <div className="bg-white shadow rounded-lg overflow-hidden">
            <div className="p-6">
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-lg font-medium text-gray-900">
                  Quiz: {selectedModule.title}
                </h2>
                <button
                  onClick={() => {
                    setSelectedModule(null);
                    setShowQuiz(false);
                  }}
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
                  setShowQuiz(false);
                }} 
              />
            </div>
          </div>
        )}
      </div>
    </SettingsLayout>
  );
}