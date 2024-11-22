import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Edit, Trash2, ArrowLeft } from 'lucide-react';
import { supabase } from '../../../lib/supabase';
import { VideoUploader } from '../../../components/admin/VideoUploader';
import { uploadVideo } from '../../../lib/storage';
import { RichTextEditor } from '../../../components/RichTextEditor';
import { PDFUploader } from '../../../components/PDFUploader';
import toast from 'react-hot-toast';

export default function LessonsSettings() {
  const { moduleId } = useParams();
  const navigate = useNavigate();
  const [module, setModule] = useState<any>(null);
  const [lessons, setLessons] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedLesson, setSelectedLesson] = useState<any>(null);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    video_url: '',
    order_num: 1,
    attachments: [] as File[]
  });
  const [isEditing, setIsEditing] = useState(false);

  useEffect(() => {
    if (moduleId) {
      fetchData();
    }
  }, [moduleId]);

  const fetchData = async () => {
    try {
      setLoading(true);

      // Get module details
      const { data: moduleData, error: moduleError } = await supabase
        .from('modules')
        .select('*, category:categories(id, name, department:departments(id, name))')
        .eq('id', moduleId)
        .single();

      if (moduleError) throw moduleError;
      setModule(moduleData);

      // Get lessons with attachments
      const { data: lessonsData, error: lessonsError } = await supabase
        .from('lessons')
        .select(`
          *,
          attachments:lesson_attachments(*)
        `)
        .eq('module_id', moduleId)
        .order('order_num');

      if (lessonsError) throw lessonsError;
      setLessons(lessonsData || []);

      // Set next order number
      setFormData(prev => ({
        ...prev,
        order_num: (lessonsData?.length || 0) + 1
      }));
    } catch (error) {
      console.error('Error fetching data:', error);
      toast.error('Erro ao carregar dados');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setLoading(true);

      // First, create/update the lesson
      const lessonData = {
        title: formData.title,
        description: formData.description,
        video_url: formData.video_url,
        order_num: formData.order_num,
        module_id: moduleId
      };

      let lessonId;

      if (isEditing && selectedLesson) {
        const { data, error } = await supabase
          .from('lessons')
          .update(lessonData)
          .eq('id', selectedLesson.id)
          .select()
          .single();

        if (error) throw error;
        lessonId = data.id;
      } else {
        const { data, error } = await supabase
          .from('lessons')
          .insert([lessonData])
          .select()
          .single();

        if (error) throw error;
        lessonId = data.id;
      }

      // Then handle attachments
      if (formData.attachments.length > 0) {
        for (const file of formData.attachments) {
          const fileExt = file.name.split('.').pop();
          const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
          
          const { data: uploadData, error: uploadError } = await supabase.storage
            .from('attachments')
            .upload(fileName, file);

          if (uploadError) throw uploadError;

          const { data: { publicUrl } } = supabase.storage
            .from('attachments')
            .getPublicUrl(fileName);

          const { error: attachmentError } = await supabase
            .from('lesson_attachments')
            .insert([{
              lesson_id: lessonId,
              title: file.name,
              file_url: publicUrl
            }]);

          if (attachmentError) throw attachmentError;
        }
      }

      setFormData({
        title: '',
        description: '',
        video_url: '',
        order_num: lessons.length + 1,
        attachments: []
      });
      setIsEditing(false);
      setSelectedLesson(null);
      toast.success(isEditing ? 'Aula atualizada com sucesso!' : 'Aula criada com sucesso!');
      fetchData();
    } catch (error) {
      console.error('Error saving lesson:', error);
      toast.error('Erro ao salvar aula');
    } finally {
      setLoading(false);
    }
  };

  const handleVideoUpload = async (file: File) => {
    try {
      setLoading(true);
      const videoUrl = await uploadVideo(file);
      setFormData(prev => ({ ...prev, video_url: videoUrl }));
      toast.success('Vídeo enviado com sucesso!');
    } catch (error) {
      console.error('Error uploading video:', error);
      toast.error('Erro ao enviar vídeo');
    } finally {
      setLoading(false);
    }
  };

  const handleAttachmentUpload = async (file: File) => {
    setFormData(prev => ({
      ...prev,
      attachments: [...prev.attachments, file]
    }));
    toast.success('Arquivo anexado com sucesso!');
  };

  if (!module) {
    return (
      <SettingsLayout>
        <div className="text-center py-12">
          <p className="text-gray-500">Módulo não encontrado</p>
          <button
            onClick={() => navigate('/admin/settings/courses')}
            className="mt-4 inline-flex items-center text-blue-600 hover:text-blue-700"
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            Voltar para Módulos
          </button>
        </div>
      </SettingsLayout>
    );
  }

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <button
              onClick={() => navigate('/admin/settings/courses')}
              className="inline-flex items-center text-gray-600 hover:text-gray-900"
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              Voltar para Módulos
            </button>
            <h1 className="text-2xl font-semibold text-gray-900 mt-2">
              {module.title} - Aulas
            </h1>
            {module.category && (
              <p className="text-sm text-gray-500">
                {module.category.department.name} - {module.category.name}
              </p>
            )}
          </div>
        </div>

        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <label htmlFor="title" className="block text-sm font-medium text-gray-700">
                  Título da Aula
                </label>
                <input
                  type="text"
                  id="title"
                  value={formData.title}
                  onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label htmlFor="description" className="block text-sm font-medium text-gray-700">
                  Descrição
                </label>
                <RichTextEditor
                  value={formData.description}
                  onChange={(value) => setFormData(prev => ({ ...prev, description: value }))}
                  placeholder="Descreva o conteúdo da aula..."
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Vídeo da Aula
                </label>
                <VideoUploader onUpload={handleVideoUpload} />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Anexos
                </label>
                <PDFUploader onUpload={handleAttachmentUpload} />
                {formData.attachments.length > 0 && (
                  <div className="mt-2 space-y-2">
                    {formData.attachments.map((file, index) => (
                      <div key={index} className="flex items-center justify-between p-2 bg-gray-50 rounded-md">
                        <span className="text-sm text-gray-600">{file.name}</span>
                        <button
                          type="button"
                          onClick={() => setFormData(prev => ({
                            ...prev,
                            attachments: prev.attachments.filter((_, i) => i !== index)
                          }))}
                          className="text-red-500 hover:text-red-700"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              <div>
                <label htmlFor="order_num" className="block text-sm font-medium text-gray-700">
                  Ordem da Aula
                </label>
                <input
                  type="number"
                  id="order_num"
                  value={formData.order_num}
                  onChange={(e) => setFormData(prev => ({ ...prev, order_num: parseInt(e.target.value) }))}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                  min="1"
                />
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setFormData({
                      title: '',
                      description: '',
                      video_url: '',
                      order_num: lessons.length + 1,
                      attachments: []
                    });
                    setIsEditing(false);
                    setSelectedLesson(null);
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
                  {loading ? 'Salvando...' : isEditing ? 'Atualizar' : 'Criar Aula'}
                </button>
              </div>
            </form>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">
              Aulas Cadastradas
            </h2>

            <div className="space-y-4">
              {lessons.map((lesson) => (
                <div
                  key={lesson.id}
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                >
                  <div>
                    <h3 className="text-sm font-medium text-gray-900">
                      {lesson.order_num}. {lesson.title}
                    </h3>
                    <div 
                      className="mt-1 text-sm text-gray-500 prose max-w-none"
                      dangerouslySetInnerHTML={{ __html: lesson.description }}
                    />
                    {lesson.attachments?.length > 0 && (
                      <div className="mt-2">
                        <p className="text-xs text-gray-400">
                          {lesson.attachments.length} anexo(s)
                        </p>
                      </div>
                    )}
                  </div>

                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => {
                        setSelectedLesson(lesson);
                        setFormData({
                          title: lesson.title,
                          description: lesson.description || '',
                          video_url: lesson.video_url,
                          order_num: lesson.order_num,
                          attachments: []
                        });
                        setIsEditing(true);
                      }}
                      className="p-2 text-gray-400 hover:text-gray-500"
                    >
                      <Edit className="w-5 h-5" />
                    </button>
                    <button
                      onClick={async () => {
                        if (window.confirm('Tem certeza que deseja excluir esta aula?')) {
                          try {
                            const { error } = await supabase
                              .from('lessons')
                              .delete()
                              .eq('id', lesson.id);

                            if (error) throw error;
                            toast.success('Aula excluída com sucesso!');
                            fetchData();
                          } catch (error) {
                            console.error('Error deleting lesson:', error);
                            toast.error('Erro ao excluir aula');
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