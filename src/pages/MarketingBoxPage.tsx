import React, { useEffect, useState } from 'react';
import { Layout } from '../components/Layout';
import { useMarketingBoxStore } from '../store/marketingBoxStore';
import { MarketingBoxFilters } from '../components/marketingBox/MarketingBoxFilters';
import { MarketingBoxGrid } from '../components/marketingBox/MarketingBoxGrid';
import { MarketingBoxUpload } from '../components/marketingBox/MarketingBoxUpload';
import { Download, Upload } from 'lucide-react';

export default function MarketingBoxPage() {
  const { 
    items, 
    loading, 
    filters,
    fetchItems, 
    fetchCategories,
    downloadItems,
    setFilters 
  } = useMarketingBoxStore();
  
  const [selectedItems, setSelectedItems] = useState<string[]>([]);
  const [showUpload, setShowUpload] = useState(false);

  useEffect(() => {
    fetchItems();
    fetchCategories();
  }, []);

  // Filter items based on current filters
  const filteredItems = items.filter(item => {
    if (filters.fileType.length && !filters.fileType.includes(item.file_type)) return false;
    if (filters.mediaType.length && !filters.mediaType.includes(item.media_type)) return false;
    if (filters.resolution.length && !filters.resolution.includes(item.resolution || '')) return false;
    if (filters.category.length && !filters.category.includes(item.category)) return false;
    if (filters.search && !item.title.toLowerCase().includes(filters.search.toLowerCase())) return false;
    return true;
  });

  const handleDownloadSelected = async () => {
    const itemsToDownload = items.filter(item => selectedItems.includes(item.id));
    await downloadItems(itemsToDownload);
    setSelectedItems([]);
  };

  return (
    <Layout title="Marketing BOX">
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <MarketingBoxFilters />
          
          <div className="flex items-center space-x-4">
            {selectedItems.length > 0 && (
              <button
                onClick={handleDownloadSelected}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
              >
                <Download className="w-4 h-4 mr-2" />
                Download Selecionados ({selectedItems.length})
              </button>
            )}

            <button
              onClick={() => setShowUpload(true)}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
            >
              <Upload className="w-4 h-4 mr-2" />
              Upload
            </button>
          </div>
        </div>

        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
          </div>
        ) : (
          <MarketingBoxGrid
            items={filteredItems}
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
        <MarketingBoxUpload
          onClose={() => setShowUpload(false)}
          onSuccess={() => {
            setShowUpload(false);
            fetchItems();
          }}
        />
      )}
    </Layout>
  );
}