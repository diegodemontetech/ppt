import React, { useState } from 'react';
import { Plus, Video, FileText, List } from 'lucide-react';
import { Course, Lesson } from '../../types';
import { supabase } from '../../lib/supabase';
import { uploadVideo } from '../../lib/storage';
import { VideoUploader } from './VideoUploader';
import { QuizManager } from './QuizManager';
import toast from 'react-hot-toast';

interface LessonManagerProps {
  course: Course;
  onUpdate: () => void;
}

export function LessonManager({ course, onUpdate }: LessonManagerProps) {
  const [isAdding, setIsAdding] = useState(false);
  const [selectedLesson, setSelectedLesson] = useState<Lesson | null>(null);
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    videoUrl: '',
    pdfUrl: '',
    orderNum: (course.lessons?.length || 0) + 1
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setLoading(true);

      const { data: lesson, error } = await supabase
        .from('lessons')
        .insert([{
          course_id: course.id,
          title: formData.title,
          description: formData.description,
          video_url: formData.videoUrl,
          pdf_url: formData.pdfUrl,
          order_num: formData.orderNum
        }])
        .select()
        .single();

      if (error) throw error;

      toast.success('Aula criada com sucesso!');
      setIsAdding(false);
      setFormData({
        title: '',
        description: '',
        videoUrl: '',
        pdfUrl: '',
        orderNum: (course.lessons?.length || 0) + 2
      });
      onUpdate();
    } catch (error) {
      console.error('Error creating lesson:', error);
      toast.error('Erro ao criar aula');
    } finally {
      setLoading(false);
    }
  };

  const handleVideoUpload = async (file: File) => {
    try {
      setLoading(true);
      const videoUrl = await uploadVideo(file);
      setFormData(prev => ({ ...prev, videoUrl }));
      toast.success('Vídeo enviado com sucesso!');
    } catch (error) {
      console.error('Error uploading video:', error);
      toast.error('Erro ao enviar vídeo');
    } finally {
      setLoading(false);
    }
  };

  // Rest of the component remains the same...
}