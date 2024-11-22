import React from 'react';
import { Search } from 'lucide-react';
import { useDocBoxStore } from '../../store/docboxStore';

export function DocBoxFilters() {
  const { filters, categories, setFilters } = useDocBoxStore();

  const mainCategories = categories.filter(cat => !cat.parent_id);

  return (
    <div className="flex items-center space-x-4">
      <div className="flex-1 max-w-xs relative">
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <Search className="h-5 w-5 text-gray-400" />
        </div>
        <input
          type="text"
          value={filters.search}
          onChange={(e) => setFilters({ search: e.target.value })}
          placeholder="Buscar documentos..."
          className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
        />
      </div>

      <div className="flex-shrink-0">
        <select
          value={filters.fileType[0] || ''}
          onChange={(e) => setFilters({ fileType: e.target.value ? [e.target.value] : [] })}
          className="block w-40 pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
        >
          <option value="">Todos os tipos</option>
          <option value="PDF">PDF</option>
          <option value="DOC">DOC</option>
          <option value="DOCX">DOCX</option>
          <option value="XLS">XLS</option>
          <option value="XLSX">XLSX</option>
        </select>
      </div>

      <div className="flex-shrink-0">
        <select
          value={filters.category[0] || ''}
          onChange={(e) => setFilters({ category: e.target.value ? [e.target.value] : [] })}
          className="block w-64 pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
        >
          <option value="">Todas as categorias</option>
          {mainCategories.map(category => (
            <optgroup key={category.id} label={category.name}>
              <option value={category.id}>{category.name}</option>
              {categories
                .filter(sub => sub.parent_id === category.id)
                .map(subCategory => (
                  <option key={subCategory.id} value={subCategory.id}>
                    ↳ {subCategory.name}
                  </option>
                ))}
            </optgroup>
          ))}
        </select>
      </div>
    </div>
  );
}