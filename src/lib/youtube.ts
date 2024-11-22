import { supabase } from './supabase';

const API_KEY = import.meta.env.VITE_YOUTUBE_API_KEY;

export async function getVideoDetails(videoId: string) {
  try {
    const response = await fetch(
      `https://www.googleapis.com/youtube/v3/videos?id=${videoId}&key=${API_KEY}&part=snippet,contentDetails`,
      {
        headers: {
          'Accept': 'application/json',
          'Origin': window.location.origin
        }
      }
    );

    if (!response.ok) {
      throw new Error('Failed to fetch video details');
    }

    const data = await response.json();
    return data.items[0];
  } catch (error) {
    console.error('Error fetching video details:', error);
    throw error;
  }
}