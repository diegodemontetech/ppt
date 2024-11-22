import React from 'react';
import { Search, Filter } from 'lucide-react';

interface EBookFiltersProps {
  filters: {
    search: string;
    category: string;
    featured: boolean;
  };
  categories: any[];
  onFilterChange: (filters: any) => void;
}

export function EBookFilters({ filters, categories, onFilterChange }: EBookFiltersProps) {
  return (
    <div className="flex items-center space-x-4">
      <div className="flex-1 max-w-xs relative">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
        <input
          type="text"
          value={filters.search}
          onChange={(e) => onFilterChange({ ...filters, search: e.target.value })}
          placeholder="Buscar e-books..."
          className="pl-10 pr-4 py-2 w-full border border-gray-300 rounded-lg focus:ring-red-500 focus:border-red-500"
        />
      </div>

      <select
        value={filters.category}
        onChange={(e) => onFilterChange({ ...filters, category: e.target.value })}
        className="border border-gray-300 rounded-lg px-4 py-2 focus:ring-red-500 focus:border-red-500"
      >
        <option value="">Todas as categorias</option>
        {categories.map(category => (
          <option key={category.id} value={category.id}>
            {category.department.name} - {category.name}
          </option>
        ))}
      </select>

      <label className="flex items-center">
        <input
          type="checkbox"
          checked={filters.featured}
          onChange={(e) => onFilterChange({ ...filters, featured: e.target.checked })}
          className="rounded border-gray-300 text-red-600 focus:ring-red-500"
        />
        <span className="ml-2 text-sm text-gray-600">
          Destaques
        </span>
      </label>
    </div>
  );
}