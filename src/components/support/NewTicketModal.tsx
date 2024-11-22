import React, { useState, useEffect } from 'react';
import { X } from 'lucide-react';
import { useSupportStore } from '../../store/supportStore';
import { RichTextEditor } from '../RichTextEditor';
import { FileUploader } from '../FileUploader';
import toast from 'react-hot-toast';

interface NewTicketModalProps {
  onClose: () => void;
  onSuccess: () => void;
}

export function NewTicketModal({ onClose, onSuccess }: NewTicketModalProps) {
  const { departments, reasons, loading, fetchDepartments, fetchReasons, createTicket } = useSupportStore();
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    department_id: '',
    reason_id: '',
    priority: 'medium' as 'urgent' | 'medium' | 'low'
  });
  const [files, setFiles] = useState<File[]>([]);

  useEffect(() => {
    fetchDepartments();
  }, []);

  useEffect(() => {
    if (formData.department_id) {
      fetchReasons(formData.department_id);
    }
  }, [formData.department_id]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      // Create ticket first
      await createTicket(formData);

      // Upload attachments if any
      if (files.length > 0) {
        for (const file of files) {
          await useSupportStore.getState().addAttachment(formData.title, file);
        }
      }

      toast.success('Ticket criado com sucesso!');
      onSuccess();
    } catch (error) {
      console.error('Error creating ticket:', error);
      toast.error('Erro ao criar ticket');
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-lg font-medium text-gray-900">
              Novo Ticket
            </h2>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-500"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="grid grid-cols-2 gap-6">
              <div>
                <label htmlFor="department" className="block text-sm font-medium text-gray-700">
                  Departamento
                </label>
                <select
                  id="department"
                  value={formData.department_id}
                  onChange={(e) => setFormData({ ...formData, department_id: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                >
                  <option value="">Selecione um departamento</option>
                  {departments.map(dept => (
                    <option key={dept.id} value={dept.id}>
                      {dept.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label htmlFor="reason" className="block text-sm font-medium text-gray-700">
                  Motivo
                </label>
                <select
                  id="reason"
                  value={formData.reason_id}
                  onChange={(e) => setFormData({ ...formData, reason_id: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                  disabled={!formData.department_id}
                >
                  <option value="">Selecione um motivo</option>
                  {reasons.map(reason => (
                    <option key={reason.id} value={reason.id}>
                      {reason.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

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
              <RichTextEditor
                value={formData.description}
                onChange={(value) => setFormData({ ...formData, description: value })}
              />
            </div>

            <div>
              <label htmlFor="priority" className="block text-sm font-medium text-gray-700">
                Prioridade
              </label>
              <select
                id="priority"
                value={formData.priority}
                onChange={(e) => setFormData({ ...formData, priority: e.target.value as any })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                required
              >
                <option value="urgent">Urgente</option>
                <option value="medium">Médio</option>
                <option value="low">Baixo</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">
                Anexos
              </label>
              <FileUploader
                onUpload={(file) => setFiles(prev => [...prev, file])}
                maxSize={10 * 1024 * 1024} // 10MB
                accept={{
                  'image/*': ['.png', '.jpg', '.jpeg', '.gif'],
                  'application/pdf': ['.pdf'],
                  'application/msword': ['.doc'],
                  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx']
                }}
              />
              {files.length > 0 && (
                <div className="mt-2 space-y-2">
                  {files.map((file, index) => (
                    <div key={index} className="flex items-center justify-between p-2 bg-gray-50 rounded-md">
                      <span className="text-sm text-gray-600">{file.name}</span>
                      <button
                        type="button"
                        onClick={() => setFiles(files.filter((_, i) => i !== index))}
                        className="text-red-500 hover:text-red-700"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
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
                {loading ? 'Criando...' : 'Criar Ticket'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}