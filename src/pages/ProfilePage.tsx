import React, { useState, useEffect } from 'react';
import { Layout } from '../components/Layout';
import { useAuthStore } from '../store/authStore';
import { Certificate } from '../components/Certificate';
import { Book, Award, Star, Trophy } from 'lucide-react';
import { getCompletedCourses } from '../lib/db';
import toast from 'react-hot-toast';

export default function ProfilePage() {
  const { user } = useAuthStore();
  const [completedCourses, setCompletedCourses] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (user?.id) {
      fetchCompletedCourses();
    }
  }, [user?.id]);

  const fetchCompletedCourses = async () => {
    try {
      if (!user?.id) return;
      const courses = await getCompletedCourses(user.id);
      setCompletedCourses(courses);
    } catch (error) {
      console.error('Erro ao buscar cursos concluídos:', error);
      toast.error('Erro ao carregar cursos concluídos');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Layout title="Meu Perfil">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Profile */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-lg shadow-sm p-6">
              <div className="text-center">
                <div className="w-32 h-32 mx-auto rounded-full bg-blue-100 flex items-center justify-center">
                  <span className="text-4xl font-medium text-blue-600">
                    {user?.user_metadata?.full_name?.[0] || 'U'}
                  </span>
                </div>
                <h2 className="mt-4 text-xl font-medium text-gray-900">
                  {user?.user_metadata?.full_name}
                </h2>
                <p className="text-sm text-gray-500">{user?.email}</p>
              </div>

              <div className="mt-6 border-t pt-6">
                <div className="flex justify-between items-center mb-4">
                  <div className="flex items-center">
                    <Trophy className="w-5 h-5 text-blue-600 mr-2" />
                    <span className="text-sm font-medium text-gray-900">Pontos</span>
                  </div>
                  <span className="text-lg font-semibold text-blue-600">
                    {user?.user_metadata?.points || 0}
                  </span>
                </div>

                <div className="flex justify-between items-center mb-4">
                  <div className="flex items-center">
                    <Book className="w-5 h-5 text-blue-600 mr-2" />
                    <span className="text-sm font-medium text-gray-900">Cursos Concluídos</span>
                  </div>
                  <span className="text-lg font-semibold text-blue-600">
                    {completedCourses.length}
                  </span>
                </div>

                <div className="flex justify-between items-center">
                  <div className="flex items-center">
                    <Award className="w-5 h-5 text-blue-600 mr-2" />
                    <span className="text-sm font-medium text-gray-900">Certificados</span>
                  </div>
                  <span className="text-lg font-semibold text-blue-600">
                    {completedCourses.length}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Certificates */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-lg shadow-sm p-6">
              <h3 className="text-lg font-medium text-gray-900 mb-6">Meus Certificados</h3>

              {loading ? (
                <div className="flex justify-center items-center h-48">
                  <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
                </div>
              ) : completedCourses.length === 0 ? (
                <div className="text-center py-12">
                  <Award className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-500">Nenhum certificado disponível ainda</p>
                  <p className="text-sm text-gray-400 mt-1">
                    Complete cursos para receber seus certificados
                  </p>
                </div>
              ) : (
                <div className="space-y-6">
                  {completedCourses.map((course) => (
                    <Certificate
                      key={course.id}
                      courseName={course.title}
                      studentName={user?.user_metadata?.full_name}
                      completionDate={new Date()}
                      duration={course.total_duration}
                    />
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}