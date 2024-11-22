import React from 'react';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { Clock, Users, Tag } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { ptBR } from 'date-fns/locale';

interface PipelineCardProps {
  id: string;
  title: string;
  description?: string;
  data: Record<string, any>;
  assignedTo: string[];
  dueDate?: string;
  priority?: 'low' | 'medium' | 'high' | 'urgent';
  labels: string[];
}

export function PipelineCard({ 
  id, 
  title, 
  description,
  data,
  assignedTo,
  dueDate,
  priority,
  labels
}: PipelineCardProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging
  } = useSortable({ id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  const getPriorityColor = () => {
    switch (priority) {
      case 'urgent':
        return 'bg-red-100 text-red-800';
      case 'high':
        return 'bg-orange-100 text-orange-800';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800';
      case 'low':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className="bg-white p-4 rounded-lg shadow-sm hover:shadow-md transition-shadow cursor-pointer"
      {...attributes}
      {...listeners}
    >
      <h4 className="font-medium text-gray-900">{title}</h4>

      {description && (
        <p className="mt-1 text-sm text-gray-500 line-clamp-2">
          {description}
        </p>
      )}

      {/* Display card fields that are marked as show_on_card */}
      {Object.entries(data)
        .filter(([key, value]) => value.show_on_card)
        .map(([key, value]) => (
          <div key={key} className="mt-2">
            <p className="text-xs font-medium text-gray-500">{value.label}</p>
            <p className="text-sm text-gray-900">{value.value}</p>
          </div>
        ))
      }

      <div className="mt-4 flex items-center justify-between text-xs text-gray-500">
        {dueDate && (
          <div className="flex items-center">
            <Clock className="w-3 h-3 mr-1" />
            {formatDistanceToNow(new Date(dueDate), { 
              addSuffix: true,
              locale: ptBR 
            })}
          </div>
        )}

        {assignedTo.length > 0 && (
          <div className="flex items-center">
            <Users className="w-3 h-3 mr-1" />
            {assignedTo.length}
          </div>
        )}
      </div>

      {/* Labels and Priority */}
      <div className="mt-2 flex flex-wrap gap-1">
        {priority && (
          <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${getPriorityColor()}`}>
            {priority}
          </span>
        )}

        {labels.map(label => (
          <span 
            key={label}
            className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800"
          >
            <Tag className="w-3 h-3 mr-1" />
            {label}
          </span>
        ))}
      </div>

      {/* Display assigned users */}
      {assignedTo.length > 0 && (
        <div className="mt-2 flex -space-x-2">
          {assignedTo.map((userId) => (
            <div
              key={userId}
              className="w-6 h-6 rounded-full bg-gray-200 flex items-center justify-center text-xs font-medium text-gray-600 border-2 border-white"
            >
              {userId[0].toUpperCase()}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}