import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { 
  Home, 
  BookOpen, 
  Video, 
  KanbanSquare, 
  FileBox,
  Settings,
  FileSignature,
  FolderArchive,
  HelpCircle
} from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { cn } from '../lib/utils';

export default function Sidebar() {
  const location = useLocation();
  const { user, isAdmin } = useAuthStore();

  const menuItems = [
    { icon: Home, label: 'Início', path: '/' },
    { icon: BookOpen, label: 'Meus Cursos', path: '/courses' },
    { icon: BookOpen, label: 'E-Books', path: '/ebooks' },
    { icon: Video, label: 'Transmissão ao Vivo', path: '/live' },
    { icon: KanbanSquare, label: 'Pipelines', path: '/pipelines' },
    { icon: FileBox, label: 'MídiaBox', path: '/marketing-box' },
    { icon: FolderArchive, label: 'DocBox', path: '/docbox' },
    { icon: FileSignature, label: 'E-Sign', path: '/esign' },
    { icon: HelpCircle, label: 'Suporte', path: '/support' }
  ];

  return (
    <div className="w-64 bg-white border-r border-gray-200">
      <div className="flex flex-col h-full">
        <div className="flex items-center justify-center h-14 border-b border-gray-200">
          <img 
            src="https://i.ibb.co/1zxnNry/download.png" 
            alt="Logo" 
            className="h-8 w-auto object-contain"
            crossOrigin="anonymous"
          />
        </div>

        <nav className="flex-1 p-4 space-y-1">
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

          {isAdmin && (
            <Link
              to="/admin"
              className={`flex items-center px-4 py-3 text-sm font-medium rounded-lg ${
                location.pathname.startsWith('/admin')
                  ? 'bg-blue-50 text-blue-700'
                  : 'text-gray-700 hover:bg-gray-50'
              }`}
            >
              <Settings className="w-5 h-5 mr-3" />
              Administração
            </Link>
          )}
        </nav>

        {user && (
          <div className="p-4 border-t border-gray-200">
            <Link to="/profile" className="flex items-center space-x-3">
              <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center">
                <span className="text-gray-600 font-medium">
                  {user.user_metadata?.full_name?.[0] || user.email?.[0]?.toUpperCase() || 'U'}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-900 truncate">
                  {user.user_metadata?.full_name || user.email}
                </p>
                <p className="text-xs text-gray-500">
                  {isAdmin ? 'Administrador' : 'Usuário'}
                </p>
              </div>
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}