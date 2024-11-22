export interface NewsArticle {
  id: string;
  title: string;
  content: string;
  image_url?: string;
  video_url?: string;
  category: string;
  is_featured: boolean;
  is_published: boolean;
  published_at?: string;
  created_at: string;
  updated_at: string;
}

export interface NewsCategory {
  id: string;
  name: string;
  description?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}