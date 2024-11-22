import React, { useState, useEffect } from 'react';
import { SettingsLayout } from '../../../components/admin/Settings/SettingsLayout';
import { Plus, Edit, Trash2 } from 'lucide-react';
import { useUserGroupStore } from '../../../store/userGroupStore';
import { useModuleStore } from '../../../store/moduleStore';
import toast from 'react-hot-toast';

export default function GroupsSettings() {
  const { groups, loading, createGroup, updateGroup, deleteGroup } = useUserGroupStore();
  const { modules, fetchModules } = useModuleStore();
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    permissions: [] as string[],
    modules: [] as string[]
  });
  const [isEditing, setIsEditing] = useState(false);
  const [selectedGroup, setSelectedGroup] = useState<any>(null);

  useEffect(() => {
    fetchModules();
  }, [fetchModules]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      // Verificar grupos com mesma autonomia
      const existingGroup = groups.find(group => 
        group.id !== selectedGroup?.id &&
        JSON.stringify(group.permissions.sort()) === JSON.stringify(formData.permissions.sort())
      );

      if (existingGroup) {
        const useExisting = window.confirm(
          `Já existe um grupo "${existingGroup.name}" com as mesmas permissões. Deseja utilizá-lo ao invés de criar um novo?`
        );
        
        if (useExisting) {
          return;
        }
      }

      if (isEditing && selectedGroup) {
        await updateGroup(
          selectedGroup.id,
          formData.name,
          formData.description,
          formData.permissions,
          formData.modules
        );
      } else {
        await createGroup(
          formData.name,
          formData.description,
          formData.permissions,
          formData.modules
        );
      }

      setFormData({
        name: '',
        description: '',
        permissions: [],
        modules: []
      });
      setIsEditing(false);
      setSelectedGroup(null);
    } catch (error) {
      console.error('Error saving group:', error);
      toast.error('Erro ao salvar grupo');
    }
  };

  return (
    <SettingsLayout>
      {/* Rest of the component JSX */}
    </SettingsLayout>
  );
}