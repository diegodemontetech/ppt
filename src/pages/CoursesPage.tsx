import React, { useState, useEffect } from 'react';
import { Layout } from '../components/Layout';
import { FeaturedCourses } from '../components/FeaturedCourses';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';

export default function CoursesPage() {
  const [courses, setCourses] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    department: '',
    category: '',
    search: '',
    pendingOnly: false
  });

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [coursesData, departmentsData] = await Promise.all([
        fetchCourses(),
        fetchDepartments()
      ]);
      
      setCourses(coursesData || []);
      setDepartments(departmentsData || []);
    } catch (error) {
      console.error('Error fetching data:', error);
      toast.error('Erro ao carregar dados');
    } finally {
      setLoading(false);
    }
  };

  const fetchCourses = async () => {
    const { data, error } = await supabase
      .from('modules')
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
        lessons(
          id,
          lesson_progress(completed)
        ),
        course_ratings(
          rating,
          user_id
        )
      `)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  };

  const fetchDepartments = async () => {
    const { data, error } = await supabase
      .from('departments')
      .select('*, categories(*)');

    if (error) throw error;
    return data;
  };

  const handleDepartmentChange = (deptId: string) => {
    setFilters(prev => ({
      ...prev,
      department: deptId,
      category: '' // Reset category when department changes
    }));

    if (deptId) {
      const dept = departments.find(d => d.id === deptId);
      setCategories(dept?.categories || []);
    } else {
      setCategories([]);
    }
  };

  // Filter courses based on current filters
  const filteredCourses = courses.filter(course => {
    if (filters.department && course.category?.department?.id !== filters.department) return false;
    if (filters.category && course.category?.id !== filters.category) return false;
    if (filters.search && !course.title.toLowerCase().includes(filters.search.toLowerCase())) return false;
    if (filters.pendingOnly) {
      const isCompleted = course.lessons?.every(lesson => 
        lesson.lesson_progress?.some(p => p.completed)
      );
      if (isCompleted) return false;
    }
    return true;
  });

  return (
    <Layout title="Cursos">
      <div className="space-y-6">
        <div className="flex items-center space-x-4">
          <div className="flex-1 max-w-xs">
            <input
              type="text"
              value={filters.search}
              onChange={(e) => setFilters(prev => ({ ...prev, search: e.target.value }))}
              placeholder="Buscar cursos..."
              className="block w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
            />
          </div>

          <select
            value={filters.department}
            onChange={(e) => handleDepartmentChange(e.target.value)}
            className="block rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
          >
            <option value="">Todos os Departamentos</option>
            {departments.map(dept => (
              <option key={dept.id} value={dept.id}>{dept.name}</option>
            ))}
          </select>

          <select
            value={filters.category}
            onChange={(e) => setFilters(prev => ({ ...prev, category: e.target.value }))}
            className="block rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
          >
            <option value="">Todas as Categorias</option>
            {categories.map(cat => (
              <option key={cat.id} value={cat.id}>{cat.name}</option>
            ))}
          </select>

          <label className="flex items-center">
            <input
              type="checkbox"
              checked={filters.pendingOnly}
              onChange={(e) => setFilters(prev => ({ ...prev, pendingOnly: e.target.checked }))}
              className="rounded border-gray-300 text-red-600 focus:ring-red-500"
            />
            <span className="ml-2 text-sm text-gray-600">
              Apenas pendentes
            </span>
          </label>
        </div>

        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-red-500"></div>
          </div>
        ) : (
          <FeaturedCourses courses={filteredCourses} />
        )}
      </div>
    </Layout>
  );
}