import React, { useState, useEffect } from 'react';
import { Layout } from '../components/Layout';
import { Plus, Download } from 'lucide-react';
import { useDocBoxStore } from '../store/docboxStore';
import { DocBoxFilters } from '../components/docbox/DocBoxFilters';
import { DocBoxGrid } from '../components/docbox/DocBoxGrid';
import { DocBoxUpload } from '../components/docbox/DocBoxUpload';
import toast from 'react-hot-toast';

export default function DocBoxPage() {
  const { 
    documents, 
    loading, 
    filters,
    fetchDocuments, 
    fetchCategories,
    downloadDocument,
    setFilters 
  } = useDocBoxStore();
  
  const [selectedItems, setSelectedItems] = useState<string[]>([]);
  const [showUpload, setShowUpload] = useState(false);

  useEffect(() => {
    fetchDocuments();
    fetchCategories();
  }, []);

  // Filter documents based on current filters
  const filteredDocuments = documents.filter(doc => {
    if (filters.fileType.length && !filters.fileType.includes(doc.file_type)) return false;
    if (filters.category.length && !filters.category.includes(doc.category_id)) return false;
    if (filters.search && !doc.title.toLowerCase().includes(filters.search.toLowerCase())) return false;
    return true;
  });

  const handleDownloadSelected = async () => {
    const itemsToDownload = documents.filter(doc => selectedItems.includes(doc.id));
    for (const doc of itemsToDownload) {
      await downloadDocument(doc);
    }
    setSelectedItems([]);
  };

  return (
    <Layout title="DocBox">
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <DocBoxFilters />
          
          <div className="flex items-center space-x-4">
            {selectedItems.length > 0 && (
              <button
                onClick={handleDownloadSelected}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
              >
                <Download className="w-4 h-4 mr-2" />
                Download ({selectedItems.length})
              </button>
            )}

            <button
              onClick={() => setShowUpload(true)}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
            >
              <Plus className="w-4 h-4 mr-2" />
              Upload
            </button>
          </div>
        </div>

        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
          </div>
        ) : (
          <DocBoxGrid
            documents={filteredDocuments}
            selectedItems={selectedItems}
            onSelectItem={(id) => {
              setSelectedItems(prev => 
                prev.includes(id) 
                  ? prev.filter(i => i !== id)
                  : [...prev, id]
              );
            }}
          />
        )}
      </div>

      {showUpload && (
        <DocBoxUpload
          onClose={() => setShowUpload(false)}
          onSuccess={() => {
            setShowUpload(false);
            fetchDocuments();
          }}
        />
      )}
    </Layout>
  );
}