import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Plus, Edit, Trash2, Book } from 'lucide-react';
import { supabase } from '../../../lib/supabase';
import { PDFUploader } from '../../../components/PDFUploader';
import { ImageUploader } from '../../../components/admin/ImageUploader';
import { uploadPdf, uploadImage } from '../../../lib/storage';
import { extractPdfThumbnail } from '../../../lib/pdfUtils';
import toast from 'react-hot-toast';

export default function EBooksSettings() {
  const [ebooks, setEbooks] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState({
    title: '',
    subtitle: '',
    author: '',
    description: '',
    category_id: '',
    pdf_url: '',
    cover_url: '',
    is_featured: false
  });
  const [isEditing, setIsEditing] = useState(false);
  const [selectedEbook, setSelectedEbook] = useState(null);

  useEffect(() => {
    fetchEbooks();
    fetchCategories();
  }, []);

  const fetchEbooks = async () => {
    try {
      const { data, error } = await supabase
        .from('ebooks')
        .select(`
          *,
          category:categories(
            id,
            name,
            department:departments(
              id,
              name
            )
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setEbooks(data || []);
    } catch (error) {
      console.error('Error fetching ebooks:', error);
      toast.error('Erro ao carregar e-books');
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

  const handlePdfUpload = async (file: File) => {
    try {
      setLoading(true);
      
      // Upload PDF
      const pdfUrl = await uploadPdf(file);
      setFormData(prev => ({ ...prev, pdf_url: pdfUrl }));

      // Generate thumbnail from first page
      const thumbnailUrl = await extractPdfThumbnail(pdfUrl);
      if (thumbnailUrl) {
        setFormData(prev => ({ ...prev, cover_url: thumbnailUrl }));
      }

      toast.success('PDF enviado com sucesso!');
    } catch (error) {
      console.error('Error uploading PDF:', error);
      toast.error('Erro ao enviar PDF');
    } finally {
      setLoading(false);
    }
  };

  const handleCoverUpload = async (file: File) => {
    try {
      setLoading(true);
      const coverUrl = await uploadImage(file);
      setFormData(prev => ({ ...prev, cover_url: coverUrl }));
      toast.success('Capa enviada com sucesso!');
    } catch (error) {
      console.error('Error uploading cover:', error);
      toast.error('Erro ao enviar capa');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setLoading(true);

      if (isEditing && selectedEbook) {
        const { error } = await supabase
          .from('ebooks')
          .update(formData)
          .eq('id', selectedEbook.id);

        if (error) throw error;
        toast.success('E-book atualizado com sucesso!');
      } else {
        const { error } = await supabase
          .from('ebooks')
          .insert([formData]);

        if (error) throw error;
        toast.success('E-book criado com sucesso!');
      }

      setFormData({
        title: '',
        subtitle: '',
        author: '',
        description: '',
        category_id: '',
        pdf_url: '',
        cover_url: '',
        is_featured: false
      });
      setIsEditing(false);
      setSelectedEbook(null);
      fetchEbooks();
    } catch (error) {
      console.error('Error saving ebook:', error);
      toast.error('Erro ao salvar e-book');
    } finally {
      setLoading(false);
    }
  };

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            Gerenciar E-Books
          </h1>
          <button
            onClick={() => {
              setFormData({
                title: '',
                subtitle: '',
                author: '',
                description: '',
                category_id: '',
                pdf_url: '',
                cover_url: '',
                is_featured: false
              });
              setIsEditing(false);
              setSelectedEbook(null);
            }}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700"
          >
            <Plus className="w-4 h-4 mr-2" />
            Novo E-Book
          </button>
        </div>

        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <label htmlFor="title" className="block text-sm font-medium text-gray-700">
                    Título
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
                  <label htmlFor="subtitle" className="block text-sm font-medium text-gray-700">
                    Subtítulo
                  </label>
                  <input
                    type="text"
                    id="subtitle"
                    value={formData.subtitle}
                    onChange={(e) => setFormData({ ...formData, subtitle: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-6">
                <div>
                  <label htmlFor="author" className="block text-sm font-medium text-gray-700">
                    Autor
                  </label>
                  <input
                    type="text"
                    id="author"
                    value={formData.author}
                    onChange={(e) => setFormData({ ...formData, author: e.target.value })}
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
                  PDF
                </label>
                <PDFUploader onUpload={handlePdfUpload} />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Capa
                </label>
                <ImageUploader onUpload={handleCoverUpload} />
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
                  Destacar e-book
                </label>
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setFormData({
                      title: '',
                      subtitle: '',
                      author: '',
                      description: '',
                      category_id: '',
                      pdf_url: '',
                      cover_url: '',
                      is_featured: false
                    });
                    setIsEditing(false);
                    setSelectedEbook(null);
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
                  {loading ? 'Salvando...' : isEditing ? 'Atualizar' : 'Criar E-Book'}
                </button>
              </div>
            </form>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">
              E-Books Cadastrados
            </h2>

            <div className="space-y-4">
              {ebooks.map((ebook) => (
                <div
                  key={ebook.id}
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                >
                  <div className="flex items-center space-x-4">
                    {ebook.cover_url ? (
                      <img
                        src={ebook.cover_url}
                        alt={ebook.title}
                        className="w-16 h-20 object-cover rounded"
                        crossOrigin="anonymous"
                      />
                    ) : (
                      <div className="w-16 h-20 bg-gray-200 rounded flex items-center justify-center">
                        <Book className="w-8 h-8 text-gray-400" />
                      </div>
                    )}
                    <div>
                      <h3 className="text-sm font-medium text-gray-900">
                        {ebook.title}
                      </h3>
                      {ebook.subtitle && (
                        <p className="text-sm text-gray-500">
                          {ebook.subtitle}
                        </p>
                      )}
                      <p className="text-sm text-gray-600 mt-1">
                        {ebook.author}
                      </p>
                      {ebook.category && (
                        <p className="text-xs text-gray-400 mt-1">
                          {ebook.category.department.name} - {ebook.category.name}
                        </p>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => {
                        setSelectedEbook(ebook);
                        setFormData({
                          title: ebook.title,
                          subtitle: ebook.subtitle || '',
                          author: ebook.author,
                          description: ebook.description || '',
                          category_id: ebook.category_id,
                          pdf_url: ebook.pdf_url,
                          cover_url: ebook.cover_url || '',
                          is_featured: ebook.is_featured
                        });
                        setIsEditing(true);
                      }}
                      className="p-2 text-gray-400 hover:text-gray-500"
                    >
                      <Edit className="w-5 h-5" />
                    </button>
                    <button
                      onClick={async () => {
                        if (window.confirm('Tem certeza que deseja excluir este e-book?')) {
                          try {
                            const { error } = await supabase
                              .from('ebooks')
                              .delete()
                              .eq('id', ebook.id);

                            if (error) throw error;
                            toast.success('E-book excluído com sucesso!');
                            fetchEbooks();
                          } catch (error) {
                            console.error('Error deleting ebook:', error);
                            toast.error('Erro ao excluir e-book');
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