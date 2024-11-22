import React, { useState } from 'react';
import { Plus, Minus } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import toast from 'react-hot-toast';

interface QuizManagerProps {
  module: any;
  onUpdate: () => void;
}

export function QuizManager({ module, onUpdate }: QuizManagerProps) {
  const [loading, setLoading] = useState(false);
  const [questions, setQuestions] = useState<any[]>(
    module.quiz?.[0]?.questions || []
  );

  const addQuestion = () => {
    setQuestions([
      ...questions,
      {
        text: '',
        options: ['', '', '', ''],
        correctOption: 0
      }
    ]);
  };

  const removeQuestion = (index: number) => {
    setQuestions(questions.filter((_, i) => i !== index));
  };

  const updateQuestion = (index: number, field: string, value: string | number) => {
    const newQuestions = [...questions];
    newQuestions[index] = {
      ...newQuestions[index],
      [field]: value
    };
    setQuestions(newQuestions);
  };

  const updateOption = (questionIndex: number, optionIndex: number, value: string) => {
    const newQuestions = [...questions];
    newQuestions[questionIndex].options[optionIndex] = value;
    setQuestions(newQuestions);
  };

  const handleSubmit = async () => {
    try {
      setLoading(true);

      // Use upsert to handle both insert and update
      const { error } = await supabase
        .from('quizzes')
        .upsert({
          id: module.quiz?.[0]?.id, // Include existing ID if updating
          module_id: module.id,
          questions: questions,
          updated_at: new Date().toISOString()
        }, {
          onConflict: 'module_id' // Handle duplicate module_id
        });

      if (error) throw error;

      toast.success('Quiz salvo com sucesso!');
      onUpdate();
    } catch (error) {
      console.error('Error saving quiz:', error);
      toast.error('Erro ao salvar quiz');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h3 className="text-lg font-medium text-gray-900">
          Questões do Quiz
        </h3>
        <button
          onClick={addQuestion}
          className="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
        >
          <Plus className="w-4 h-4 mr-2" />
          Adicionar Questão
        </button>
      </div>

      {questions.map((question, questionIndex) => (
        <div key={questionIndex} className="bg-gray-50 p-4 rounded-lg">
          <div className="flex justify-between items-start mb-4">
            <div className="flex-grow mr-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Questão {questionIndex + 1}
              </label>
              <input
                type="text"
                value={question.text}
                onChange={(e) => updateQuestion(questionIndex, 'text', e.target.value)}
                className="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                placeholder="Digite a pergunta"
                required
              />
            </div>
            <button
              onClick={() => removeQuestion(questionIndex)}
              className="text-red-600 hover:text-red-700"
            >
              <Minus className="w-5 h-5" />
            </button>
          </div>

          <div className="space-y-3">
            {question.options.map((option: string, optionIndex: number) => (
              <div key={optionIndex} className="flex items-center space-x-2">
                <input
                  type="radio"
                  name={`correct-${questionIndex}`}
                  checked={question.correctOption === optionIndex}
                  onChange={() => updateQuestion(questionIndex, 'correctOption', optionIndex)}
                  className="focus:ring-blue-500 h-4 w-4 text-blue-600 border-gray-300"
                />
                <input
                  type="text"
                  value={option}
                  onChange={(e) => updateOption(questionIndex, optionIndex, e.target.value)}
                  className="flex-grow rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  placeholder={`Opção ${optionIndex + 1}`}
                  required
                />
              </div>
            ))}
          </div>
        </div>
      ))}

      {questions.length > 0 && (
        <div className="flex justify-end">
          <button
            onClick={handleSubmit}
            disabled={loading}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
          >
            {loading ? 'Salvando...' : 'Salvar Quiz'}
          </button>
        </div>
      )}
    </div>
  );
}