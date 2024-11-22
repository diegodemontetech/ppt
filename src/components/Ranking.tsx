import React, { useEffect } from 'react';
import { Trophy, Medal, Award } from 'lucide-react';
import { useRankingStore } from '../store/rankingStore';

export function Ranking() {
  const { users, loading, fetchRanking } = useRankingStore();

  useEffect(() => {
    fetchRanking();
  }, [fetchRanking]);

  const getMedalIcon = (position: number) => {
    switch (position) {
      case 1:
        return <Trophy className="w-6 h-6 text-yellow-400" />;
      case 2:
        return <Medal className="w-6 h-6 text-gray-400" />;
      case 3:
        return <Award className="w-6 h-6 text-amber-600" />;
      default:
        return null;
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-48">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  if (users.length === 0) {
    return (
      <div className="text-center py-8">
        <Trophy className="w-12 h-12 text-gray-400 mx-auto mb-4" />
        <p className="text-gray-500">Nenhum usuário pontuou ainda</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {users.map((user, index) => (
        <div
          key={user.id}
          className={`flex items-center justify-between p-4 rounded-lg ${
            index < 3 ? 'bg-blue-50' : 'bg-gray-50'
          }`}
        >
          <div className="flex items-center space-x-4">
            <div className="flex-shrink-0 w-8 text-center">
              {getMedalIcon(index + 1) || <span className="text-gray-500">{index + 1}º</span>}
            </div>
            <div>
              <p className="font-medium text-gray-900">{user.full_name}</p>
              <div className="flex items-center space-x-2">
                <p className="text-sm text-gray-500">{user.points} pontos</p>
                <span className="text-gray-300">•</span>
                <p className="text-sm text-gray-500">Nível {user.level}</p>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}