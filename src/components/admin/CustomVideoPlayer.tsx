import React, { useEffect, useRef } from 'react';
import Plyr from 'plyr';
import 'plyr/dist/plyr.css';

interface CustomVideoPlayerProps {
  src: string;
  title?: string;
  onEnded?: () => void;
}

export function CustomVideoPlayer({ src, title, onEnded }: CustomVideoPlayerProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const playerRef = useRef<Plyr>();

  useEffect(() => {
    if (videoRef.current) {
      playerRef.current = new Plyr(videoRef.current, {
        controls: [
          'play-large',
          'play',
          'progress',
          'current-time',
          'mute',
          'volume',
          'settings',
          'fullscreen'
        ],
        settings: ['quality', 'speed'],
        quality: {
          default: 720,
          options: [4320, 2880, 2160, 1440, 1080, 720, 576, 480, 360, 240]
        }
      });

      if (onEnded) {
        videoRef.current.addEventListener('ended', onEnded);
      }

      return () => {
        if (playerRef.current) {
          playerRef.current.destroy();
        }
        if (videoRef.current && onEnded) {
          videoRef.current.removeEventListener('ended', onEnded);
        }
      };
    }
  }, [onEnded]);

  return (
    <div className="relative aspect-w-16 aspect-h-9">
      <video
        ref={videoRef}
        className="plyr-react plyr"
        crossOrigin="anonymous"
        playsInline
      >
        <source src={`http://66.165.230.178:3000/videos/${src}`} type="video/mp4" />
      </video>
    </div>
  );
}