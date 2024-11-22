import React, { useState, useEffect } from 'react';
import { Layout } from '../components/Layout';
import { Plus, FileSignature } from 'lucide-react';
import { useESignStore } from '../store/esignStore';
import { NewContractModal } from '../components/esign/NewContractModal';
import { ContractCard } from '../components/esign/ContractCard';
import { ContractView } from '../components/esign/ContractView';
import { ContractFlow } from '../components/esign/ContractFlow';
import type { Contract } from '../types/esign';
import toast from 'react-hot-toast';

export default function ESignPage() {
  const { contracts, loading, fetchContracts, deleteContract } = useESignStore();
  const [showNewContract, setShowNewContract] = useState(false);
  const [selectedContract, setSelectedContract] = useState<Contract | null>(null);

  useEffect(() => {
    fetchContracts();
  }, []);

  const handleDelete = async (contract: Contract) => {
    if (window.confirm('Tem certeza que deseja excluir este contrato?')) {
      try {
        await deleteContract(contract.id);
        toast.success('Contrato excluído com sucesso!');
      } catch (error) {
        console.error('Error deleting contract:', error);
        toast.error('Erro ao excluir contrato');
      }
    }
  };

  return (
    <Layout title="E-Sign">
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            Contratos
          </h1>
          <button
            onClick={() => setShowNewContract(true)}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
          >
            <Plus className="w-4 h-4 mr-2" />
            Novo Contrato
          </button>
        </div>

        {/* Contract Flow */}
        <ContractFlow contracts={contracts} />

        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
          </div>
        ) : contracts.length === 0 ? (
          <div className="text-center py-12">
            <FileSignature className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900">Nenhum contrato encontrado</h3>
            <p className="mt-2 text-sm text-gray-500">
              Clique no botão acima para criar um novo contrato.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {contracts.map((contract) => (
              <ContractCard
                key={contract.id}
                contract={contract}
                onView={() => setSelectedContract(contract)}
                onSend={() => {/* Handle send */}}
                onDelete={handleDelete}
              />
            ))}
          </div>
        )}

        {showNewContract && (
          <NewContractModal
            onClose={() => setShowNewContract(false)}
            onSuccess={() => {
              setShowNewContract(false);
              fetchContracts();
            }}
          />
        )}

        {selectedContract && (
          <ContractView
            contract={selectedContract}
            onClose={() => setSelectedContract(null)}
          />
        )}
      </div>
    </Layout>
  );
}