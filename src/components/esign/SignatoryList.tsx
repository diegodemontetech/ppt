import React from 'react';
import { Check, Clock, Trash2 } from 'lucide-react';
import { useESignStore } from '../../store/esignStore';
import type { ContractSignatory } from '../../types/esign';

interface SignatoryListProps {
  contractId: string;
}

export function SignatoryList({ contractId }: SignatoryListProps) {
  const { signatories, removeSignatory } = useESignStore();

  const handleRemove = async (signatory: ContractSignatory) => {
    if (window.confirm('Tem certeza que deseja remover este signatário?')) {
      await removeSignatory(signatory.id);
    }
  };

  return (
    <div className="space-y-3">
      {signatories.map((signatory) => (
        <div
          key={signatory.id}
          className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
        >
          <div>
            <p className="text-sm font-medium text-gray-900">
              {signatory.name}
            </p>
            <p className="text-xs text-gray-500">
              {signatory.email} • {signatory.role}
            </p>
          </div>

          <div className="flex items-center space-x-2">
            {signatory.signed_at ? (
              <span className="inline-flex items-center text-green-600">
                <Check className="w-4 h-4 mr-1" />
                <span className="text-xs">
                  {new Date(signatory.signed_at).toLocaleDateString()}
                </span>
              </span>
            ) : (
              <span className="inline-flex items-center text-yellow-600">
                <Clock className="w-4 h-4 mr-1" />
                <span className="text-xs">Pendente</span>
              </span>
            )}

            {!signatory.signed_at && (
              <button
                onClick={() => handleRemove(signatory)}
                className="text-gray-400 hover:text-red-500"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>
      ))}

      {signatories.length === 0 && (
        <p className="text-sm text-gray-500 text-center py-4">
          Nenhum signatário adicionado
        </p>
      )}
    </div>
  );
}