export interface Contract {
  id: string;
  title: string;
  description?: string;
  content: string;
  status: 'draft' | 'sent' | 'pending_signatures' | 'partially_signed' | 'completed' | 'archived' | 'deleted';
  metadata: Record<string, any>;
  hash?: string;
  created_by: string;
  created_at: string;
  updated_at: string;
  deleted_at?: string;
}

export interface ContractSignatory {
  id: string;
  contract_id: string;
  user_id?: string;
  email: string;
  name: string;
  role: string;
  order_num: number;
  signature_url?: string;
  signed_at?: string;
  sign_token?: string;
  expires_at?: string;
  created_at: string;
  updated_at: string;
}

export interface ContractHistory {
  id: string;
  contract_id: string;
  user_id: string;
  action: string;
  details: Record<string, any>;
  ip_address?: string;
  user_agent?: string;
  created_at: string;
}

export interface ContractComment {
  id: string;
  contract_id: string;
  user_id: string;
  content: string;
  created_at: string;
  updated_at: string;
}

export interface ContractStatus {
  status: Contract['status'];
  total_signatories: number;
  signed_count: number;
  pending_count: number;
  is_valid: boolean;
}</content>