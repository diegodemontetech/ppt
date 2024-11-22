import React from 'react';
import { useProcessStore } from '../store/processStore';
import { Loader2, CheckCircle, XCircle } from 'lucide-react';

export function ProcessList() {
  const { processes } = useProcessStore();
  const activeProcesses = Object.values(processes).filter(p => p.status !== 'completed' && p.status !== 'failed');
  
  if (activeProcesses.length === 0) return null;

  return (
    <div className="fixed bottom-4 right-4 z-50 space-y-2">
      {activeProcesses.map((process) => (
        <div 
          key={process.id}
          className="bg-white rounded-lg shadow-lg p-4 w-80 border border-gray-200"
        >
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-sm font-medium text-gray-900">
              {process.type === 'course_generation' ? 'Gerando Curso' : 'Processando Vídeo'}
            </h3>
            {process.status === 'processing' && (
              <Loader2 className="w-4 h-4 animate-spin text-red-500" />
            )}
            {process.status === 'completed' && (
              <CheckCircle className="w-4 h-4 text-green-500" />
            )}
            {process.status === 'failed' && (
              <XCircle className="w-4 h-4 text-red-500" />
            )}
          </div>
          
          <div className="w-full bg-gray-200 rounded-full h-1.5">
            <div
              className="bg-red-600 h-1.5 rounded-full transition-all duration-500"
              style={{ width: `${process.progress}%` }}
            />
          </div>
          
          {process.currentStep && (
            <p className="mt-2 text-xs text-gray-500">
              {process.currentStep}
            </p>
          )}
        </div>
      ))}
    </div>
  );
}