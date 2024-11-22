export interface MarketingBoxItem {
  id: string;
  title: string;
  description?: string;
  file_url: string;
  thumbnail_url?: string;
  file_type: string;
  media_type: string;
  resolution?: string;
  category: string;
  tags: string[];
  metadata: Record<string, any>;
  downloads: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface MarketingBoxCategory {
  id: string;
  name: string;
  description?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface MarketingBoxDownload {
  id: string;
  item_id: string;
  user_id: string;
  downloaded_at: string;
}