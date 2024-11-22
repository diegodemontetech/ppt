import React from 'react';
import { useESignStore } from '../../store/esignStore';

interface ContractHistoryProps {
  contractId: string;
}

export function ContractHistory({ contractId }: ContractHistoryProps) {
  const { history } = useESignStore();

  const getActionText = (action: string) => {
    switch (action) {
      case 'created':
        return 'Contrato criado';
      case 'status_changed':
        return 'Status alterado';
      case 'signed':
        return 'Contrato assinado';
      default:
        return action;
    }
  };

  return (
    <div className="space-y-4">
      {history.map((event) => (
        <div key={event.id} className="relative pb-4">
          <div className="flex space-x-3">
            <div>
              <div className="h-8 w-8 rounded-full bg-gray-100 flex items-center justify-center">
                {/* Add icon based on action */}
              </div>
            </div>
            <div className="min-w-0 flex-1">
              <div className="text-sm text-gray-500">
                <span className="font-medium text-gray-900">
                  {getActionText(event.action)}
                </span>
                <span className="ml-2">
                  {new Date(event.created_at).toLocaleString()}
                </span>
              </div>
              {event.details && (
                <div className="mt-2 text-sm text-gray-700">
                  <pre className="whitespace-pre-wrap">
                    {JSON.stringify(event.details, null, 2)}
                  </pre>
                </div>
              )}
            </div>
          </div>
        </div>
      ))}

      {history.length === 0 && (
        <p className="text-sm text-gray-500 text-center py-4">
          Nenhum histórico disponível
        </p>
      )}
    </div>
  );
}