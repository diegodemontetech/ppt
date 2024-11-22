import { GoogleGenerativeAI } from '@google/generative-ai';
import toast from 'react-hot-toast';

const GOOGLE_API_KEY = 'AIzaSyA4ENDjWZ8VifoUmQhB1bqurqPbdNHZngY';
const DALLE_PROXY_URL = 'https://dalle.feiyuyu.net/v1/images/generations';

const genAI = new GoogleGenerativeAI(GOOGLE_API_KEY);

interface CourseContent {
  title: string;
  description: string;
  lessons: Array<{
    title: string;
    description: string;
    questions: Array<{
      text: string;
      options: string[];
      correctOption: number;
    }>;
  }>;
}

export async function generateCourseContent(topic: string): Promise<CourseContent> {
  try {
    const model = genAI.getGenerativeModel({ model: "gemini-pro" });

    const prompt = `Crie um curso sobre "${topic}" em português com a seguinte estrutura:
    {
      "title": "Título do curso (máximo 60 caracteres)",
      "description": "Descrição do curso (máximo 300 caracteres)",
      "lessons": [
        {
          "title": "Título da aula (máximo 60 caracteres)",
          "description": "Descrição detalhada da aula (máximo 500 palavras)",
          "questions": [
            {
              "text": "Pergunta",
              "options": ["Opção 1", "Opção 2", "Opção 3", "Opção 4"],
              "correctOption": 0
            }
          ]
        }
      ]
    }
    
    Crie exatamente 5 aulas, cada uma com 3 questões. Retorne apenas o JSON, sem explicações adicionais.`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    
    try {
      const content = JSON.parse(response.text());
      return content;
    } catch (parseError) {
      console.error('Error parsing AI response:', parseError);
      throw new Error('Erro ao processar resposta da IA');
    }
  } catch (error) {
    console.error('Error generating course content:', error);
    throw new Error('Erro ao gerar conteúdo do curso');
  }
}

export async function generateImage(prompt: string): Promise<string> {
  try {
    const response = await fetch(DALLE_PROXY_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer free-dalle-proxy'
      },
      body: JSON.stringify({
        model: 'dall-e-3',
        prompt: prompt,
        n: 1,
        size: '1024x1024'
      })
    });

    if (!response.ok) {
      throw new Error('Failed to generate image');
    }

    const data = await response.json();
    return data.data[0].url;
  } catch (error) {
    console.error('Error generating image:', error);
    throw new Error('Erro ao gerar imagem');
  }
}