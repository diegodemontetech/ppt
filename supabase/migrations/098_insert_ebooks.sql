-- Insert e-books with proper dependencies
DO $$ 
DECLARE
    dept_vendas UUID;
    dept_literatura UUID;
    dept_desenv_pessoal UUID;
    dept_empreend UUID;
    dept_marketing UUID;
    dept_biografia UUID;
    dept_tecnologia UUID;
    dept_design UUID;
    dept_historia UUID;
    dept_comunicacao UUID;
    dept_financas UUID;
    
    cat_vendas UUID;
    cat_romance UUID;
    cat_proposito UUID;
    cat_sucesso UUID;
    cat_neuro UUID;
    cat_prod UUID;
    cat_insp UUID;
    cat_resil UUID;
    cat_edu UUID;
    cat_design UUID;
    cat_antro UUID;
    cat_prod_neg UUID;
    cat_auto UUID;
    cat_cultura UUID;
    cat_habitos UUID;
    cat_oratoria UUID;
    cat_economia UUID;
    cat_autoconh UUID;
    cat_riqueza UUID;
BEGIN
    -- Insert Departments
    INSERT INTO departments (name, description) 
    VALUES ('Vendas', 'Departamento de Vendas e Negociações')
    RETURNING id INTO dept_vendas;

    INSERT INTO departments (name, description)
    VALUES ('Literatura', 'Literatura Clássica e Contemporânea')
    RETURNING id INTO dept_literatura;

    INSERT INTO departments (name, description)
    VALUES ('Desenvolvimento Pessoal', 'Crescimento e Desenvolvimento Individual')
    RETURNING id INTO dept_desenv_pessoal;

    INSERT INTO departments (name, description)
    VALUES ('Empreendedorismo', 'Empreendedorismo e Negócios')
    RETURNING id INTO dept_empreend;

    INSERT INTO departments (name, description)
    VALUES ('Marketing', 'Marketing e Estratégias de Mercado')
    RETURNING id INTO dept_marketing;

    INSERT INTO departments (name, description)
    VALUES ('Biografia', 'Biografias e Histórias de Vida')
    RETURNING id INTO dept_biografia;

    INSERT INTO departments (name, description)
    VALUES ('Tecnologia', 'Tecnologia e Inovação')
    RETURNING id INTO dept_tecnologia;

    INSERT INTO departments (name, description)
    VALUES ('Design', 'Design e Comunicação Visual')
    RETURNING id INTO dept_design;

    INSERT INTO departments (name, description)
    VALUES ('História', 'História e Antropologia')
    RETURNING id INTO dept_historia;

    INSERT INTO departments (name, description)
    VALUES ('Comunicação', 'Comunicação e Oratória')
    RETURNING id INTO dept_comunicacao;

    INSERT INTO departments (name, description)
    VALUES ('Finanças', 'Finanças e Economia')
    RETURNING id INTO dept_financas;

    -- Insert Categories
    INSERT INTO categories (department_id, name, description)
    VALUES (dept_vendas, 'Técnicas de Vendas', 'Metodologias e técnicas para vendas')
    RETURNING id INTO cat_vendas;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_literatura, 'Romance Clássico', 'Obras clássicas da literatura')
    RETURNING id INTO cat_romance;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_desenv_pessoal, 'Propósito de Vida', 'Descoberta e desenvolvimento do propósito')
    RETURNING id INTO cat_proposito;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_empreend, 'Sucesso Profissional', 'Estratégias para sucesso na carreira')
    RETURNING id INTO cat_sucesso;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_marketing, 'Neuromarketing', 'Marketing baseado em neurociência')
    RETURNING id INTO cat_neuro;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_desenv_pessoal, 'Produtividade', 'Técnicas de produtividade')
    RETURNING id INTO cat_prod;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_biografia, 'Inspiração', 'Histórias inspiradoras')
    RETURNING id INTO cat_insp;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_desenv_pessoal, 'Resiliência', 'Desenvolvimento de resiliência')
    RETURNING id INTO cat_resil;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_tecnologia, 'Educação', 'Tecnologia na educação')
    RETURNING id INTO cat_edu;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_design, 'Comunicação Visual', 'Princípios de design')
    RETURNING id INTO cat_design;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_historia, 'Antropologia', 'Estudos antropológicos')
    RETURNING id INTO cat_antro;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_empreend, 'Produtividade', 'Produtividade nos negócios')
    RETURNING id INTO cat_prod_neg;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_desenv_pessoal, 'Autoajuda', 'Desenvolvimento pessoal')
    RETURNING id INTO cat_auto;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_tecnologia, 'Cultura Digital', 'Impacto da tecnologia na sociedade')
    RETURNING id INTO cat_cultura;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_desenv_pessoal, 'Hábitos', 'Formação e mudança de hábitos')
    RETURNING id INTO cat_habitos;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_comunicacao, 'Oratória', 'Técnicas de comunicação')
    RETURNING id INTO cat_oratoria;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_financas, 'Economia', 'Economia e mercado')
    RETURNING id INTO cat_economia;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_desenv_pessoal, 'Autoconhecimento', 'Desenvolvimento pessoal')
    RETURNING id INTO cat_autoconh;

    INSERT INTO categories (department_id, name, description)
    VALUES (dept_financas, 'Riqueza', 'Educação financeira')
    RETURNING id INTO cat_riqueza;

    -- Insert E-books
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
        cat_vendas,
        'Spin-Selling-Alcancando-Excelencia-Em-Vendas-2.pdf',
        'https://m.media-amazon.com/images/I/51Y5UFcZw8L._SY344_BO1,204,203,200_.jpg',
        true
    ),
    (
        'Dom Quixote',
        NULL,
        'Miguel de Cervantes',
        'Considerado uma das maiores obras da literatura mundial, acompanha as aventuras de Dom Quixote, um fidalgo que se imagina cavaleiro.',
        cat_romance,
        'Dom-Quixote-Miguel-de-Cervantes.pdf',
        'https://m.media-amazon.com/images/I/51CBX5qg4rL._SY344_BO1,204,203,200_.jpg',
        true
    ),
    (
        'Uma Vida com Propósitos',
        NULL,
        'Rick Warren',
        'Guia para descobrir o propósito de vida, abordando questões espirituais e práticas para uma existência significativa.',
        cat_proposito,
        'uma-vida-com-propositos-rick-warren.pdf',
        'https://m.media-amazon.com/images/I/51YWN9DzCwL._SY344_BO1,204,203,200_.jpg',
        true
    ),
    (
        'A Lei do Triunfo',
        NULL,
        'Napoleon Hill',
        'Apresenta os 16 princípios do sucesso, baseados em entrevistas com líderes e empreendedores de destaque.',
        cat_sucesso,
        'A-Lei-do-Triunfo-Napoleon-Hill-1.pdf',
        'https://m.media-amazon.com/images/I/51Z0s6sIk1L._SY344_BO1,204,203,200_.jpg',
        true
    ),
    (
        'O Milagre da Manhã',
        'Para Transformar seu Relacionamento',
        'Hal Elrod',
        'Propõe uma rotina matinal para melhorar a produtividade e o desenvolvimento pessoal.',
        cat_prod,
        'O_Milagre_da_Manha_-Para_Transformar_seu_Relacionamento-_Hal_Elrod.pdf',
        'https://m.media-amazon.com/images/I/51SKCCYI7bL._SY346_.jpg',
        true
    ),
    (
        'Aprendizados: Minha Caminhada para uma Vida com Mais Significado',
        NULL,
        'Gisele Bündchen',
        'Gisele Bündchen compartilha suas experiências de vida e as lições aprendidas ao longo de sua carreira.',
        cat_insp,
        'Aprendizados_-_Gisele_Bundchen.pdf',
        'https://m.media-amazon.com/images/I/51ZKq+3XbSL._SY344_BO1,204,203,200_.jpg',
        false
    ),
    (
        'Mais Forte do que Nunca',
        NULL,
        'Brené Brown',
        'Discute como superar adversidades e transformar fracassos em oportunidades de crescimento.',
        cat_resil,
        'Mais-forte-do-que-nunca-Brene-Brown.pdf',
        'https://m.media-amazon.com/images/I/41V+FZQ6YJL._SY344_BO1,204,203,200_.jpg',
        false
    ),
    (
        'Design para Quem Não é Designer',
        NULL,
        'Robin Williams',
        'Introdução aos princípios básicos de design gráfico para leigos, melhorando a qualidade visual de materiais.',
        cat_design,
        'design-para-quem-nao-e-designer-robin-williams.pdf',
        'https://m.media-amazon.com/images/I/41V+Y18LqDL._SY344_BO1,204,203,200_.jpg',
        true
    ),
    (
        'Sapiens: Uma Breve História da Humanidade',
        NULL,
        'Yuval Noah Harari',
        'Explora a evolução do Homo sapiens desde a pré-história até os dias atuais.',
        cat_antro,
        'Sapiens_Uma_Breve_Historia_da_Humanidade.pdf',
        'https://m.media-amazon.com/images/I/41eDsI6CGHL._SY344_BO1,204,203,200_.jpg',
        true
    ),
    (
        'Trabalhe 4 Horas por Semana',
        NULL,
        'Timothy Ferriss',
        'Apresenta estratégias para aumentar a eficiência no trabalho e alcançar uma vida equilibrada.',
        cat_prod_neg,
        'Timothy_Ferriss_-_Trabalhe_4_Horas_Por_Semana.pdf',
        'https://m.media-amazon.com/images/I/51n2eY5iUnL._SY344_BO1,204,203,200_.jpg',
        true
    ),
    (
        'Os Quatro Compromissos',
        NULL,
        'Don Miguel Ruiz',
        'Baseado na sabedoria tolteca, oferece princípios para alcançar liberdade pessoal e felicidade.',
        cat_auto,
        'os_4_compromissos.pdf',
        'https://m.media-amazon.com/images/I/51e4EHzQ7nL._SY344_BO1,204,203,200_.jpg',
        false
    ),
    (
        'Cibercultura',
        NULL,
        'Pierre Lévy',
        'Analisa o impacto da internet e das novas tecnologias na sociedade contemporânea.',
        cat_cultura,
        'Cibercultura.pdf',
        'https://m.media-amazon.com/images/I/41BL6+B3SSL._SY344_BO1,204,203,200_.jpg',
        false
    ),
    (
        'Hábitos Atômicos',
        NULL,
        'James Clear',
        'Oferece um guia para a criação de bons hábitos e eliminação dos maus, através de pequenas mudanças diárias.',
        cat_habitos,
        'habitos-atomicos-by-james-clear-z-liborg.pdf',
        'https://m.media-amazon.com/images/I/513Y5o-DYtL._SY344_BO1,204,203,200_.jpg',
        true
    ),
    (
        'A Lógica do Cisne Negro',
        NULL,
        'Nassim Nicholas Taleb',
        'Explora o impacto de eventos imprevisíveis e altamente improváveis na economia e na vida.',
        cat_economia,
        'A-Logica-do-Cisne-Negro-o-impacto-do-altamente-improvavel-Nassim-Nicholas-Taleb.pdf',
        'https://m.media-amazon.com/images/I/41QZy6CqClL._SY344_BO1,204,203,200_.jpg',
        true
    ),
    (
        'A Coragem de Ser Imperfeito',
        NULL,
        'Brené Brown',
        'Discute a importância da vulnerabilidade e autenticidade para uma vida plena.',
        cat_autoconh,
        'A-Coragem-de-Ser-Imperfeito.pdf',
        'https://m.media-amazon.com/images/I/41qY9wSXmtL._SY344_BO1,204,203,200_.jpg',
        false
    ),
    (
        'Os Segredos da Mente Milionária',
        NULL,
        'T. Harv Eker',
        'Revela como a mentalidade influencia o sucesso financeiro e oferece estratégias para alcançá-lo.',
        cat_riqueza,
        'Os_Segredos_Da_Mente_Milionaria.pdf',
        'https://m.media-amazon.com/images/I/51HcW2TThxL._SY344_BO1,204,203,200_.jpg',
        true
    );

END $$;</content></file>
</boltArtifact>

Agora o script está usando variáveis para armazenar os IDs gerados automaticamente dos departamentos e categorias, e então usando essas variáveis para criar os relacionamentos corretos com os e-books. Isso garante que todas as chaves estrangeiras sejam válidas.

O script:
1. Cria os departamentos e armazena seus IDs
2. Cria as categorias usando os IDs dos departamentos
3. Cria os e-books usando os IDs das categorias

Isso deve resolver o erro de violação de chave estrangeira que você estava