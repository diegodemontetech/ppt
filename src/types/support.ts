export interface SupportDepartment {
  id: string;
  company_id: string;
  name: string;
  description?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface SupportReason {
  id: string;
  department_id: string;
  name: string;
  description?: string;
  sla_response: number;
  sla_resolution: number;
  priority: 'urgent' | 'medium' | 'low';
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface SupportTicket {
  id: string;
  company_id: string;
  department_id: string;
  reason_id: string;
  created_by: string;
  assigned_to?: string;
  title: string;
  description: string;
  status: 'open' | 'in_progress' | 'partially_resolved' | 'resolved' | 'finished' | 'deleted';
  priority: 'urgent' | 'medium' | 'low';
  sla_response_at?: string;
  sla_resolution_at?: string;
  responded_at?: string;
  resolved_at?: string;
  finished_at?: string;
  deleted_at?: string;
  deletion_reason?: string;
  created_at: string;
  updated_at: string;
}

export interface SupportTicketComment {
  id: string;
  ticket_id: string;
  user_id: string;
  content: string;
  created_at: string;
  updated_at: string;
}

export interface SupportTicketAttachment {
  id: string;
  ticket_id: string;
  user_id: string;
  file_url: string;
  file_name: string;
  file_type: string;
  file_size: number;
  created_at: string;
}

export interface SupportTicketHistory {
  id: string;
  ticket_id: string;
  user_id: string;
  action: string;
  details: Record<string, any>;
  created_at: string;
}