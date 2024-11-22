import React, { useState } from 'react';
import { Wand2 } from 'lucide-react';

interface MagicLearningPromptProps {
  onSubmit: (prompt: string) => void;
  onClose: () => void;
}

export function MagicLearningPrompt({ onSubmit, onClose }: MagicLearningPromptProps) {
  const [prompt, setPrompt] = useState('');

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg max-w-lg w-full p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">
          Magic Learning
        </h3>
        
        <p className="text-sm text-gray-500 mb-4">
          Descreva o conteúdo que você deseja gerar e o Magic Learning criará automaticamente um módulo completo com aulas e exercícios.
        </p>

        <textarea
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          className="w-full h-32 p-2 border rounded-md"
          placeholder="Ex: Crie um curso completo sobre JavaScript para iniciantes..."
        />

        <div className="mt-4 flex justify-end space-x-3">
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-md"
          >
            Cancelar
          </button>
          <button
            onClick={() => onSubmit(prompt)}
            className="px-4 py-2 text-sm text-white bg-blue-700 hover:bg-blue-800 rounded-md inline-flex items-center"
          >
            <Wand2 className="w-4 h-4 mr-2" />
            Gerar Conteúdo
          </button>
        </div>
      </div>
    </div>
  );
}