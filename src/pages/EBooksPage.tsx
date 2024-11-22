import React, { useState, useEffect } from 'react';
import { Layout } from '../components/Layout';
import { Book, Download, Search, Filter } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { RatingStars } from '../components/RatingStars';
import { downloadPdf } from '../lib/storage';
import toast from 'react-hot-toast';

export default function EBooksPage() {
  const [ebooks, setEbooks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    search: '',
    category: '',
    featured: false
  });
  const [categories, setCategories] = useState([]);

  useEffect(() => {
    fetchEbooks();
    fetchCategories();
  }, []);

  const fetchEbooks = async () => {
    try {
      const { data, error } = await supabase
        .from('ebooks')
        .select(`
          *,
          category:categories(
            id,
            name,
            department:departments(
              id,
              name
            )
          ),
          ebook_ratings(
            rating,
            user_id
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setEbooks(data || []);
    } catch (error) {
      console.error('Error fetching ebooks:', error);
      toast.error('Erro ao carregar e-books');
    } finally {
      setLoading(false);
    }
  };

  const fetchCategories = async () => {
    try {
      const { data, error } = await supabase
        .from('categories')
        .select(`
          id,
          name,
          department:departments(
            id,
            name
          )
        `)
        .order('name');

      if (error) throw error;
      setCategories(data || []);
    } catch (error) {
      console.error('Error fetching categories:', error);
      toast.error('Erro ao carregar categorias');
    }
  };

  const handleDownload = async (ebook: any) => {
    try {
      await downloadPdf(ebook.pdf_url);
      toast.success('Download iniciado!');
    } catch (error) {
      console.error('Error downloading ebook:', error);
      toast.error('Erro ao fazer download');
    }
  };

  // Filter ebooks based on current filters
  const filteredEbooks = ebooks.filter(ebook => {
    if (filters.search && !ebook.title.toLowerCase().includes(filters.search.toLowerCase())) {
      return false;
    }
    if (filters.category && ebook.category?.id !== filters.category) {
      return false;
    }
    if (filters.featured && !ebook.is_featured) {
      return false;
    }
    return true;
  });

  // Calculate average rating
  const getAverageRating = (ratings: any[]) => {
    if (!ratings?.length) return 0;
    const sum = ratings.reduce((acc, curr) => acc + curr.rating, 0);
    return sum / ratings.length;
  };

  return (
    <Layout title="E-Books">
      <div className="space-y-6">
        {/* Filters */}
        <div className="flex items-center space-x-4">
          <div className="flex-1 max-w-xs relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
            <input
              type="text"
              value={filters.search}
              onChange={(e) => setFilters({ ...filters, search: e.target.value })}
              placeholder="Buscar e-books..."
              className="pl-10 pr-4 py-2 w-full border border-gray-300 rounded-lg focus:ring-red-500 focus:border-red-500"
            />
          </div>

          <select
            value={filters.category}
            onChange={(e) => setFilters({ ...filters, category: e.target.value })}
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
              onChange={(e) => setFilters({ ...filters, featured: e.target.checked })}
              className="rounded border-gray-300 text-red-600 focus:ring-red-500"
            />
            <span className="ml-2 text-sm text-gray-600">
              Destaques
            </span>
          </label>
        </div>

        {loading ? (
          <div className="flex justify-center items-center h-64">
            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-red-500"></div>
          </div>
        ) : filteredEbooks.length === 0 ? (
          <div className="text-center py-12">
            <Book className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900">Nenhum e-book encontrado</h3>
            <p className="mt-2 text-sm text-gray-500">
              Tente ajustar os filtros ou fazer uma nova busca.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filteredEbooks.map((ebook: any) => (
              <div
                key={ebook.id}
                className="bg-white rounded-lg shadow-sm overflow-hidden hover:shadow-md transition-shadow"
              >
                {/* Cover Image */}
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

                {/* Content */}
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
                      rating={getAverageRating(ebook.ebook_ratings)}
                      totalRatings={ebook.ebook_ratings?.length || 0}
                      size="sm"
                    />
                    {ebook.is_featured && (
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                        Destaque
                      </span>
                    )}
                  </div>

                  <button
                    onClick={() => handleDownload(ebook)}
                    className="w-full flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700"
                  >
                    <Download className="w-4 h-4 mr-2" />
                    Download PDF
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </Layout>
  );
}