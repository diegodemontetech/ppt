-- Insert e-books in batches for better performance
BEGIN;

-- First batch: Insert first 5 e-books
INSERT INTO ebooks (
  title,
  subtitle,
  author,
  description,
  category_id,
  pdf_url,
  cover_url,
  is_featured
) VALUES
  (
    'SPIN Selling: Alcançando Excelência em Vendas',
    NULL,
    'Neil Rackham',
    'Apresenta a metodologia SPIN Selling para vendas complexas, focando em perguntas situacionais, de problema, implicação e necessidade para fechar negócios.',
    'c1111111-1111-1111-1111-111111111111',
    'Spin-Selling-Alcancando-Excelencia-Em-Vendas-2.pdf',
    'https://m.media-amazon.com/images/I/51Y5UFcZw8L._SY344_BO1,204,203,200_.jpg',
    true
  ),
  (
    'Dom Quixote',
    NULL,
    'Miguel de Cervantes',
    'Considerado uma das maiores obras da literatura mundial, acompanha as aventuras de Dom Quixote, um fidalgo que se imagina cavaleiro.',
    'c2222222-2222-2222-2222-222222222222',
    'Dom-Quixote-Miguel-de-Cervantes.pdf',
    'https://m.media-amazon.com/images/I/51CBX5qg4rL._SY344_BO1,204,203,200_.jpg',
    true
  ),
  (
    'Uma Vida com Propósitos',
    NULL,
    'Rick Warren',
    'Guia para descobrir o propósito de vida, abordando questões espirituais e práticas para uma existência significativa.',
    'c3333333-3333-3333-3333-333333333333',
    'uma-vida-com-propositos-rick-warren.pdf',
    'https://m.media-amazon.com/images/I/51YWN9DzCwL._SY344_BO1,204,203,200_.jpg',
    true
  ),
  (
    'A Lei do Triunfo',
    NULL,
    'Napoleon Hill',
    'Apresenta os 16 princípios do sucesso, baseados em entrevistas com líderes e empreendedores de destaque.',
    'c4444444-4444-4444-4444-444444444444',
    'A-Lei-do-Triunfo-Napoleon-Hill-1.pdf',
    'https://m.media-amazon.com/images/I/51Z0s6sIk1L._SY344_BO1,204,203,200_.jpg',
    true
  ),
  (
    'O Milagre da Manhã',
    'Para Transformar seu Relacionamento',
    'Hal Elrod',
    'Propõe uma rotina matinal para melhorar a produtividade e o desenvolvimento pessoal.',
    'c6666666-6666-6666-6666-666666666666',
    'O_Milagre_da_Manha_-Para_Transformar_seu_Relacionamento-_Hal_Elrod.pdf',
    'https://m.media-amazon.com/images/I/51SKCCYI7bL._SY346_.jpg',
    true
  );

-- Commit first batch
COMMIT;

-- Second batch
BEGIN;

INSERT INTO ebooks (
  title,
  subtitle,
  author,
  description,
  category_id,
  pdf_url,
  cover_url,
  is_featured
) VALUES
  (
    'Aprendizados: Minha Caminhada para uma Vida com Mais Significado',
    NULL,
    'Gisele Bündchen',
    'Gisele Bündchen compartilha suas experiências de vida e as lições aprendidas ao longo de sua carreira.',
    'c7777777-7777-7777-7777-777777777777',
    'Aprendizados_-_Gisele_Bundchen.pdf',
    'https://m.media-amazon.com/images/I/51ZKq+3XbSL._SY344_BO1,204,203,200_.jpg',
    false
  ),
  (
    'Mais Forte do que Nunca',
    NULL,
    'Brené Brown',
    'Discute como superar adversidades e transformar fracassos em oportunidades de crescimento.',
    'c8888888-8888-8888-8888-888888888888',
    'Mais-forte-do-que-nunca-Brene-Brown.pdf',
    'https://m.media-amazon.com/images/I/41V+FZQ6YJL._SY344_BO1,204,203,200_.jpg',
    false
  ),
  (
    'Design para Quem Não é Designer',
    NULL,
    'Robin Williams',
    'Introdução aos princípios básicos de design gráfico para leigos, melhorando a qualidade visual de materiais.',
    'caaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'design-para-quem-nao-e-designer-robin-williams.pdf',
    'https://m.media-amazon.com/images/I/41V+Y18LqDL._SY344_BO1,204,203,200_.jpg',
    true
  ),
  (
    'Sapiens: Uma Breve História da Humanidade',
    NULL,
    'Yuval Noah Harari',
    'Explora a evolução do Homo sapiens desde a pré-história até os dias atuais.',
    'cbbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'Sapiens_Uma_Breve_Historia_da_Humanidade.pdf',
    'https://m.media-amazon.com/images/I/41eDsI6CGHL._SY344_BO1,204,203,200_.jpg',
    true
  ),
  (
    'Trabalhe 4 Horas por Semana',
    NULL,
    'Timothy Ferriss',
    'Apresenta estratégias para aumentar a eficiência no trabalho e alcançar uma vida equilibrada.',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    'Timothy_Ferriss_-_Trabalhe_4_Horas_Por_Semana.pdf',
    'https://m.media-amazon.com/images/I/51n2eY5iUnL._SY344_BO1,204,203,200_.jpg',
    true
  );

-- Commit second batch
COMMIT;

-- Final batch
BEGIN;

INSERT INTO ebooks (
  title,
  subtitle,
  author,
  description,
  category_id,
  pdf_url,
  cover_url,
  is_featured
) VALUES
  (
    'Os Quatro Compromissos',
    NULL,
    'Don Miguel Ruiz',
    'Baseado na sabedoria tolteca, oferece princípios para alcançar liberdade pessoal e felicidade.',
    'dddddddd-dddd-dddd-dddd-dddddddddddd',
    'os_4_compromissos.pdf',
    'https://m.media-amazon.com/images/I/51e4EHzQ7nL._SY344_BO1,204,203,200_.jpg',
    false
  ),
  (
    'Cibercultura',
    NULL,
    'Pierre Lévy',
    'Analisa o impacto da internet e das novas tecnologias na sociedade contemporânea.',
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    'Cibercultura.pdf',
    'https://m.media-amazon.com/images/I/41BL6+B3SSL._SY344_BO1,204,203,200_.jpg',
    false
  ),
  (
    'Hábitos Atômicos',
    NULL,
    'James Clear',
    'Oferece um guia para a criação de bons hábitos e eliminação dos maus, através de pequenas mudanças diárias.',
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'habitos-atomicos-by-james-clear-z-liborg.pdf',
    'https://m.media-amazon.com/images/I/513Y5o-DYtL._SY344_BO1,204,203,200_.jpg',
    true
  ),
  (
    'A Lógica do Cisne Negro',
    NULL,
    'Nassim Nicholas Taleb',
    'Explora o impacto de eventos imprevisíveis e altamente improváveis na economia e na vida.',
    '22222222-2222-2222-2222-222222222222',
    'A-Logica-do-Cisne-Negro-o-impacto-do-altamente-improvavel-Nassim-Nicholas-Taleb.pdf',
    'https://m.media-amazon.com/images/I/41QZy6CqClL._SY344_BO1,204,203,200_.jpg',
    true
  ),
  (
    'A Coragem de Ser Imperfeito',
    NULL,
    'Brené Brown',
    'Discute a importância da vulnerabilidade e autenticidade para uma vida plena.',
    '33333333-3333-3333-3333-333333333333',
    'A-Coragem-de-Ser-Imperfeito.pdf',
    'https://m.media-amazon.com/images/I/41qY9wSXmtL._SY344_BO1,204,203,200_.jpg',
    false
  ),
  (
    'Os Segredos da Mente Milionária',
    NULL,
    'T. Harv Eker',
    'Revela como a mentalidade influencia o sucesso financeiro e oferece estratégias para alcançá-lo.',
    '44444444-4444-4444-4444-444444444444',
    'Os_Segredos_Da_Mente_Milionaria.pdf',
    'https://m.media-amazon.com/images/I/51HcW2TThxL._SY344_BO1,204,203,200_.jpg',
    true
  );

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;