import React from 'react';
import { DndContext, DragEndEvent, DragOverlay, useSensor, useSensors, PointerSensor } from '@dnd-kit/core';
import { SortableContext, horizontalListSortingStrategy } from '@dnd-kit/sortable';
import { PipelineColumn } from './PipelineColumn';
import { PipelineCard } from './PipelineCard';
import { usePipelineStore } from '../../store/pipelineStore';
import { useAutoAnimate } from '@formkit/auto-animate/react';

interface PipelineBoardProps {
  pipelineId: string;
}

export function PipelineBoard({ pipelineId }: PipelineBoardProps) {
  const { stages, cards, loading, moveCard } = usePipelineStore();
  const [parent] = useAutoAnimate();
  const [activeId, setActiveId] = React.useState<string | null>(null);

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    })
  );

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    
    if (!over) return;

    const cardId = active.id as string;
    const toStageId = over.id as string;
    
    // Calculate new order
    const stageCards = cards.filter(c => c.stage_id === toStageId);
    const newOrder = stageCards.length + 1;

    moveCard(cardId, toStageId, newOrder);
    setActiveId(null);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <DndContext 
      sensors={sensors}
      onDragStart={({ active }) => setActiveId(active.id as string)}
      onDragEnd={handleDragEnd}
    >
      <div 
        ref={parent}
        className="h-full overflow-x-auto"
      >
        <div className="inline-flex h-full items-start p-4 space-x-4">
          <SortableContext 
            items={stages.map(s => s.id)} 
            strategy={horizontalListSortingStrategy}
          >
            {stages.map(stage => {
              const stageCards = cards.filter(card => card.stage_id === stage.id);
              
              return (
                <PipelineColumn 
                  key={stage.id} 
                  id={stage.id}
                  title={stage.name}
                  description={stage.description}
                  color={stage.color}
                  count={stageCards.length}
                >
                  {stageCards.map(card => (
                    <PipelineCard
                      key={card.id}
                      id={card.id}
                      title={card.title}
                      description={card.description}
                      data={card.data}
                      assignedTo={card.assigned_to}
                      dueDate={card.due_date}
                      priority={card.priority}
                      labels={card.labels}
                    />
                  ))}
                </PipelineColumn>
              );
            })}
          </SortableContext>
        </div>
      </div>

      <DragOverlay>
        {activeId ? (
          <div className="transform rotate-3 opacity-50">
            <PipelineCard
              {...cards.find(c => c.id === activeId)!}
            />
          </div>
        ) : null}
      </DragOverlay>
    </DndContext>
  );
}