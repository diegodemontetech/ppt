import React from 'react';
import { DndContext, DragEndEvent } from '@dnd-kit/core';
import { SortableContext, horizontalListSortingStrategy } from '@dnd-kit/sortable';

interface KanbanBoardProps {
  children: React.ReactNode;
  onDragEnd: (event: DragEndEvent) => void;
}

export function KanbanBoard({ children, onDragEnd }: KanbanBoardProps) {
  return (
    <DndContext onDragEnd={onDragEnd}>
      <div className="h-full overflow-x-auto">
        <div className="inline-flex h-full items-start p-4 space-x-4">
          <SortableContext items={[]} strategy={horizontalListSortingStrategy}>
            {children}
          </SortableContext>
        </div>
      </div>
    </DndContext>
  );
}