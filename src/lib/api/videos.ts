import toast from 'react-hot-toast';

interface UploadVideoParams {
  file: File;
  onProgress?: (progress: number) => void;
}

export async function uploadVideo({ file, onProgress }: UploadVideoParams): Promise<string> {
  const formData = new FormData();
  formData.append('video', file);

  try {
    const response = await fetch('http://66.165.230.178:3000/upload', {
      method: 'POST',
      headers: {
        'Authorization': 'Basic ' + btoa('root:Kabul@21')
      },
      body: formData
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Failed to upload video');
    }

    const data = await response.json();
    return data.path.replace('/videos/', '');
  } catch (error) {
    console.error('Error uploading video:', error);
    toast.error('Erro ao fazer upload do vídeo');
    throw error;
  }
}