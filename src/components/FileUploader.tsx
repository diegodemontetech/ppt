import React, { useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import { Upload, X } from 'lucide-react';
import toast from 'react-hot-toast';

interface FileUploaderProps {
  onUpload: (file: File) => void;
  maxSize?: number;
  accept?: Record<string, string[]>;
}

export function FileUploader({ onUpload, maxSize = 5 * 1024 * 1024, accept }: FileUploaderProps) {
  const onDrop = useCallback(async (acceptedFiles: File[]) => {
    const file = acceptedFiles[0];
    if (!file) return;

    // Check file size
    if (file.size > maxSize) {
      toast.error(`O arquivo deve ter no máximo ${maxSize / (1024 * 1024)}MB`);
      return;
    }

    try {
      await onUpload(file);
    } catch (error) {
      console.error('Error uploading file:', error);
      toast.error('Erro ao enviar arquivo');
    }
  }, [onUpload, maxSize]);

  const { getRootProps, getInputProps, isDragActive, acceptedFiles } = useDropzone({
    onDrop,
    accept,
    maxFiles: 1
  });

  return (
    <div className="space-y-4">
      <div
        {...getRootProps()}
        className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors ${
          isDragActive ? 'border-blue-500 bg-blue-50' : 'border-gray-300 hover:border-gray-400'
        }`}
      >
        <input {...getInputProps()} />
        <Upload className="w-12 h-12 mx-auto text-gray-400 mb-4" />
        {isDragActive ? (
          <p className="text-blue-600">Solte o arquivo aqui...</p>
        ) : (
          <div>
            <p className="text-gray-600">Arraste um arquivo ou clique para selecionar</p>
            <p className="text-sm text-gray-500 mt-1">
              {maxSize / (1024 * 1024)}MB máximo
            </p>
          </div>
        )}
      </div>

      {acceptedFiles.length > 0 && (
        <div className="bg-gray-50 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="font-medium text-gray-900">{acceptedFiles[0].name}</p>
              <p className="text-sm text-gray-500">
                {(acceptedFiles[0].size / (1024 * 1024)).toFixed(2)} MB
              </p>
            </div>
            <button
              onClick={(e) => {
                e.stopPropagation();
                acceptedFiles.splice(0, acceptedFiles.length);
              }}
              className="p-1 hover:bg-gray-200 rounded-full"
            >
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}