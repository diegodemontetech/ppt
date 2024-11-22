import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { Layout } from '../components/Layout';
import toast from 'react-hot-toast';

export default function SignContract() {
  const { contractId, token } = useParams();
  const [contract, setContract] = useState<any>(null);
  const [signatory, setSignatory] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [signing, setSigning] = useState(false);

  useEffect(() => {
    fetchContract();
  }, [contractId, token]);

  const fetchContract = async () => {
    try {
      // Fetch contract and signatory details
      const { data: contracts, error: contractError } = await supabase
        .from('contracts')
        .select(`
          *,
          signatories:contract_signatories(*)
        `)
        .eq('id', contractId)
        .single();

      if (contractError) throw contractError;

      // Find matching signatory
      const matchingSignatory = contracts.signatories.find(
        (s: any) => s.sign_token === token
      );

      if (!matchingSignatory) {
        throw new Error('Link de assinatura inválido');
      }

      if (matchingSignatory.signed_at) {
        throw new Error('Este documento já foi assinado');
      }

      setContract(contracts);
      setSignatory(matchingSignatory);
    } catch (error: any) {
      console.error('Error fetching contract:', error);
      toast.error(error.message || 'Erro ao carregar contrato');
    } finally {
      setLoading(false);
    }
  };

  const handleSign = async () => {
    try {
      setSigning(true);

      // Call secure RPC function to sign contract
      const { error } = await supabase.rpc('sign_contract', {
        contract_uuid: contractId,
        signatory_uuid: signatory.id,
        signature_url: '', // Would be replaced with actual signature image URL
        ip_address: await fetch('https://api.ipify.org?format=json').then(r => r.json()).then(data => data.ip),
        user_agent: navigator.userAgent
      });

      if (error) throw error;

      toast.success('Documento assinado com sucesso!');
      window.location.reload();
    } catch (error: any) {
      console.error('Error signing contract:', error);
      toast.error('Erro ao assinar documento');
    } finally {
      setSigning(false);
    }
  };

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
        </div>
      </Layout>
    );
  }

  if (!contract || !signatory) {
    return (
      <Layout>
        <div className="text-center py-12">
          <p className="text-red-500">Link de assinatura inválido ou expirado</p>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="max-w-4xl mx-auto">
        <div className="bg-white shadow-lg rounded-lg overflow-hidden">
          <div className="p-6">
            <h1 className="text-2xl font-bold text-gray-900 mb-4">
              {contract.title}
            </h1>

            {/* Contract content */}
            <div 
              className="prose max-w-none mb-8"
              dangerouslySetInnerHTML={{ __html: contract.content }}
            />

            {/* Signatory info */}
            <div className="bg-gray-50 p-4 rounded-lg mb-6">
              <h3 className="font-medium text-gray-900">Informações do Signatário</h3>
              <p className="text-gray-600">{signatory.name}</p>
              <p className="text-gray-600">{signatory.email}</p>
              <p className="text-gray-600">{signatory.role}</p>
            </div>

            {/* Sign button */}
            <div className="flex justify-end">
              <button
                onClick={handleSign}
                disabled={signing}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
              >
                {signing ? 'Assinando...' : 'Assinar Documento'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}