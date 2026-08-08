final _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

/// Typos frecuentes de dominio → sugerencia.
/// Mantener en sync con tindog-api email-typo.ts
const _emailDomainTypos = <String, String>{
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

String? _emailTypoSuggestion(String email) {
  final at = email.lastIndexOf('@');
  if (at < 0) return null;
  final local = email.substring(0, at);
  final domain = email.substring(at + 1).toLowerCase();
  final suggestion = _emailDomainTypos[domain];
  if (suggestion == null || suggestion == domain) return null;
  return '$local@$suggestion';
}

String? validateEmail(String? value) {
  final trimmed = value?.trim().toLowerCase() ?? '';
  if (trimmed.isEmpty) return 'El email es requerido';
  if (!_emailRegex.hasMatch(trimmed)) return 'Ingresa un email válido';
  final suggested = _emailTypoSuggestion(trimmed);
  if (suggested != null) {
    return 'Parece un error de tipeo. ¿Quisiste decir $suggested?';
  }
  return null;
}

String? validateLoginPassword(String? value) {
  if (value == null || value.isEmpty) return 'La contraseña es requerida';
  return null;
}

String? validateRegisterPassword(String? value) {
  if (value == null || value.isEmpty) return 'La contraseña es requerida';
  if (value.length < 8) return 'Usa al menos 8 caracteres';
  return null;
}

String? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) return 'Confirma tu contraseña';
  if (value != password) return 'Las contraseñas no coinciden';
  return null;
}

String? validateResetCode(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return 'Ingresa el código de 6 dígitos';
  if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
    return 'El código debe tener 6 dígitos';
  }
  return null;
}

String? authFieldError(Map<String, String>? fieldErrors, String field) =>
    fieldErrors?[field];
