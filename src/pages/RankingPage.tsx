import React from 'react';
import { Layout } from '../components/Layout';
import { Ranking } from '../components/Ranking';

export default function RankingPage() {
  return (
    <Layout title="Ranking">
      <div className="max-w-3xl mx-auto">
        <Ranking />
      </div>
    </Layout>
  );
}