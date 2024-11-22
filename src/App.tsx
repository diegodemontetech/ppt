import React, { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { useAuthStore } from './store/authStore';

// Pages
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import CoursesPage from './pages/CoursesPage';
import EBooksPage from './pages/EBooksPage';
import LiveClassesPage from './pages/LiveClassesPage';
import NotificationsPage from './pages/NotificationsPage';
import ProfilePage from './pages/ProfilePage';
import PipelinesPage from './pages/PipelinesPage';
import MarketingBoxPage from './pages/MarketingBoxPage';
import DocBoxPage from './pages/DocBoxPage';
import ESignPage from './pages/ESignPage';
import SupportPage from './pages/SupportPage';
import CourseView from './pages/CourseView';
import AdminDashboard from './pages/AdminDashboard';

// Admin Pages
import DepartmentsSettings from './pages/admin/Settings/DepartmentsSettings';
import CategoriesSettings from './pages/admin/Settings/CategoriesSettings';
import CoursesSettings from './pages/admin/Settings/CoursesSettings';
import LessonsSettings from './pages/admin/Settings/LessonsSettings';
import QuizSettings from './pages/admin/Settings/QuizSettings';
import EBooksSettings from './pages/admin/Settings/EBooksSettings';
import LiveEventsSettings from './pages/admin/Settings/LiveEventsSettings';
import UsersSettings from './pages/admin/Settings/UsersSettings';
import GroupsSettings from './pages/admin/Settings/GroupsSettings';
import NewsSettings from './pages/admin/Settings/NewsSettings';
import PipelinesSettings from './pages/admin/Settings/PipelinesSettings';
import MarketingBoxSettings from './pages/admin/Settings/MarketingBoxSettings';
import DocBoxSettings from './pages/admin/Settings/DocBoxSettings';
import ESignSettings from './pages/admin/Settings/ESignSettings';
import MagicLearningSettings from './pages/admin/Settings/MagicLearningSettings';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requireAdmin?: boolean;
}

const ProtectedRoute = ({ children, requireAdmin = false }: ProtectedRouteProps) => {
  const { user, isAdmin } = useAuthStore();

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (requireAdmin && !isAdmin) {
    return <Navigate to="/" replace />;
  }

  return children;
};

function App() {
  const { checkAuth, loading } = useAuthStore();

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-red-500"></div>
      </div>
    );
  }

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        
        <Route path="/" element={
          <ProtectedRoute>
            <Dashboard />
          </ProtectedRoute>
        } />
        
        <Route path="/courses" element={
          <ProtectedRoute>
            <CoursesPage />
          </ProtectedRoute>
        } />

        <Route path="/course/:moduleId" element={
          <ProtectedRoute>
            <CourseView />
          </ProtectedRoute>
        } />

        <Route path="/ebooks" element={
          <ProtectedRoute>
            <EBooksPage />
          </ProtectedRoute>
        } />

        <Route path="/live" element={
          <ProtectedRoute>
            <LiveClassesPage />
          </ProtectedRoute>
        } />

        <Route path="/pipelines" element={
          <ProtectedRoute>
            <PipelinesPage />
          </ProtectedRoute>
        } />

        <Route path="/marketing-box" element={
          <ProtectedRoute>
            <MarketingBoxPage />
          </ProtectedRoute>
        } />

        <Route path="/docbox" element={
          <ProtectedRoute>
            <DocBoxPage />
          </ProtectedRoute>
        } />

        <Route path="/esign" element={
          <ProtectedRoute>
            <ESignPage />
          </ProtectedRoute>
        } />

        <Route path="/support" element={
          <ProtectedRoute>
            <SupportPage />
          </ProtectedRoute>
        } />

        <Route path="/notifications" element={
          <ProtectedRoute>
            <NotificationsPage />
          </ProtectedRoute>
        } />

        <Route path="/profile" element={
          <ProtectedRoute>
            <ProfilePage />
          </ProtectedRoute>
        } />

        {/* Admin Routes */}
        <Route path="/admin" element={
          <ProtectedRoute requireAdmin>
            <AdminDashboard />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/departments" element={
          <ProtectedRoute requireAdmin>
            <DepartmentsSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/categories" element={
          <ProtectedRoute requireAdmin>
            <CategoriesSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/courses" element={
          <ProtectedRoute requireAdmin>
            <CoursesSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/courses/:moduleId/lessons" element={
          <ProtectedRoute requireAdmin>
            <LessonsSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/quiz" element={
          <ProtectedRoute requireAdmin>
            <QuizSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/ebooks" element={
          <ProtectedRoute requireAdmin>
            <EBooksSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/live" element={
          <ProtectedRoute requireAdmin>
            <LiveEventsSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/users" element={
          <ProtectedRoute requireAdmin>
            <UsersSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/groups" element={
          <ProtectedRoute requireAdmin>
            <GroupsSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/news" element={
          <ProtectedRoute requireAdmin>
            <NewsSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/pipelines" element={
          <ProtectedRoute requireAdmin>
            <PipelinesSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/marketing-box" element={
          <ProtectedRoute requireAdmin>
            <MarketingBoxSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/docbox" element={
          <ProtectedRoute requireAdmin>
            <DocBoxSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/esign" element={
          <ProtectedRoute requireAdmin>
            <ESignSettings />
          </ProtectedRoute>
        } />

        <Route path="/admin/settings/magic-learning" element={
          <ProtectedRoute requireAdmin>
            <MagicLearningSettings />
          </ProtectedRoute>
        } />
      </Routes>
      <Toaster position="top-right" />
    </BrowserRouter>
  );
}

export default App;