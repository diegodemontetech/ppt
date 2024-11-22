import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Plus, Edit, Trash2, KanbanSquare, Settings } from 'lucide-react';
import { supabase } from '../../../lib/supabase';
import { usePipelineStore } from '../../../store/pipelineStore';
import toast from 'react-hot-toast';

export default function PipelinesSettings() {
  const { pipelines, loading, createPipeline, updatePipeline, deletePipeline } = usePipelineStore();
  const [departments, setDepartments] = useState([]);
  const [showStages, setShowStages] = useState(false);
  const [showFields, setShowFields] = useState(false);
  const [selectedPipeline, setSelectedPipeline] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    department_id: '',
    icon: '',
    color: '#3B82F6',
    is_active: true
  });

  // Stage form data
  const [stageData, setStageData] = useState({
    name: '',
    description: '',
    color: '#3B82F6',
    order_num: 1,
    sla_hours: null
  });

  // Field form data
  const [fieldData, setFieldData] = useState({
    name: '',
    label: '',
    type: 'text',
    mask: '',
    options: [],
    validation_rules: {
      required: false,
      min: null,
      max: null,
      regex: ''
    },
    show_on_card: false,
    order_num: 1
  });

  useEffect(() => {
    fetchDepartments();
  }, []);

  const fetchDepartments = async () => {
    try {
      const { data, error } = await supabase
        .from('departments')
        .select('*')
        .order('name');

      if (error) throw error;
      setDepartments(data || []);
    } catch (error) {
      console.error('Error fetching departments:', error);
      toast.error('Erro ao carregar departamentos');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      if (selectedPipeline) {
        await updatePipeline(selectedPipeline.id, formData);
      } else {
        await createPipeline(formData);
      }

      setFormData({
        name: '',
        description: '',
        department_id: '',
        icon: '',
        color: '#3B82F6',
        is_active: true
      });
      setSelectedPipeline(null);
    } catch (error) {
      console.error('Error saving pipeline:', error);
      toast.error('Erro ao salvar pipeline');
    }
  };

  const handleStageSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      const { data, error } = await supabase
        .from('pipeline_stages')
        .insert([{
          ...stageData,
          pipeline_id: selectedPipeline.id
        }]);

      if (error) throw error;

      setStageData({
        name: '',
        description: '',
        color: '#3B82F6',
        order_num: 1,
        sla_hours: null
      });

      toast.success('Fase criada com sucesso!');
    } catch (error) {
      console.error('Error creating stage:', error);
      toast.error('Erro ao criar fase');
    }
  };

  const handleFieldSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      const { data, error } = await supabase
        .from('pipeline_fields')
        .insert([{
          ...fieldData,
          pipeline_id: selectedPipeline.id
        }]);

      if (error) throw error;

      setFieldData({
        name: '',
        label: '',
        type: 'text',
        mask: '',
        options: [],
        validation_rules: {
          required: false,
          min: null,
          max: null,
          regex: ''
        },
        show_on_card: false,
        order_num: 1
      });

      toast.success('Campo criado com sucesso!');
    } catch (error) {
      console.error('Error creating field:', error);
      toast.error('Erro ao criar campo');
    }
  };

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            Gerenciar Pipelines
          </h1>
          <button
            onClick={() => {
              setFormData({
                name: '',
                description: '',
                department_id: '',
                icon: '',
                color: '#3B82F6',
                is_active: true
              });
              setSelectedPipeline(null);
              setShowStages(false);
              setShowFields(false);
            }}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
          >
            <Plus className="w-4 h-4 mr-2" />
            Novo Pipeline
          </button>
        </div>

        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                    Nome do Pipeline
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
                <label htmlFor="color" className="block text-sm font-medium text-gray-700">
                  Cor do Pipeline
                </label>
                <div className="mt-1 flex items-center space-x-2">
                  <input
                    type="color"
                    id="color"
                    value={formData.color}
                    onChange={(e) => setFormData({ ...formData, color: e.target.value })}
                    className="h-8 w-8 rounded-md border border-gray-300"
                  />
                  <input
                    type="text"
                    value={formData.color}
                    onChange={(e) => setFormData({ ...formData, color: e.target.value })}
                    className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    pattern="^#[0-9A-Fa-f]{6}$"
                    required
                  />
                </div>
              </div>

              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="is_active"
                  checked={formData.is_active}
                  onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label htmlFor="is_active" className="ml-2 block text-sm text-gray-900">
                  Pipeline ativo
                </label>
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setFormData({
                      name: '',
                      description: '',
                      department_id: '',
                      icon: '',
                      color: '#3B82F6',
                      is_active: true
                    });
                    setSelectedPipeline(null);
                    setShowStages(false);
                    setShowFields(false);
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
                  {loading ? 'Salvando...' : selectedPipeline ? 'Atualizar' : 'Criar Pipeline'}
                </button>
              </div>
            </form>
          </div>
        </div>

        {selectedPipeline && (
          <>
            {/* Pipeline Stages */}
            <div className="bg-white shadow rounded-lg overflow-hidden">
              <div className="p-6">
                <div className="flex justify-between items-center mb-6">
                  <h2 className="text-lg font-medium text-gray-900">
                    Fases do Pipeline
                  </h2>
                  <button
                    onClick={() => setShowStages(!showStages)}
                    className="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                  >
                    <Plus className="w-4 h-4 mr-2" />
                    Nova Fase
                  </button>
                </div>

                {showStages && (
                  <form onSubmit={handleStageSubmit} className="space-y-6">
                    <div className="grid grid-cols-2 gap-6">
                      <div>
                        <label htmlFor="stage_name" className="block text-sm font-medium text-gray-700">
                          Nome da Fase
                        </label>
                        <input
                          type="text"
                          id="stage_name"
                          value={stageData.name}
                          onChange={(e) => setStageData({ ...stageData, name: e.target.value })}
                          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                          required
                        />
                      </div>

                      <div>
                        <label htmlFor="stage_color" className="block text-sm font-medium text-gray-700">
                          Cor da Fase
                        </label>
                        <input
                          type="color"
                          id="stage_color"
                          value={stageData.color}
                          onChange={(e) => setStageData({ ...stageData, color: e.target.value })}
                          className="mt-1 block w-full h-10 rounded-md border-gray-300"
                        />
                      </div>
                    </div>

                    <div>
                      <label htmlFor="stage_description" className="block text-sm font-medium text-gray-700">
                        Descrição
                      </label>
                      <textarea
                        id="stage_description"
                        value={stageData.description}
                        onChange={(e) => setStageData({ ...stageData, description: e.target.value })}
                        rows={3}
                        className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                      />
                    </div>

                    <div>
                      <label htmlFor="sla_hours" className="block text-sm font-medium text-gray-700">
                        SLA (horas)
                      </label>
                      <input
                        type="number"
                        id="sla_hours"
                        value={stageData.sla_hours || ''}
                        onChange={(e) => setStageData({ ...stageData, sla_hours: parseInt(e.target.value) })}
                        className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                        min="1"
                      />
                    </div>

                    <div className="flex justify-end">
                      <button
                        type="submit"
                        className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                      >
                        Adicionar Fase
                      </button>
                    </div>
                  </form>
                )}
              </div>
            </div>

            {/* Pipeline Fields */}
            <div className="bg-white shadow rounded-lg overflow-hidden">
              <div className="p-6">
                <div className="flex justify-between items-center mb-6">
                  <h2 className="text-lg font-medium text-gray-900">
                    Campos do Pipeline
                  </h2>
                  <button
                    onClick={() => setShowFields(!showFields)}
                    className="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                  >
                    <Plus className="w-4 h-4 mr-2" />
                    Novo Campo
                  </button>
                </div>

                {showFields && (
                  <form onSubmit={handleFieldSubmit} className="space-y-6">
                    <div className="grid grid-cols-2 gap-6">
                      <div>
                        <label htmlFor="field_name" className="block text-sm font-medium text-gray-700">
                          Nome do Campo
                        </label>
                        <input
                          type="text"
                          id="field_name"
                          value={fieldData.name}
                          onChange={(e) => setFieldData({ ...fieldData, name: e.target.value })}
                          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                          required
                        />
                      </div>

                      <div>
                        <label htmlFor="field_label" className="block text-sm font-medium text-gray-700">
                          Label
                        </label>
                        <input
                          type="text"
                          id="field_label"
                          value={fieldData.label}
                          onChange={(e) => setFieldData({ ...fieldData, label: e.target.value })}
                          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                          required
                        />
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-6">
                      <div>
                        <label htmlFor="field_type" className="block text-sm font-medium text-gray-700">
                          Tipo do Campo
                        </label>
                        <select
                          id="field_type"
                          value={fieldData.type}
                          onChange={(e) => setFieldData({ ...fieldData, type: e.target.value })}
                          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                          required
                        >
                          <option value="text">Texto</option>
                          <option value="textarea">Área de Texto</option>
                          <option value="number">Número</option>
                          <option value="date">Data</option>
                          <option value="select">Seleção</option>
                          <option value="multiselect">Múltipla Seleção</option>
                          <option value="file">Arquivo</option>
                        </select>
                      </div>

                      <div>
                        <label htmlFor="field_mask" className="block text-sm font-medium text-gray-700">
                          Máscara
                        </label>
                        <select
                          id="field_mask"
                          value={fieldData.mask}
                          onChange={(e) => setFieldData({ ...fieldData, mask: e.target.value })}
                          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                        >
                          <option value="">Sem máscara</option>
                          <option value="cpf">CPF</option>
                          <option value="cnpj">CNPJ</option>
                          <option value="phone">Telefone</option>
                          <option value="plate">Placa</option>
                          <option value="cep">CEP</option>
                        </select>
                      </div>
                    </div>

                    {(fieldData.type === 'select' || fieldData.type === 'multiselect') && (
                      <div>
                        <label htmlFor="field_options" className="block text-sm font-medium text-gray-700">
                          Opções (uma por linha)
                        </label>
                        <textarea
                          id="field_options"
                          value={fieldData.options.join('\n')}
                          onChange={(e) => setFieldData({ 
                            ...fieldData, 
                            options: e.target.value.split('\n').filter(Boolean)
                          })}
                          rows={3}
                          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                          required
                        />
                      </div>
                    )}

                    <div className="space-y-4">
                      <div className="flex items-center">
                        <input
                          type="checkbox"
                          id="field_required"
                          checked={fieldData.validation_rules.required}
                          onChange={(e) => setFieldData({
                            ...fieldData,
                            validation_rules: {
                              ...fieldData.validation_rules,
                              required: e.target.checked
                            }
                          })}
                          className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        />
                        <label htmlFor="field_required" className="ml-2 block text-sm text-gray-900">
                          Campo obrigatório
                        </label>
                      </div>

                      <div className="flex items-center">
                        <input
                          type="checkbox"
                          id="show_on_card"
                          checked={fieldData.show_on_card}
                          onChange={(e) => setFieldData({ ...fieldData, show_on_card: e.target.checked })}
                          className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        />
                        <label htmlFor="show_on_card" className="ml-2 block text-sm text-gray-900">
                          Mostrar no card
                        </label>
                      </div>
                    </div>

                    <div className="flex justify-end">
                      <button
                        type="submit"
                        className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                      >
                        Adicionar Campo
                      </button>
                    </div>
                  </form>
                )}
              </div>
            </div>
          </>
        )}

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">
              Pipelines Cadastrados
            </h2>

            <div className="space-y-4">
              {pipelines.map((pipeline: any) => (
                <div
                  key={pipeline.id}
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                >
                  <div className="flex items-center">
                    <div 
                      className="w-10 h-10 rounded-lg flex items-center justify-center mr-4"
                      style={{ backgroundColor: pipeline.color }}
                    >
                      <KanbanSquare className="w-6 h-6 text-white" />
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-900">
                        {pipeline.name}
                      </h3>
                      {pipeline.description && (
                        <p className="text-sm text-gray-500 mt-1">
                          {pipeline.description}
                        </p>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => {
                        setSelectedPipeline(pipeline);
                        setFormData({
                          name: pipeline.name,
                          description: pipeline.description || '',
                          department_id: pipeline.department_id,
                          icon: pipeline.icon || '',
                          color: pipeline.color,
                          is_active: pipeline.is_active
                        });
                      }}
                      className="p-2 text-gray-400 hover:text-gray-500"
                    >
                      <Settings className="w-5 h-5" />
                    </button>
                    <button
                      onClick={() => {
                        setSelectedPipeline(pipeline);
                        setFormData({
                          name: pipeline.name,
                          description: pipeline.description || '',
                          department_id: pipeline.department_id,
                          icon: pipeline.icon || '',
                          color: pipeline.color,
                          is_active: pipeline.is_active
                        });
                      }}
                      className="p-2 text-gray-400 hover:text-gray-500"
                    >
                      <Edit className="w-5 h-5" />
                    </button>
                    <button
                      onClick={async () => {
                        if (window.confirm('Tem certeza que deseja excluir este pipeline?')) {
                          await deletePipeline(pipeline.id);
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