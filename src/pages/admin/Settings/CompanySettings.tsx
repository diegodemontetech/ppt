import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { ImageUploader } from '../../../components/admin/ImageUploader';
import { uploadImage } from '../../../lib/storage';
import { supabase } from '../../../lib/supabase';
import { useEmailStore } from '../../../store/emailStore';
import toast from 'react-hot-toast';

export default function CompanySettings() {
  const { configurations, fetchConfigurations, createConfiguration, updateConfiguration } = useEmailStore();
  const [loading, setLoading] = useState(true);
  const [company, setCompany] = useState<any>(null);
  const [formData, setFormData] = useState({
    name: '',
    cnpj: '',
    email: '',
    address: '',
    logo_url: '',
    favicon_url: '',
    domain: ''
  });

  useEffect(() => {
    fetchCompany();
    fetchConfigurations();
  }, []);

  const fetchCompany = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user?.company_id) return;

      const { data, error } = await supabase
        .from('companies')
        .select('*')
        .eq('id', user.company_id)
        .single();

      if (error) throw error;
      setCompany(data);
      setFormData({
        name: data.name,
        cnpj: data.cnpj,
        email: data.email,
        address: data.address || '',
        logo_url: data.logo_url || '',
        favicon_url: data.favicon_url || '',
        domain: data.domain || ''
      });
    } catch (error) {
      console.error('Error fetching company:', error);
      toast.error('Erro ao carregar dados da empresa');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setLoading(true);

      // Update company
      const { error: companyError } = await supabase
        .from('companies')
        .update(formData)
        .eq('id', company.id);

      if (companyError) throw companyError;

      // Update email configurations
      const emailPurposes = ['contracts', 'notifications', 'marketing', 'support', 'billing'];
      
      for (const purpose of emailPurposes) {
        const existingConfig = configurations.find(c => c.purpose === purpose);
        const configData = {
          purpose,
          from_name: formData.name,
          from_email: formData.email,
          smtp_host: 'smtp.gmail.com', // Default values
          smtp_port: 587,
          smtp_user: '',
          smtp_pass: ''
        };

        if (existingConfig) {
          await updateConfiguration(existingConfig.id, configData);
        } else {
          await createConfiguration({
            ...configData,
            company_id: company.id
          });
        }
      }

      toast.success('Configurações salvas com sucesso!');
      fetchCompany();
    } catch (error) {
      console.error('Error saving settings:', error);
      toast.error('Erro ao salvar configurações');
    } finally {
      setLoading(false);
    }
  };

  const handleLogoUpload = async (file: File) => {
    try {
      setLoading(true);
      const logoUrl = await uploadImage(file);
      setFormData(prev => ({ ...prev, logo_url: logoUrl }));
      toast.success('Logo enviada com sucesso!');
    } catch (error) {
      console.error('Error uploading logo:', error);
      toast.error('Erro ao enviar logo');
    } finally {
      setLoading(false);
    }
  };

  const handleFaviconUpload = async (file: File) => {
    try {
      setLoading(true);
      const faviconUrl = await uploadImage(file);
      setFormData(prev => ({ ...prev, favicon_url: faviconUrl }));
      toast.success('Favicon enviado com sucesso!');
    } catch (error) {
      console.error('Error uploading favicon:', error);
      toast.error('Erro ao enviar favicon');
    } finally {
      setLoading(false);
    }
  };

  if (!company) {
    return (
      <SettingsLayout>
        <div className="text-center py-12">
          <p className="text-gray-500">Empresa não encontrada</p>
        </div>
      </SettingsLayout>
    );
  }

  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div className="bg-white shadow rounded-lg">
          <div className="p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-6">
              Configurações da Empresa
            </h2>

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
                    Email Principal
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
                  <label htmlFor="domain" className="block text-sm font-medium text-gray-700">
                    Domínio
                  </label>
                  <input
                    type="text"
                    id="domain"
                    value={formData.domain}
                    onChange={(e) => setFormData({ ...formData, domain: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div>
                <label htmlFor="address" className="block text-sm font-medium text-gray-700">
                  Endereço
                </label>
                <textarea
                  id="address"
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  rows={3}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Logo
                </label>
                <ImageUploader onUpload={handleLogoUpload} />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Favicon
                </label>
                <ImageUploader onUpload={handleFaviconUpload} />
              </div>

              <div className="flex justify-end">
                <button
                  type="submit"
                  disabled={loading}
                  className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  {loading ? 'Salvando...' : 'Salvar Configurações'}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </SettingsLayout>
  );
}