import React from 'react';
import { Book, Download } from 'lucide-react';
import { RatingStars } from './RatingStars';

interface EBookGridProps {
  ebooks: any[];
  onDownload: (ebook: any) => void;
}

export function EBookGrid({ ebooks, onDownload }: EBookGridProps) {
  if (ebooks.length === 0) {
    return (
      <div className="text-center py-12">
        <Book className="w-12 h-12 text-gray-400 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-gray-900">Nenhum e-book encontrado</h3>
        <p className="mt-2 text-sm text-gray-500">
          Tente ajustar os filtros ou fazer uma nova busca.
        </p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {ebooks.map((ebook) => (
        <div
          key={ebook.id}
          className="bg-white rounded-lg shadow-sm overflow-hidden hover:shadow-md transition-shadow"
        >
          <div className="aspect-w-3 aspect-h-4 bg-gray-100">
            {ebook.cover_url ? (
              <img
                src={ebook.cover_url}
                alt={ebook.title}
                className="object-cover"
                crossOrigin="anonymous"
              />
            ) : (
              <div className="flex items-center justify-center">
                <Book className="w-12 h-12 text-gray-400" />
              </div>
            )}
          </div>

          <div className="p-4">
            <h3 className="font-medium text-gray-900 mb-1">
              {ebook.title}
            </h3>
            
            {ebook.subtitle && (
              <p className="text-sm text-gray-500 mb-2">
                {ebook.subtitle}
              </p>
            )}

            <p className="text-sm text-gray-600 mb-4">
              {ebook.author}
            </p>

            <div className="flex items-center justify-between mb-4">
              <RatingStars
                rating={ebook.average_rating || 0}
                totalRatings={ebook.total_ratings || 0}
                size="sm"
              />
              {ebook.is_featured && (
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                  Destaque
                </span>
              )}
            </div>

            <button
              onClick={() => onDownload(ebook)}
              className="w-full flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700"
            >
              <Download className="w-4 h-4 mr-2" />
              Download PDF
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}