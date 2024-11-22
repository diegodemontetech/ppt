import React, { useState } from 'react';
import { Layout } from '../../components/Layout';
import { VideoUpload } from '../../components/admin/VideoUpload';
import { CustomVideoPlayer } from '../../components/admin/CustomVideoPlayer';
import { uploadVideo } from '../../lib/api/videos';
import { supabase } from '../../lib/supabase';
import toast from 'react-hot-toast';

export default function Settings() {
  const [uploadedVideo, setUploadedVideo] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleVideoUpload = async (file: File) => {
    try {
      setLoading(true);
      const videoPath = await uploadVideo({ file });
      setUploadedVideo(videoPath);
      toast.success('Vídeo enviado com sucesso!');
    } catch (error) {
      console.error('Error uploading video:', error);
      toast.error('Erro ao enviar vídeo');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Layout title="Configurações">
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            Upload de Vídeos
          </h2>
          
          <VideoUpload onUpload={handleVideoUpload} />

          {loading && (
            <div className="mt-4 text-center">
              <div className="inline-flex items-center">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-500 mr-2"></div>
                <span className="text-sm text-gray-500">Enviando vídeo...</span>
              </div>
            </div>
          )}

          {uploadedVideo && (
            <div className="mt-6">
              <h3 className="text-sm font-medium text-gray-700 mb-2">
                Preview do Vídeo
              </h3>
              <CustomVideoPlayer src={uploadedVideo} />
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
}