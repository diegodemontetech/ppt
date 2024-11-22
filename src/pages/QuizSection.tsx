import React, { useState } from 'react';
import { CheckCircle, XCircle, ArrowRight } from 'lucide-react';
import type { Quiz } from '../types';

interface QuizSectionProps {
  quiz: Quiz;
  onComplete: (score: number) => void;
}

export default function QuizSection({ quiz, onComplete }: QuizSectionProps) {
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState<number[]>([]);
  const [showResults, setShowResults] = useState(false);

  const handleAnswer = (optionIndex: number) => {
    const newAnswers = [...answers];
    newAnswers[currentQuestion] = optionIndex;
    setAnswers(newAnswers);
  };

  const handleNext = () => {
    if (currentQuestion < quiz.questions.length - 1) {
      setCurrentQuestion(currentQuestion + 1);
    } else if (answers.length === quiz.questions.length) {
      calculateScore();
    }
  };

  const calculateScore = () => {
    const correctAnswers = answers.reduce((acc, answer, index) => {
      return acc + (answer === quiz.questions[index].correctOption ? 1 : 0);
    }, 0);
    const score = (correctAnswers / quiz.questions.length) * 10;
    setShowResults(true);
    onComplete(score);
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

  const question = quiz.questions[currentQuestion];

  return (
    <div className="py-4">
      <div className="mb-6">
        <div className="flex justify-between items-center mb-4">
          <span className="text-sm font-medium text-gray-500">
            Questão {currentQuestion + 1} de {quiz.questions.length}
          </span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-2">
          <div
            className="bg-blue-600 h-2 rounded-full transition-all duration-300"
            style={{
              width: `${((currentQuestion + 1) / quiz.questions.length) * 100}%`,
            }}
          />
        </div>
      </div>

      <h3 className="text-lg font-medium text-gray-900 mb-6">{question.text}</h3>

      <div className="space-y-3">
        {question.options.map((option, index) => (
          <button
            key={index}
            onClick={() => handleAnswer(index)}
            className={`w-full text-left p-4 rounded-lg border transition-all duration-200 ${
              answers[currentQuestion] === index
                ? 'border-blue-500 bg-blue-50 ring-2 ring-blue-200'
                : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'
            }`}
          >
            <div className="flex items-center">
              <div
                className={`flex-shrink-0 w-5 h-5 border rounded-full mr-3 ${
                  answers[currentQuestion] === index
                    ? 'border-blue-500 bg-blue-500'
                    : 'border-gray-300'
                }`}
              >
                {answers[currentQuestion] === index && (
                  <div className="w-full h-full flex items-center justify-center">
                    <div className="w-2 h-2 bg-white rounded-full" />
                  </div>
                )}
              </div>
              <span
                className={
                  answers[currentQuestion] === index
                    ? 'text-blue-900'
                    : 'text-gray-700'
                }
              >
                {option}
              </span>
            </div>
          </button>
        ))}
      </div>

      {answers[currentQuestion] !== undefined && (
        <div className="mt-6 flex justify-end">
          <button
            onClick={handleNext}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
          >
            {currentQuestion === quiz.questions.length - 1 ? (
              'Finalizar Quiz'
            ) : (
              <>
                Próxima Questão
                <ArrowRight className="ml-2 w-4 h-4" />
              </>
            )}
          </button>
        </div>
      )}
    </div>
  );
}