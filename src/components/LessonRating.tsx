import React, { useState, useEffect } from 'react';
import { Star } from 'lucide-react';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';

interface LessonRatingProps {
  lessonId: string;
  initialRating?: number;
  totalRatings?: number;
  onRatingSubmit?: () => void;
}

export function LessonRating({
  lessonId,
  initialRating = 0,
  totalRatings = 0,
  onRatingSubmit
}: LessonRatingProps) {
  const [rating, setRating] = useState(initialRating);
  const [total, setTotal] = useState(totalRatings);
  const [submitting, setSubmitting] = useState(false);
  const [hasRated, setHasRated] = useState(false);
  const [hoveredRating, setHoveredRating] = useState(0);

  useEffect(() => {
    checkUserRating();
  }, [lessonId]);

  const checkUserRating = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data, error } = await supabase
        .from('lesson_ratings')
        .select('rating')
        .eq('lesson_id', lessonId)
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
    if (hasRated) {
      toast.error('Você já avaliou esta aula');
      return;
    }

    try {
      setSubmitting(true);
      
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        toast.error('Você precisa estar logado para avaliar');
        return;
      }

      const { error } = await supabase
        .from('lesson_ratings')
        .insert({
          lesson_id: lessonId,
          user_id: user.id,
          rating: value
        });

      if (error) {
        if (error.code === '23505') {
          toast.error('Você já avaliou esta aula');
          setHasRated(true);
          return;
        }
        throw error;
      }

      setRating(value);
      setTotal(prev => prev + 1);
      setHasRated(true);
      
      toast.success('Avaliação enviada com sucesso!');
      
      if (onRatingSubmit) {
        onRatingSubmit();
      }
    } catch (error) {
      console.error('Error submitting rating:', error);
      toast.error('Erro ao enviar avaliação');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="flex items-center space-x-2">
      <div className="flex">
        {[1, 2, 3, 4, 5].map((value) => (
          <button
            key={value}
            disabled={submitting || hasRated}
            onClick={() => handleRating(value)}
            onMouseEnter={() => setHoveredRating(value)}
            onMouseLeave={() => setHoveredRating(0)}
            className={`p-1 focus:outline-none ${
              hasRated ? 'cursor-not-allowed' : 'cursor-pointer hover:scale-110'
            }`}
            title={hasRated ? 'Você já avaliou esta aula' : 'Avaliar aula'}
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
      <span className="text-sm text-gray-500">
        ({total} {total === 1 ? 'avaliação' : 'avaliações'})
      </span>
    </div>
  );
}