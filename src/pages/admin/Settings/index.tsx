import React from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../../../components/ui/Tabs';
import CoursesSettings from './CoursesSettings';
import CategoriesSettings from './CategoriesSettings';
import UsersSettings from './UsersSettings';
import LiveEventsSettings from './LiveEventsSettings';
import LiveRecordingsSettings from './LiveRecordingsSettings';
import SupportSettings from './SupportSettings';

export default function Settings() {
  return (
    <SettingsLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">
            Configurações do Sistema
          </h1>
          <p className="mt-1 text-sm text-gray-500">
            Gerencie todos os aspectos da plataforma
          </p>
        </div>

        <Tabs defaultValue="courses" className="space-y-6">
          <TabsList>
            <TabsTrigger value="courses">Cursos e Aulas</TabsTrigger>
            <TabsTrigger value="categories">Categorias</TabsTrigger>
            <TabsTrigger value="users">Usuários</TabsTrigger>
            <TabsTrigger value="live">Aulas ao Vivo</TabsTrigger>
            <TabsTrigger value="recordings">Gravações</TabsTrigger>
            <TabsTrigger value="support">Suporte</TabsTrigger>
          </TabsList>

          <TabsContent value="courses">
            <CoursesSettings />
          </TabsContent>

          <TabsContent value="categories">
            <CategoriesSettings />
          </TabsContent>

          <TabsContent value="users">
            <UsersSettings />
          </TabsContent>

          <TabsContent value="live">
            <LiveEventsSettings />
          </TabsContent>

          <TabsContent value="recordings">
            <LiveRecordingsSettings />
          </TabsContent>

          <TabsContent value="support">
            <SupportSettings />
          </TabsContent>
        </Tabs>
      </div>
    </SettingsLayout>
  );
}