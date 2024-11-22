import React, { useState, useEffect } from 'react';
import { X, MessageSquare, Paperclip, Clock, AlertCircle } from 'lucide-react';
import { useSupportStore } from '../../store/supportStore';
import { RichTextEditor } from '../RichTextEditor';
import { FileUploader } from '../FileUploader';
import { formatDistanceToNow, format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import type { SupportTicket } from '../../types/support';

interface TicketDetailsProps {
  ticket: SupportTicket;
  onClose: () => void;
}

export function TicketDetails({ ticket, onClose }: TicketDetailsProps) {
  const { updateTicket, addComment, addAttachment, getTicketHistory } = useSupportStore();
  const [comment, setComment] = useState('');
  const [history, setHistory] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchHistory();
  }, [ticket.id]);

  const fetchHistory = async () => {
    const historyData = await getTicketHistory(ticket.id);
    setHistory(historyData);
  };

  const handleAddComment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!comment.trim()) return;

    try {
      setLoading(true);
      await addComment(ticket.id, comment);
      setComment('');
      fetchHistory();
    } catch (error) {
      console.error('Error adding comment:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleFileUpload = async (file: File) => {
    try {
      setLoading(true);
      await addAttachment(ticket.id, file);
      fetchHistory();
    } catch (error) {
      console.error('Error uploading file:', error);
    } finally {
      setLoading(false);
    }
  };

  const getSLAStatus = () => {
    const now = new Date();
    const responseAt = ticket.sla_response_at ? new Date(ticket.sla_response_at) : null;
    const resolutionAt = ticket.sla_resolution_at ? new Date(ticket.sla_resolution_at) : null;

    if (ticket.status === 'open' && responseAt && now > responseAt) {
      return {
        message: 'SLA de resposta ultrapassado',
        color: 'text-red-600'
      };
    }

    if (resolutionAt && now > resolutionAt) {
      return {
        message: 'SLA de resolução ultrapassado',
        color: 'text-red-600'
      };
    }

    if (responseAt && now <= responseAt) {
      return {
        message: `Resposta em até ${formatDistanceToNow(responseAt, { locale: ptBR })}`,
        color: 'text-yellow-600'
      };
    }

    if (resolutionAt && now <= resolutionAt) {
      return {
        message: `Resolução em até ${formatDistanceToNow(resolutionAt, { locale: ptBR })}`,
        color: 'text-yellow-600'
      };
    }

    return null;
  };

  const slaStatus = getSLAStatus();

  return (
    <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] overflow-hidden">
        <div className="flex h-full">
          {/* Left panel - Ticket details */}
          <div className="flex-1 overflow-y-auto p-6 border-r border-gray-200">
            <div className="flex justify-between items-start mb-6">
              <div>
                <h2 className="text-lg font-medium text-gray-900">
                  {ticket.title}
                </h2>
                <div className="mt-1 text-sm text-gray-500">
                  Aberto {formatDistanceToNow(new Date(ticket.created_at), { 
                    addSuffix: true,
                    locale: ptBR 
                  })}
                </div>
              </div>
              <button
                onClick={onClose}
                className="text-gray-400 hover:text-gray-500"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="prose max-w-none" dangerouslySetInnerHTML={{ __html: ticket.description }} />

            <div className="mt-6 border-t pt-6">
              <h3 className="text-sm font-medium text-gray-900">Comentários</h3>
              
              <form onSubmit={handleAddComment} className="mt-4 space-y-4">
                <RichTextEditor
                  value={comment}
                  onChange={setComment}
                  placeholder="Adicione um comentário..."
                />
                <div className="flex justify-end">
                  <button
                    type="submit"
                    disabled={loading || !comment.trim()}
                    className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
                  >
                    <MessageSquare className="w-4 h-4 mr-2" />
                    Comentar
                  </button>
                </div>
              </form>

              <div className="mt-6 space-y-4">
                {history.map((item) => (
                  <div key={item.id} className="bg-gray-50 rounded-lg p-4">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm font-medium text-gray-900">
                        {item.user?.full_name || item.user?.email}
                      </span>
                      <span className="text-xs text-gray-500">
                        {format(new Date(item.created_at), "dd/MM/yyyy 'às' HH:mm", {
                          locale: ptBR
                        })}
                      </span>
                    </div>
                    {item.action === 'comment' ? (
                      <div className="text-sm text-gray-700" dangerouslySetInnerHTML={{ __html: item.details.content }} />
                    ) : (
                      <div className="text-sm text-gray-500">
                        {item.action === 'status_changed' && (
                          <>Alterou o status de <b>{item.details.old_status}</b> para <b>{item.details.new_status}</b></>
                        )}
                        {item.action === 'assigned' && (
                          <>Atribuiu o ticket para <b>{item.details.new_assigned_to}</b></>
                        )}
                        {item.action === 'attachment_added' && (
                          <>Anexou o arquivo <b>{item.details.file_name}</b></>
                        )}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Right panel - Status and info */}
          <div className="w-80 p-6 bg-gray-50">
            <div className="space-y-6">
              <div>
                <h3 className="text-sm font-medium text-gray-900">Status</h3>
                <select
                  value={ticket.status}
                  onChange={(e) => updateTicket(ticket.id, { status: e.target.value as any })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="open">Aberto</option>
                  <option value="in_progress">Em Atendimento</option>
                  <option value="partially_resolved">Resolvido Parcialmente</option>
                  <option value="resolved">Resolvido</option>
                  <option value="finished">Finalizado</option>
                </select>
              </div>

              <div>
                <h3 className="text-sm font-medium text-gray-900">Prioridade</h3>
                <select
                  value={ticket.priority}
                  onChange={(e) => updateTicket(ticket.id, { priority: e.target.value as any })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="urgent">Urgente</option>
                  <option value="medium">Médio</option>
                  <option value="low">Baixo</option>
                </select>
              </div>

              {slaStatus && (
                <div className={`flex items-center ${slaStatus.color}`}>
                  <Clock className="w-4 h-4 mr-2" />
                  {slaStatus.message}
                </div>
              )}

              <div>
                <h3 className="text-sm font-medium text-gray-900">Anexos</h3>
                <div className="mt-2">
                  <FileUploader
                    onUpload={handleFileUpload}
                    maxSize={10 * 1024 * 1024} // 10MB
                    accept={{
                      'image/*': ['.png', '.jpg', '.jpeg', '.gif'],
                      'application/pdf': ['.pdf'],
                      'application/msword': ['.doc'],
                      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx']
                    }}
                  />
                </div>
                <div className="mt-4 space-y-2">
                  {ticket.attachments?.map((attachment: any) => (
                    <a
                      key={attachment.id}
                      href={attachment.file_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center p-2 text-sm text-gray-600 bg-white rounded-md hover:bg-gray-50"
                    >
                      <Paperclip className="w-4 h-4 mr-2" />
                      {attachment.file_name}
                    </a>
                  ))}
                </div>
              </div>

              <div className="border-t pt-6">
                <h3 className="text-sm font-medium text-gray-900 mb-4">Histórico</h3>
                <div className="space-y-3">
                  {history.map((item) => (
                    <div key={item.id} className="text-xs text-gray-500">
                      {format(new Date(item.created_at), "dd/MM/yyyy 'às' HH:mm", {
                        locale: ptBR
                      })} - {item.action}
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}