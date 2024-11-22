import React from 'react';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';

interface KanbanColumnProps {
  id: string;
  title: string;
  description?: string;
  color: string;
  children: React.ReactNode;
}

export function KanbanColumn({ id, title, description, color, children }: KanbanColumnProps) {
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
      className="flex flex-col w-80 bg-gray-50 rounded-lg"
      {...attributes}
      {...listeners}
    >
      <div 
        className="p-4 border-b-2"
        style={{ borderColor: color }}
      >
        <h3 className="font-medium text-gray-900">{title}</h3>
        {description && (
          <p className="mt-1 text-sm text-gray-500">{description}</p>
        )}
      </div>

      <div className="flex-1 p-2 space-y-2 overflow-y-auto">
        {children}
      </div>
    </div>
  );
}