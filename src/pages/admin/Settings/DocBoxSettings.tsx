import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Plus, Edit, Trash2, FileText } from 'lucide-react';
import { useDocBoxStore } from '../../../store/docboxStore';
import { supabase } from '../../../lib/supabase';
import toast from 'react-hot-toast';

export default function DocBoxSettings() {
  const { categories, loading, fetchCategories } = useDocBoxStore();
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    parent_id: ''
  });
  const [isEditing, setIsEditing] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState(null);

  useEffect(() => {
    fetchCategories();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      if (isEditing && selectedCategory) {
        const { error } = await supabase
          .from('doc_categories')
          .update(formData)
          .eq('id', selectedCategory.id);

        if (error) throw error;
        toast.success('Categoria atualizada com sucesso!');
      } else {
        const { error } = await supabase
          .from('doc_categories')
          .insert([formData]);

        if (error) throw error;
        toast.success('Categoria criada com sucesso!');
      }

      setFormData({ name: '', description: '', parent_id: '' });
      setIsEditing(false);
      setSelectedCategory(null);
      fetchCategories();
    } catch (error) {
      console.error('Error saving category:', error);
      toast.error('Erro ao salvar categoria');
    }
  };

  const mainCategories = categories.filter(cat => !cat.parent_id);
  const subCategories = categories.filter(cat => cat.parent_id);

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            DocBox
          </h1>
          <button
            onClick={() => {
              setFormData({ name: '', description: '', parent_id: '' });
              setIsEditing(false);
              setSelectedCategory(null);
            }}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
          >
            <Plus className="w-4 h-4 mr-2" />
            Nova Categoria
          </button>
        </div>

        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                  Nome da Categoria
                </label>
                <input
                  type="text"
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label htmlFor="parent_id" className="block text-sm font-medium text-gray-700">
                  Categoria Pai
                </label>
                <select
                  id="parent_id"
                  value={formData.parent_id}
                  onChange={(e) => setFormData({ ...formData, parent_id: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="">Nenhuma (Categoria Principal)</option>
                  {mainCategories.map(category => (
                    <option key={category.id} value={category.id}>
                      {category.name}
                    </option>
                  ))}
                </select>
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

              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setFormData({ name: '', description: '', parent_id: '' });
                    setIsEditing(false);
                    setSelectedCategory(null);
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
                  {loading ? 'Salvando...' : isEditing ? 'Atualizar' : 'Criar Categoria'}
                </button>
              </div>
            </form>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">
              Categorias Cadastradas
            </h2>

            <div className="space-y-6">
              {mainCategories.map((category) => (
                <div key={category.id} className="space-y-4">
                  <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                    <div>
                      <h3 className="text-sm font-medium text-gray-900">
                        {category.name}
                      </h3>
                      {category.description && (
                        <p className="text-sm text-gray-500 mt-1">
                          {category.description}
                        </p>
                      )}
                    </div>

                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => {
                          setSelectedCategory(category);
                          setFormData({
                            name: category.name,
                            description: category.description || '',
                            parent_id: category.parent_id || ''
                          });
                          setIsEditing(true);
                        }}
                        className="p-2 text-gray-400 hover:text-gray-500"
                      >
                        <Edit className="w-5 h-5" />
                      </button>
                      <button
                        onClick={async () => {
                          if (window.confirm('Tem certeza que deseja excluir esta categoria?')) {
                            try {
                              const { error } = await supabase
                                .from('doc_categories')
                                .delete()
                                .eq('id', category.id);

                              if (error) throw error;
                              toast.success('Categoria excluída com sucesso!');
                              fetchCategories();
                            } catch (error) {
                              console.error('Error deleting category:', error);
                              toast.error('Erro ao excluir categoria');
                            }
                          }
                        }}
                        className="p-2 text-gray-400 hover:text-red-500"
                      >
                        <Trash2 className="w-5 h-5" />
                      </button>
                    </div>
                  </div>

                  {/* Subcategories */}
                  <div className="ml-8 space-y-4">
                    {subCategories
                      .filter(sub => sub.parent_id === category.id)
                      .map(subCategory => (
                        <div
                          key={subCategory.id}
                          className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border-l-4 border-blue-500"
                        >
                          <div>
                            <h4 className="text-sm font-medium text-gray-900">
                              {subCategory.name}
                            </h4>
                            {subCategory.description && (
                              <p className="text-sm text-gray-500 mt-1">
                                {subCategory.description}
                              </p>
                            )}
                          </div>

                          <div className="flex items-center space-x-2">
                            <button
                              onClick={() => {
                                setSelectedCategory(subCategory);
                                setFormData({
                                  name: subCategory.name,
                                  description: subCategory.description || '',
                                  parent_id: subCategory.parent_id || ''
                                });
                                setIsEditing(true);
                              }}
                              className="p-2 text-gray-400 hover:text-gray-500"
                            >
                              <Edit className="w-5 h-5" />
                            </button>
                            <button
                              onClick={async () => {
                                if (window.confirm('Tem certeza que deseja excluir esta subcategoria?')) {
                                  try {
                                    const { error } = await supabase
                                      .from('doc_categories')
                                      .delete()
                                      .eq('id', subCategory.id);

                                    if (error) throw error;
                                    toast.success('Subcategoria excluída com sucesso!');
                                    fetchCategories();
                                  } catch (error) {
                                    console.error('Error deleting subcategory:', error);
                                    toast.error('Erro ao excluir subcategoria');
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
              ))}
            </div>
          </div>
        </div>
      </div>
    </SettingsLayout>
  );
}