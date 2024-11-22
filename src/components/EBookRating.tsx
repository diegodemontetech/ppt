import React, { useState } from 'react';
import { Star } from 'lucide-react';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';

interface EBookRatingProps {
  ebookId: string;
  initialRating?: number;
  onRatingSubmit?: () => void;
}

export function EBookRating({ ebookId, initialRating = 0, onRatingSubmit }: EBookRatingProps) {
  const [rating, setRating] = useState(initialRating);
  const [hoveredRating, setHoveredRating] = useState(0);
  const [submitting, setSubmitting] = useState(false);

  const handleRating = async (value: number) => {
    try {
      setSubmitting(true);
      
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        toast.error('Você precisa estar logado para avaliar');
        return;
      }

      const { error } = await supabase
        .from('ebook_ratings')
        .upsert({
          ebook_id: ebookId,
          user_id: user.id,
          rating: value
        });

      if (error) throw error;

      setRating(value);
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
          disabled={submitting}
          onClick={() => handleRating(value)}
          onMouseEnter={() => setHoveredRating(value)}
          onMouseLeave={() => setHoveredRating(0)}
          className="p-1 focus:outline-none disabled:cursor-not-allowed"
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