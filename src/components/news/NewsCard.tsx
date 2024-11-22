import React from 'react';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Star } from 'lucide-react';

interface NewsCardProps {
  article: {
    id: string;
    title: string;
    content: string;
    image_url?: string;
    video_url?: string;
    is_featured?: boolean;
    published_at: string;
  };
}

export function NewsCard({ article }: NewsCardProps) {
  return (
    <div className="bg-white rounded-lg shadow-sm overflow-hidden">
      <div className="flex">
        {article.image_url && (
          <div className="flex-shrink-0 w-48">
            <img
              src={article.image_url}
              alt={article.title}
              className="h-full w-full object-cover"
              crossOrigin="anonymous"
            />
          </div>
        )}
        <div className="flex-1 p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              {article.is_featured && (
                <Star className="w-4 h-4 text-yellow-400 mr-2" />
              )}
              <h3 className="text-base font-medium text-gray-900 font-newsreader">
                {article.title}
              </h3>
            </div>
            <time className="text-xs text-gray-500">
              {format(new Date(article.published_at), "dd 'de' MMMM 'às' HH:mm", {
                locale: ptBR
              })}
            </time>
          </div>

          <div 
            className="mt-2 prose prose-sm max-w-none text-gray-500 font-newsreader"
            dangerouslySetInnerHTML={{ __html: article.content }}
          />

          {article.video_url && (
            <div className="mt-4">
              <iframe
                src={article.video_url}
                className="w-full aspect-video rounded-md"
                frameBorder="0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowFullScreen
              />
            </div>
          )}
        </div>
      </div>
    </div>
  );
}