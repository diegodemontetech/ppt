import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Plus, Edit, Trash2, Building } from 'lucide-react';
import { supabase } from '../../../lib/supabase';
import { ImageUploader } from '../../../components/admin/ImageUploader';
import { uploadImage } from '../../../lib/storage';
import toast from 'react-hot-toast';

export default function CompanySettings() {
  const [companies, setCompanies] = useState([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState({
    name: '',
    cnpj: '',
    email: '',
    subdomain: '',
    address: '',
    max_users: 10,
    logo_url: '',
    favicon_url: '',
    login_bg_url: '',
    is_active: true
  });
  const [isEditing, setIsEditing] = useState(false);
  const [selectedCompany, setSelectedCompany] = useState(null);

  useEffect(() => {
    fetchCompanies();
  }, []);

  const fetchCompanies = async () => {
    try {
      const { data, error } = await supabase
        .from('companies')
        .select('*')
        .order('name');

      if (error) throw error;
      setCompanies(data || []);
    } catch (error) {
      console.error('Error fetching companies:', error);
      toast.error('Erro ao carregar empresas');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setLoading(true);

      // Validate subdomain format
      const subdomainRegex = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
      if (!subdomainRegex.test(formData.subdomain)) {
        toast.error('Subdomínio inválido. Use apenas letras minúsculas, números e hífens.');
        return;
      }

      if (isEditing && selectedCompany) {
        const { error } = await supabase
          .from('companies')
          .update(formData)
          .eq('id', selectedCompany.id);

        if (error) throw error;
        toast.success('Empresa atualizada com sucesso!');
      } else {
        const { error } = await supabase
          .from('companies')
          .insert([formData]);

        if (error) throw error;
        toast.success('Empresa criada com sucesso!');
      }

      setFormData({
        name: '',
        cnpj: '',
        email: '',
        subdomain: '',
        address: '',
        max_users: 10,
        logo_url: '',
        favicon_url: '',
        login_bg_url: '',
        is_active: true
      });
      setIsEditing(false);
      setSelectedCompany(null);
      fetchCompanies();
    } catch (error) {
      console.error('Error saving company:', error);
      toast.error('Erro ao salvar empresa');
    } finally {
      setLoading(false);
    }
  };

  const handleImageUpload = async (file: File, type: 'logo' | 'favicon' | 'login_bg') => {
    try {
      setLoading(true);
      const imageUrl = await uploadImage(file);
      setFormData(prev => ({
        ...prev,
        [`${type}_url`]: imageUrl
      }));
      toast.success(`${type === 'login_bg' ? 'Background' : type.charAt(0).toUpperCase() + type.slice(1)} enviado com sucesso!`);
    } catch (error) {
      console.error(`Error uploading ${type}:`, error);
      toast.error(`Erro ao enviar ${type === 'login_bg' ? 'background' : type}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            Gerenciar Empresas
          </h1>
          <button
            onClick={() => {
              setFormData({
                name: '',
                cnpj: '',
                email: '',
                subdomain: '',
                address: '',
                max_users: 10,
                logo_url: '',
                favicon_url: '',
                login_bg_url: '',
                is_active: true
              });
              setIsEditing(false);
              setSelectedCompany(null);
            }}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
          >
            <Plus className="w-4 h-4 mr-2" />
            Nova Empresa
          </button>
        </div>

        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                    Nome da Empresa
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
                  <label htmlFor="cnpj" className="block text-sm font-medium text-gray-700">
                    CNPJ
                  </label>
                  <input
                    type="text"
                    id="cnpj"
                    value={formData.cnpj}
                    onChange={(e) => setFormData({ ...formData, cnpj: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    required
                  />
                </div>

                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                    Email
                  </label>
                  <input
                    type="email"
                    id="email"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    required
                  />
                </div>

                <div>
                  <label htmlFor="subdomain" className="block text-sm font-medium text-gray-700">
                    Subdomínio
                  </label>
                  <div className="mt-1 flex rounded-md shadow-sm">
                    <input
                      type="text"
                      id="subdomain"
                      value={formData.subdomain}
                      onChange={(e) => setFormData({ ...formData, subdomain: e.target.value.toLowerCase() })}
                      className="flex-1 min-w-0 block w-full rounded-none rounded-l-md border-gray-300 focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                      required
                      pattern="[a-z0-9]+(?:-[a-z0-9]+)*"
                      title="Use apenas letras minúsculas, números e hífens"
                    />
                    <span className="inline-flex items-center px-3 rounded-r-md border border-l-0 border-gray-300 bg-gray-50 text-gray-500 sm:text-sm">
                      .seudominio.com.br
                    </span>
                  </div>
                  <p className="mt-1 text-xs text-gray-500">
                    Exemplo: minhaempresa (resultará em minhaempresa.seudominio.com.br)
                  </p>
                </div>

                <div>
                  <label htmlFor="address" className="block text-sm font-medium text-gray-700">
                    Endereço
                  </label>
                  <input
                    type="text"
                    id="address"
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label htmlFor="max_users" className="block text-sm font-medium text-gray-700">
                    Máximo de Usuários
                  </label>
                  <input
                    type="number"
                    id="max_users"
                    value={formData.max_users}
                    onChange={(e) => setFormData({ ...formData, max_users: parseInt(e.target.value) })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    min="1"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Logo
                </label>
                <ImageUploader onUpload={(file) => handleImageUpload(file, 'logo')} />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Favicon
                </label>
                <ImageUploader onUpload={(file) => handleImageUpload(file, 'favicon')} />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Background da Tela de Login
                </label>
                <ImageUploader onUpload={(file) => handleImageUpload(file, 'login_bg')} />
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
                  Empresa ativa
                </label>
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setFormData({
                      name: '',
                      cnpj: '',
                      email: '',
                      subdomain: '',
                      address: '',
                      max_users: 10,
                      logo_url: '',
                      favicon_url: '',
                      login_bg_url: '',
                      is_active: true
                    });
                    setIsEditing(false);
                    setSelectedCompany(null);
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
                  {loading ? 'Salvando...' : isEditing ? 'Atualizar' : 'Criar Empresa'}
                </button>
              </div>
            </form>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-4">
              Empresas Cadastradas
            </h2>

            <div className="space-y-4">
              {companies.map((company) => (
                <div
                  key={company.id}
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                >
                  <div>
                    <h3 className="text-sm font-medium text-gray-900">
                      {company.name}
                    </h3>
                    <p className="text-sm text-gray-500 mt-1">
                      {company.subdomain}.seudominio.com.br
                    </p>
                    <div className="mt-2 flex items-center space-x-2">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        company.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                      }`}>
                        {company.is_active ? 'Ativa' : 'Inativa'}
                      </span>
                      <span className="text-xs text-gray-500">
                        {company.max_users} usuários
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => {
                        setSelectedCompany(company);
                        setFormData({
                          name: company.name,
                          cnpj: company.cnpj,
                          email: company.email,
                          subdomain: company.subdomain,
                          address: company.address || '',
                          max_users: company.max_users,
                          logo_url: company.logo_url || '',
                          favicon_url: company.favicon_url || '',
                          login_bg_url: company.login_bg_url || '',
                          is_active: company.is_active
                        });
                        setIsEditing(true);
                      }}
                      className="p-2 text-gray-400 hover:text-gray-500"
                    >
                      <Edit className="w-5 h-5" />
                    </button>
                    <button
                      onClick={async () => {
                        if (window.confirm('Tem certeza que deseja excluir esta empresa?')) {
                          try {
                            const { error } = await supabase
                              .from('companies')
                              .delete()
                              .eq('id', company.id);

                            if (error) throw error;
                            toast.success('Empresa excluída com sucesso!');
                            fetchCompanies();
                          } catch (error) {
                            console.error('Error deleting company:', error);
                            toast.error('Erro ao excluir empresa');
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