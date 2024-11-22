import React, { useState, useEffect } from 'react';
import { Layout } from '../components/Layout';
import { CourseManager } from '../components/admin/CourseManager';
import { UserManager } from '../components/admin/UserManager';
import { Layers, Users } from 'lucide-react';

type Tab = 'courses' | 'users';

function AdminPanel() {
  const [activeTab, setActiveTab] = useState<Tab>('courses');

  return (
    <Layout title="Admin Panel">
      <div className="bg-white shadow rounded-lg">
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex" aria-label="Tabs">
            <button
              onClick={() => setActiveTab('courses')}
              className={`${
                activeTab === 'courses'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              } flex items-center w-1/2 py-4 px-1 border-b-2 font-medium text-sm`}
            >
              <Layers className="w-5 h-5 mr-2" />
              Courses & Lessons
            </button>
            <button
              onClick={() => setActiveTab('users')}
              className={`${
                activeTab === 'users'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              } flex items-center w-1/2 py-4 px-1 border-b-2 font-medium text-sm`}
            >
              <Users className="w-5 h-5 mr-2" />
              Users
            </button>
          </nav>
        </div>
        <div className="p-6">
          {activeTab === 'courses' ? <CourseManager /> : <UserManager />}
        </div>
      </div>
    </Layout>
  );
}

export default AdminPanel;