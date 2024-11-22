-- Limpar dados existentes
TRUNCATE categories, user_groups, courses, lessons, quizzes, lesson_progress, lesson_ratings, notifications, live_events, certificates CASCADE;

-- Criar categorias
INSERT INTO categories (id, name, description) VALUES
  ('c1111111-1111-1111-1111-111111111111', 'Desenvolvimento', 'Cursos de programação e desenvolvimento'),
  ('c2222222-2222-2222-2222-222222222222', 'Gestão', 'Cursos de gestão e liderança'),
  ('c3333333-3333-3333-3333-333333333333', 'Marketing', 'Marketing digital e vendas'),
  ('c4444444-4444-4444-4444-444444444444', 'Design', 'Design gráfico e UX/UI');

-- Criar grupos de usuários
INSERT INTO user_groups (id, name, description, permissions) VALUES
  ('g1111111-1111-1111-1111-111111111111', 'Diretores', 'Diretores da empresa', '["all"]'),
  ('g2222222-2222-2222-2222-222222222222', 'Gerentes', 'Gerentes de departamento', '["view_all", "take_courses"]'),
  ('g3333333-3333-3333-3333-333333333333', 'Instrutores', 'Professores e instrutores', '["teach", "take_courses"]'),
  ('g4444444-4444-4444-4444-444444444444', 'Alunos', 'Alunos regulares', '["take_courses"]');

-- Criar usuários
INSERT INTO auth.users (id, email, encrypted_password, raw_user_meta_data) VALUES
  ('u1111111-1111-1111-1111-111111111111', 'maria.silva@empresa.com', crypt('senha123', gen_salt('bf')), '{"role": "admin", "full_name": "Maria Silva", "points": 1250}'),
  ('u2222222-2222-2222-2222-222222222222', 'joao.santos@empresa.com', crypt('senha123', gen_salt('bf')), '{"role": "user", "full_name": "João Santos", "points": 980}'),
  ('u3333333-3333-3333-3333-333333333333', 'ana.oliveira@empresa.com', crypt('senha123', gen_salt('bf')), '{"role": "user", "full_name": "Ana Oliveira", "points": 1500}'),
  ('u4444444-4444-4444-4444-444444444444', 'pedro.costa@empresa.com', crypt('senha123', gen_salt('bf')), '{"role": "user", "full_name": "Pedro Costa", "points": 750}'),
  ('u5555555-5555-5555-5555-555555555555', 'julia.martins@empresa.com', crypt('senha123', gen_salt('bf')), '{"role": "user", "full_name": "Julia Martins", "points": 2100}'),
  ('u6666666-6666-6666-6666-666666666666', 'lucas.ferreira@empresa.com', crypt('senha123', gen_salt('bf')), '{"role": "user", "full_name": "Lucas Ferreira", "points": 1800}'),
  ('u7777777-7777-7777-7777-777777777777', 'beatriz.lima@empresa.com', crypt('senha123', gen_salt('bf')), '{"role": "user", "full_name": "Beatriz Lima", "points": 950}'),
  ('u8888888-8888-8888-8888-888888888888', 'rafael.alves@empresa.com', crypt('senha123', gen_salt('bf')), '{"role": "user", "full_name": "Rafael Alves", "points": 1650}'),
  ('u9999999-9999-9999-9999-999999999999', 'carolina.dias@empresa.com', crypt('senha123', gen_salt('bf')), '{"role": "user", "full_name": "Carolina Dias", "points": 1100}'),
  ('uaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bruno.rocha@empresa.com', crypt('senha123', gen_salt('bf')), '{"role": "user", "full_name": "Bruno Rocha", "points": 890}');

-- Criar cursos
INSERT INTO courses (id, title, description, category_id, total_duration, is_featured) VALUES
  ('cc111111-1111-1111-1111-111111111111', 'JavaScript Avançado', 'Domine JavaScript e suas funcionalidades modernas', 'c1111111-1111-1111-1111-111111111111', 3600, true),
  ('cc222222-2222-2222-2222-222222222222', 'React do Zero', 'Aprenda React com projetos práticos', 'c1111111-1111-1111-1111-111111111111', 5400, true),
  ('cc333333-3333-3333-3333-333333333333', 'Gestão de Equipes Ágeis', 'Metodologias ágeis na prática', 'c2222222-2222-2222-2222-222222222222', 4800, true),
  ('cc444444-4444-4444-4444-444444444444', 'Marketing no Instagram', 'Estratégias para crescer no Instagram', 'c3333333-3333-3333-3333-333333333333', 3600, false),
  ('cc555555-5555-5555-5555-555555555555', 'UI/UX Design', 'Design de interfaces modernas', 'c4444444-4444-4444-4444-444444444444', 4200, true);

-- Criar aulas
INSERT INTO lessons (id, course_id, title, description, video_url, duration, is_live, order_num) VALUES
  -- JavaScript Avançado
  ('l1111111-1111-1111-1111-111111111111', 'cc111111-1111-1111-1111-111111111111', 'Introdução ao ES6+', 'Novidades do JavaScript moderno', 'W6NZfCO5SIk', 1200, false, 1),
  ('l2222222-2222-2222-2222-222222222222', 'cc111111-1111-1111-1111-111111111111', 'Promises e Async/Await', 'Programação assíncrona', 'edlFjlzxkSI', 1200, false, 2),
  
  -- React do Zero
  ('l3333333-3333-3333-3333-333333333333', 'cc222222-2222-2222-2222-222222222222', 'Fundamentos do React', 'Conceitos básicos do React', 'RYAp4XhlHhs', 1800, false, 1),
  ('l4444444-4444-4444-4444-444444444444', 'cc222222-2222-2222-2222-222222222222', 'Hooks na Prática', 'Usando React Hooks', 'qFDqWiHrXf0', 1800, false, 2),
  
  -- Gestão de Equipes
  ('l5555555-5555-5555-5555-555555555555', 'cc333333-3333-3333-3333-333333333333', 'Scrum na Prática', 'Implementando Scrum', 'ZtHwqGmjPu8', 1500, false, 1),
  ('l6666666-6666-6666-6666-666666666666', 'cc333333-3333-3333-3333-333333333333', 'Kanban', 'Gestão visual de projetos', 'GhoNJzg0VME', 1500, false, 2);

-- Criar quizzes
INSERT INTO quizzes (id, lesson_id, questions) VALUES
  -- Quiz JavaScript
  ('q1111111-1111-1111-1111-111111111111', 'l1111111-1111-1111-1111-111111111111', '[
    {
      "text": "Qual é a principal diferença entre let e var?",
      "options": [
        "Escopo de bloco",
        "Escopo global",
        "Não há diferença",
        "Tipagem"
      ],
      "correctOption": 0
    },
    {
      "text": "O que é destructuring?",
      "options": [
        "Deletar objetos",
        "Extrair valores de objetos/arrays",
        "Criar objetos",
        "Copiar arrays"
      ],
      "correctOption": 1
    }
  ]'),
  
  -- Quiz React
  ('q2222222-2222-2222-2222-222222222222', 'l3333333-3333-3333-3333-333333333333', '[
    {
      "text": "O que é JSX?",
      "options": [
        "Uma linguagem de programação",
        "Uma extensão de sintaxe para JavaScript",
        "Um framework",
        "Uma biblioteca"
      ],
      "correctOption": 1
    },
    {
      "text": "Para que serve o useState?",
      "options": [
        "Fazer requisições HTTP",
        "Gerenciar estado do componente",
        "Estilizar componentes",
        "Criar rotas"
      ],
      "correctOption": 1
    }
  ]');

-- Criar progresso das aulas
INSERT INTO lesson_progress (id, user_id, lesson_id, completed, score) VALUES
  -- Maria Silva
  ('lp111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111111', 'l1111111-1111-1111-1111-111111111111', true, 9.5),
  ('lp222222-2222-2222-2222-222222222222', 'u1111111-1111-1111-1111-111111111111', 'l2222222-2222-2222-2222-222222222222', true, 8.0),
  
  -- João Santos
  ('lp333333-3333-3333-3333-333333333333', 'u2222222-2222-2222-2222-222222222222', 'l1111111-1111-1111-1111-111111111111', true, 7.5),
  ('lp444444-4444-4444-4444-444444444444', 'u2222222-2222-2222-2222-222222222222', 'l3333333-3333-3333-3333-333333333333', true, 9.0);

-- Criar avaliações das aulas
INSERT INTO lesson_ratings (id, lesson_id, user_id, rating) VALUES
  ('lr111111-1111-1111-1111-111111111111', 'l1111111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111111', 5),
  ('lr222222-2222-2222-2222-222222222222', 'l1111111-1111-1111-1111-111111111111', 'u2222222-2222-2222-2222-222222222222', 4),
  ('lr333333-3333-3333-3333-333333333333', 'l2222222-2222-2222-2222-222222222222', 'u1111111-1111-1111-1111-111111111111', 5),
  ('lr444444-4444-4444-4444-444444444444', 'l3333333-3333-3333-3333-333333333333', 'u2222222-2222-2222-2222-222222222222', 5);

-- Criar certificados
INSERT INTO certificates (id, user_id, course_id, issued_at) VALUES
  ('cert11111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111111', 'cc111111-1111-1111-1111-111111111111', CURRENT_TIMESTAMP),
  ('cert22222-2222-2222-2222-222222222222', 'u2222222-2222-2222-2222-222222222222', 'cc222222-2222-2222-2222-222222222222', CURRENT_TIMESTAMP);

-- Criar aulas ao vivo
INSERT INTO live_events (id, title, description, instructor_id, meeting_url, starts_at, duration) VALUES
  ('live11111-1111-1111-1111-111111111111', 'Workshop de React Hooks', 'Aprenda hooks avançados na prática', 'u3333333-3333-3333-3333-333333333333', 'https://meet.example.com/react-workshop', CURRENT_TIMESTAMP + INTERVAL '2 days', 120),
  ('live22222-2222-2222-2222-222222222222', 'Masterclass UX/UI', 'Design de interfaces modernas', 'u4444444-4444-4444-4444-444444444444', 'https://meet.example.com/ux-masterclass', CURRENT_TIMESTAMP + INTERVAL '5 days', 90);

-- Criar notificações
INSERT INTO notifications (id, user_id, title, message, read) VALUES
  ('notif1111-1111-1111-1111-111111111111', 'u1111111-1111-1111-1111-111111111111', 'Nova aula disponível', 'A aula de React Hooks já está disponível!', false),
  ('notif2222-2222-2222-2222-222222222222', 'u2222222-2222-2222-2222-222222222222', 'Lembrete de aula ao vivo', 'Não esqueça do workshop amanhã!', false),
  ('notif3333-3333-3333-3333-333333333333', 'u1111111-1111-1111-1111-111111111111', 'Parabéns!', 'Você completou o curso de JavaScript!', true);

-- Atualizar progresso dos usuários
INSERT INTO user_progress (user_id, points, level, badges) VALUES
  ('u1111111-1111-1111-1111-111111111111', 1250, 3, '[
    {"id": "points_1000", "name": "Milha Extra", "description": "Alcançou 1000 pontos"},
    {"id": "courses_5", "name": "Estudioso", "description": "Completou 5 cursos"}
  ]'),
  ('u2222222-2222-2222-2222-222222222222', 980, 2, '[
    {"id": "streak_7", "name": "Dedicado", "description": "7 dias seguidos de estudo"}
  ]');