import React from 'react';
import { Calendar, Clock, Users, Bell } from 'lucide-react';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';

interface LiveClassProps {
  id: string;
  title: string;
  description: string;
  instructor_name: string;
  instructor_email: string;
  meeting_url: string;
  starts_at: string;
  duration: number;
  attendees_count: number;
  isSubscribed?: boolean;
  onSubscribe?: () => void;
}

export function LiveClass({
  title,
  description,
  instructor_name,
  instructor_email,
  meeting_url,
  starts_at,
  duration,
  attendees_count,
  isSubscribed,
  onSubscribe
}: LiveClassProps) {
  const startTime = new Date(starts_at);
  const isLive = new Date() >= startTime && 
                 new Date() <= new Date(startTime.getTime() + duration * 60000);

  return (
    <div className="bg-white rounded-lg shadow-sm p-4 sm:p-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center">
        <div>
          <h3 className="text-lg font-medium text-gray-900">{title}</h3>
          <p className="mt-1 text-sm text-gray-500">{description}</p>
        </div>
        {isLive && (
          <span className="mt-2 sm:mt-0 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
            AO VIVO
          </span>
        )}
      </div>

      <div className="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div className="flex items-center text-sm text-gray-500">
          <Calendar className="w-4 h-4 mr-2" />
          {format(startTime, "dd 'de' MMMM", { locale: ptBR })}
        </div>
        <div className="flex items-center text-sm text-gray-500">
          <Clock className="w-4 h-4 mr-2" />
          {format(startTime, 'HH:mm')} ({duration} min)
        </div>
      </div>

      <div className="mt-4">
        <p className="text-sm font-medium text-gray-900">Instrutor</p>
        <p className="text-sm text-gray-500">{instructor_name || instructor_email}</p>
      </div>

      <div className="mt-4 flex flex-col sm:flex-row items-start sm:items-center justify-between">
        <div className="flex items-center text-sm text-gray-500 mb-4 sm:mb-0">
          <Users className="w-4 h-4 mr-2" />
          {attendees_count} participantes
        </div>

        <div className="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-4 w-full sm:w-auto">
          {!isSubscribed && onSubscribe && (
            <button
              onClick={onSubscribe}
              className="w-full sm:w-auto inline-flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
            >
              <Bell className="w-4 h-4 mr-2" />
              Quero participar
            </button>
          )}

          {(isLive || isSubscribed) && (
            <a
              href={meeting_url}
              target="_blank"
              rel="noopener noreferrer"
              className={`w-full sm:w-auto inline-flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white ${
                isLive
                  ? 'bg-blue-600 hover:bg-blue-700'
                  : 'bg-gray-400 cursor-not-allowed'
              }`}
              onClick={(e) => !isLive && e.preventDefault()}
            >
              {isLive ? 'Entrar na Aula' : 'Aula não iniciada'}
            </a>
          )}
        </div>
      </div>
    </div>
  );
}