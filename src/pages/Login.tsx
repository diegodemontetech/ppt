import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Lock, Mail } from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { supabase } from '../lib/supabase';

function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [companySettings, setCompanySettings] = useState<any>(null);
  const navigate = useNavigate();
  const { signIn, user } = useAuthStore();

  useEffect(() => {
    if (user) {
      navigate('/');
    }
    fetchCompanySettings();
  }, [user, navigate]);

  const fetchCompanySettings = async () => {
    try {
      // Get subdomain from window.location
      const hostname = window.location.hostname;
      const subdomain = hostname.split('.')[0];
      
      // Skip if no subdomain or localhost
      if (!subdomain || hostname === 'localhost') {
        return;
      }

      const { data, error } = await supabase
        .from('companies')
        .select('*')
        .eq('subdomain', subdomain)
        .single();

      if (error && error.code !== 'PGRST116') throw error;
      if (data) {
        setCompanySettings(data);
        // Set favicon if provided
        if (data.favicon_url) {
          const favicon = document.querySelector<HTMLLinkElement>('link[rel="icon"]');
          if (favicon) {
            favicon.href = data.favicon_url;
          }
        }
      }
    } catch (error) {
      console.error('Error fetching company settings:', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    
    try {
      await signIn(email, password);
    } catch (err: any) {
      setError(err.message || 'Failed to sign in');
    }
  };

  const backgroundStyle = companySettings?.login_bg_url
    ? { backgroundImage: `url(${companySettings.login_bg_url})` }
    : { backgroundColor: '#f3f4f6' };

  return (
    <div 
      className="min-h-screen bg-cover bg-center bg-no-repeat flex flex-col justify-center py-12 sm:px-6 lg:px-8"
      style={backgroundStyle}
    >
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="flex justify-center">
          {companySettings?.logo_url ? (
            <img 
              src={companySettings.logo_url} 
              alt="Logo" 
              className="h-12 w-auto object-contain"
              crossOrigin="anonymous"
            />
          ) : (
            <img 
              src="https://i.ibb.co/1zxnNry/download.png" 
              alt="Logo" 
              className="h-12 w-auto object-contain"
              crossOrigin="anonymous"
            />
          )}
        </div>
        <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
          {companySettings?.name || 'Plataforma EAD'}
        </h2>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          <form className="space-y-6" onSubmit={handleSubmit}>
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-md text-sm">
                {error}
              </div>
            )}

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                Email
              </label>
              <div className="mt-1 relative rounded-md shadow-sm">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Mail className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  id="email"
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-red-500 focus:border-red-500 sm:text-sm"
                  placeholder="you@example.com"
                />
              </div>
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                Senha
              </label>
              <div className="mt-1 relative rounded-md shadow-sm">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  id="password"
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-red-500 focus:border-red-500 sm:text-sm"
                />
              </div>
            </div>

            <div>
              <button
                type="submit"
                className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
              >
                Entrar
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

export default Login;