import React from 'react';
import { Link } from 'react-router-dom';
import { Clock, Users, ChevronLeft, ChevronRight } from 'lucide-react';
import { formatDuration } from '../utils/format';
import { RatingStars } from './RatingStars';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';

interface Course {
  id: string;
  title: string;
  description?: string;
  thumbnail_url?: string;
  bg_color: string;
  duration?: number;
  category?: {
    id: string;
    name: string;
    department?: {
      id: string;
      name: string;
    };
  };
  enrolled_count?: number;
  course_ratings?: Array<{
    rating: number;
    user_id: string;
  }>;
}

interface FeaturedCoursesProps {
  courses: Course[];
  showCarousel?: boolean;
}

export function FeaturedCourses({ courses, showCarousel = false }: FeaturedCoursesProps) {
  const scrollLeft = () => {
    const container = document.getElementById('featured-courses');
    if (container) {
      container.scrollBy({ left: -300, behavior: 'smooth' });
    }
  };

  const scrollRight = () => {
    const container = document.getElementById('featured-courses');
    if (container) {
      container.scrollBy({ left: 300, behavior: 'smooth' });
    }
  };

  const handleRating = async (moduleId: string, rating: number, event: React.MouseEvent) => {
    event.preventDefault();
    event.stopPropagation();

    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        toast.error('Você precisa estar logado para avaliar');
        return;
      }

      const { error } = await supabase
        .from('course_ratings')
        .upsert({
          module_id: moduleId,
          user_id: user.id,
          rating
        });

      if (error) throw error;
      toast.success('Avaliação enviada com sucesso!');
    } catch (error) {
      console.error('Error rating course:', error);
      toast.error('Erro ao enviar avaliação');
    }
  };

  // Calculate average rating
  const getAverageRating = (ratings: any[] = []) => {
    if (!ratings?.length) return 0;
    const sum = ratings.reduce((acc, curr) => acc + curr.rating, 0);
    return sum / ratings.length;
  };

  const renderCourseCard = (course: Course) => (
    <Link
      key={course.id}
      to={`/course/${course.id}`}
      className="block group"
    >
      <div 
        className="bg-white rounded-lg shadow-sm overflow-hidden hover:shadow-md transition-shadow"
      >
        {/* Thumbnail */}
        <div className="aspect-w-16 aspect-h-9 bg-gray-100">
          {course.thumbnail_url ? (
            <img
              src={course.thumbnail_url}
              alt={course.title}
              className="object-cover"
              crossOrigin="anonymous"
            />
          ) : (
            <div 
              className="w-full h-full flex items-center justify-center"
              style={{ backgroundColor: course.bg_color }}
            >
              <span className="text-2xl font-bold text-white">
                {course.title[0]}
              </span>
            </div>
          )}
        </div>

        <div className="p-3">
          <h3 className="font-medium text-gray-900 text-sm line-clamp-2">
            {course.title}
          </h3>

          <div className="mt-2 flex items-center justify-between text-xs text-gray-500">
            <div className="flex items-center">
              <Clock className="w-3 h-3 mr-1" />
              {formatDuration(course.duration || 0)}
            </div>
            <div className="flex items-center">
              <Users className="w-3 h-3 mr-1" />
              {course.enrolled_count || 0}
            </div>
          </div>

          <div className="mt-2 flex items-center justify-between">
            <div onClick={(e) => e.preventDefault()}>
              <RatingStars
                rating={getAverageRating(course.course_ratings)}
                totalRatings={course.course_ratings?.length || 0}
                size="sm"
                onRate={(rating) => handleRating(course.id, rating, event)}
              />
            </div>

            {course.category && (
              <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800">
                {course.category.department?.name || course.category.name}
              </span>
            )}
          </div>
        </div>
      </div>
    </Link>
  );

  if (showCarousel && courses.length > 4) {
    return (
      <div className="relative group">
        <button
          onClick={scrollLeft}
          className="absolute left-0 top-1/2 -translate-y-1/2 z-10 p-2 rounded-full bg-white shadow-lg opacity-0 group-hover:opacity-100 transition-opacity"
        >
          <ChevronLeft className="w-6 h-6 text-gray-600" />
        </button>

        <div
          id="featured-courses"
          className="flex space-x-4 overflow-x-auto scrollbar-hide pb-4"
          style={{ scrollBehavior: 'smooth' }}
        >
          {courses.map(course => (
            <div key={course.id} className="flex-none w-72">
              {renderCourseCard(course)}
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
    );
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
      {courses.map(course => renderCourseCard(course))}
    </div>
  );
}