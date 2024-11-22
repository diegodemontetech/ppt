import React, { useEffect } from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/Tabs';
import { useNewsStore } from '../../store/newsStore';
import { NewsCard } from './NewsCard';
import { Newspaper } from 'lucide-react';

export function NewsSection() {
  const { articles, categories, loading, fetchArticles, fetchCategories } = useNewsStore();

  useEffect(() => {
    fetchArticles();
    fetchCategories();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-32">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-red-500"></div>
      </div>
    );
  }

  if (articles.length === 0) {
    return (
      <div className="text-center py-8">
        <Newspaper className="w-12 h-12 text-gray-400 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-gray-900">Nenhuma notícia encontrada</h3>
        <p className="mt-2 text-sm text-gray-500">
          As notícias serão exibidas aqui quando forem publicadas.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <Tabs defaultValue="latest">
        <TabsList>
          <TabsTrigger value="latest">Últimas</TabsTrigger>
          <TabsTrigger value="featured">Importantes</TabsTrigger>
          {categories.map(category => (
            <TabsTrigger key={category.id} value={category.id}>
              {category.name}
            </TabsTrigger>
          ))}
        </TabsList>

        <TabsContent value="latest">
          <div className="space-y-4">
            {articles
              .sort((a, b) => new Date(b.published_at).getTime() - new Date(a.published_at).getTime())
              .slice(0, 3)
              .map(article => (
                <NewsCard key={article.id} article={article} />
              ))}
          </div>
        </TabsContent>

        <TabsContent value="featured">
          <div className="space-y-4">
            {articles
              .filter(article => article.is_featured)
              .slice(0, 3)
              .map(article => (
                <NewsCard key={article.id} article={article} />
              ))}
          </div>
        </TabsContent>

        {categories.map(category => (
          <TabsContent key={category.id} value={category.id}>
            <div className="space-y-4">
              {articles
                .filter(article => article.category?.id === category.id)
                .slice(0, 3)
                .map(article => (
                  <NewsCard key={article.id} article={article} />
                ))}
            </div>
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
}