import React, { useEffect } from 'react';
import { Layout } from '../components/Layout';
import { Link } from 'react-router-dom';
import { KanbanSquare } from 'lucide-react';
import { usePipelineStore } from '../store/pipelineStore';

export default function PipelinesPage() {
  const { pipelines, loading, fetchPipelines } = usePipelineStore();

  useEffect(() => {
    fetchPipelines();
  }, [fetchPipelines]);

  // Group pipelines by department safely
  const pipelinesByDepartment = pipelines.reduce((acc: any, pipeline: any) => {
    // Skip if pipeline or department is missing
    if (!pipeline?.department?.id) return acc;

    const deptId = pipeline.department.id;
    if (!acc[deptId]) {
      acc[deptId] = {
        name: pipeline.department.name,
        pipelines: []
      };
    }
    acc[deptId].pipelines.push(pipeline);
    return acc;
  }, {});

  if (loading) {
    return (
      <Layout title="Pipelines">
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-red-500"></div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout title="Pipelines">
      <div className="space-y-8">
        {Object.entries(pipelinesByDepartment).map(([deptId, dept]: [string, any]) => (
          <div key={deptId} className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">
              {dept.name}
            </h2>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
              {dept.pipelines.map((pipeline: any) => (
                <Link
                  key={pipeline.id}
                  to={`/pipelines/${pipeline.id}`}
                  className="block group"
                >
                  <div 
                    className="bg-white rounded-lg shadow-sm p-6 hover:shadow-md transition-shadow border-l-4"
                    style={{ borderLeftColor: pipeline.color }}
                  >
                    <div className="flex items-center justify-between mb-4">
                      <div className="flex items-center">
                        <KanbanSquare 
                          className="w-5 h-5 mr-2"
                          style={{ color: pipeline.color }}
                        />
                        <h3 className="font-medium text-gray-900">
                          {pipeline.name}
                        </h3>
                      </div>
                    </div>

                    {pipeline.description && (
                      <p className="text-sm text-gray-500 line-clamp-2">
                        {pipeline.description}
                      </p>
                    )}

                    <div className="mt-4 flex items-center text-xs text-gray-500">
                      <span className="flex items-center">
                        {pipeline.cards_count || 0} cards
                      </span>
                      <span className="mx-2">•</span>
                      <span>
                        {pipeline.stages_count || 0} etapas
                      </span>
                    </div>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        ))}

        {Object.keys(pipelinesByDepartment).length === 0 && (
          <div className="text-center py-12">
            <KanbanSquare className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900">Nenhum pipeline encontrado</h3>
            <p className="mt-2 text-sm text-gray-500">
              Não há pipelines configurados para seus departamentos.
            </p>
          </div>
        )}
      </div>
    </Layout>
  );
}