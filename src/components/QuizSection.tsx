import React, { useState } from 'react';
import { CheckCircle, XCircle, ArrowRight } from 'lucide-react';
import toast from 'react-hot-toast';

interface QuizProps {
  quiz: {
    id: string;
    questions: Array<{
      text: string;
      options: string[];
      correctOption: number;
    }>;
  };
  onComplete: (score: number) => void;
}

export default function QuizSection({ quiz, onComplete }: QuizProps) {
  const [answers, setAnswers] = useState<number[]>([]);
  const [showResults, setShowResults] = useState(false);
  const [loading, setLoading] = useState(false);
  const [currentPage, setCurrentPage] = useState(0);
  const questionsPerPage = 5;

  // Validate quiz data
  if (!quiz?.questions || !Array.isArray(quiz.questions) || quiz.questions.length === 0) {
    return (
      <div className="text-center py-8">
        <p className="text-gray-500">Nenhuma questão disponível para este quiz.</p>
      </div>
    );
  }

  const totalPages = Math.ceil(quiz.questions.length / questionsPerPage);
  const startIndex = currentPage * questionsPerPage;
  const endIndex = startIndex + questionsPerPage;
  const currentQuestions = quiz.questions.slice(startIndex, endIndex);

  const handleAnswer = (questionIndex: number, optionIndex: number) => {
    const globalQuestionIndex = startIndex + questionIndex;
    const newAnswers = [...answers];
    newAnswers[globalQuestionIndex] = optionIndex;
    setAnswers(newAnswers);
  };

  const handleSubmit = async () => {
    if (answers.length < quiz.questions.length) {
      toast.error('Por favor, responda todas as questões antes de finalizar.');
      return;
    }

    if (!window.confirm('Tem certeza que deseja finalizar o quiz? Este processo é definitivo e sua nota será registrada.')) {
      return;
    }

    try {
      setLoading(true);
      
      const correctAnswers = answers.reduce((acc, answer, index) => {
        return acc + (answer === quiz.questions[index].correctOption ? 1 : 0);
      }, 0);

      const score = (correctAnswers / quiz.questions.length) * 10;
      
      setShowResults(true);
      await onComplete(score);
      
      toast.success('Quiz concluído com sucesso!');
    } catch (error) {
      console.error('Error calculating score:', error);
      toast.error('Erro ao calcular pontuação');
    } finally {
      setLoading(false);
    }
  };

  if (showResults) {
    const correctAnswers = answers.reduce((acc, answer, index) => {
      return acc + (answer === quiz.questions[index].correctOption ? 1 : 0);
    }, 0);
    const score = (correctAnswers / quiz.questions.length) * 10;

    return (
      <div className="text-center py-8">
        <div className="mb-4">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-blue-100">
            <CheckCircle className="w-8 h-8 text-blue-600" />
          </div>
        </div>
        <h3 className="text-xl font-semibold mb-2">Quiz Concluído!</h3>
        <p className="text-gray-600 mb-4">
          Você acertou {correctAnswers} de {quiz.questions.length} questões.
        </p>
        <p className="text-2xl font-bold text-blue-600 mb-6">
          Nota: {score.toFixed(1)}
        </p>
        <div className="space-y-4">
          {quiz.questions.map((question, index) => (
            <div
              key={index}
              className={`p-4 rounded-lg ${
                answers[index] === question.correctOption
                  ? 'bg-green-50'
                  : 'bg-red-50'
              }`}
            >
              <div className="flex items-start">
                <div className="flex-shrink-0 mt-0.5">
                  {answers[index] === question.correctOption ? (
                    <CheckCircle className="w-5 h-5 text-green-500" />
                  ) : (
                    <XCircle className="w-5 h-5 text-red-500" />
                  )}
                </div>
                <div className="ml-3">
                  <p className="text-sm font-medium text-gray-900">
                    {question.text}
                  </p>
                  <p className="mt-1 text-sm text-gray-600">
                    Resposta correta: {question.options[question.correctOption]}
                  </p>
                  {answers[index] !== question.correctOption && (
                    <p className="mt-1 text-sm text-red-600">
                      Sua resposta: {question.options[answers[index]]}
                    </p>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="py-4">
      <div className="mb-6">
        <div className="flex justify-between items-center mb-4">
          <span className="text-sm font-medium text-gray-500">
            Página {currentPage + 1} de {totalPages}
          </span>
          <span className="text-sm font-medium text-gray-500">
            {answers.filter(a => a !== undefined).length} de {quiz.questions.length} questões respondidas
          </span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-2">
          <div
            className="bg-blue-600 h-2 rounded-full transition-all duration-300"
            style={{
              width: `${(answers.filter(a => a !== undefined).length / quiz.questions.length) * 100}%`,
            }}
          />
        </div>
      </div>

      <div className="space-y-8">
        {currentQuestions.map((question, index) => (
          <div key={startIndex + index} className="space-y-4">
            <h3 className="text-lg font-medium text-gray-900">
              {startIndex + index + 1}. {question.text}
            </h3>

            <div className="space-y-3">
              {question.options.map((option, optionIndex) => (
                <button
                  key={optionIndex}
                  onClick={() => handleAnswer(index, optionIndex)}
                  className={`w-full text-left p-4 rounded-lg border transition-all duration-200 ${
                    answers[startIndex + index] === optionIndex
                      ? 'border-blue-500 bg-blue-50 ring-2 ring-blue-200'
                      : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'
                  }`}
                >
                  <div className="flex items-center">
                    <div
                      className={`flex-shrink-0 w-5 h-5 border rounded-full mr-3 ${
                        answers[startIndex + index] === optionIndex
                          ? 'border-blue-500 bg-blue-500'
                          : 'border-gray-300'
                      }`}
                    >
                      {answers[startIndex + index] === optionIndex && (
                        <div className="w-full h-full flex items-center justify-center">
                          <div className="w-2 h-2 bg-white rounded-full" />
                        </div>
                      )}
                    </div>
                    <span className={
                      answers[startIndex + index] === optionIndex
                        ? 'text-blue-900'
                        : 'text-gray-700'
                    }>
                      {option}
                    </span>
                  </div>
                </button>
              ))}
            </div>
          </div>
        ))}
      </div>

      <div className="mt-6 flex justify-between">
        <button
          onClick={() => setCurrentPage(prev => prev - 1)}
          disabled={currentPage === 0}
          className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Anterior
        </button>

        {currentPage === totalPages - 1 ? (
          <button
            onClick={handleSubmit}
            disabled={loading || answers.length < quiz.questions.length}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
          >
            {loading ? 'Finalizando...' : 'Finalizar Quiz'}
          </button>
        ) : (
          <button
            onClick={() => setCurrentPage(prev => prev + 1)}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
          >
            Próxima
            <ArrowRight className="ml-2 w-4 h-4" />
          </button>
        )}
      </div>
    </div>
  );
}