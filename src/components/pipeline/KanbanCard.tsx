import React from 'react';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';

interface KanbanCardProps {
  id: string;
  title: string;
  data: Record<string, any>;
  assignedTo: string[];
}

export function KanbanCard({ id, title, data, assignedTo }: KanbanCardProps) {
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

  return (
    <div
      ref={setNodeRef}
      style={style}
      className="bg-white p-4 rounded-lg shadow-sm hover:shadow-md transition-shadow cursor-pointer"
      {...attributes}
      {...listeners}
    >
      <h4 className="font-medium text-gray-900">{title}</h4>

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

      {/* Display assigned users */}
      {assignedTo.length > 0 && (
        <div className="mt-4 flex -space-x-2">
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