/**
 * Dominios mal tipeados frecuentes → sugerencia correcta.
 */
const EMAIL_DOMAIN_TYPOS: Record<string, string> = {
  'gmmail.com': 'gmail.com',
  'gmal.com': 'gmail.com',
  'gamil.com': 'gmail.com',
  'gnail.com': 'gmail.com',
  'gmai.com': 'gmail.com',
  'gmail.co': 'gmail.com',
  'gmail.con': 'gmail.com',
  'gmail.cm': 'gmail.com',
  'hotmial.com': 'hotmail.com',
  'hotmal.com': 'hotmail.com',
  'hotmail.co': 'hotmail.com',
  'hotmail.con': 'hotmail.com',
  'outlok.com': 'outlook.com',
  'outllok.com': 'outlook.com',
  'outlook.co': 'outlook.com',
  'yahooo.com': 'yahoo.com',
  'yaho.com': 'yahoo.com',
  'icloud.co': 'icloud.com',
};

export function suggestEmailTypo(email: string): string | null {
  const at = email.lastIndexOf('@');
  if (at < 0) return null;
  const local = email.slice(0, at);
  const domain = email.slice(at + 1).toLowerCase();
  const suggestion = EMAIL_DOMAIN_TYPOS[domain];
  if (!suggestion || suggestion === domain) return null;
  return `${local}@${suggestion}`;
}

export function emailTypoMessage(email: string): string | null {
  const suggested = suggestEmailTypo(email);
  if (!suggested) return null;
  return `Parece un error de tipeo. ¿Quisiste decir ${suggested}?`;
}
