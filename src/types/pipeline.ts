export interface Pipeline {
  id: string;
  department_id: string;
  name: string;
  description?: string;
  icon?: string;
  color: string;
  table_name: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface PipelineStage {
  id: string;
  pipeline_id: string;
  name: string;
  description?: string;
  color: string;
  order_num: number;
  sla_hours?: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface PipelineField {
  id: string;
  pipeline_id: string;
  name: string;
  label: string;
  type: 'text' | 'textarea' | 'number' | 'date' | 'select' | 'multiselect' | 'file' | 'phone' | 'email' | 'cpf' | 'cnpj' | 'cep' | 'money';
  mask?: string;
  options?: any[];
  validation_rules?: {
    required?: boolean;
    min?: number;
    max?: number;
    regex?: string;
  };
  show_on_card: boolean;
  order_num: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface PipelineCard {
  id: string;
  pipeline_id: string;
  stage_id: string;
  title: string;
  description?: string;
  assigned_to: string[];
  data: Record<string, any>;
  order_num: number;
  due_date?: string;
  priority?: 'low' | 'medium' | 'high' | 'urgent';
  labels: string[];
  is_active: boolean;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface PipelineCardHistory {
  id: string;
  card_id: string;
  user_id: string;
  action: string;
  old_data?: Record<string, any>;
  new_data?: Record<string, any>;
  ip_address?: string;
  user_agent?: string;
  created_at: string;
}

export interface PipelineCardComment {
  id: string;
  card_id: string;
  user_id: string;
  content: string;
  attachments: Array<{
    name: string;
    url: string;
    type: string;
  }>;
  created_at: string;
  updated_at: string;
}

export interface PipelineAutomation {
  id: string;
  pipeline_id: string;
  name: string;
  description?: string;
  trigger_type: 'stage_change' | 'field_update' | 'sla_breach' | 'due_date' | 'comment_added' | 'assigned' | 'label_added';
  trigger_config: Record<string, any>;
  action_type: 'notify' | 'update_field' | 'move_stage' | 'assign_user' | 'add_comment' | 'send_email' | 'webhook';
  action_config: Record<string, any>;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface PipelineStats {
  total_cards: number;
  cards_by_stage: Record<string, number>;
  cards_by_priority: Record<string, number>;
  avg_completion_time: string;
  sla_breach_count: number;
}