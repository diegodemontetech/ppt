import React, { useState, useEffect } from 'react';
import { Layout } from '../components/Layout';
import { SupportKanban } from '../components/support/SupportKanban';
import { NewTicketModal } from '../components/support/NewTicketModal';
import { Plus } from 'lucide-react';
import { useSupportStore } from '../store/supportStore';

export default function SupportPage() {
  const { tickets, loading, fetchTickets } = useSupportStore();
  const [showNewTicket, setShowNewTicket] = useState(false);

  useEffect(() => {
    fetchTickets();
  }, []);

  return (
    <Layout title="Suporte">
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-semibold text-gray-900">
            Central de Suporte
          </h1>
          <button
            onClick={() => setShowNewTicket(true)}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
          >
            <Plus className="w-4 h-4 mr-2" />
            Novo Ticket
          </button>
        </div>

        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
          </div>
        ) : (
          <SupportKanban tickets={tickets} />
        )}

        {showNewTicket && (
          <NewTicketModal
            onClose={() => setShowNewTicket(false)}
            onSuccess={() => {
              setShowNewTicket(false);
              fetchTickets();
            }}
          />
        )}
      </div>
    </Layout>
  );
}