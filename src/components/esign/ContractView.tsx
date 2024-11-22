import React, { useState } from 'react';
import { X, UserPlus, Download, History, MessageSquare, Copy, Check } from 'lucide-react';
import { useESignStore } from '../../store/esignStore';
import { SignatoryList } from './SignatoryList';
import { ContractHistory } from './ContractHistory';
import { ContractComments } from './ContractComments';
import { AddSignatoryModal } from './AddSignatoryModal';
import type { Contract } from '../../types/esign';
import toast from 'react-hot-toast';

interface ContractViewProps {
  contract: Contract;
  onClose: () => void;
}

export function ContractView({ contract, onClose }: ContractViewProps) {
  const { updateContract, addSignatory } = useESignStore();
  const [showSignatoryModal, setShowSignatoryModal] = useState(false);
  const [activeTab, setActiveTab] = useState<'details'|'history'|'comments'>('details');
  const [copiedLinks, setCopiedLinks] = useState<{[key: string]: boolean}>({});

  const handleStatusChange = async () => {
    try {
      await updateContract(contract.id, { status: 'pending_signatures' });
      toast.success('Status do contrato atualizado com sucesso!');
    } catch (error) {
      console.error('Error updating contract:', error);
      toast.error('Erro ao atualizar status do contrato');
    }
  };

  const generateSignatureLink = (signatory: any) => {
    // Use a URL que será válida em produção
    const baseUrl = 'https://seudominio.com.br'; // Substitua pelo seu domínio real
    return `${baseUrl}/sign/${contract.id}/${signatory.sign_token}`;
  };

  const copyToClipboard = (signatoryId: string, link: string) => {
    navigator.clipboard.writeText(link);
    setCopiedLinks(prev => ({ ...prev, [signatoryId]: true }));
    toast.success('Link copiado para a área de transferência!');
    setTimeout(() => {
      setCopiedLinks(prev => ({ ...prev, [signatoryId]: false }));
    }, 3000);
  };

  return (
    <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-6xl max-h-[90vh] overflow-hidden">
        <div className="flex h-full">
          {/* Left panel - Contract content */}
          <div className="flex-1 overflow-y-auto p-6 border-r border-gray-200">
            <div className="flex justify-between items-start mb-6">
              <div>
                <h2 className="text-lg font-medium text-gray-900">
                  {contract.title}
                </h2>
                {contract.description && (
                  <p className="mt-1 text-sm text-gray-500">
                    {contract.description}
                  </p>
                )}
              </div>
              <button
                onClick={onClose}
                className="text-gray-400 hover:text-gray-500"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="prose max-w-none" dangerouslySetInnerHTML={{ __html: contract.content }} />
          </div>

          {/* Right panel - Actions and info */}
          <div className="w-96 flex flex-col">
            {/* Tabs */}
            <div className="flex border-b border-gray-200">
              <button
                onClick={() => setActiveTab('details')}
                className={`flex-1 py-4 px-1 text-center text-sm font-medium ${
                  activeTab === 'details'
                    ? 'border-b-2 border-blue-500 text-blue-600'
                    : 'text-gray-500 hover:text-gray-700'
                }`}
              >
                Detalhes
              </button>
              <button
                onClick={() => setActiveTab('history')}
                className={`flex-1 py-4 px-1 text-center text-sm font-medium ${
                  activeTab === 'history'
                    ? 'border-b-2 border-blue-500 text-blue-600'
                    : 'text-gray-500 hover:text-gray-700'
                }`}
              >
                Histórico
              </button>
              <button
                onClick={() => setActiveTab('comments')}
                className={`flex-1 py-4 px-1 text-center text-sm font-medium ${
                  activeTab === 'comments'
                    ? 'border-b-2 border-blue-500 text-blue-600'
                    : 'text-gray-500 hover:text-gray-700'
                }`}
              >
                Comentários
              </button>
            </div>

            {/* Tab content */}
            <div className="flex-1 overflow-y-auto p-6">
              {activeTab === 'details' && (
                <div className="space-y-6">
                  {/* Actions */}
                  <div className="space-y-3">
                    {contract.status === 'draft' && (
                      <>
                        <button
                          onClick={() => setShowSignatoryModal(true)}
                          className="w-full inline-flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                        >
                          <UserPlus className="w-4 h-4 mr-2" />
                          Adicionar Signatário
                        </button>
                        <button
                          onClick={handleStatusChange}
                          className="w-full inline-flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700"
                        >
                          <History className="w-4 h-4 mr-2" />
                          Iniciar Processo de Assinatura
                        </button>
                      </>
                    )}
                    {contract.status === 'completed' && (
                      <button
                        onClick={() => {/* Handle download */}}
                        className="w-full inline-flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                      >
                        <Download className="w-4 h-4 mr-2" />
                        Download
                      </button>
                    )}
                  </div>

                  {/* Signatories */}
                  <div>
                    <h3 className="text-sm font-medium text-gray-900 mb-3">
                      Signatários
                    </h3>
                    <SignatoryList contractId={contract.id} />
                  </div>

                  {/* Links de Assinatura */}
                  {contract.status !== 'draft' && (
                    <div className="mt-4 space-y-3">
                      <h4 className="text-sm font-medium text-gray-700">
                        Links para Assinatura
                      </h4>
                      {contract.signatories?.map((signatory: any) => (
                        <div key={signatory.id} className="flex items-center justify-between bg-gray-50 p-2 rounded-lg">
                          <div className="flex-1 min-w-0 mr-2">
                            <p className="text-sm text-gray-900 truncate">{signatory.name}</p>
                            <p className="text-xs text-gray-500 truncate">{signatory.email}</p>
                            {signatory.signed_at && (
                              <p className="text-xs text-green-600">
                                Assinado em {new Date(signatory.signed_at).toLocaleString()}
                              </p>
                            )}
                          </div>
                          {!signatory.signed_at && (
                            <button
                              onClick={() => copyToClipboard(signatory.id, generateSignatureLink(signatory))}
                              className="flex-shrink-0 p-2 text-gray-400 hover:text-gray-600"
                              title="Copiar link de assinatura"
                            >
                              {copiedLinks[signatory.id] ? (
                                <Check className="w-5 h-5 text-green-500" />
                              ) : (
                                <Copy className="w-5 h-5" />
                              )}
                            </button>
                          )}
                        </div>
                      ))}
                      <p className="text-xs text-gray-500 mt-2">
                        Copie e envie os links para os signatários por email ou mensagem.
                      </p>
                    </div>
                  )}
                </div>
              )}

              {activeTab === 'history' && (
                <ContractHistory contractId={contract.id} />
              )}

              {activeTab === 'comments' && (
                <ContractComments contractId={contract.id} />
              )}
            </div>
          </div>
        </div>
      </div>

      {showSignatoryModal && (
        <AddSignatoryModal
          contractId={contract.id}
          onClose={() => setShowSignatoryModal(false)}
        />
      )}
    </div>
  );
}