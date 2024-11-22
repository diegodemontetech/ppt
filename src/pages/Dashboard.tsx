import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { ChevronRight } from 'lucide-react';
import { FeaturedCourses } from '../components/FeaturedCourses';
import { LiveClass } from '../components/LiveClass';
import { Ranking } from '../components/Ranking';
import { CourseStats } from '../components/CourseStats';
import { NewsSection } from '../components/news/NewsSection';
import { useNotifications } from '../store/notificationStore';
import { supabase } from '../lib/supabase';
import { getUserStats } from '../lib/db';
import { Layout } from '../components/Layout';
import toast from 'react-hot-toast';

export default function Dashboard() {
  const [modules, setModules] = useState([]);
  const [categories, setCategories] = useState([]);
  const [upcomingLiveClass, setUpcomingLiveClass] = useState(null);
  const [loading, setLoading] = useState(true);
  const [userStats, setUserStats] = useState({
    certificatesCount: 0,
    pendingCourses: 0,
    completedHours: 0
  });
  const [selectedCategory, setSelectedCategory] = useState('');
  const [showUncompletedOnly, setShowUncompletedOnly] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        throw new Error('User not authenticated');
      }

      // Fetch modules
      const { data: modulesData, error: modulesError } = await supabase
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
            title,
            video_url,
            lesson_progress(
              completed,
              score,
              user_id
            )
          ),
          course_ratings(
            rating,
            user_id
          )
        `)
        .eq('is_featured', true)
        .order('created_at', { ascending: false });

      if (modulesError) throw modulesError;
      setModules(modulesData || []);

      // Fetch categories
      const { data: categoriesData, error: categoriesError } = await supabase
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

      if (categoriesError) throw categoriesError;
      setCategories(categoriesData || []);

      // Fetch live class
      const { data: liveClass, error: liveError } = await supabase.rpc('get_next_live_event');
      if (liveError && liveError.code !== '42P01') throw liveError;
      setUpcomingLiveClass(liveClass?.[0]);

      // Fetch user stats
      const stats = await getUserStats(user.id);
      setUserStats(stats);

    } catch (error) {
      console.error('Error fetching data:', error);
      toast.error('Erro ao carregar dados');
    } finally {
      setLoading(false);
    }
  };

  // Filter modules based on selected category and completion status
  const filteredModules = React.useMemo(() => {
    return modules.filter(module => {
      const matchesCategory = !selectedCategory || module.category?.id === selectedCategory;
      
      if (!showUncompletedOnly) return matchesCategory;

      const isCompleted = module.lessons?.every(lesson => 
        lesson.lesson_progress?.some(p => p.completed)
      );

      return matchesCategory && !isCompleted;
    });
  }, [modules, selectedCategory, showUncompletedOnly]);

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-red-500"></div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="grid grid-cols-3 gap-6">
        <div className="col-span-2 space-y-6">
          <CourseStats {...userStats} />

          {/* Featured Courses */}
          {modules.length > 0 && (
            <div>
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-sm font-medium text-gray-900">Cursos em Destaque</h2>
              </div>
              <FeaturedCourses courses={filteredModules} showCarousel={true} />
            </div>
          )}

          {/* Next Live Class */}
          {upcomingLiveClass && (
            <div>
              <h2 className="text-sm font-medium text-gray-900 mb-3">
                Próxima Aula ao Vivo
              </h2>
              <LiveClass {...upcomingLiveClass} />
            </div>
          )}

          {/* News Section */}
          <div className="bg-white rounded-lg shadow-sm p-4">
            <div className="flex justify-between items-center mb-3">
              <h2 className="text-sm font-medium text-gray-900">Notícias</h2>
            </div>
            <NewsSection />
          </div>
        </div>

        {/* Ranking */}
        <div className="bg-white rounded-lg shadow-sm p-4">
          <div className="flex justify-between items-center mb-3">
            <h2 className="text-sm font-medium text-gray-900">Ranking</h2>
          </div>
          <Ranking />
        </div>
      </div>
    </Layout>
  );
}