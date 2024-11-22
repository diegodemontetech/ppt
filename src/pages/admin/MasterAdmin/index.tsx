import React from 'react';
import { Layout } from '../../../components/Layout';
import { Building, Users, Settings } from 'lucide-react';
import { Link } from 'react-router-dom';

export default function MasterAdmin() {
  return (
    <Layout title="Master Admin">
      <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
          <Link
            to="/admin/master/companies"
            className="bg-white overflow-hidden shadow rounded-lg hover:shadow-md transition-shadow"
          >
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <Building className="h-6 w-6 text-gray-400" />
                </div>
                <div className="ml-5">
                  <h3 className="text-lg font-medium text-gray-900">Empresas</h3>
                  <p className="text-sm text-gray-500">
                    Gerenciar empresas e configurações
                  </p>
                </div>
              </div>
            </div>
          </Link>

          <Link
            to="/admin/master/users"
            className="bg-white overflow-hidden shadow rounded-lg hover:shadow-md transition-shadow"
          >
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <Users className="h-6 w-6 text-gray-400" />
                </div>
                <div className="ml-5">
                  <h3 className="text-lg font-medium text-gray-900">Usuários</h3>
                  <p className="text-sm text-gray-500">
                    Gerenciar usuários do sistema
                  </p>
                </div>
              </div>
            </div>
          </Link>

          <Link
            to="/admin/master/settings"
            className="bg-white overflow-hidden shadow rounded-lg hover:shadow-md transition-shadow"
          >
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <Settings className="h-6 w-6 text-gray-400" />
                </div>
                <div className="ml-5">
                  <h3 className="text-lg font-medium text-gray-900">Configurações</h3>
                  <p className="text-sm text-gray-500">
                    Configurações globais do sistema
                  </p>
                </div>
              </div>
            </div>
          </Link>
        </div>
      </div>
    </Layout>
  );
}