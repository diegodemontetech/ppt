import React, { ReactNode } from 'react';
import { Layout } from '../../Layout';
import { Book, Users, Building, Layers, Bell, Video, BookOpen, KanbanSquare, FileBox, FileSignature, FolderArchive } from 'lucide-react';
import { Link, useLocation } from 'react-router-dom';

interface SettingsLayoutProps {
  children: ReactNode;
}

const menuItems = [
  { icon: Building, label: 'Departamentos', path: '/admin/settings/departments' },
  { icon: Layers, label: 'Categorias', path: '/admin/settings/categories' },
  { icon: Book, label: 'Cursos e Aulas', path: '/admin/settings/courses' },
  { icon: BookOpen, label: 'E-Books', path: '/admin/settings/ebooks' },
  { icon: Video, label: 'Aulas ao Vivo', path: '/admin/settings/live' },
  { icon: Users, label: 'Usuários', path: '/admin/settings/users' },
  { icon: Bell, label: 'Notificações', path: '/admin/settings/notifications' },
  { icon: KanbanSquare, label: 'Pipelines', path: '/admin/settings/pipelines' },
  { icon: FileBox, label: 'MídiaBox', path: '/admin/settings/marketing-box' },
  { icon: FolderArchive, label: 'DocBox', path: '/admin/settings/docbox' },
  { icon: FileSignature, label: 'E-Sign', path: '/admin/settings/esign' }
];

export function SettingsLayout({ children }: SettingsLayoutProps) {
  const location = useLocation();

  return (
    <Layout title="Configurações">
      <div className="flex min-h-screen bg-gray-50">
        <div className="w-64 bg-white border-r border-gray-200">
          <nav className="p-4 space-y-1">
            {menuItems.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.path;

              return (
                <Link
                  key={item.path}
                  to={item.path}
                  className={`flex items-center px-4 py-3 text-sm font-medium rounded-lg ${
                    isActive
                      ? 'bg-blue-50 text-blue-700'
                      : 'text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <Icon className="w-5 h-5 mr-3" />
                  {item.label}
                </Link>
              );
            })}
          </nav>
        </div>

        <div className="flex-1 p-8">
          {children}
        </div>
      </div>
    </Layout>
  );
}