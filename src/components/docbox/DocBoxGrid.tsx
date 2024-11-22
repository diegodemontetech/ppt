import React from 'react';
import { Download, FileText } from 'lucide-react';
import type { Document } from '../../types/docbox';

interface DocBoxGridProps {
  documents: Document[];
  selectedItems: string[];
  onSelectItem: (id: string) => void;
}

export function DocBoxGrid({ documents, selectedItems, onSelectItem }: DocBoxGridProps) {
  if (documents.length === 0) {
    return (
      <div className="text-center py-12">
        <FileText className="w-12 h-12 text-gray-400 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-gray-900">Nenhum documento encontrado</h3>
        <p className="mt-2 text-sm text-gray-500">
          Tente ajustar os filtros ou fazer uma nova busca.
        </p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-6">
      {documents.map((document) => (
        <div
          key={document.id}
          className={`relative group bg-white rounded-lg shadow-sm overflow-hidden cursor-pointer hover:shadow-md transition-shadow ${
            selectedItems.includes(document.id) ? 'ring-2 ring-blue-500' : ''
          }`}
          onClick={() => onSelectItem(document.id)}
        >
          <div className="aspect-w-16 aspect-h-9 bg-gray-100">
            <div className="flex items-center justify-center p-4">
              <FileText className={`w-12 h-12 ${getColorByFileType(document.file_type)}`} />
            </div>
          </div>

          <div className="p-4">
            <h3 className="text-sm font-medium text-gray-900 truncate">
              {document.title}
            </h3>
            
            {document.description && (
              <p className="mt-1 text-sm text-gray-500 line-clamp-2">
                {document.description}
              </p>
            )}

            <div className="mt-4 flex items-center justify-between">
              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                {document.file_type}
              </span>
              <span className="text-xs text-gray-500">
                {document.downloads} downloads
              </span>
            </div>

            <div className="mt-4 flex items-center justify-between">
              <span className="text-xs text-gray-500 truncate max-w-[150px]">
                {document.metadata.category}
              </span>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  window.open(document.file_url, '_blank');
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
  );
}

function getColorByFileType(fileType: string): string {
  switch (fileType.toLowerCase()) {
    case 'pdf':
      return 'text-red-500';
    case 'doc':
    case 'docx':
      return 'text-blue-500';
    case 'xls':
    case 'xlsx':
      return 'text-green-500';
    case 'ppt':
    case 'pptx':
      return 'text-orange-500';
    default:
      return 'text-gray-500';
  }
}