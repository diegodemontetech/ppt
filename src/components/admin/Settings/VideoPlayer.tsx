import React from 'react';
import Plyr from 'plyr';
import 'plyr/dist/plyr.css';

interface VideoPlayerProps {
  src: string;
  title?: string;
}

export function VideoPlayer({ src, title }: VideoPlayerProps) {
  const playerRef = React.useRef<HTMLVideoElement>(null);

  React.useEffect(() => {
    if (playerRef.current) {
      const player = new Plyr(playerRef.current, {
        controls: [
          'play-large',
          'play',
          'progress',
          'current-time',
          'mute',
          'volume',
          'captions',
          'settings',
          'pip',
          'airplay',
          'fullscreen',
        ],
      });

      return () => {
        player.destroy();
      };
    }
  }, []);

  return (
    <div className="aspect-w-16 aspect-h-9">
      <video
        ref={playerRef}
        className="plyr-react plyr"
        crossOrigin="anonymous"
      >
        <source src={`http://66.165.230.178:3000/videos/${src}`} type="video/mp4" />
      </video>
    </div>
  );
}