import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

interface QuestionTemplate {
  relationshipType: string;
  questionText: string;
  category: string;
  displayOrder: number;
}

const templates: QuestionTemplate[] = [
  // PARENT QUESTIONS (45)
  // Childhood & Growing Up (10)
  { relationshipType: 'parent', questionText: "What's your earliest memory?", category: 'childhood', displayOrder: 1 },
  { relationshipType: 'parent', questionText: "What was your favorite thing to do as a child?", category: 'childhood', displayOrder: 2 },
  { relationshipType: 'parent', questionText: "What was your childhood home like?", category: 'childhood', displayOrder: 3 },
  { relationshipType: 'parent', questionText: "Who was your best friend growing up, and what did you do together?", category: 'childhood', displayOrder: 4 },
  { relationshipType: 'parent', questionText: "What was school like for you?", category: 'childhood', displayOrder: 5 },
  { relationshipType: 'parent', questionText: "What did you want to be when you grew up?", category: 'childhood', displayOrder: 6 },
  { relationshipType: 'parent', questionText: "What was the best gift you ever received as a child?", category: 'childhood', displayOrder: 7 },
  { relationshipType: 'parent', questionText: "What family traditions did you have growing up?", category: 'childhood', displayOrder: 8 },
  { relationshipType: 'parent', questionText: "What was your favorite meal your parents made?", category: 'childhood', displayOrder: 9 },
  { relationshipType: 'parent', questionText: "What got you in trouble as a kid?", category: 'childhood', displayOrder: 10 },

  // Family History (6)
  { relationshipType: 'parent', questionText: "Tell me about your parents. What were they like?", category: 'family_history', displayOrder: 11 },
  { relationshipType: 'parent', questionText: "What do you know about your grandparents?", category: 'family_history', displayOrder: 12 },
  { relationshipType: 'parent', questionText: "Do you know how your parents met?", category: 'family_history', displayOrder: 13 },
  { relationshipType: 'parent', questionText: "What values did your parents teach you?", category: 'family_history', displayOrder: 14 },
  { relationshipType: 'parent', questionText: "What's a story about our family that should never be forgotten?", category: 'family_history', displayOrder: 15 },
  { relationshipType: 'parent', questionText: "Is there anything about our family history you wish you knew more about?", category: 'family_history', displayOrder: 16 },

  // Life Lessons & Wisdom (6)
  { relationshipType: 'parent', questionText: "What's the best advice you've ever received?", category: 'wisdom', displayOrder: 17 },
  { relationshipType: 'parent', questionText: "What do you wish you had known at 20?", category: 'wisdom', displayOrder: 18 },
  { relationshipType: 'parent', questionText: "What are you most proud of in your life?", category: 'wisdom', displayOrder: 19 },
  { relationshipType: 'parent', questionText: "What's a mistake you learned the most from?", category: 'wisdom', displayOrder: 20 },
  { relationshipType: 'parent', questionText: "If you could go back and change one decision, would you? What would it be?", category: 'wisdom', displayOrder: 21 },
  { relationshipType: 'parent', questionText: "What does a good life mean to you?", category: 'wisdom', displayOrder: 22 },

  // Relationships & Love (5)
  { relationshipType: 'parent', questionText: "How did you meet mom/dad?", category: 'relationships', displayOrder: 23 },
  { relationshipType: 'parent', questionText: "What made you fall in love with them?", category: 'relationships', displayOrder: 24 },
  { relationshipType: 'parent', questionText: "What's the secret to a lasting relationship?", category: 'relationships', displayOrder: 25 },
  { relationshipType: 'parent', questionText: "What was your wedding day like?", category: 'relationships', displayOrder: 26 },
  { relationshipType: 'parent', questionText: 'When did you know they were "the one"?', category: 'relationships', displayOrder: 27 },

  // Parenting & Family (7)
  { relationshipType: 'parent', questionText: "What was it like when you found out you were going to be a parent?", category: 'parenting', displayOrder: 28 },
  { relationshipType: 'parent', questionText: "What do you remember about the day I was born?", category: 'parenting', displayOrder: 29 },
  { relationshipType: 'parent', questionText: "What's your favorite memory of me as a child?", category: 'parenting', displayOrder: 30 },
  { relationshipType: 'parent', questionText: "What was the hardest part of raising kids?", category: 'parenting', displayOrder: 31 },
  { relationshipType: 'parent', questionText: "What's something you hope I always remember?", category: 'parenting', displayOrder: 32 },
  { relationshipType: 'parent', questionText: "Is there anything you wish you had done differently as a parent?", category: 'parenting', displayOrder: 33 },
  { relationshipType: 'parent', questionText: "What are your hopes and dreams for me?", category: 'parenting', displayOrder: 34 },

  // Career & Accomplishments (5)
  { relationshipType: 'parent', questionText: "What jobs have you had throughout your life?", category: 'career', displayOrder: 35 },
  { relationshipType: 'parent', questionText: "What was your dream job?", category: 'career', displayOrder: 36 },
  { relationshipType: 'parent', questionText: "What accomplishment are you most proud of?", category: 'career', displayOrder: 37 },
  { relationshipType: 'parent', questionText: "Who influenced your career the most?", category: 'career', displayOrder: 38 },
  { relationshipType: 'parent', questionText: "What would you do differently in your career if you could start over?", category: 'career', displayOrder: 39 },

  // Fun & Personal (6)
  { relationshipType: 'parent', questionText: "What's the happiest day of your life?", category: 'fun', displayOrder: 40 },
  { relationshipType: 'parent', questionText: "What's a trip or adventure you'll never forget?", category: 'fun', displayOrder: 41 },
  { relationshipType: 'parent', questionText: "What music defined your younger years?", category: 'fun', displayOrder: 42 },
  { relationshipType: 'parent', questionText: "What's your favorite book or movie and why?", category: 'fun', displayOrder: 43 },
  { relationshipType: 'parent', questionText: "If you could have dinner with anyone from history, who would it be?", category: 'fun', displayOrder: 44 },
  { relationshipType: 'parent', questionText: "What's something most people don't know about you?", category: 'fun', displayOrder: 45 },

  // GRANDPARENT QUESTIONS (30)
  // Early Life & History (8)
  { relationshipType: 'grandparent', questionText: "Where and when were you born?", category: 'early_life', displayOrder: 1 },
  { relationshipType: 'grandparent', questionText: "What was the world like when you were growing up?", category: 'early_life', displayOrder: 2 },
  { relationshipType: 'grandparent', questionText: "What was your town or neighborhood like?", category: 'early_life', displayOrder: 3 },
  { relationshipType: 'grandparent', questionText: "How did your family make a living?", category: 'early_life', displayOrder: 4 },
  { relationshipType: 'grandparent', questionText: "What was school like in your day?", category: 'early_life', displayOrder: 5 },
  { relationshipType: 'grandparent', questionText: "What did you do for fun before TV and internet?", category: 'early_life', displayOrder: 6 },
  { relationshipType: 'grandparent', questionText: "What major historical events do you remember living through?", category: 'early_life', displayOrder: 7 },
  { relationshipType: 'grandparent', questionText: "How has the world changed the most in your lifetime?", category: 'early_life', displayOrder: 8 },

  // Family Legacy (6)
  { relationshipType: 'grandparent', questionText: "Tell me about your parents and grandparents.", category: 'family_legacy', displayOrder: 9 },
  { relationshipType: 'grandparent', questionText: "Where did our family originally come from?", category: 'family_legacy', displayOrder: 10 },
  { relationshipType: 'grandparent', questionText: "What family traditions have been passed down?", category: 'family_legacy', displayOrder: 11 },
  { relationshipType: 'grandparent', questionText: "What should our family never forget?", category: 'family_legacy', displayOrder: 12 },
  { relationshipType: 'grandparent', questionText: "Is there a family recipe that's been passed down?", category: 'family_legacy', displayOrder: 13 },
  { relationshipType: 'grandparent', questionText: "What does our family name mean to you?", category: 'family_legacy', displayOrder: 14 },

  // Life Story (5)
  { relationshipType: 'grandparent', questionText: "What's the bravest thing you ever did?", category: 'life_story', displayOrder: 15 },
  { relationshipType: 'grandparent', questionText: "What's your greatest accomplishment?", category: 'life_story', displayOrder: 16 },
  { relationshipType: 'grandparent', questionText: "What was the hardest time in your life and how did you get through it?", category: 'life_story', displayOrder: 17 },
  { relationshipType: 'grandparent', questionText: "What are you most grateful for?", category: 'life_story', displayOrder: 18 },
  { relationshipType: 'grandparent', questionText: "What's a moment that changed the course of your life?", category: 'life_story', displayOrder: 19 },

  // Wisdom for Future Generations (5)
  { relationshipType: 'grandparent', questionText: "What advice would you give to young people today?", category: 'wisdom', displayOrder: 20 },
  { relationshipType: 'grandparent', questionText: "What do you want your great-grandchildren to know about you?", category: 'wisdom', displayOrder: 21 },
  { relationshipType: 'grandparent', questionText: "What values do you hope our family always holds onto?", category: 'wisdom', displayOrder: 22 },
  { relationshipType: 'grandparent', questionText: "What does happiness mean to you?", category: 'wisdom', displayOrder: 23 },
  { relationshipType: 'grandparent', questionText: "If you could leave one message for the future, what would it be?", category: 'wisdom', displayOrder: 24 },

  // Personal & Fun (6)
  { relationshipType: 'grandparent', questionText: "What's your favorite memory with grandma/grandpa?", category: 'fun', displayOrder: 25 },
  { relationshipType: 'grandparent', questionText: "What's the funniest thing that ever happened to you?", category: 'fun', displayOrder: 26 },
  { relationshipType: 'grandparent', questionText: "What's a skill you're proud of?", category: 'fun', displayOrder: 27 },
  { relationshipType: 'grandparent', questionText: "What's your favorite family memory?", category: 'fun', displayOrder: 28 },
  { relationshipType: 'grandparent', questionText: "What songs remind you of the best times in your life?", category: 'fun', displayOrder: 29 },
  { relationshipType: 'grandparent', questionText: "What's a dream you still have?", category: 'fun', displayOrder: 30 },

  // SPOUSE/PARTNER QUESTIONS (20)
  // Your Story Together (5)
  { relationshipType: 'spouse', questionText: "What was your first impression of me?", category: 'story_together', displayOrder: 1 },
  { relationshipType: 'spouse', questionText: "When did you know you loved me?", category: 'story_together', displayOrder: 2 },
  { relationshipType: 'spouse', questionText: "What's your favorite memory of us?", category: 'story_together', displayOrder: 3 },
  { relationshipType: 'spouse', questionText: "What moment in our relationship are you most proud of?", category: 'story_together', displayOrder: 4 },
  { relationshipType: 'spouse', questionText: "What's something I do that always makes you smile?", category: 'story_together', displayOrder: 5 },

  // Getting to Know Each Other (5)
  { relationshipType: 'spouse', questionText: "What did you dream about for your future before we met?", category: 'getting_to_know', displayOrder: 6 },
  { relationshipType: 'spouse', questionText: "What's something you've never told me?", category: 'getting_to_know', displayOrder: 7 },
  { relationshipType: 'spouse', questionText: "What's a childhood memory that shaped who you are?", category: 'getting_to_know', displayOrder: 8 },
  { relationshipType: 'spouse', questionText: "What are you most afraid of?", category: 'getting_to_know', displayOrder: 9 },
  { relationshipType: 'spouse', questionText: "What makes you feel most loved?", category: 'getting_to_know', displayOrder: 10 },

  // Looking Forward (5)
  { relationshipType: 'spouse', questionText: "What dreams do you have for our future?", category: 'looking_forward', displayOrder: 11 },
  { relationshipType: 'spouse', questionText: "Where do you see us in 10 years?", category: 'looking_forward', displayOrder: 12 },
  { relationshipType: 'spouse', questionText: "What do you want us to never stop doing?", category: 'looking_forward', displayOrder: 13 },
  { relationshipType: 'spouse', questionText: "What tradition should we create together?", category: 'looking_forward', displayOrder: 14 },
  { relationshipType: 'spouse', questionText: "What's something you want us to experience together?", category: 'looking_forward', displayOrder: 15 },

  // Love & Appreciation (5)
  { relationshipType: 'spouse', questionText: "What do you love most about our relationship?", category: 'appreciation', displayOrder: 16 },
  { relationshipType: 'spouse', questionText: "What's something I do that you're grateful for?", category: 'appreciation', displayOrder: 17 },
  { relationshipType: 'spouse', questionText: "What's a hard time we got through that made us stronger?", category: 'appreciation', displayOrder: 18 },
  { relationshipType: 'spouse', questionText: "What would you want to tell me if today was our last day?", category: 'appreciation', displayOrder: 19 },
  { relationshipType: 'spouse', questionText: "Why do you choose me, every day?", category: 'appreciation', displayOrder: 20 },

  // Also add for 'partner' relationship type
  { relationshipType: 'partner', questionText: "What was your first impression of me?", category: 'story_together', displayOrder: 1 },
  { relationshipType: 'partner', questionText: "When did you know you loved me?", category: 'story_together', displayOrder: 2 },
  { relationshipType: 'partner', questionText: "What's your favorite memory of us?", category: 'story_together', displayOrder: 3 },
  { relationshipType: 'partner', questionText: "What moment in our relationship are you most proud of?", category: 'story_together', displayOrder: 4 },
  { relationshipType: 'partner', questionText: "What's something I do that always makes you smile?", category: 'story_together', displayOrder: 5 },
  { relationshipType: 'partner', questionText: "What did you dream about for your future before we met?", category: 'getting_to_know', displayOrder: 6 },
  { relationshipType: 'partner', questionText: "What's something you've never told me?", category: 'getting_to_know', displayOrder: 7 },
  { relationshipType: 'partner', questionText: "What's a childhood memory that shaped who you are?", category: 'getting_to_know', displayOrder: 8 },
  { relationshipType: 'partner', questionText: "What are you most afraid of?", category: 'getting_to_know', displayOrder: 9 },
  { relationshipType: 'partner', questionText: "What makes you feel most loved?", category: 'getting_to_know', displayOrder: 10 },
  { relationshipType: 'partner', questionText: "What dreams do you have for our future?", category: 'looking_forward', displayOrder: 11 },
  { relationshipType: 'partner', questionText: "Where do you see us in 10 years?", category: 'looking_forward', displayOrder: 12 },
  { relationshipType: 'partner', questionText: "What do you want us to never stop doing?", category: 'looking_forward', displayOrder: 13 },
  { relationshipType: 'partner', questionText: "What tradition should we create together?", category: 'looking_forward', displayOrder: 14 },
  { relationshipType: 'partner', questionText: "What's something you want us to experience together?", category: 'looking_forward', displayOrder: 15 },
  { relationshipType: 'partner', questionText: "What do you love most about our relationship?", category: 'appreciation', displayOrder: 16 },
  { relationshipType: 'partner', questionText: "What's something I do that you're grateful for?", category: 'appreciation', displayOrder: 17 },
  { relationshipType: 'partner', questionText: "What's a hard time we got through that made us stronger?", category: 'appreciation', displayOrder: 18 },
  { relationshipType: 'partner', questionText: "What would you want to tell me if today was our last day?", category: 'appreciation', displayOrder: 19 },
  { relationshipType: 'partner', questionText: "Why do you choose me, every day?", category: 'appreciation', displayOrder: 20 },

  // FRIEND QUESTIONS (15)
  // Your Friendship (5)
  { relationshipType: 'friend', questionText: "What's your first memory of meeting me?", category: 'friendship', displayOrder: 1 },
  { relationshipType: 'friend', questionText: "When did you know we'd be real friends?", category: 'friendship', displayOrder: 2 },
  { relationshipType: 'friend', questionText: "What's your favorite memory of us?", category: 'friendship', displayOrder: 3 },
  { relationshipType: 'friend', questionText: "What do you value most about our friendship?", category: 'friendship', displayOrder: 4 },
  { relationshipType: 'friend', questionText: "What's the hardest thing we've been through together?", category: 'friendship', displayOrder: 5 },

  // Getting to Know You (5)
  { relationshipType: 'friend', questionText: "What's a dream you've never told many people?", category: 'getting_to_know', displayOrder: 6 },
  { relationshipType: 'friend', questionText: "What's something you're really proud of?", category: 'getting_to_know', displayOrder: 7 },
  { relationshipType: 'friend', questionText: "What's a defining moment in your life?", category: 'getting_to_know', displayOrder: 8 },
  { relationshipType: 'friend', questionText: "What do you want your life to look like in 10 years?", category: 'getting_to_know', displayOrder: 9 },
  { relationshipType: 'friend', questionText: "What's something you wish more people understood about you?", category: 'getting_to_know', displayOrder: 10 },

  // Fun & Nostalgia (5)
  { relationshipType: 'friend', questionText: "What's the funniest thing we've ever done together?", category: 'fun', displayOrder: 11 },
  { relationshipType: 'friend', questionText: "What's an inside joke only we understand?", category: 'fun', displayOrder: 12 },
  { relationshipType: 'friend', questionText: "What song reminds you of our friendship?", category: 'fun', displayOrder: 13 },
  { relationshipType: 'friend', questionText: "If we could take any trip together, where would we go?", category: 'fun', displayOrder: 14 },
  { relationshipType: 'friend', questionText: "What's something you want us to do together before we're old?", category: 'fun', displayOrder: 15 },

  // SIBLING QUESTIONS (15)
  // Growing Up Together (5)
  { relationshipType: 'sibling', questionText: "What's your earliest memory of us?", category: 'growing_up', displayOrder: 1 },
  { relationshipType: 'sibling', questionText: "What did we fight about most as kids?", category: 'growing_up', displayOrder: 2 },
  { relationshipType: 'sibling', questionText: "What's your favorite memory from our childhood?", category: 'growing_up', displayOrder: 3 },
  { relationshipType: 'sibling', questionText: "What's something we did that mom and dad never found out about?", category: 'growing_up', displayOrder: 4 },
  { relationshipType: 'sibling', questionText: "What did you think of me when we were kids?", category: 'growing_up', displayOrder: 5 },

  // Our Relationship Now (5)
  { relationshipType: 'sibling', questionText: "What do you value most about having me as a sibling?", category: 'relationship_now', displayOrder: 6 },
  { relationshipType: 'sibling', questionText: "What's something you've always wanted to tell me?", category: 'relationship_now', displayOrder: 7 },
  { relationshipType: 'sibling', questionText: "What's a moment you were really proud of me?", category: 'relationship_now', displayOrder: 8 },
  { relationshipType: 'sibling', questionText: "What do you think makes our family unique?", category: 'relationship_now', displayOrder: 9 },
  { relationshipType: 'sibling', questionText: "What tradition from our childhood should we keep alive?", category: 'relationship_now', displayOrder: 10 },

  // Personal (5)
  { relationshipType: 'sibling', questionText: "What's something most people don't know about you?", category: 'personal', displayOrder: 11 },
  { relationshipType: 'sibling', questionText: "What's a goal or dream you're working toward?", category: 'personal', displayOrder: 12 },
  { relationshipType: 'sibling', questionText: "What's the best advice you'd give me?", category: 'personal', displayOrder: 13 },
  { relationshipType: 'sibling', questionText: "What do you want your kids to know about our family?", category: 'personal', displayOrder: 14 },
  { relationshipType: 'sibling', questionText: "What do you hope we never stop doing as siblings?", category: 'personal', displayOrder: 15 },

  // CHILD QUESTIONS (15)
  // Growing Up (5)
  { relationshipType: 'child', questionText: "What's your favorite memory from your childhood?", category: 'growing_up', displayOrder: 1 },
  { relationshipType: 'child', questionText: "What did you love most about growing up in our family?", category: 'growing_up', displayOrder: 2 },
  { relationshipType: 'child', questionText: "What was hard about your childhood?", category: 'growing_up', displayOrder: 3 },
  { relationshipType: 'child', questionText: "What family tradition meant the most to you?", category: 'growing_up', displayOrder: 4 },
  { relationshipType: 'child', questionText: "What's something you remember that I might have forgotten?", category: 'growing_up', displayOrder: 5 },

  // Your Perspective (5)
  { relationshipType: 'child', questionText: "What did you think of me as a parent?", category: 'perspective', displayOrder: 6 },
  { relationshipType: 'child', questionText: "What's something I did that really mattered to you?", category: 'perspective', displayOrder: 7 },
  { relationshipType: 'child', questionText: "What do you wish had been different?", category: 'perspective', displayOrder: 8 },
  { relationshipType: 'child', questionText: "What values from our family do you want to pass on?", category: 'perspective', displayOrder: 9 },
  { relationshipType: 'child', questionText: "What's something you understand now that you didn't as a kid?", category: 'perspective', displayOrder: 10 },

  // Your Life Now (5)
  { relationshipType: 'child', questionText: "What are you most proud of in your life?", category: 'life_now', displayOrder: 11 },
  { relationshipType: 'child', questionText: "What's a dream you're working toward?", category: 'life_now', displayOrder: 12 },
  { relationshipType: 'child', questionText: "What does happiness look like for you?", category: 'life_now', displayOrder: 13 },
  { relationshipType: 'child', questionText: "What do you want your own family to be like?", category: 'life_now', displayOrder: 14 },
  { relationshipType: 'child', questionText: "What do you want me to know about who you've become?", category: 'life_now', displayOrder: 15 },

  // COWORKER QUESTIONS (10)
  // Career & Work (5)
  { relationshipType: 'coworker', questionText: "What led you to this career?", category: 'career', displayOrder: 1 },
  { relationshipType: 'coworker', questionText: "What do you love most about what you do?", category: 'career', displayOrder: 2 },
  { relationshipType: 'coworker', questionText: "What's the biggest challenge you've faced professionally?", category: 'career', displayOrder: 3 },
  { relationshipType: 'coworker', questionText: "What accomplishment are you most proud of at work?", category: 'career', displayOrder: 4 },
  { relationshipType: 'coworker', questionText: "What advice would you give someone starting in this field?", category: 'career', displayOrder: 5 },

  // Working Together (5)
  { relationshipType: 'coworker', questionText: "What's your favorite memory of us working together?", category: 'working_together', displayOrder: 6 },
  { relationshipType: 'coworker', questionText: "What project are you most proud of that we did together?", category: 'working_together', displayOrder: 7 },
  { relationshipType: 'coworker', questionText: "What have you learned from our team?", category: 'working_together', displayOrder: 8 },
  { relationshipType: 'coworker', questionText: "What makes a great colleague in your view?", category: 'working_together', displayOrder: 9 },
  { relationshipType: 'coworker', questionText: "What do you hope people remember about your work?", category: 'working_together', displayOrder: 10 },

  // MENTOR QUESTIONS (10)
  // Their Guidance (5)
  { relationshipType: 'mentor', questionText: "What's the most important lesson you've tried to teach me?", category: 'guidance', displayOrder: 1 },
  { relationshipType: 'mentor', questionText: "What do you see as my greatest strength?", category: 'guidance', displayOrder: 2 },
  { relationshipType: 'mentor', questionText: "What do you think I should work on?", category: 'guidance', displayOrder: 3 },
  { relationshipType: 'mentor', questionText: "What's the best career advice you can give?", category: 'guidance', displayOrder: 4 },
  { relationshipType: 'mentor', questionText: "What mistake have you made that you want me to avoid?", category: 'guidance', displayOrder: 5 },

  // Their Journey (5)
  { relationshipType: 'mentor', questionText: "Who mentored you, and what did they teach you?", category: 'journey', displayOrder: 6 },
  { relationshipType: 'mentor', questionText: "What was a turning point in your career?", category: 'journey', displayOrder: 7 },
  { relationshipType: 'mentor', questionText: "What do you wish you had known when you were my age?", category: 'journey', displayOrder: 8 },
  { relationshipType: 'mentor', questionText: "What keeps you motivated after all these years?", category: 'journey', displayOrder: 9 },
  { relationshipType: 'mentor', questionText: "What does success mean to you now versus when you were younger?", category: 'journey', displayOrder: 10 },

  // BOSS QUESTIONS (10)
  // Leadership & Guidance (5)
  { relationshipType: 'boss', questionText: "What do you think makes a great employee?", category: 'leadership', displayOrder: 1 },
  { relationshipType: 'boss', questionText: "What's the best career advice you can give me?", category: 'leadership', displayOrder: 2 },
  { relationshipType: 'boss', questionText: "What's something you've noticed about my work that I should know?", category: 'leadership', displayOrder: 3 },
  { relationshipType: 'boss', questionText: "What opportunities do you see for my growth?", category: 'leadership', displayOrder: 4 },
  { relationshipType: 'boss', questionText: "What's a mistake you made early in your career that taught you something?", category: 'leadership', displayOrder: 5 },

  // Their Journey (5)
  { relationshipType: 'boss', questionText: "How did you get to where you are today?", category: 'journey', displayOrder: 6 },
  { relationshipType: 'boss', questionText: "What do you love most about leading a team?", category: 'journey', displayOrder: 7 },
  { relationshipType: 'boss', questionText: "What's the hardest part of your job?", category: 'journey', displayOrder: 8 },
  { relationshipType: 'boss', questionText: "What are you most proud of in your career?", category: 'journey', displayOrder: 9 },
  { relationshipType: 'boss', questionText: "What do you wish more people understood about leadership?", category: 'journey', displayOrder: 10 },

  // OTHER/CUSTOM QUESTIONS (10)
  { relationshipType: 'other', questionText: "How did we meet, and what was your first impression?", category: 'general', displayOrder: 1 },
  { relationshipType: 'other', questionText: "What's your favorite memory of us?", category: 'general', displayOrder: 2 },
  { relationshipType: 'other', questionText: "What's something you've always wanted to tell me?", category: 'general', displayOrder: 3 },
  { relationshipType: 'other', questionText: "What do you value most about knowing me?", category: 'general', displayOrder: 4 },
  { relationshipType: 'other', questionText: "What's a defining moment in your life?", category: 'general', displayOrder: 5 },
  { relationshipType: 'other', questionText: "What are you most proud of?", category: 'general', displayOrder: 6 },
  { relationshipType: 'other', questionText: "What's a dream you're still chasing?", category: 'general', displayOrder: 7 },
  { relationshipType: 'other', questionText: "What does happiness mean to you?", category: 'general', displayOrder: 8 },
  { relationshipType: 'other', questionText: "What's the best advice you've ever received?", category: 'general', displayOrder: 9 },
  { relationshipType: 'other', questionText: "If you could tell the world one thing, what would it be?", category: 'general', displayOrder: 10 },
];

async function main() {
  console.log('Seeding question templates...');

  // Clear existing templates
  await prisma.questionTemplate.deleteMany();

  // Insert all templates
  await prisma.questionTemplate.createMany({
    data: templates,
  });

  const count = await prisma.questionTemplate.count();
  console.log(`Seeded ${count} question templates.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
