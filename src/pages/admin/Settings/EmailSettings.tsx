import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Plus, Edit, Trash2, Mail, Send } from 'lucide-react';
import { useEmailStore } from '../../../store/emailStore';
import { RichTextEditor } from '../../../components/RichTextEditor';
import toast from 'react-hot-toast';

export default function EmailSettings() {
  const { 
    configurations, 
    templates, 
    loading, 
    fetchConfigurations, 
    fetchTemplates,
    createConfiguration,
    updateConfiguration,
    createTemplate,
    updateTemplate,
    deleteTemplate,
    sendTestEmail
  } = useEmailStore();

  const [configFormData, setConfigFormData] = useState({
    purpose: '',
    from_name: '',
    from_email: '',
    reply_to: '',
    smtp_host: '',
    smtp_port: 587,
    smtp_user: '',
    smtp_pass: ''
  });

  const [templateFormData, setTemplateFormData] = useState({
    purpose: '',
    name: '',
    subject: '',
    content: '',
    variables: []
  });

  const [isEditingConfig, setIsEditingConfig] = useState(false);
  const [selectedConfig, setSelectedConfig] = useState(null);
  const [isEditingTemplate, setIsEditingTemplate] = useState(false);
  const [selectedTemplate, setSelectedTemplate] = useState(null);

  useEffect(() => {
    fetchConfigurations();
    fetchTemplates();
  }, []);

  const handleConfigSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      if (isEditingConfig && selectedConfig) {
        await updateConfiguration(selectedConfig.id, configFormData);
      } else {
        await createConfiguration(configFormData);
      }

      setConfigFormData({
        purpose: '',
        from_name: '',
        from_email: '',
        reply_to: '',
        smtp_host: '',
        smtp_port: 587,
        smtp_user: '',
        smtp_pass: ''
      });
      setIsEditingConfig(false);
      setSelectedConfig(null);
    } catch (error) {
      console.error('Error saving configuration:', error);
    }
  };

  const handleTemplateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      if (isEditingTemplate && selectedTemplate) {
        await updateTemplate(selectedTemplate.id, templateFormData);
      } else {
        await createTemplate(templateFormData);
      }

      setTemplateFormData({
        purpose: '',
        name: '',
        subject: '',
        content: '',
        variables: []
      });
      setIsEditingTemplate(false);
      setSelectedTemplate(null);
    } catch (error) {
      console.error('Error saving template:', error);
    }
  };

  return (
    <SettingsLayout>
      <div className="space-y-6">
        {/* Email Configurations */}
        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-6">
              Configurações de Email
            </h2>

            <form onSubmit={handleConfigSubmit} className="space-y-6">
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <label htmlFor="purpose" className="block text-sm font-medium text-gray-700">
                    Finalidade
                  </label>
                  <select
                    id="purpose"
                    value={configFormData.purpose}
                    onChange={(e) => setConfigFormData({ ...configFormData, purpose: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    required
                  >
                    <option value="">Selecione uma finalidade</option>
                    <option value="contracts">Contratos</option>
                    <option value="notifications">Notificações</option>
                    <option value="marketing">Marketing</option>
                    <option value="support">Suporte</option>
                    <option value="billing">Financeiro</option>
                  </select>
                </div>

                <div>
                  <label htmlFor="from_name" className="block text-sm font-medium text-gray-700">
                    Nome do Remetente
                  </label>
                  <input
                    type="text"
                    id="from_name"
                    value={configFormData.from_name}
                    onChange={(e) => setConfigFormData({ ...configFormData, from_name: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    required
                  />
                </div>

                <div>
                  <label htmlFor="from_email" className="block text-sm font-medium text-gray-700">
                    Email do Remetente
                  </label>
                  <input
                    type="email"
                    id="from_email"
                    value={configFormData.from_email}
                    onChange={(e) => setConfigFormData({ ...configFormData, from_email: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    required
                  />
                </div>

                <div>
                  <label htmlFor="reply_to" className="block text-sm font-medium text-gray-700">
                    Responder Para (opcional)
                  </label>
                  <input
                    type="email"
                    id="reply_to"
                    value={configFormData.reply_to}
                    onChange={(e) => setConfigFormData({ ...configFormData, reply_to: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label htmlFor="smtp_host" className="block text-sm font-medium text-gray-700">
                    Servidor SMTP
                  </label>
                  <input
                    type="text"
                    id="smtp_host"
                    value={configFormData.smtp_host}
                    onChange={(e) => setConfigFormData({ ...configFormData, smtp_host: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    required
                  />
                </div>

                <div>
                  <label htmlFor="smtp_port" className="block text-sm font-medium text-gray-700">
                    Porta SMTP
                  </label>
                  <input
                    type="number"
                    id="smtp_port"
                    value={configFormData.smtp_port}
                    onChange={(e) => setConfigFormData({ ...configFormData, smtp_port: parseInt(e.target.value) })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    required
                  />
                </div>

                <div>
                  <label htmlFor="smtp_user" className="block text-sm font-medium text-gray-700">
                    Usuário SMTP
                  </label>
                  <input
                    type="text"
                    id="smtp_user"
                    value={configFormData.smtp_user}
                    onChange={(e) => setConfigFormData({ ...configFormData, smtp_user: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    required
                  />
                </div>

                <div>
                  <label htmlFor="smtp_pass" className="block text-sm font-medium text-gray-700">
                    Senha SMTP
                  </label>
                  <input
                    type="password"
                    id="smtp_pass"
                    value={configFormData.smtp_pass}
                    onChange={(e) => setConfigFormData({ ...configFormData, smtp_pass: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    required
                  />
                </div>
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setConfigFormData({
                      purpose: '',
                      from_name: '',
                      from_email: '',
                      reply_to: '',
                      smtp_host: '',
                      smtp_port: 587,
                      smtp_user: '',
                      smtp_pass: ''
                    });
                    setIsEditingConfig(false);
                    setSelectedConfig(null);
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
                  {loading ? 'Salvando...' : isEditingConfig ? 'Atualizar' : 'Criar Configuração'}
                </button>
              </div>
            </form>
          </div>
        </div>

        {/* Email Templates */}
        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-lg font-medium text-gray-900">
                Templates de Email
              </h2>
              <button
                onClick={() => {
                  setTemplateFormData({
                    purpose: '',
                    name: '',
                    subject: '',
                    content: '',
                    variables: []
                  });
                  setIsEditingTemplate(false);
                  setSelectedTemplate(null);
                }}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
              >
                <Plus className="w-4 h-4 mr-2" />
                Novo Template
              </button>
            </div>

            <form onSubmit={handleTemplateSubmit} className="space-y-6">
              <div>
                <label htmlFor="template_purpose" className="block text-sm font-medium text-gray-700">
                  Finalidade
                </label>
                <select
                  id="template_purpose"
                  value={templateFormData.purpose}
                  onChange={(e) => setTemplateFormData({ ...templateFormData, purpose: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                >
                  <option value="">Selecione uma finalidade</option>
                  <option value="contracts">Contratos</option>
                  <option value="notifications">Notificações</option>
                  <option value="marketing">Marketing</option>
                  <option value="support">Suporte</option>
                  <option value="billing">Financeiro</option>
                </select>
              </div>

              <div>
                <label htmlFor="template_name" className="block text-sm font-medium text-gray-700">
                  Nome do Template
                </label>
                <input
                  type="text"
                  id="template_name"
                  value={templateFormData.name}
                  onChange={(e) => setTemplateFormData({ ...templateFormData, name: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label htmlFor="template_subject" className="block text-sm font-medium text-gray-700">
                  Assunto
                </label>
                <input
                  type="text"
                  id="template_subject"
                  value={templateFormData.subject}
                  onChange={(e) => setTemplateFormData({ ...templateFormData, subject: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label htmlFor="template_content" className="block text-sm font-medium text-gray-700">
                  Conteúdo
                </label>
                <RichTextEditor
                  value={templateFormData.content}
                  onChange={(value) => setTemplateFormData({ ...templateFormData, content: value })}
                />
                <p className="mt-2 text-sm text-gray-500">
                  Use {{variável}} para inserir variáveis dinâmicas.
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Variáveis Disponíveis
                </label>
                <div className="mt-2 space-x-2">
                  {templateFormData.variables.map((variable, index) => (
                    <span
                      key={index}
                      className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                    >
                      {variable}
                      <button
                        type="button"
                        onClick={() => {
                          const newVariables = [...templateFormData.variables];
                          newVariables.splice(index, 1);
                          setTemplateFormData({ ...templateFormData, variables: newVariables });
                        }}
                        className="ml-1 text-blue-600 hover:text-blue-500"
                      >
                        ×
                      </button>
                    </span>
                  ))}
                  <button
                    type="button"
                    onClick={() => {
                      const variable = prompt('Digite o nome da variável:');
                      if (variable) {
                        setTemplateFormData({
                          ...templateFormData,
                          variables: [...templateFormData.variables, variable]
                        });
                      }
                    }}
                    className="inline-flex items-center px-2 py-1 border border-gray-300 rounded-md text-xs font-medium text-gray-700 bg-white hover:bg-gray-50"
                  >
                    <Plus className="w-3 h-3 mr-1" />
                    Adicionar Variável
                  </button>
                </div>
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setTemplateFormData({
                      purpose: '',
                      name: '',
                      subject: '',
                      content: '',
                      variables: []
                    });
                    setIsEditingTemplate(false);
                    setSelectedTemplate(null);
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
                  {loading ? 'Salvando...' : isEditingTemplate ? 'Atualizar' : 'Criar Template'}
                </button>
               </button>
              </div>
            </form>
          </div>
        </div>

        {/* Templates List */}
        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">
              Templates Cadastrados
            </h2>

            <div className="space-y-4">
              {templates.map((template) => (
                <div
                  key={template.id}
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                >
                  <div>
                    <h3 className="text-sm font-medium text-gray-900">
                      {template.name}
                    </h3>
                    <p className="text-sm text-gray-500 mt-1">
                      {template.subject}
                    </p>
                    <div className="mt-2">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                        {template.purpose}
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => {
                        const email = prompt('Digite o email para teste:');
                        if (email) {
                          sendTestEmail(template.id, email);
                        }
                      }}
                      className="p-2 text-gray-400 hover:text-blue-500"
                    >
                      <Send className="w-5 h-5" />
                    </button>
                    <button
                      onClick={() => {
                        setSelectedTemplate(template);
                        setTemplateFormData({
                          purpose: template.purpose,
                          name: template.name,
                          subject: template.subject,
                          content: template.content,
                          variables: template.variables
                        });
                        setIsEditingTemplate(true);
                      }}
                      className="p-2 text-gray-400 hover:text-gray-500"
                    >
                      <Edit className="w-5 h-5" />
                    </button>
                    <button
                      onClick={async () => {
                        if (window.confirm('Tem certeza que deseja excluir este template?')) {
                          await deleteTemplate(template.id);
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