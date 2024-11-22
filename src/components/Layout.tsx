import React from 'react';
import { Link } from 'react-router-dom';
import { LogOut, Bell } from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { useNotifications } from '../store/notificationStore';
import { UniversalSearch } from './UniversalSearch';
import Sidebar from './Sidebar';

interface LayoutProps {
  children: React.ReactNode;
  title?: string;
}

export function Layout({ children, title }: LayoutProps) {
  const { signOut } = useAuthStore();
  const { notifications, unreadCount, markAsRead } = useNotifications();

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar />
      
      <div className="flex-1 flex flex-col overflow-hidden">
        <header className="bg-white shadow-sm h-16 flex items-center px-4 lg:px-6">
          <div className="flex-1 flex items-center justify-between">
            <div className="flex-1 max-w-2xl">
              <UniversalSearch />
            </div>

            <div className="flex items-center space-x-4 ml-4">
              {/* Notifications Dropdown */}
              <div className="relative">
                <button
                  className="relative p-2 text-gray-400 hover:text-gray-500 focus:outline-none"
                  onClick={() => {
                    const dropdown = document.getElementById('notifications-dropdown');
                    if (dropdown) {
                      dropdown.classList.toggle('hidden');
                    }
                  }}
                >
                  <Bell className="h-5 w-5" />
                  {unreadCount > 0 && (
                    <span className="absolute top-0 right-0 block h-4 w-4 rounded-full bg-red-500 text-white text-xs font-medium flex items-center justify-center transform -translate-y-1/2 translate-x-1/2">
                      {unreadCount}
                    </span>
                  )}
                </button>

                {/* Notifications Dropdown Panel */}
                <div
                  id="notifications-dropdown"
                  className="hidden absolute right-0 mt-2 w-80 bg-white rounded-lg shadow-lg border border-gray-200 z-50"
                >
                  <div className="p-4">
                    <div className="flex justify-between items-center mb-4">
                      <h3 className="text-sm font-medium text-gray-900">Notificações</h3>
                      {unreadCount > 0 && (
                        <button
                          onClick={() => markAsRead()}
                          className="text-xs text-red-600 hover:text-red-700"
                        >
                          Marcar todas como lidas
                        </button>
                      )}
                    </div>

                    <div className="space-y-3 max-h-96 overflow-y-auto">
                      {notifications.length === 0 ? (
                        <p className="text-sm text-gray-500 text-center py-4">
                          Nenhuma notificação
                        </p>
                      ) : (
                        notifications.slice(0, 5).map((notification) => (
                          <div
                            key={notification.id}
                            className={`p-3 rounded-lg ${
                              !notification.read ? 'bg-red-50' : 'bg-gray-50'
                            }`}
                          >
                            <h4 className="text-sm font-medium text-gray-900">
                              {notification.title}
                            </h4>
                            <p className="mt-1 text-xs text-gray-500">
                              {notification.message}
                            </p>
                          </div>
                        ))
                      )}
                    </div>

                    {notifications.length > 5 && (
                      <div className="mt-4 pt-3 border-t">
                        <Link
                          to="/notifications"
                          className="text-sm text-red-600 hover:text-red-700"
                        >
                          Ver todas as notificações
                        </Link>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              <button
                onClick={() => signOut()}
                className="inline-flex items-center px-3 py-1.5 text-sm text-gray-700 hover:text-gray-900"
              >
                <LogOut className="h-4 w-4 mr-2" />
                <span className="hidden sm:inline">Sair</span>
              </button>
            </div>
          </div>
        </header>

        <main className="flex-1 overflow-y-auto bg-gray-50">
          <div className="max-w-[2000px] mx-auto py-6 px-4 sm:px-6 lg:px-8">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}