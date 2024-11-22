import React from 'react';
import { Search } from 'lucide-react';
import { useMarketingBoxStore } from '../../store/marketingBoxStore';

export function MarketingBoxFilters() {
  const { filters, categories, setFilters } = useMarketingBoxStore();

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
          placeholder="Buscar arquivos..."
          className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
        />
      </div>

      <div className="flex-shrink-0">
        <select
          value={filters.fileType[0] || ''}
          onChange={(e) => setFilters({ fileType: e.target.value ? [e.target.value] : [] })}
          className="block w-40 pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
        >
          <option value="">Todos os formatos</option>
          <option value="PNG">PNG</option>
          <option value="JPG">JPG</option>
          <option value="MP4">MP4</option>
          <option value="PDF">PDF</option>
        </select>
      </div>

      <div className="flex-shrink-0">
        <select
          value={filters.mediaType[0] || ''}
          onChange={(e) => setFilters({ mediaType: e.target.value ? [e.target.value] : [] })}
          className="block w-40 pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
        >
          <option value="">Todos os tipos</option>
          <option value="Image">Imagem</option>
          <option value="Video">Vídeo</option>
          <option value="Document">Documento</option>
        </select>
      </div>

      <div className="flex-shrink-0">
        <select
          value={filters.resolution[0] || ''}
          onChange={(e) => setFilters({ resolution: e.target.value ? [e.target.value] : [] })}
          className="block w-40 pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
        >
          <option value="">Todas as resoluções</option>
          <option value="HD">HD</option>
          <option value="Full HD">Full HD</option>
          <option value="4K">4K</option>
        </select>
      </div>

      <div className="flex-shrink-0">
        <select
          value={filters.category[0] || ''}
          onChange={(e) => setFilters({ category: e.target.value ? [e.target.value] : [] })}
          className="block w-40 pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
        >
          <option value="">Todas as categorias</option>
          {categories.map(category => (
            <option key={category.id} value={category.id}>
              {category.name}
            </option>
          ))}
        </select>
      </div>
    </div>
  );
}