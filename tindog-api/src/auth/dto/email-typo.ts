/**
 * Dominios mal tipeados frecuentes → sugerencia correcta.
 * Mantener en sync con tindog-app auth_validators.dart
 */
const EMAIL_DOMAIN_TYPOS: Record<string, string> = {
  // Gmail
  'gmmail.com': 'gmail.com',
  'gmal.com': 'gmail.com',
  'gamil.com': 'gmail.com',
  'gnail.com': 'gmail.com',
  'gmnail.com': 'gmail.com',
  'gmaill.com': 'gmail.com',
  'gmai.com': 'gmail.com',
  'gmaul.com': 'gmail.com',
  'gmil.com': 'gmail.com',
  'gogglemail.com': 'gmail.com',
  'googlemail.co': 'gmail.com',
  'gmail.co': 'gmail.com',
  'gmail.con': 'gmail.com',
  'gmail.cm': 'gmail.com',
  'gmail.om': 'gmail.com',
  'gmail.comm': 'gmail.com',
  // Hotmail / Outlook / Live
  'hotmial.com': 'hotmail.com',
  'hotmal.com': 'hotmail.com',
  'hotnail.com': 'hotmail.com',
  'hotmaill.com': 'hotmail.com',
  'hotmail.co': 'hotmail.com',
  'hotmail.con': 'hotmail.com',
  'hotmail.cm': 'hotmail.com',
  'outlok.com': 'outlook.com',
  'outllok.com': 'outlook.com',
  'outlokk.com': 'outlook.com',
  'outlook.co': 'outlook.com',
  'outlook.con': 'outlook.com',
  'outlook.cm': 'outlook.com',
  'live.con': 'live.com',
  // Yahoo / iCloud
  'yahooo.com': 'yahoo.com',
  'yaho.com': 'yahoo.com',
  'yahoo.con': 'yahoo.com',
  'yahoo.cm': 'yahoo.com',
  'yahoocom.com': 'yahoo.com',
  'icloud.co': 'icloud.com',
  'icloud.con': 'icloud.com',
  'icoud.com': 'icloud.com',
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
