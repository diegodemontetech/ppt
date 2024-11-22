import React from 'react';
import html2canvas from 'html2canvas';
import { jsPDF } from 'jspdf';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';

interface CertificateProps {
  courseName: string;
  studentName: string;
  completionDate: Date;
  duration: number;
  score?: number;
  instructorName?: string;
  companyLogo?: string;
  companyName?: string;
  sealUrl?: string;
  signatureName?: string;
}

export function Certificate({ 
  courseName, 
  studentName, 
  completionDate, 
  duration,
  score,
  instructorName = "Carlos Silva",
  companyLogo,
  companyName = "EAD Platform",
  sealUrl,
  signatureName
}: CertificateProps) {
  const certificateRef = React.useRef<HTMLDivElement>(null);

  const downloadCertificate = async () => {
    if (!certificateRef.current) return;

    try {
      const canvas = await html2canvas(certificateRef.current);
      const imgData = canvas.toDataURL('image/png');
      const pdf = new jsPDF('landscape', 'mm', 'a4');
      const width = pdf.internal.pageSize.getWidth();
      const height = pdf.internal.pageSize.getHeight();

      pdf.addImage(imgData, 'PNG', 0, 0, width, height);
      pdf.save(`certificado-${courseName.toLowerCase().replace(/\s+/g, '-')}.pdf`);
    } catch (error) {
      console.error('Erro ao gerar certificado:', error);
    }
  };

  return (
    <div className="p-4">
      <div
        ref={certificateRef}
        className="bg-[#000C2A] text-white p-8 rounded-lg shadow-lg max-w-4xl mx-auto relative overflow-hidden"
        style={{ aspectRatio: '1.414' }}
      >
        {/* Background Pattern */}
        <div className="absolute inset-0 opacity-10">
          <div className="absolute inset-0 bg-gradient-to-br from-blue-500 to-purple-600" />
          <div className="absolute inset-0" style={{ 
            backgroundImage: 'url("data:image/svg+xml,%3Csvg width="20" height="20" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"%3E%3Cg fill="%239C92AC" fill-opacity="0.4"%3E%3Cpath d="M0 0h20L0 20z"/%3E%3C/g%3E%3C/svg%3E")',
            backgroundSize: '20px 20px'
          }} />
        </div>

        {/* Content */}
        <div className="relative z-10">
          <div className="flex justify-between items-start mb-8">
            {companyLogo ? (
              <img src={companyLogo} alt={companyName} className="h-16" />
            ) : (
              <h2 className="text-2xl font-bold">{companyName}</h2>
            )}
            <div className="text-right">
              <p className="text-sm opacity-75">Certificado Nº</p>
              <p className="font-mono">{format(completionDate, 'yyyyMMdd')}-{Math.random().toString(36).substr(2, 6).toUpperCase()}</p>
            </div>
          </div>

          <div className="text-center space-y-6 my-12">
            <h1 className="text-4xl font-bold tracking-wider mb-2">CERTIFICADO</h1>
            <div className="w-32 h-1 bg-gradient-to-r from-blue-400 to-purple-500 mx-auto mb-8"></div>
            
            <p className="text-xl">Certificamos que</p>
            <p className="text-3xl font-bold mb-4">{studentName}</p>
            <p className="text-xl">concluiu com êxito o curso</p>
            <p className="text-3xl font-bold text-blue-400 mb-4">{courseName}</p>
            <p className="text-xl">
              com carga horária de {Math.ceil(duration / 3600)} horas
              {score !== undefined && (
                <span> e nota {score.toFixed(1)}</span>
              )}
            </p>
          </div>

          <div className="mt-16 flex justify-between items-end">
            <div className="text-center">
              <div className="w-40 h-px bg-white mb-2"></div>
              <p className="text-sm">
                {format(completionDate, "dd 'de' MMMM 'de' yyyy", { locale: ptBR })}
              </p>
              <p className="text-xs opacity-75">Data de Conclusão</p>
            </div>

            <div className="text-center">
              <div className="w-40 h-px bg-white mb-2"></div>
              <p className="text-sm font-['Signatura'] text-lg">{signatureName || instructorName}</p>
              <p className="text-xs opacity-75">Instrutor Responsável</p>
            </div>
          </div>

          {sealUrl && (
            <div className="absolute top-8 left-8 w-24 h-24">
              <img 
                src={sealUrl} 
                alt="Selo" 
                className="w-full h-full object-contain"
              />
            </div>
          )}

          <div className="absolute bottom-8 right-8">
            <div className="w-20 h-20 rounded-full bg-gradient-to-br from-blue-400 to-purple-500 flex items-center justify-center">
              <div className="w-16 h-16 rounded-full border-2 border-white flex items-center justify-center">
                <span className="text-2xl font-bold">✓</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="mt-6 text-center">
        <button
          onClick={downloadCertificate}
          className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          Baixar Certificado
        </button>
      </div>
    </div>
  );
}