import React from 'react';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { Clock, User, AlertCircle, MessageSquare, Paperclip } from 'lucide-react';
import type { SupportTicket } from '../../types/support';
import { formatDistanceToNow } from 'date-fns';
import { ptBR } from 'date-fns/locale';

interface SupportCardProps {
  ticket: SupportTicket & {
    department?: { name: string };
    reason?: { name: string };
    creator?: { email: string; full_name: string };
    assignee?: { email: string; full_name: string };
  };
}

export function SupportCard({ ticket }: SupportCardProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging
  } = useSortable({ id: ticket.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgent':
        return 'bg-red-100 text-red-800';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800';
      case 'low':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getSLAStatus = () => {
    const now = new Date();
    const responseAt = ticket.sla_response_at ? new Date(ticket.sla_response_at) : null;
    const resolutionAt = ticket.sla_resolution_at ? new Date(ticket.sla_resolution_at) : null;

    if (ticket.status === 'open' && responseAt && now > responseAt) {
      return 'SLA de resposta ultrapassado';
    }

    if (resolutionAt && now > resolutionAt) {
      return 'SLA de resolução ultrapassado';
    }

    return null;
  };

  const slaStatus = getSLAStatus();

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`bg-white p-4 rounded-lg shadow-sm hover:shadow-md transition-shadow cursor-pointer ${
        slaStatus ? 'border-l-4 border-red-500' : ''
      }`}
      {...attributes}
      {...listeners}
    >
      <div className="space-y-3">
        <div className="flex items-start justify-between">
          <h4 className="text-sm font-medium text-gray-900 line-clamp-2">
            {ticket.title}
          </h4>
          <span className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getPriorityColor(ticket.priority)}`}>
            {ticket.priority}
          </span>
        </div>

        <div className="flex items-center text-xs text-gray-500 space-x-4">
          <div className="flex items-center">
            <Clock className="w-3 h-3 mr-1" />
            {formatDistanceToNow(new Date(ticket.created_at), { 
              addSuffix: true,
              locale: ptBR 
            })}
          </div>

          {ticket.assignee && (
            <div className="flex items-center">
              <User className="w-3 h-3 mr-1" />
              {ticket.assignee.full_name || ticket.assignee.email}
            </div>
          )}
        </div>

        {slaStatus && (
          <div className="flex items-center text-xs text-red-600">
            <AlertCircle className="w-3 h-3 mr-1" />
            {slaStatus}
          </div>
        )}

        <div className="flex items-center justify-between text-xs text-gray-500">
          <div className="flex items-center space-x-2">
            <span className="inline-flex items-center">
              <MessageSquare className="w-3 h-3 mr-1" />
              3
            </span>
            <span className="inline-flex items-center">
              <Paperclip className="w-3 h-3 mr-1" />
              2
            </span>
          </div>

          <div className="flex items-center">
            <span className="inline-flex items-center px-2 py-1 rounded bg-gray-100 text-gray-700">
              {ticket.department?.name}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}