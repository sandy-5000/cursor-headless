export type Gender = "female" | "male";

const BACKGROUNDS = "b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf,c1f4cd";

export function normalizeGender(value: unknown): Gender {
  return value === "male" ? "male" : "female";
}

/**
 * Deterministic DiceBear "notionists" avatar (clean line-art on a pastel
 * background). Gender is expressed through the beard: male avatars always have
 * one, female avatars never do.
 */
export function avatarUrl(seed: string, gender: Gender = "female"): string {
  const beardProbability = gender === "male" ? 100 : 0;
  return (
    `https://api.dicebear.com/7.x/notionists/svg?seed=${encodeURIComponent(seed)}` +
    `&backgroundColor=${BACKGROUNDS}&backgroundType=solid&radius=50` +
    `&beardProbability=${beardProbability}`
  );
}
