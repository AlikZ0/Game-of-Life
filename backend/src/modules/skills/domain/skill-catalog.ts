/**
 * The default skill tree every new character receives. Skills gain XP whenever a
 * quest tagged with the matching `skillKey` is completed. Users can extend this
 * with custom skills in a later sprint; these eight are the seeded baseline.
 */
export interface SkillDefinition {
  key: string;
  name: string;
  icon: string;
  color: string;
}

export const DEFAULT_SKILLS: SkillDefinition[] = [
  { key: 'programming', name: 'Programming', icon: 'code', color: '#7C5CFF' },
  { key: 'fitness', name: 'Fitness', icon: 'dumbbell', color: '#FF6B6B' },
  { key: 'reading', name: 'Reading', icon: 'book', color: '#4ECDC4' },
  { key: 'english', name: 'English', icon: 'language', color: '#FFD166' },
  { key: 'business', name: 'Business', icon: 'briefcase', color: '#06D6A0' },
  { key: 'finance', name: 'Finance', icon: 'coins', color: '#118AB2' },
  { key: 'leadership', name: 'Leadership', icon: 'crown', color: '#EF476F' },
  { key: 'discipline', name: 'Discipline', icon: 'shield', color: '#8D99AE' },
];

export const SKILL_KEYS = DEFAULT_SKILLS.map((s) => s.key);
