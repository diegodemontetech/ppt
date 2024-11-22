import React, { useEffect, useRef, useState } from 'react';
import toast from 'react-hot-toast';

interface VideoPlayerProps {
  videoUrl: string;
  onComplete?: () => void;
}

export default function VideoPlayer({ videoUrl, onComplete }: VideoPlayerProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (videoRef.current) {
      videoRef.current.addEventListener('ended', () => {
        onComplete?.();
      });
    }
  }, [onComplete]);

  const handleError = () => {
    setError('Erro ao carregar vídeo');
    setLoading(false);
    toast.error('Erro ao carregar vídeo');
  };

  const handleReady = () => {
    setLoading(false);
    setError(null);
  };

  // Prevent context menu on video
  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
  };

  if (error) {
    return (
      <div className="relative w-full bg-black rounded-lg overflow-hidden">
        <div className="aspect-w-16 aspect-h-9 flex items-center justify-center">
          <div className="text-white text-center">
            <p>{error}</p>
            <button
              onClick={() => {
                setError(null);
                setLoading(true);
              }}
              className="mt-4 px-4 py-2 bg-blue-600 rounded-md hover:bg-blue-700"
            >
              Tentar Novamente
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Get public URL from Supabase storage
  const url = videoUrl.startsWith('http') 
    ? videoUrl 
    : `https://grtuisjorfehyuzjncok.supabase.co/storage/v1/object/public/videos/${videoUrl}`;

  return (
    <div className="relative w-full bg-black rounded-lg overflow-hidden">
      {loading && (
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
        </div>
      )}
      <div className="aspect-w-16 aspect-h-9">
        <video
          ref={videoRef}
          src={url}
          className="absolute top-0 left-0 w-full h-full"
          controls
          controlsList="nodownload" 
          onContextMenu={handleContextMenu}
          playsInline
          onError={handleError}
          onCanPlay={handleReady}
          style={{ opacity: loading ? 0 : 1 }}
          crossOrigin="anonymous"
        >
          <source src={url} type="video/mp4" />
          Seu navegador não suporta vídeos.
        </video>
      </div>
    </div>
  );
}