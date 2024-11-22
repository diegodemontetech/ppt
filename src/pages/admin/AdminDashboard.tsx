import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Layout } from '../components/Layout';
import { 
  Building, 
  Layers, 
  BookOpen, 
  Video,
  Users,
  Bell,
  KanbanSquare,
  FileBox,
  FolderArchive,
  FileSignature,
  Newspaper,
  Users2,
  Wand2,
  HelpCircle
} from 'lucide-react';

export default function AdminDashboard() {
  const navigate = useNavigate();

  const adminModules = [
    {
      icon: Building,
      name: 'Departamentos',
      description: 'Gerenciar departamentos da empresa',
      path: '/admin/settings/departments',
      color: 'bg-blue-500'
    },
    {
      icon: Layers,
      name: 'Categorias',
      description: 'Gerenciar categorias de conteúdo',
      path: '/admin/settings/categories',
      color: 'bg-purple-500'
    },
    {
      icon: BookOpen,
      name: 'Cursos e Aulas',
      description: 'Gerenciar cursos e conteúdo',
      path: '/admin/settings/courses',
      color: 'bg-green-500'
    },
    {
      icon: BookOpen,
      name: 'E-Books',
      description: 'Gerenciar biblioteca digital',
      path: '/admin/settings/ebooks',
      color: 'bg-yellow-500'
    },
    {
      icon: Video,
      name: 'Transmissão ao Vivo',
      description: 'Gerenciar eventos ao vivo',
      path: '/admin/settings/live',
      color: 'bg-red-500'
    },
    {
      icon: Users,
      name: 'Usuários',
      description: 'Gerenciar usuários do sistema',
      path: '/admin/settings/users',
      color: 'bg-indigo-500'
    },
    {
      icon: Users2,
      name: 'Grupos',
      description: 'Gerenciar grupos e permissões',
      path: '/admin/settings/groups',
      color: 'bg-pink-500'
    },
    {
      icon: Newspaper,
      name: 'Notícias',
      description: 'Gerenciar notícias e comunicados',
      path: '/admin/settings/news',
      color: 'bg-orange-500'
    },
    {
      icon: Bell,
      name: 'Notificações',
      description: 'Gerenciar notificações do sistema',
      path: '/admin/settings/notifications',
      color: 'bg-cyan-500'
    },
    {
      icon: KanbanSquare,
      name: 'Pipelines',
      description: 'Gerenciar pipelines e fluxos',
      path: '/admin/settings/pipelines',
      color: 'bg-teal-500'
    },
    {
      icon: FileBox,
      name: 'MídiaBox',
      description: 'Gerenciar biblioteca de mídia',
      path: '/admin/settings/marketing-box',
      color: 'bg-emerald-500'
    },
    {
      icon: FolderArchive,
      name: 'DocBox',
      description: 'Gerenciar documentos',
      path: '/admin/settings/docbox',
      color: 'bg-rose-500'
    },
    {
      icon: FileSignature,
      name: 'E-Sign',
      description: 'Gerenciar assinaturas digitais',
      path: '/admin/settings/esign',
      color: 'bg-violet-500'
    },
    {
      icon: HelpCircle,
      name: 'Suporte',
      description: 'Gerenciar central de suporte',
      path: '/admin/settings/support',
      color: 'bg-sky-500'
    },
    {
      icon: Wand2,
      name: 'Magic Learning',
      description: 'Geração automática de conteúdo',
      path: '/admin/settings/magic-learning',
      color: 'bg-fuchsia-500'
    }
  ];

  return (
    <Layout>
      <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
        <h1 className="text-2xl font-semibold text-gray-900 mb-6">
          Painel Administrativo
        </h1>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {adminModules.map((module) => {
            const Icon = module.icon;
            
            return (
              <div
                key={module.path}
                onClick={() => navigate(module.path)}
                className="bg-white rounded-lg shadow-sm p-6 hover:shadow-md transition-shadow cursor-pointer"
              >
                <div className="flex items-center space-x-4">
                  <div className={`p-3 rounded-lg ${module.color}`}>
                    <Icon className="w-6 h-6 text-white" />
                  </div>
                  <div>
                    <h3 className="text-lg font-medium text-gray-900">
                      {module.name}
                    </h3>
                    <p className="text-sm text-gray-500 mt-1">
                      {module.description}
                    </p>
                  </div>
                </div> </div>
              </div>
            );
          })}
        </div>
      </div>
    </Layout>
  );
}