import React, { useState } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { VideoUploader } from '../../../components/admin/VideoUploader';
import { ImageUploader } from '../../../components/admin/ImageUploader';
import { uploadVideo, uploadImage } from '../../../lib/storage';
import { useProcessStore } from '../../../store/processStore';
import toast from 'react-hot-toast';

export default function VideoSettings() {
  const [loading, setLoading] = useState(false);
  const { startProcess } = useProcessStore();

  const handleVideoUpload = async (file: File) => {
    try {
      setLoading(true);
      
      // Upload video first
      const videoUrl = await uploadVideo(file);

      // Start background process for video enhancements
      const processId = await startProcess('video_processing', {
        videoUrl,
        addWatermark: true,
        addCaptions: true
      });

      toast.success('Vídeo enviado! O processamento continuará em segundo plano.');
    } catch (error) {
      console.error('Error uploading video:', error);
      toast.error('Erro ao enviar vídeo');
    } finally {
      setLoading(false);
    }
  };

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            Upload de Vídeos
          </h2>
          
          <div className="space-y-6">
            <VideoUploader onUpload={handleVideoUpload} />

            <div className="space-y-4">
              <h3 className="text-sm font-medium text-gray-700">Opções de Processamento</h3>
              
              <div className="space-y-3">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    className="rounded border-gray-300 text-red-600 focus:ring-red-500"
                  />
                  <span className="ml-2 text-sm text-gray-600">
                    Adicionar marca d'água
                  </span>
                </label>

                <label className="flex items-center">
                  <input
                    type="checkbox"
                    className="rounded border-gray-300 text-red-600 focus:ring-red-500"
                  />
                  <span className="ml-2 text-sm text-gray-600">
                    Gerar legendas automáticas
                  </span>
                </label>
              </div>
            </div>
          </div>
        </div>
      </div>
    </SettingsLayout>
  );
}