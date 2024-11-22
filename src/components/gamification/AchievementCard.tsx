import React from 'react';
import { Trophy, Medal, Star } from 'lucide-react';
import Confetti from 'react-confetti';

interface AchievementCardProps {
  title: string;
  description: string;
  type: 'badge' | 'level' | 'milestone';
  icon: string;
  isNew?: boolean;
}

export function AchievementCard({
  title,
  description,
  type,
  icon,
  isNew = false
}: AchievementCardProps) {
  const getIcon = () => {
    switch (icon) {
      case 'trophy':
        return <Trophy className="w-8 h-8 text-yellow-400" />;
      case 'medal':
        return <Medal className="w-8 h-8 text-blue-500" />;
      default:
        return <Star className="w-8 h-8 text-purple-500" />;
    }
  };

  const getBackgroundColor = () => {
    switch (type) {
      case 'badge':
        return 'bg-yellow-50';
      case 'level':
        return 'bg-blue-50';
      case 'milestone':
        return 'bg-purple-50';
      default:
        return 'bg-gray-50';
    }
  };

  return (
    <div className={`relative p-6 rounded-lg ${getBackgroundColor()}`}>
      {isNew && <Confetti numberOfPieces={50} recycle={false} />}
      
      <div className="flex items-start">
        <div className="flex-shrink-0">{getIcon()}</div>
        <div className="ml-4">
          <h4 className="text-lg font-medium text-gray-900">{title}</h4>
          <p className="mt-1 text-sm text-gray-500">{description}</p>
        </div>
      </div>

      {isNew && (
        <span className="absolute top-2 right-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
          Novo!
        </span>
      )}
    </div>
  );
}