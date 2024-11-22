import React from 'react';
import { Bar, Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  PointElement
} from 'chart.js';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  PointElement
);

interface CourseAnalyticsProps {
  courseStats: any;
}

export function CourseAnalytics({ courseStats }: CourseAnalyticsProps) {
  const completionData = {
    labels: courseStats.courses.map((c: any) => c.title),
    datasets: [
      {
        label: 'Taxa de Conclusão (%)',
        data: courseStats.courses.map((c: any) => c.completion_rate),
        backgroundColor: 'rgba(59, 130, 246, 0.5)',
        borderColor: 'rgb(59, 130, 246)',
        borderWidth: 1
      }
    ]
  };

  const progressionData = {
    labels: courseStats.progression.map((p: any) => p.date),
    datasets: [
      {
        label: 'Progresso Diário',
        data: courseStats.progression.map((p: any) => p.count),
        borderColor: 'rgb(59, 130, 246)',
        tension: 0.1
      }
    ]
  };

  return (
    <div className="space-y-8">
      <div className="bg-white p-6 rounded-lg shadow-sm">
        <h3 className="text-lg font-medium text-gray-900 mb-4">
          Taxa de Conclusão por Curso
        </h3>
        <Bar data={completionData} />
      </div>

      <div className="bg-white p-6 rounded-lg shadow-sm">
        <h3 className="text-lg font-medium text-gray-900 mb-4">
          Progresso Diário
        </h3>
        <Line data={progressionData} />
      </div>
    </div>
  );
}