export interface DocCategory {
  id: string;
  name: string;
  description?: string;
  parent_id?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Document {
  id: string;
  title: string;
  description?: string;
  category_id: string;
  file_url: string;
  file_type: string;
  metadata: Record<string, any>;
  downloads: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface DocumentDownload {
  id: string;
  document_id: string;
  user_id: string;
  downloaded_at: string;
}