export interface EmailConfiguration {
  id: string;
  company_id: string;
  purpose: string;
  from_name: string;
  from_email: string;
  reply_to?: string;
  smtp_host: string;
  smtp_port: number;
  smtp_user: string;
  smtp_pass: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface EmailTemplate {
  id: string;
  company_id: string;
  purpose: string;
  name: string;
  subject: string;
  content: string;
  variables: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface EmailLog {
  id: string;
  company_id: string;
  template_id: string;
  from_email: string;
  to_email: string;
  subject: string;
  content: string;
  status: 'pending' | 'sent' | 'failed';
  error?: string;
  sent_at?: string;
  created_at: string;
}