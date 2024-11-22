import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Plus, Edit, Trash2, Clock } from 'lucide-react';
import { supabase } from '../../../lib/supabase';
import toast from 'react-hot-toast';

export default function SupportSettings() {
  const [departments, setDepartments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    reasons: [{
      name: '',
      description: '',
      sla_response: 60,
      sla_resolution: 240,
      priority: 'medium' as 'urgent' | 'medium' | 'low'
    }]
  });
  const [isEditing, setIsEditing] = useState(false);
  const [selectedDepartment, setSelectedDepartment] = useState(null);

  useEffect(() => {
    fetchDepartments();
  }, []);

  const fetchDepartments = async () => {
    try {
      const { data, error } = await supabase
        .from('support_departments')
        .select(`
          *,
          reasons:support_reasons(*)
        `)
        .order('name');

      if (error) throw error;
      setDepartments(data || []);
    } catch (error) {
      console.error('Error fetching departments:', error);
      toast.error('Erro ao carregar departamentos');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setLoading(true);

      if (isEditing && selectedDepartment) {
        // Update department
        const { error: deptError } = await supabase
          .from('support_departments')
          .update({
            name: formData.name,
            description: formData.description
          })
          .eq('id', selectedDepartment.id);

        if (deptError) throw deptError;

        // Update reasons
        for (const reason of formData.reasons) {
          if (reason.id) {
            const { error } = await supabase
              .from('support_reasons')
              .update(reason)
              .eq('id', reason.id);

            if (error) throw error;
          } else {
            const { error } = await supabase
              .from('support_reasons')
              .insert([{
                ...reason,
                department_id: selectedDepartment.id
              }]);

            if (error) throw error;
          }
        }

        toast.success('Departamento atualizado com sucesso!');
      } else {
        // Create department
        const { data: dept, error: deptError } = await supabase
          .from('support_departments')
          .insert([{
            name: formData.name,
            description: formData.description
          }])
          .select()
          .single();

        if (deptError) throw deptError;

        // Create reasons
        const { error: reasonsError } = await supabase
          .from('support_reasons')
          .insert(
            formData.reasons.map(reason => ({
              ...reason,
              department_id: dept.id
            }))
          );

        if (reasonsError) throw reasonsError;

        toast.success('Departamento criado com sucesso!');
      }

      setFormData({
        name: '',
        description: '',
        reasons: [{
          name: '',
          description: '',
          sla_response: 60,
          sla_resolution: 240,
          priority: 'medium'
        }]
      });
      setIsEditing(false);
      setSelectedDepartment(null);
      fetchDepartments();
    } catch (error) {
      console.error('Error saving department:', error);
      toast.error('Erro ao salvar departamento');
    } finally {
      setLoading(false);
    }
  };

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            Gerenciar Suporte
          </h1>
          <button
            onClick={() => {
              setFormData({
                name: '',
                description: '',
                reasons: [{
                  name: '',
                  description: '',
                  sla_response: 60,
                  sla_resolution: 240,
                  priority: 'medium'
                }]
              });
              setIsEditing(false);
              setSelectedDepartment(null);
            }}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
          >
            <Plus className="w-4 h-4 mr-2" />
            Novo Departamento
          </button>
        </div>

        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                  Nome do Departamento
                </label>
                <input
                  type="text"
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
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
                <h3 className="text-sm font-medium text-gray-700 mb-4">Motivos</h3>
                <div className="space-y-4">
                  {formData.reasons.map((reason, index) => (
                    <div key={index} className="p-4 bg-gray-50 rounded-lg space-y-4">
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <label className="block text-sm font-medium text-gray-700">
                            Nome do Motivo
                          </label>
                          <input
                            type="text"
                            value={reason.name}
                            onChange={(e) => {
                              const newReasons = [...formData.reasons];
                              newReasons[index].name = e.target.value;
                              setFormData({ ...formData, reasons: newReasons });
                            }}
                            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                            required
                          />
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-gray-700">
                            Prioridade
                          </label>
                          <select
                            value={reason.priority}
                            onChange={(e) => {
                              const newReasons = [...formData.reasons];
                              newReasons[index].priority = e.target.value as any;
                              setFormData({ ...formData, reasons: newReasons });
                            }}
                            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                            required
                          >
                            <option value="urgent">Urgente</option>
                            <option value="medium">Médio</option>
                            <option value="low">Baixo</option>
                          </select>
                        </div>
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700">
                          Descrição
                        </label>
                        <textarea
                          value={reason.description}
                          onChange={(e) => {
                            const newReasons = [...formData.reasons];
                            newReasons[index].description = e.target.value;
                            setFormData({ ...formData, reasons: newReasons });
                          }}
                          rows={2}
                          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                        />
                      </div>

                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <label className="block text-sm font-medium text-gray-700">
                            SLA de Resposta (minutos)
                          </label>
                          <input
                            type="number"
                            value={reason.sla_response}
                            onChange={(e) => {
                              const newReasons = [...formData.reasons];
                              newReasons[index].sla_response = parseInt(e.target.value);
                              setFormData({ ...formData, reasons: newReasons });
                            }}
                            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                            required
                            min="1"
                          />
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-gray-700">
                            SLA de Resolução (minutos)
                          </label>
                          <input
                            type="number"
                            value={reason.sla_resolution}
                            onChange={(e) => {
                              const newReasons = [...formData.reasons];
                              newReasons[index].sla_resolution = parseInt(e.target.value);
                              setFormData({ ...formData, reasons: newReasons });
                            }}
                            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                            required
                            min="1"
                          />
                        </div>
                      </div>

                      {formData.reasons.length > 1 && (
                        <button
                          type="button"
                          onClick={() => {
                            const newReasons = [...formData.reasons];
                            newReasons.splice(index, 1);
                            setFormData({ ...formData, reasons: newReasons });
                          }}
                          className="text-red-600 hover:text-red-700 text-sm"
                        >
                          Remover Motivo
                        </button>
                      )}
                    </div>
                  ))}

                  <button
                    type="button"
                    onClick={() => {
                      setFormData({
                        ...formData,
                        reasons: [
                          ...formData.reasons,
                          {
                            name: '',
                            description: '',
                            sla_response: 60,
                            sla_resolution: 240,
                            priority: 'medium'
                          }
                        ]
                      });
                    }}
                    className="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                  >
                    <Plus className="w-4 h-4 mr-2" />
                    Adicionar Motivo
                  </button>
                </div>
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setFormData({
                      name: '',
                      description: '',
                      reasons: [{
                        name: '',
                        description: '',
                        sla_response: 60,
                        sla_resolution: 240,
                        priority: 'medium'
                      }]
                    });
                    setIsEditing(false);
                    setSelectedDepartment(null);
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
                  {loading ? 'Salvando...' : isEditing ? 'Atualizar' : 'Criar Departamento'}
                </button>
              </div>
            </form>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">
              Departamentos Cadastrados
            </h2>

            <div className="space-y-4">
              {departments.map((department: any) => (
                <div
                  key={department.id}
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                >
                  <div>
                    <h3 className="text-sm font-medium text-gray-900">
                      {department.name}
                    </h3>
                    {department.description && (
                      <p className="text-sm text-gray-500 mt-1">
                        {department.description}
                      </p>
                    )}
                    <div className="mt-2 space-x-2">
                      {department.reasons?.map((reason: any) => (
                        <span
                          key={reason.id}
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                            reason.priority === 'urgent'
                              ? 'bg-red-100 text-red-800'
                              : reason.priority === 'medium'
                              ? 'bg-yellow-100 text-yellow-800'
                              : 'bg-green-100 text-green-800'
                          }`}
                        >
                          <Clock className="w-3 h-3 mr-1" />
                          {reason.name} ({reason.sla_resolution}min)
                        </span>
                      ))}
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => {
                        setSelectedDepartment(department);
                        setFormData({
                          name: department.name,
                          description: department.description || '',
                          reasons: department.reasons || [{
                            name: '',
                            description: '',
                            sla_response: 60,
                            sla_resolution: 240,
                            priority: 'medium'
                          }]
                        });
                        setIsEditing(true);
                      }}
                      className="p-2 text-gray-400 hover:text-gray-500"
                    >
                      <Edit className="w-5 h-5" />
                    </button>
                    <button
                      onClick={async () => {
                        if (window.confirm('Tem certeza que deseja excluir este departamento?')) {
                          try {
                            const { error } = await supabase
                              .from('support_departments')
                              .delete()
                              .eq('id', department.id);

                            if (error) throw error;
                            toast.success('Departamento excluído com sucesso!');
                            fetchDepartments();
                          } catch (error) {
                            console.error('Error deleting department:', error);
                            toast.error('Erro ao excluir departamento');
                          }
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