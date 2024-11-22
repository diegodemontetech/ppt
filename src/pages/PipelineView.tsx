import React, { useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { Layout } from '../components/Layout';
import { DndContext, DragEndEvent } from '@dnd-kit/core';
import { SortableContext, horizontalListSortingStrategy } from '@dnd-kit/sortable';
import { KanbanBoard } from '../components/pipeline/KanbanBoard';
import { KanbanColumn } from '../components/pipeline/KanbanColumn';
import { KanbanCard } from '../components/pipeline/KanbanCard';
import { usePipelineStore } from '../store/pipelineStore';

export default function PipelineView() {
  const { pipelineId } = useParams();
  const { 
    stages, 
    cards, 
    loading, 
    fetchStages, 
    fetchCards, 
    moveCard 
  } = usePipelineStore();

  useEffect(() => {
    if (pipelineId) {
      fetchStages(pipelineId);
      fetchCards(pipelineId);
    }
  }, [pipelineId]);

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    
    if (!over) return;

    const cardId = active.id as string;
    const toStageId = over.id as string;
    
    // Calculate new order
    const stageCards = cards.filter(c => c.stage_id === toStageId);
    const newOrder = stageCards.length + 1;

    moveCard(cardId, toStageId, newOrder);
  };

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-red-500"></div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <DndContext onDragEnd={handleDragEnd}>
        <div className="h-full overflow-x-auto">
          <div className="inline-flex h-full items-start p-4 space-x-4">
            <SortableContext items={stages.map(s => s.id)} strategy={horizontalListSortingStrategy}>
              {stages.map(stage => {
                const stageCards = cards.filter(card => card.stage_id === stage.id);
                
                return (
                  <KanbanColumn 
                    key={stage.id} 
                    id={stage.id}
                    title={stage.name}
                    description={stage.description}
                    color={stage.color}
                  >
                    {stageCards.map(card => (
                      <KanbanCard
                        key={card.id}
                        id={card.id}
                        title={card.title}
                        data={card.data}
                        assignedTo={card.assigned_to}
                      />
                    ))}
                  </KanbanColumn>
                );
              })}
            </SortableContext>
          </div>
        </div>
      </DndContext>
    </Layout>
  );
}