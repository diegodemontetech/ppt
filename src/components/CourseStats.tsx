import React from 'react';
import { Award, Clock, BookOpen } from 'lucide-react';
import { Link } from 'react-router-dom';

interface CourseStatsProps {
  certificatesCount: number;
  pendingCourses: number;
  completedHours: number;
}

export function CourseStats({ certificatesCount, pendingCourses, completedHours }: CourseStatsProps) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
      <Link
        to="/profile"
        className="bg-white p-4 rounded-lg shadow-sm hover:shadow-md transition-shadow"
      >
        <div className="flex items-center">
          <div className="p-2 bg-blue-100 rounded-lg">
            <Award className="h-6 w-6 text-blue-600" />
          </div>
          <div className="ml-4">
            <p className="text-sm font-medium text-gray-600">Certificados</p>
            <p className="text-2xl font-semibold text-gray-900">{certificatesCount}</p>
          </div>
        </div>
      </Link>

      <div className="bg-white p-4 rounded-lg shadow-sm">
        <div className="flex items-center">
          <div className="p-2 bg-yellow-100 rounded-lg">
            <BookOpen className="h-6 w-6 text-yellow-600" />
          </div>
          <div className="ml-4">
            <p className="text-sm font-medium text-gray-600">Cursos Pendentes</p>
            <p className="text-2xl font-semibold text-gray-900">{pendingCourses}</p>
          </div>
        </div>
      </div>

      <div className="bg-white p-4 rounded-lg shadow-sm">
        <div className="flex items-center">
          <div className="p-2 bg-green-100 rounded-lg">
            <Clock className="h-6 w-6 text-green-600" />
          </div>
          <div className="ml-4">
            <p className="text-sm font-medium text-gray-600">Horas Concluídas</p>
            <p className="text-2xl font-semibold text-gray-900">{completedHours}</p>
          </div>
        </div>
      </div>
    </div>
  );
}