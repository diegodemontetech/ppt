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
    <div className="grid grid-cols-3 gap-2 mb-4">
      <Link
        to="/profile"
        className="bg-white p-3 rounded-lg shadow-sm hover:shadow-md transition-shadow"
      >
        <div className="flex items-center">
          <div className="p-1.5 bg-blue-100 rounded-lg">
            <Award className="h-4 w-4 text-blue-600" />
          </div>
          <div className="ml-2">
            <p className="text-xs font-medium text-gray-600">Certificados</p>
            <p className="text-lg font-semibold text-gray-900">{certificatesCount}</p>
          </div>
        </div>
      </Link>

      <div className="bg-white p-3 rounded-lg shadow-sm">
        <div className="flex items-center">
          <div className="p-1.5 bg-yellow-100 rounded-lg">
            <BookOpen className="h-4 w-4 text-yellow-600" />
          </div>
          <div className="ml-2">
            <p className="text-xs font-medium text-gray-600">Pendentes</p>
            <p className="text-lg font-semibold text-gray-900">{pendingCourses}</p>
          </div>
        </div>
      </div>

      <div className="bg-white p-3 rounded-lg shadow-sm">
        <div className="flex items-center">
          <div className="p-1.5 bg-green-100 rounded-lg">
            <Clock className="h-4 w-4 text-green-600" />
          </div>
          <div className="ml-2">
            <p className="text-xs font-medium text-gray-600">Horas</p>
            <p className="text-lg font-semibold text-gray-900">{completedHours}</p>
          </div>
        </div>
      </div>
    </div>
  );
}