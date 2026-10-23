// ═══════════════════════════════════════════════════════════════════
//  قواعد المتجر والامتثال لسياسات Google Play
//  حظر المكملات والأجهزة الطبية من العرض والشراء
// ═══════════════════════════════════════════════════════════════════

export const HIDDEN_CATS = new Set([
  'فيتامينات ومكملات',
  'مكملات غذائية',
  'مكملات طبيعية',
  'أطعمة ومكملات',
  'أجهزة طبية'
]);

const SUPP_WORDS = [
  'مكمل',
  'مكمّل',
  'فيتامينات',
  'حمض الفوليك',
  'أوميغا',
  'حديد +',
  'كالسيوم +'
];

export function isHiddenProduct(p) {
  if (!p) return false;
  const category = String(p.category || '').trim();
  if (HIDDEN_CATS.has(category)) return true;
  const n = String(p.name || p.title || '');
  return SUPP_WORDS.some(w => n.includes(w));
}
