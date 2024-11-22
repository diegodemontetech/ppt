import React, { useState } from 'react';
import { X, HelpCircle } from 'lucide-react';
import { useESignStore } from '../../store/esignStore';
import { RichTextEditor } from '../RichTextEditor';
import toast from 'react-hot-toast';

interface NewContractModalProps {
  onClose: () => void;
  onSuccess: () => void;
}

export function NewContractModal({ onClose, onSuccess }: NewContractModalProps) {
  const { createContract } = useESignStore();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    content: '',
    metadata: {}
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setLoading(true);
      await createContract({
        ...formData,
        status: 'draft'
      });
      onSuccess();
      onClose();
    } catch (error) {
      console.error('Error creating contract:', error);
      toast.error('Erro ao criar contrato');
    } finally {
      setLoading(false);
    }
  };

  const variableExamples = [
    { name: '{{nome}}', description: 'Nome do signatário' },
    { name: '{{email}}', description: 'Email do signatário' },
    { name: '{{funcao}}', description: 'Função/cargo do signatário' }
  ];

  return (
    <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-lg font-medium text-gray-900">
              Novo Contrato
            </h2>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-500"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label htmlFor="title" className="block text-sm font-medium text-gray-700">
                Título
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
              <div className="flex items-center justify-between mb-2">
                <label htmlFor="content" className="block text-sm font-medium text-gray-700">
                  Conteúdo do Contrato
                </label>
                <button
                  type="button"
                  className="inline-flex items-center text-sm text-blue-600 hover:text-blue-700"
                  onClick={() => {
                    const example = `CONTRATO DE PRESTAÇÃO DE SERVIÇOS

CONTRATANTE:
{{nome}}, pessoa física, portador do e-mail {{email}}, na função de {{funcao}}.

CONTRATADA:
[Nome da Empresa], pessoa jurídica...

[Resto do contrato...]`;
                    setFormData(prev => ({ ...prev, content: example }));
                  }}
                >
                  <HelpCircle className="w-4 h-4 mr-1" />
                  Ver Exemplo
                </button>
              </div>
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
                onClick={onClose}
                className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Cancelar
              </button>
              <button
                type="submit"
                disabled={loading}
                className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                {loading ? 'Criando...' : 'Criar Contrato'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}