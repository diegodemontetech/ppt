import { createClient } from '@supabase/supabase-js';
import toast from 'react-hot-toast';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

// Create retryable fetch function
const createRetryableFetch = (maxRetries = 3, baseDelay = 1000) => {
  return async (url: string, options: any = {}) => {
    let attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        const response = await fetch(url, {
          ...options,
          headers: {
            ...options.headers,
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache'
          },
          credentials: 'include'
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        return response;
      } catch (error) {
        attempt++;
        
        if (attempt === maxRetries) {
          throw error;
        }

        // Exponential backoff
        await new Promise(resolve => 
          setTimeout(resolve, baseDelay * Math.pow(2, attempt - 1))
        );
      }
    }
  };
};

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  },
  global: {
    headers: {
      'x-custom-header': 'ead-platform'
    }
  },
  db: {
    schema: 'public'
  },
  fetch: createRetryableFetch()
});

// Add connection status monitoring
let isOffline = false;

window.addEventListener('online', () => {
  if (isOffline) {
    isOffline = false;
    toast.success('Conexão restaurada!');
    // Trigger data refresh
    window.dispatchEvent(new CustomEvent('connection-restored'));
  }
});

window.addEventListener('offline', () => {
  isOffline = true;
  toast.error('Sem conexão com a internet');
});

export const handleSupabaseError = (error: any) => {
  console.error('Supabase Error:', error);
  
  if (!navigator.onLine) {
    toast.error('Sem conexão com a internet. Por favor, verifique sua conexão e tente novamente.');
    return;
  }

  if (error.code === 'PGRST301' || error.code === '401') {
    toast.error('Sua sessão expirou. Por favor, faça login novamente.');
    supabase.auth.signOut();
    return;
  }

  if (error.code === '42501') {
    toast.error('Você não tem permissão para realizar esta ação.');
    return;
  }

  if (error.code === '23505') {
    toast.error('Este registro já existe.');
    return;
  }

  if (error.code === '42P01') {
    console.warn('Table not found, refreshing schema cache...');
    supabase.rpc('reload_schema').catch(() => {
      // Ignore error if RPC not available
    });
    return;
  }

  if (error.message?.includes('Failed to fetch')) {
    toast.error('Erro de conexão. Verifique sua internet e tente novamente.');
    return;
  }

  if (error.code === 'PGRST200') {
    console.warn('Schema cache error, refreshing...');
    supabase.rpc('reload_schema').catch(() => {
      // Ignore error if RPC not available
    });
    return;
  }

  // Add retry mechanism for specific errors
  if (error.code === 'PGRST204' || error.code === 'PGRST116') {
    return new Promise((resolve) => {
      setTimeout(() => {
        console.warn('Retrying operation after schema error...');
        resolve(null);
      }, 1000);
    });
  }

  toast.error(error.message || 'Ocorreu um erro. Por favor, tente novamente.');
};