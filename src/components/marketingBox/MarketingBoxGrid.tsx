import React from 'react';
import { Download, Image as ImageIcon, Video, FileText, ChevronLeft, ChevronRight } from 'lucide-react';
import type { MarketingBoxItem } from '../../types/marketingBox';

interface MarketingBoxGridProps {
  items: MarketingBoxItem[];
  selectedItems: string[];
  onSelectItem: (id: string) => void;
}

export function MarketingBoxGrid({ items, selectedItems, onSelectItem }: MarketingBoxGridProps) {
  const scrollLeft = () => {
    const container = document.getElementById('marketing-box-grid');
    if (container) {
      container.scrollBy({ left: -container.offsetWidth, behavior: 'smooth' });
    }
  };

  const scrollRight = () => {
    const container = document.getElementById('marketing-box-grid');
    if (container) {
      container.scrollBy({ left: container.offsetWidth, behavior: 'smooth' });
    }
  };

  const getIcon = (mediaType: string) => {
    switch (mediaType.toLowerCase()) {
      case 'image':
        return <ImageIcon className="w-6 h-6" />;
      case 'video':
        return <Video className="w-6 h-6" />;
      default:
        return <FileText className="w-6 h-6" />;
    }
  };

  if (items.length === 0) {
    return (
      <div className="text-center py-12">
        <FileText className="w-12 h-12 text-gray-400 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-gray-900">Nenhum item encontrado</h3>
        <p className="mt-2 text-sm text-gray-500">
          Tente ajustar os filtros ou fazer uma nova busca.
        </p>
      </div>
    );
  }

  return (
    <div className="relative">
      <button
        onClick={scrollLeft}
        className="absolute left-0 top-1/2 -translate-y-1/2 z-10 p-2 rounded-full bg-white shadow-lg opacity-0 group-hover:opacity-100 transition-opacity"
      >
        <ChevronLeft className="w-6 h-6 text-gray-600" />
      </button>

      <div
        id="marketing-box-grid"
        className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-6 overflow-x-auto scrollbar-hide pb-4"
        style={{ scrollBehavior: 'smooth' }}
      >
        {items.map((item) => (
          <div
            key={item.id}
            className={`relative group bg-white rounded-lg shadow-sm overflow-hidden cursor-pointer hover:shadow-md transition-shadow ${
              selectedItems.includes(item.id) ? 'ring-2 ring-blue-500' : ''
            }`}
            onClick={() => onSelectItem(item.id)}
          >
            <div className="aspect-w-1 aspect-h-1 bg-gray-100">
              {item.thumbnail_url ? (
                <img
                  src={item.thumbnail_url}
                  alt={item.title}
                  className="object-cover w-full h-full"
                  crossOrigin="anonymous"
                />
              ) : (
                <div className="flex items-center justify-center">
                  {getIcon(item.media_type)}
                </div>
              )}
            </div>

            <div className="p-4">
              <h3 className="text-sm font-medium text-gray-900 truncate">
                {item.title}
              </h3>

              <div className="mt-4 flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800">
                    {item.file_type}
                  </span>
                  {item.resolution && (
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                      {item.resolution}
                    </span>
                  )}
                </div>
                <span className="text-xs text-gray-500">
                  {item.downloads} downloads
                </span>
              </div>

              <div className="mt-4 flex items-center justify-between">
                <span className="text-xs text-gray-500">
                  {item.category}
                </span>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    window.open(item.file_url, '_blank');
                  }}
                  className="p-1 text-gray-400 hover:text-gray-500"
                >
                  <Download className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      <button
        onClick={scrollRight}
        className="absolute right-0 top-1/2 -translate-y-1/2 z-10 p-2 rounded-full bg-white shadow-lg opacity-0 group-hover:opacity-100 transition-opacity"
      >
        <ChevronRight className="w-6 h-6 text-gray-600" />
      </button>

      {selectedItems.length > 0 && (
        <div className="fixed bottom-4 right-4 z-50">
          <button
            onClick={() => {/* Handle bulk download */}}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
          >
            <Download className="w-4 h-4 mr-2" />
            Download ({selectedItems.length})
          </button>
        </div>
      )}
    </div>
  );
}