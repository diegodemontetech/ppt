import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Plus, Edit, Trash2, Newspaper } from 'lucide-react';
import { useNewsStore } from '../../../store/newsStore';
import { supabase } from '../../../lib/supabase';
import { ImageUploader } from '../../../components/admin/ImageUploader';
import { uploadImage } from '../../../lib/storage';
import toast from 'react-hot-toast';

export default function NewsSettings() {
  const { articles, categories, loading, fetchArticles, fetchCategories } = useNewsStore();
  const [formData, setFormData] = useState({
    title: '',
    content: '',
    image_url: '',
    video_url: '',
    category: '',
    is_featured: false,
    is_published: false
  });
  const [isEditing, setIsEditing] = useState(false);
  const [selectedArticle, setSelectedArticle] = useState(null);

  useEffect(() => {
    fetchArticles();
    fetchCategories();
  }, []);

  const handleImageUpload = async (file: File) => {
    try {
      const imageUrl = await uploadImage(file);
      setFormData(prev => ({ ...prev, image_url: imageUrl }));
      toast.success('Imagem enviada com sucesso!');
    } catch (error) {
      console.error('Error uploading image:', error);
      toast.error('Erro ao enviar imagem');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      const data = {
        ...formData,
        published_at: formData.is_published ? new Date().toISOString() : null
      };

      if (isEditing && selectedArticle) {
        const { error } = await supabase
          .from('news_articles')
          .update(data)
          .eq('id', selectedArticle.id);

        if (error) throw error;
        toast.success('Notícia atualizada com sucesso!');
      } else {
        const { error } = await supabase
          .from('news_articles')
          .insert([data]);

        if (error) throw error;
        toast.success('Notícia criada com sucesso!');
      }

      setFormData({
        title: '',
        content: '',
        image_url: '',
        video_url: '',
        category: '',
        is_featured: false,
        is_published: false
      });
      setIsEditing(false);
      setSelectedArticle(null);
      fetchArticles();
    } catch (error) {
      console.error('Error saving article:', error);
      toast.error('Erro ao salvar notícia');
    }
  };

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            Gerenciar Notícias
          </h1>
        </div>

        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <label htmlFor="title" className="block text-sm font-medium text-gray-700">
                  Título
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
                <label htmlFor="category" className="block text-sm font-medium text-gray-700">
                  Categoria
                </label>
                <select
                  id="category"
                  value={formData.category}
                  onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                >
                  <option value="">Selecione uma categoria</option>
                  {categories.map(category => (
                    <option key={category.id} value={category.id}>
                      {category.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Imagem
                </label>
                <ImageUploader onUpload={handleImageUpload} />
              </div>

              <div>
                <label htmlFor="video_url" className="block text-sm font-medium text-gray-700">
                  URL do Vídeo (opcional)
                </label>
                <input
                  type="url"
                  id="video_url"
                  value={formData.video_url}
                  onChange={(e) => setFormData({ ...formData, video_url: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  placeholder="https://www.youtube.com/embed/..."
                />
              </div>

              <div>
                <label htmlFor="content" className="block text-sm font-medium text-gray-700">
                  Conteúdo
                </label>
                <textarea
                  id="content"
                  value={formData.content}
                  onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                  rows={10}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="flex items-center space-x-4">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={formData.is_featured}
                    onChange={(e) => setFormData({ ...formData, is_featured: e.target.checked })}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="ml-2 text-sm text-gray-900">
                    Destacar notícia
                  </span>
                </label>

                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={formData.is_published}
                    onChange={(e) => setFormData({ ...formData, is_published: e.target.checked })}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="ml-2 text-sm text-gray-900">
                    Publicar agora
                  </span>
                </label>
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setFormData({
                      title: '',
                      content: '',
                      image_url: '',
                      video_url: '',
                      category: '',
                      is_featured: false,
                      is_published: false
                    });
                    setIsEditing(false);
                    setSelectedArticle(null);
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
                  {loading ? 'Salvando...' : isEditing ? 'Atualizar' : 'Criar Notícia'}
                </button>
              </div>
            </form>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">
              Notícias Cadastradas
            </h2>

            <div className="space-y-4">
              {articles.map((article) => (
                <div
                  key={article.id}
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                >
                  <div>
                    <h3 className="text-sm font-medium text-gray-900">
                      {article.title}
                    </h3>
                    <p className="text-sm text-gray-500 mt-1">
                      {article.content.substring(0, 100)}...
                    </p>
                    <div className="mt-2 flex items-center space-x-2">
                      {article.is_featured && (
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                          Destaque
                        </span>
                      )}
                      {article.is_published ? (
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                          Publicada
                        </span>
                      ) : (
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                          Rascunho
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => {
                        setSelectedArticle(article);
                        setFormData({
                          title: article.title,
                          content: article.content,
                          image_url: article.image_url || '',
                          video_url: article.video_url || '',
                          category: article.category,
                          is_featured: article.is_featured,
                          is_published: article.is_published
                        });
                        setIsEditing(true);
                      }}
                      className="p-2 text-gray-400 hover:text-gray-500"
                    >
                      <Edit className="w-5 h-5" />
                    </button>
                    <button
                      onClick={async () => {
                        if (window.confirm('Tem certeza que deseja excluir esta notícia?')) {
                          try {
                            const { error } = await supabase
                              .from('news_articles')
                              .delete()
                              .eq('id', article.id);

                            if (error) throw error;
                            toast.success('Notícia excluída com sucesso!');
                            fetchArticles();
                          } catch (error) {
                            console.error('Error deleting article:', error);
                            toast.error('Erro ao excluir notícia');
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