final _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

String? validateEmail(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return 'El email es requerido';
  if (!_emailRegex.hasMatch(trimmed)) return 'Ingresa un email válido';
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

String? authFieldError(Map<String, String>? fieldErrors, String field) =>
    fieldErrors?[field];
