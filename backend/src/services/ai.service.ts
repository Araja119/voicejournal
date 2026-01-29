import Anthropic from '@anthropic-ai/sdk';

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

export interface SuggestedQuestion {
  question: string;
  category: string;
}

export interface SuggestQuestionsInput {
  journalTitle: string;
  journalDescription?: string | null;
  recipientName?: string | null;
  recipientRelationship?: string | null;
  existingQuestions?: string[];
}

export async function generateSuggestedQuestions(
  input: SuggestQuestionsInput,
  count: number = 3
): Promise<SuggestedQuestion[]> {
  const { journalTitle, journalDescription, recipientName, recipientRelationship, existingQuestions } = input;

  // Build context for Claude
  let context = `You are helping someone create meaningful questions for a voice journal titled "${journalTitle}".`;

  if (journalDescription) {
    context += ` The journal's description is: "${journalDescription}".`;
  }

  if (recipientName && recipientRelationship) {
    context += ` The questions will be sent to ${recipientName}, who is their ${recipientRelationship}.`;
  } else if (recipientName) {
    context += ` The questions will be sent to ${recipientName}.`;
  }

  if (existingQuestions && existingQuestions.length > 0) {
    context += ` They have already asked: ${existingQuestions.map(q => `"${q}"`).join(', ')}.`;
  }

  const prompt = `${context}

Generate ${count} thoughtful, open-ended questions that would elicit meaningful personal stories or memories. The questions should:
- Be warm and conversational in tone
- Encourage storytelling rather than yes/no answers
- Be appropriate for the relationship and journal theme
- Not repeat any existing questions

Return the questions as a JSON array with this format:
[
  {"question": "the question text", "category": "category like 'memories', 'life lessons', 'family', 'advice', etc."}
]

Only return the JSON array, no other text.`;

  try {
    const message = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1024,
      messages: [
        { role: 'user', content: prompt }
      ],
    });

    // Extract the text content
    const textContent = message.content.find(c => c.type === 'text');
    if (!textContent || textContent.type !== 'text') {
      throw new Error('No text response from Claude');
    }

    // Parse the JSON response
    const questions = JSON.parse(textContent.text) as SuggestedQuestion[];
    return questions;
  } catch (error) {
    console.error('Error generating questions with Claude:', error);

    // Return fallback questions if AI fails
    return getFallbackQuestions(input, count);
  }
}

function getFallbackQuestions(input: SuggestQuestionsInput, count: number): SuggestedQuestion[] {
  const { recipientName, recipientRelationship, journalTitle } = input;

  const generalQuestions: SuggestedQuestion[] = [
    { question: "What's one childhood memory that still makes you smile?", category: "memories" },
    { question: "What life lesson took you the longest to learn?", category: "life lessons" },
    { question: "What's a tradition from your family that you cherish?", category: "family" },
    { question: "What moment in your life are you most proud of?", category: "achievements" },
    { question: "What advice would you give your younger self?", category: "advice" },
    { question: "Who has had the biggest influence on who you are today?", category: "relationships" },
    { question: "What's a story from your life that you think should be passed down?", category: "legacy" },
    { question: "What was the happiest day of your life and why?", category: "memories" },
  ];

  // Personalize if we have recipient info
  if (recipientName && recipientRelationship) {
    const personalizedQuestions: SuggestedQuestion[] = [
      { question: `What's your favorite memory of us together?`, category: "memories" },
      { question: `What did you dream of becoming when you were young?`, category: "dreams" },
      { question: `What was the world like when you were my age?`, category: "history" },
    ];

    // Mix personalized and general
    return [...personalizedQuestions, ...generalQuestions].slice(0, count);
  }

  // Shuffle and return
  const shuffled = generalQuestions.sort(() => Math.random() - 0.5);
  return shuffled.slice(0, count);
}
