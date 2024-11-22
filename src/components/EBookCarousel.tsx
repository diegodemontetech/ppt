import React from 'react';
import { Book, ChevronLeft, ChevronRight } from 'lucide-react';
import { RatingStars } from './RatingStars';

interface EBookCarouselProps {
  title: string;
  ebooks: any[];
  onDownload: (ebook: any) => void;
}

export function EBookCarousel({ title, ebooks, onDownload }: EBookCarouselProps) {
  const scrollLeft = () => {
    const container = document.getElementById(`carousel-${title}`);
    if (container) {
      container.scrollBy({ left: -300, behavior: 'smooth' });
    }
  };

  const scrollRight = () => {
    const container = document.getElementById(`carousel-${title}`);
    if (container) {
      container.scrollBy({ left: 300, behavior: 'smooth' });
    }
  };

  if (ebooks.length === 0) return null;

  return (
    <div className="relative">
      <h2 className="text-lg font-medium text-gray-900 mb-4">{title}</h2>
      
      <div className="relative group">
        <button
          onClick={scrollLeft}
          className="absolute left-0 top-1/2 -translate-y-1/2 z-10 p-2 rounded-full bg-white shadow-lg opacity-0 group-hover:opacity-100 transition-opacity"
        >
          <ChevronLeft className="w-6 h-6 text-gray-600" />
        </button>

        <div
          id={`carousel-${title}`}
          className="flex space-x-6 overflow-x-auto scrollbar-hide pb-4"
          style={{ scrollBehavior: 'smooth' }}
        >
          {ebooks.map((ebook) => (
            <div
              key={ebook.id}
              className="flex-none w-64 bg-white rounded-lg shadow-sm overflow-hidden hover:shadow-md transition-shadow"
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
                <h3 className="font-medium text-gray-900 mb-1 truncate">
                  {ebook.title}
                </h3>
                
                {ebook.subtitle && (
                  <p className="text-sm text-gray-500 mb-2 truncate">
                    {ebook.subtitle}
                  </p>
                )}

                <p className="text-sm text-gray-600 mb-4 truncate">
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
                  Download PDF
                </button>
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
      </div>
    </div>
  );
}