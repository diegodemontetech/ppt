import React from 'react';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { Plus } from 'lucide-react';

interface PipelineColumnProps {
  id: string;
  title: string;
  description?: string;
  color: string;
  count: number;
  children: React.ReactNode;
  onAddCard?: () => void;
}

export function PipelineColumn({
  id,
  title,
  description,
  color,
  count,
  children,
  onAddCard
}: PipelineColumnProps) {
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
        <div className="flex items-center justify-between">
          <div>
            <h3 className="font-medium text-gray-900">{title}</h3>
            {description && (
              <p className="mt-1 text-sm text-gray-500">{description}</p>
            )}
          </div>
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
            {count}
          </span>
        </div>
      </div>

      <div className="flex-1 p-2 space-y-2 overflow-y-auto">
        {children}
      </div>

      {onAddCard && (
        <button
          onClick={onAddCard}
          className="m-2 p-2 flex items-center justify-center text-sm text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-md"
        >
          <Plus className="w-4 h-4 mr-1" />
          Adicionar Card
        </button>
      )}
    </div>
  );
}