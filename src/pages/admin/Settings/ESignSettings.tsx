import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Plus, Edit, Trash2, FileSignature } from 'lucide-react';
import { useESignStore } from '../../../store/esignStore';
import { RichTextEditor } from '../../../components/RichTextEditor';
import toast from 'react-hot-toast';

const variableExamples = [
  { name: '{{nome}}', description: 'Nome do signatário' },
  { name: '{{email}}', description: 'Email do signatário' },
  { name: '{{funcao}}', description: 'Função/cargo do signatário' }
];

export default function ESignSettings() {
  const { contracts, loading, fetchContracts } = useESignStore();
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    content: '',
    metadata: {}
  });
  const [isEditing, setIsEditing] = useState(false);
  const [selectedContract, setSelectedContract] = useState<any>(null);

  useEffect(() => {
    fetchContracts();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      if (isEditing && selectedContract) {
        await useESignStore.getState().updateContract(selectedContract.id, formData);
        toast.success('Modelo atualizado com sucesso!');
      } else {
        await useESignStore.getState().createContract({
          ...formData,
          status: 'draft'
        });
        toast.success('Modelo criado com sucesso!');
      }

      setFormData({
        title: '',
        description: '',
        content: '',
        metadata: {}
      });
      setIsEditing(false);
      setSelectedContract(null);
      fetchContracts();
    } catch (error) {
      console.error('Error saving contract:', error);
      toast.error('Erro ao salvar modelo');
    }
  };

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            E-Sign
          </h1>
          <button
            onClick={() => {
              setFormData({
                title: '',
                description: '',
                content: '',
                metadata: {}
              });
              setIsEditing(false);
              setSelectedContract(null);
            }}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
          >
            <Plus className="w-4 h-4 mr-2" />
            Novo Modelo
          </button>
        </div>

        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <label htmlFor="title" className="block text-sm font-medium text-gray-700">
                  Título do Modelo
                </label>
                <input
                  type="text"
                  id="title"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label htmlFor="description" className="block text-sm font-medium text-gray-700">
                  Descrição
                </label>
                <textarea
                  id="description"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  rows={3}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>

              <div>
                <label htmlFor="content" className="block text-sm font-medium text-gray-700">
                  Conteúdo do Contrato
                </label>
                <RichTextEditor
                  value={formData.content}
                  onChange={(value) => setFormData({ ...formData, content: value })}
                />
                <div className="mt-2 bg-blue-50 p-4 rounded-md">
                  <p className="text-sm font-medium text-blue-800 mb-2">
                    Variáveis Disponíveis:
                  </p>
                  <ul className="space-y-1">
                    {variableExamples.map(variable => (
                      <li key={variable.name} className="text-sm text-blue-700">
                        <code className="bg-blue-100 px-1 py-0.5 rounded">
                          {variable.name}
                        </code>
                        {' - '}
                        {variable.description}
                      </li>
                    ))}
                  </ul>
                  <p className="mt-2 text-xs text-blue-600">
                    Copie e cole estas variáveis no texto do contrato. Elas serão substituídas automaticamente pelos dados dos signatários.
                  </p>
                </div>
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setFormData({
                      title: '',
                      description: '',
                      content: '',
                      metadata: {}
                    });
                    setIsEditing(false);
                    setSelectedContract(null);
                  }}
                  className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  {loading ? 'Salvando...' : isEditing ? 'Atualizar' : 'Criar Modelo'}
                </button>
              </div>
            </form>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">
              Modelos Cadastrados
            </h2>

            <div className="space-y-4">
              {contracts.map((contract) => (
                <div
                  key={contract.id}
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                >
                  <div>
                    <h3 className="text-sm font-medium text-gray-900">
                      {contract.title}
                    </h3>
                    {contract.description && (
                      <p className="text-sm text-gray-500 mt-1">
                        {contract.description}
                      </p>
                    )}
                  </div>

                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => {
                        setSelectedContract(contract);
                        setFormData({
                          title: contract.title,
                          description: contract.description || '',
                          content: contract.content,
                          metadata: contract.metadata
                        });
                        setIsEditing(true);
                      }}
                      className="p-2 text-gray-400 hover:text-gray-500"
                    >
                      <Edit className="w-5 h-5" />
                    </button>
                    <button
                      onClick={async () => {
                        if (window.confirm('Tem certeza que deseja excluir este modelo?')) {
                          await useESignStore.getState().deleteContract(contract.id);
                          fetchContracts();
                        }
                      }}
                      className="p-2 text-gray-400 hover:text-red-500"
                    >
                      <Trash2 className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </SettingsLayout>
  );
}