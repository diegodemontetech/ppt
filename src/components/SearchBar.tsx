import React, { useState, useRef, useEffect } from 'react';
import { Search, X } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { useDebounce } from '../hooks/useDebounce';
import toast from 'react-hot-toast';

interface SearchResult {
  id: string;
  title: string;
  description: string;
  type: 'module' | 'lesson';
  moduleId?: string;
}

export function SearchBar() {
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
    if (debouncedQuery) {
      performSearch();
    } else {
      setResults([]);
    }
  }, [debouncedQuery]);

  const performSearch = async () => {
    if (debouncedQuery.length < 2) return;

    try {
      setLoading(true);

      // Search modules
      const { data: modules, error: modulesError } = await supabase
        .from('modules')
        .select('id, title, description')
        .ilike('title', `%${debouncedQuery}%`)
        .limit(3);

      if (modulesError) throw modulesError;

      // Search lessons
      const { data: lessons, error: lessonsError } = await supabase
        .from('lessons')
        .select('id, title, description, module_id')
        .ilike('title', `%${debouncedQuery}%`)
        .limit(3);

      if (lessonsError) throw lessonsError;

      const formattedResults: SearchResult[] = [
        ...(modules?.map(m => ({
          id: m.id,
          title: m.title,
          description: m.description,
          type: 'module' as const
        })) || []),
        ...(lessons?.map(l => ({
          id: l.id,
          title: l.title,
          description: l.description,
          type: 'lesson' as const,
          moduleId: l.module_id
        })) || [])
      ];

      setResults(formattedResults);
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

    if (result.type === 'module') {
      navigate(`/course/${result.id}`);
    } else {
      navigate(`/course/${result.moduleId}`, {
        state: { scrollToLesson: result.id }
      });
    }
  };

  return (
    <div ref={searchRef} className="relative w-full">
      <div className="relative">
        <input
          type="text"
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setIsOpen(true);
          }}
          onFocus={() => setIsOpen(true)}
          placeholder="Buscar cursos e aulas..."
          className="w-full pl-10 pr-10 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        />
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <Search className={`h-5 w-5 ${loading ? 'text-blue-500' : 'text-gray-400'}`} />
        </div>
        {query && (
          <button
            onClick={() => {
              setQuery('');
              setResults([]);
              setIsOpen(false);
            }}
            className="absolute inset-y-0 right-0 pr-3 flex items-center"
          >
            <X className="h-5 w-5 text-gray-400 hover:text-gray-600" />
          </button>
        )}
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
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900 truncate">
                      {result.title}
                    </p>
                    <p className="text-sm text-gray-500 truncate">
                      {result.description}
                    </p>
                  </div>
                  <span className={`
                    ml-2 inline-flex items-center px-2 py-0.5 rounded text-xs font-medium
                    ${result.type === 'module' 
                      ? 'bg-blue-100 text-blue-800'
                      : 'bg-green-100 text-green-800'
                    }
                  `}>
                    {result.type === 'module' ? 'Curso' : 'Aula'}
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