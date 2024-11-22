import React from 'react';
import { DndContext, DragEndEvent } from '@dnd-kit/core';
import { SortableContext, horizontalListSortingStrategy } from '@dnd-kit/sortable';
import { SupportColumn } from './SupportColumn';
import { SupportCard } from './SupportCard';
import { useSupportStore } from '../../store/supportStore';
import type { SupportTicket } from '../../types/support';

interface SupportKanbanProps {
  tickets: SupportTicket[];
}

export function SupportKanban({ tickets }: SupportKanbanProps) {
  const { updateTicket } = useSupportStore();

  const columns = [
    { id: 'open', title: 'Aberto', color: 'bg-gray-100' },
    { id: 'in_progress', title: 'Em Atendimento', color: 'bg-blue-100' },
    { id: 'partially_resolved', title: 'Resolvido Parcialmente', color: 'bg-yellow-100' },
    { id: 'resolved', title: 'Resolvido', color: 'bg-green-100' },
    { id: 'finished', title: 'Finalizado', color: 'bg-purple-100' },
    { id: 'deleted', title: 'Lixeira', color: 'bg-red-100' }
  ];

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    
    if (!over) return;

    const ticketId = active.id as string;
    const newStatus = over.id as SupportTicket['status'];
    
    updateTicket(ticketId, { status: newStatus });
  };

  return (
    <DndContext onDragEnd={handleDragEnd}>
      <div className="h-full overflow-x-auto">
        <div className="inline-flex h-full items-start p-4 space-x-4">
          <SortableContext items={columns.map(c => c.id)} strategy={horizontalListSortingStrategy}>
            {columns.map(column => {
              const columnTickets = tickets.filter(ticket => ticket.status === column.id);
              
              return (
                <SupportColumn 
                  key={column.id} 
                  id={column.id}
                  title={column.title}
                  color={column.color}
                  count={columnTickets.length}
                >
                  {columnTickets.map(ticket => (
                    <SupportCard
                      key={ticket.id}
                      ticket={ticket}
                    />
                  ))}
                </SupportColumn>
              );
            })}
          </SortableContext>
        </div>
      </div>
    </DndContext>
  );
}