import prisma from '../utils/prisma.js';
import { relationshipTypes } from '../validators/people.validators.js';

export interface QuestionTemplate {
  id: string;
  relationship_type: string;
  question_text: string;
  category: string | null;
  display_order: number;
}

export interface RelationshipInfo {
  type: string;
  display_name: string;
  question_count: number;
}

export async function listTemplates(
  relationship?: string,
  category?: string
): Promise<QuestionTemplate[]> {
  const templates = await prisma.questionTemplate.findMany({
    where: {
      isActive: true,
      ...(relationship && { relationshipType: relationship }),
      ...(category && { category }),
    },
    orderBy: [{ relationshipType: 'asc' }, { displayOrder: 'asc' }],
  });

  return templates.map((t) => ({
    id: t.id,
    relationship_type: t.relationshipType,
    question_text: t.questionText,
    category: t.category,
    display_order: t.displayOrder,
  }));
}

export async function listRelationships(): Promise<RelationshipInfo[]> {
  const counts = await prisma.questionTemplate.groupBy({
    by: ['relationshipType'],
    where: { isActive: true },
    _count: { id: true },
  });

  const countMap = new Map(counts.map((c) => [c.relationshipType, c._count.id]));

  const displayNames: Record<string, string> = {
    parent: 'Parent',
    grandparent: 'Grandparent',
    spouse: 'Spouse',
    partner: 'Partner',
    sibling: 'Sibling',
    child: 'Child',
    friend: 'Friend',
    coworker: 'Coworker',
    boss: 'Boss',
    mentor: 'Mentor',
    other: 'Other',
  };

  return relationshipTypes.map((type) => ({
    type,
    display_name: displayNames[type] || type,
    question_count: countMap.get(type) || 0,
  }));
}
