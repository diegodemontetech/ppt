import toast from 'react-hot-toast';

const API_TOKEN = 'a15f7c57-3ea9-4bcf-b285-7843ad3cce42';
const API_URL = 'https://app.colossyan.com/api/video-generation-jobs';

interface VideoJob {
  videoCreative: {
    settings: {
      name: string;
      videoSize: {
        height: number;
        width: number;
      };
    };
    scenes: Array<{
      name: string;
      tracks: Array<{
        type: string;
        actor: string;
        position: { x: number; y: number };
        size: { height: number; width: number };
        text: string;
        speakerId: string;
        removeBackground: boolean;
      }>;
    }>;
  };
}

export async function generateVideo(text: string): Promise<{ id: string; videoId: string }> {
  try {
    const job: VideoJob = {
      videoCreative: {
        settings: {
          name: "Generated Video",
          videoSize: {
            height: 1080,
            width: 1080,
          },
        },
        scenes: [
          {
            name: "Scene with AI Actor",
            tracks: [
              {
                type: "actor",
                actor: "ryan",
                position: { x: 0, y: 0 },
                size: { height: 1080, width: 1080 },
                text: text,
                speakerId: "en-GB-RyanNeural",
                removeBackground: true,
              },
            ],
          },
        ],
      },
    };

    const response = await fetch(API_URL, {
      method: "POST",
      headers: {
        authorizationtoken: API_TOKEN,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(job),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Failed to generate video');
    }

    const result = await response.json();
    toast.success('Video generation started successfully!');
    return result;
  } catch (error) {
    console.error('Error generating video:', error);
    toast.error('Failed to generate video');
    throw error;
  }
}

export async function checkVideoStatus(jobId: string): Promise<string> {
  try {
    const response = await fetch(`${API_URL}/${jobId}`, {
      headers: {
        authorizationtoken: API_TOKEN,
      },
    });

    if (!response.ok) {
      throw new Error('Failed to check video status');
    }

    const result = await response.json();
    return result.status;
  } catch (error) {
    console.error('Error checking video status:', error);
    throw error;
  }
}