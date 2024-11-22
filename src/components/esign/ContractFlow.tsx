import React from 'react';
import { FileSignature, Send, Clock, CheckCircle, Archive } from 'lucide-react';

interface ContractFlowProps {
  contracts: any[];
}

export function ContractFlow({ contracts }: ContractFlowProps) {
  // Count contracts by status
  const stats = {
    draft: contracts.filter(c => c.status === 'draft').length,
    pending_signatures: contracts.filter(c => c.status === 'pending_signatures').length,
    partially_signed: contracts.filter(c => c.status === 'partially_signed').length,
    completed: contracts.filter(c => c.status === 'completed').length,
    archived: contracts.filter(c => c.status === 'archived').length
  };

  const stages = [
    {
      icon: FileSignature,
      label: 'Rascunhos',
      count: stats.draft,
      color: 'bg-gray-100 text-gray-600'
    },
    {
      icon: Send,
      label: 'Aguardando Assinaturas',
      count: stats.pending_signatures,
      color: 'bg-blue-100 text-blue-600'
    },
    {
      icon: Clock,
      label: 'Parcialmente Assinados',
      count: stats.partially_signed,
      color: 'bg-yellow-100 text-yellow-600'
    },
    {
      icon: CheckCircle,
      label: 'Concluídos',
      count: stats.completed,
      color: 'bg-green-100 text-green-600'
    },
    {
      icon: Archive,
      label: 'Arquivados',
      count: stats.archived,
      color: 'bg-purple-100 text-purple-600'
    }
  ];

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm">
      <h2 className="text-lg font-medium text-gray-900 mb-6">
        Fluxo de Contratos
      </h2>

      <div className="grid grid-cols-5 gap-4">
        {stages.map((stage, index) => (
          <div key={stage.label} className="relative">
            {/* Connector line */}
            {index < stages.length - 1 && (
              <div className="absolute top-1/2 right-0 w-full h-0.5 bg-gray-200 -z-10" />
            )}

            {/* Stage */}
            <div className="relative flex flex-col items-center">
              {/* Icon */}
              <div className={`w-12 h-12 rounded-full ${stage.color} flex items-center justify-center mb-2`}>
                <stage.icon className="w-6 h-6" />
              </div>

              {/* Label */}
              <p className="text-sm font-medium text-gray-900 text-center">
                {stage.label}
              </p>

              {/* Count */}
              {stage.count > 0 && (
                <span className="absolute -top-2 -right-2 flex h-5 w-5 items-center justify-center rounded-full bg-red-600 text-xs font-medium text-white">
                  {stage.count}
                </span>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}