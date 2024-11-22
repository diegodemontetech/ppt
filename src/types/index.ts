export interface Department {
  id: string;
  name: string;
  description?: string;
  created_at: string;
  updated_at?: string;
  categories?: Category[];
}

export interface Category {
  id: string;
  department_id: string;
  name: string;
  description?: string;
  created_at: string;
  updated_at?: string;
  modules?: Module[];
}

export interface Module {
  id: string;
  category_id: string;
  title: string;
  description: string;
  thumbnail_url?: string;
  video_url?: string;
  bg_color?: string;
  is_featured: boolean;
  order_num: number;
  created_at: string;
  updated_at?: string;
  lessons?: Lesson[];
  enrolled_count?: number;
  average_rating?: number;
  total_ratings?: number;
}

export interface Lesson {
  id: string;
  module_id: string;
  title: string;
  description?: string;
  video_url: string;
  order_num: number;
  duration?: number;
  created_at: string;
  updated_at?: string;
  lesson_progress?: LessonProgress[];
  lesson_ratings?: LessonRating[];
  quizzes?: Quiz[];
  average_rating?: number;
  total_ratings?: number;
}

export interface Quiz {
  id: string;
  lesson_id: string;
  questions: Array<{
    text: string;
    options: string[];
    correctOption: number;
  }>;
  created_at?: string;
  updated_at?: string;
}

export interface LessonProgress {
  id: string;
  lesson_id: string;
  user_id: string;
  completed: boolean;
  score?: number;
  created_at: string;
  updated_at?: string;
}

export interface LessonRating {
  id: string;
  lesson_id: string;
  user_id: string;
  rating: number;
  created_at: string;
  updated_at?: string;
}

export interface LiveEvent {
  id: string;
  title: string;
  description?: string;
  instructor_id: string;
  meeting_url: string;
  starts_at: string;
  duration: number;
  attendees_count: number;
  created_at: string;
  updated_at?: string;
  instructor?: {
    id: string;
    email: string;
    full_name?: string;
  };
}

export interface ModuleSubscription {
  id: string;
  module_id: string;
  user_id: string;
  created_at: string;
}

export interface UserGroup {
  id: string;
  name: string;
  description?: string;
  permissions: string[];
  created_at: string;
  updated_at?: string;
  modules?: string[];
}

export interface User {
  id: string;
  email: string;
  full_name?: string;
  role: 'user' | 'admin' | 'instructor';
  groups?: UserGroup[];
  created_at: string;
}

export interface Notification {
  id: string;
  user_id: string;
  title: string;
  message: string;
  read: boolean;
  created_at: string;
  updated_at?: string;
}