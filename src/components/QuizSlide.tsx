import React, { useState } from 'react';
import { Question } from '../types';
import { ChevronLeft, ChevronRight, Check } from 'lucide-react';

interface QuizSlideProps {
  questions: Question[];
  onComplete: (score: number) => void;
}

export function QuizSlide({ questions, onComplete }: QuizSlideProps) {
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState<number[]>([]);
  const [submitted, setSubmitted] = useState(false);

  const handleAnswer = (optionIndex: number) => {
    const newAnswers = [...answers];
    newAnswers[currentQuestion] = optionIndex;
    setAnswers(newAnswers);
  };

  const handleNext = () => {
    if (currentQuestion < questions.length - 1) {
      setCurrentQuestion(currentQuestion + 1);
    }
  };

  const handlePrevious = () => {
    if (currentQuestion > 0) {
      setCurrentQuestion(currentQuestion - 1);
    }
  };

  const handleSubmit = () => {
    const score = questions.reduce((acc, question, index) => {
      return acc + (answers[index] === question.correctOption ? 1 : 0);
    }, 0);
    const finalScore = (score / questions.length) * 10;
    setSubmitted(true);
    onComplete(finalScore);
  };

  const question = questions[currentQuestion];

  return (
    <div className="bg-white p-6 rounded-lg shadow-lg max-w-2xl mx-auto">
      {submitted ? (
        <div className="text-center py-12">
          <div className="flex justify-center">
            <div className="rounded-full bg-green-100 p-3">
              <Check className="w-8 h-8 text-green-600" />
            </div>
          </div>
          <h3 className="mt-4 text-xl font-semibold text-gray-900">Quiz Completed!</h3>
          <p className="mt-2 text-gray-600">Your answers have been submitted successfully.</p>
        </div>
      ) : (
        <>
          <div className="mb-8">
            <div className="flex justify-between items-center mb-6">
              <span className="text-sm font-medium text-gray-500">
                Question {currentQuestion + 1} of {questions.length}
              </span>
              <div className="flex gap-2">
                <button
                  onClick={handlePrevious}
                  disabled={currentQuestion === 0}
                  className="p-2 rounded-full hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <ChevronLeft className="w-5 h-5" />
                </button>
                <button
                  onClick={handleNext}
                  disabled={currentQuestion === questions.length - 1}
                  className="p-2 rounded-full hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <ChevronRight className="w-5 h-5" />
                </button>
              </div>
            </div>
            
            <div className="w-full bg-gray-200 rounded-full h-1.5 mb-6">
              <div
                className="bg-blue-600 h-1.5 rounded-full transition-all duration-300"
                style={{ width: `${((currentQuestion + 1) / questions.length) * 100}%` }}
              ></div>
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
                    <div className={`flex-shrink-0 w-5 h-5 border rounded-full mr-3 ${
                      answers[currentQuestion] === index
                        ? 'border-blue-500 bg-blue-500'
                        : 'border-gray-300'
                    }`}>
                      {answers[currentQuestion] === index && (
                        <div className="w-full h-full flex items-center justify-center">
                          <div className="w-2 h-2 bg-white rounded-full"></div>
                        </div>
                      )}
                    </div>
                    <span className={`${
                      answers[currentQuestion] === index ? 'text-blue-900' : 'text-gray-700'
                    }`}>
                      {option}
                    </span>
                  </div>
                </button>
              ))}
            </div>
          </div>

          {currentQuestion === questions.length - 1 && answers.length === questions.length && (
            <div className="mt-8">
              <button
                onClick={handleSubmit}
                className="w-full py-3 px-4 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors duration-200"
              >
                Submit Quiz
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}