import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, Book, BookOpen, Building } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useDebounce } from '../hooks/useDebounce';
import toast from 'react-hot-toast';

interface SearchResult {
  id: string;
  title: string;
  type: 'course' | 'ebook' | 'department';
  subtitle?: string;
  department?: string;
  category?: string;
}

export function UniversalSearch() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [isOpen, setIsOpen] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();
  const debouncedQuery = useDebounce(query, 300);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (searchRef.current && !searchRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    if (debouncedQuery.length >= 2) {
      performSearch();
    } else {
      setResults([]);
    }
  }, [debouncedQuery]);

  const performSearch = async () => {
    try {
      setLoading(true);

      // Search courses
      const { data: courses, error: coursesError } = await supabase
        .from('modules')
        .select(`
          id,
          title,
          category:categories(
            id,
            name,
            department:departments(
              id,
              name
            )
          )
        `)
        .ilike('title', `%${debouncedQuery}%`)
        .limit(3);

      if (coursesError) throw coursesError;

      // Search ebooks
      const { data: ebooks, error: ebooksError } = await supabase
        .from('ebooks')
        .select(`
          id,
          title,
          subtitle,
          category:categories(
            id,
            name,
            department:departments(
              id,
              name
            )
          )
        `)
        .ilike('title', `%${debouncedQuery}%`)
        .limit(3);

      if (ebooksError) throw ebooksError;

      // Format results
      const formattedResults: SearchResult[] = [
        ...(courses?.map(course => ({
          id: course.id,
          title: course.title,
          type: 'course' as const,
          department: course.category?.department?.name,
          category: course.category?.name
        })) || []),
        ...(ebooks?.map(ebook => ({
          id: ebook.id,
          title: ebook.title,
          type: 'ebook' as const,
          subtitle: ebook.subtitle,
          department: ebook.category?.department?.name,
          category: ebook.category?.name
        })) || [])
      ];

      setResults(formattedResults);
      setIsOpen(true);
    } catch (error) {
      console.error('Error performing search:', error);
      toast.error('Erro ao realizar busca');
    } finally {
      setLoading(false);
    }
  };

  const handleSelect = (result: SearchResult) => {
    setQuery('');
    setResults([]);
    setIsOpen(false);

    switch (result.type) {
      case 'course':
        navigate(`/course/${result.id}`);
        break;
      case 'ebook':
        navigate('/ebooks');
        break;
      default:
        break;
    }
  };

  const getIcon = (type: string) => {
    switch (type) {
      case 'course':
        return <BookOpen className="w-5 h-5 text-red-500" />;
      case 'ebook':
        return <Book className="w-5 h-5 text-red-500" />;
      default:
        return <Building className="w-5 h-5 text-red-500" />;
    }
  };

  return (
    <div ref={searchRef} className="relative w-full max-w-lg">
      <div className="relative">
        <input
          type="text"
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setIsOpen(true);
          }}
          onFocus={() => setIsOpen(true)}
          placeholder="Buscar cursos, e-books..."
          className="w-full pl-10 pr-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-red-500 focus:border-transparent"
        />
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <Search className={`h-5 w-5 ${loading ? 'text-red-500' : 'text-gray-400'}`} />
        </div>
      </div>

      {isOpen && results.length > 0 && (
        <div className="absolute z-50 w-full mt-2 bg-white rounded-lg shadow-lg border border-gray-200 max-h-96 overflow-y-auto">
          <div className="p-2">
            {results.map((result) => (
              <button
                key={`${result.type}-${result.id}`}
                onClick={() => handleSelect(result)}
                className="w-full text-left px-4 py-3 hover:bg-gray-50 rounded-lg transition-colors"
              >
                <div className="flex items-center">
                  {getIcon(result.type)}
                  <div className="ml-3 flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900 truncate">
                      {result.title}
                    </p>
                    <p className="text-sm text-gray-500 truncate">
                      {result.department} &gt; {result.category}
                    </p>
                  </div>
                  <span className={`
                    ml-2 inline-flex items-center px-2 py-0.5 rounded text-xs font-medium
                    ${result.type === 'course' 
                      ? 'bg-blue-100 text-blue-800'
                      : 'bg-green-100 text-green-800'
                    }
                  `}>
                    {result.type === 'course' ? 'Curso' : 'E-Book'}
                  </span>
                </div>
              </button>
            ))}
          </div>
        </div>
      )}

      {isOpen && query.length >= 2 && results.length === 0 && !loading && (
        <div className="absolute z-50 w-full mt-2 bg-white rounded-lg shadow-lg border border-gray-200">
          <div className="p-4 text-center text-gray-500">
            Nenhum resultado encontrado
          </div>
        </div>
      )}
    </div>
  );
}