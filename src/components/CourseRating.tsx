import React, { useState, useEffect } from 'react';
import { Star } from 'lucide-react';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';

interface CourseRatingProps {
  moduleId: string;
  initialRating?: number;
  onRatingSubmit?: () => void;
}

export function CourseRating({ moduleId, initialRating = 0, onRatingSubmit }: CourseRatingProps) {
  const [rating, setRating] = useState(initialRating);
  const [hoveredRating, setHoveredRating] = useState(0);
  const [submitting, setSubmitting] = useState(false);
  const [hasRated, setHasRated] = useState(false);

  useEffect(() => {
    checkUserRating();
  }, [moduleId]);

  const checkUserRating = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data, error } = await supabase
        .from('course_ratings')
        .select('rating')
        .eq('module_id', moduleId)
        .eq('user_id', user.id)
        .maybeSingle();

      if (error && error.code !== 'PGRST116') {
        console.error('Error checking user rating:', error);
        return;
      }

      if (data) {
        setHasRated(true);
        setRating(data.rating);
      }
    } catch (error) {
      console.error('Error checking user rating:', error);
    }
  };

  const handleRating = async (value: number) => {
    try {
      setSubmitting(true);
      
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
          rating: value
        });

      if (error) throw error;

      setRating(value);
      setHasRated(true);
      toast.success('Avaliação enviada com sucesso!');
      onRatingSubmit?.();
    } catch (error) {
      console.error('Error submitting rating:', error);
      toast.error('Erro ao enviar avaliação');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="flex items-center space-x-1">
      {[1, 2, 3, 4, 5].map((value) => (
        <button
          key={value}
          disabled={submitting || hasRated}
          onClick={() => handleRating(value)}
          onMouseEnter={() => setHoveredRating(value)}
          onMouseLeave={() => setHoveredRating(0)}
          className={`p-1 focus:outline-none ${
            hasRated ? 'cursor-not-allowed' : 'cursor-pointer hover:scale-110'
          } transition-transform`}
          title={hasRated ? 'Você já avaliou este curso' : 'Avaliar curso'}
        >
          <Star
            className={`w-6 h-6 transition-colors ${
              value <= (hoveredRating || rating)
                ? 'fill-yellow-400 text-yellow-400'
                : 'text-gray-300'
            }`}
          />
        </button>
      ))}
    </div>
  );
}