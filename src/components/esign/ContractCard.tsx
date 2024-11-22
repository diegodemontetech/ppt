import React from 'react';
import { FileSignature, Download, Trash2, Eye } from 'lucide-react';
import type { Contract } from '../../types/esign';

interface ContractCardProps {
  contract: Contract;
  onView: (contract: Contract) => void;
  onSend: (contract: Contract) => void;
  onDelete: (contract: Contract) => void;
}

export function ContractCard({ contract, onView, onSend, onDelete }: ContractCardProps) {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft':
        return 'bg-gray-100 text-gray-800';
      case 'pending_signatures':
        return 'bg-blue-100 text-blue-800';
      case 'partially_signed':
        return 'bg-yellow-100 text-yellow-800';
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'archived':
        return 'bg-purple-100 text-purple-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'draft':
        return 'Rascunho';
      case 'pending_signatures':
        return 'Aguardando Assinaturas';
      case 'partially_signed':
        return 'Parcialmente Assinado';
      case 'completed':
        return 'Concluído';
      case 'archived':
        return 'Arquivado';
      default:
        return status;
    }
  };

  // Calculate signature progress
  const totalSignatories = contract.signatories?.length || 0;
  const signedCount = contract.signatories?.filter(s => s.signed_at).length || 0;
  const progress = totalSignatories > 0 ? (signedCount / totalSignatories) * 100 : 0;

  return (
    <div className="bg-white rounded-lg shadow-sm overflow-hidden hover:shadow-md transition-shadow">
      <div className="p-6">
        <div className="flex items-start justify-between">
          <div>
            <h3 className="text-lg font-medium text-gray-900">
              {contract.title}
            </h3>
            {contract.description && (
              <p className="mt-1 text-sm text-gray-500">
                {contract.description}
              </p>
            )}
          </div>
          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(contract.status)}`}>
            {getStatusText(contract.status)}
          </span>
        </div>

        {/* Signature Progress */}
        {totalSignatories > 0 && (
          <div className="mt-4">
            <div className="flex justify-between text-xs text-gray-500 mb-1">
              <span>Assinaturas</span>
              <span>{signedCount} de {totalSignatories}</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div 
                className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                style={{ width: `${progress}%` }}
              />
            </div>
          </div>
        )}

        <div className="mt-6 flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <button
              onClick={() => onView(contract)}
              className="inline-flex items-center text-sm text-gray-500 hover:text-gray-700"
            >
              <Eye className="w-4 h-4 mr-1" />
              Visualizar
            </button>
            {contract.status === 'completed' && (
              <button
                onClick={() => {/* Handle download */}}
                className="inline-flex items-center text-sm text-green-600 hover:text-green-700"
              >
                <Download className="w-4 h-4 mr-1" />
                Download
              </button>
            )}
          </div>

          {contract.status === 'draft' && (
            <button
              onClick={() => onDelete(contract)}
              className="text-gray-400 hover:text-red-500"
            >
              <Trash2 className="w-5 h-5" />
            </button>
          )}
        </div>
      </div>
    </div>
  );
}