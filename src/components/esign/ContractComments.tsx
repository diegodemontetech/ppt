import React, { useState } from 'react';
import { useESignStore } from '../../store/esignStore';

interface ContractCommentsProps {
  contractId: string;
}

export function ContractComments({ contractId }: ContractCommentsProps) {
  const { comments, addComment } = useESignStore();
  const [newComment, setNewComment] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newComment.trim()) return;

    await addComment(contractId, newComment);
    setNewComment('');
  };

  return (
    <div className="space-y-4">
      <form onSubmit={handleSubmit} className="space-y-3">
        <textarea
          value={newComment}
          onChange={(e) => setNewComment(e.target.value)}
          placeholder="Digite seu comentário..."
          className="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          rows={3}
        />
        <button
          type="submit"
          className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
        >
          Adicionar Comentário
        </button>
      </form>

      <div className="space-y-4">
        {comments.map((comment) => (
          <div key={comment.id} className="bg-gray-50 rounded-lg p-4">
            <div className="text-sm text-gray-500">
              {new Date(comment.created_at).toLocaleString()}
            </div>
            <div className="mt-1 text-sm text-gray-900">
              {comment.content}
            </div>
          </div>
        ))}

        {comments.length === 0 && (
          <p className="text-sm text-gray-500 text-center py-4">
            Nenhum comentário
          </p>
        )}
      </div>
    </div>
  );
}