import React, { useEffect, useState } from 'react';
import { Layout } from '../components/Layout';
import { Certificate } from '../components/Certificate';
import { Award } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../store/authStore';

export default function CertificatesPage() {
  const { user } = useAuthStore();
  const [certificates, setCertificates] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchCertificates();
  }, []);

  const fetchCertificates = async () => {
    try {
      const { data, error } = await supabase
        .from('certificates')
        .select(`
          *,
          course:courses(
            title,
            total_duration
          )
        `)
        .eq('user_id', user?.id);

      if (error) throw error;
      setCertificates(data || []);
    } catch (error) {
      console.error('Erro ao carregar certificados:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Layout title="Meus Certificados">
      {loading ? (
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
        </div>
      ) : certificates.length === 0 ? (
        <div className="text-center py-12">
          <Award className="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900">Nenhum certificado disponível</h3>
          <p className="mt-2 text-sm text-gray-500">
            Complete cursos para receber seus certificados
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-6">
          {certificates.map((cert) => (
            <Certificate
              key={cert.id}
              courseName={cert.course.title}
              studentName={user?.user_metadata?.full_name}
              completionDate={new Date(cert.issued_at)}
              duration={cert.course.total_duration}
            />
          ))}
        </div>
      )}
    </Layout>
  );
}