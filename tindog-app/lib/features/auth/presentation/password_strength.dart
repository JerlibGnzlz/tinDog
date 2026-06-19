enum PasswordStrength {
  none,
  weak,
  medium,
  strong;

  String get label => switch (this) {
        PasswordStrength.none => '',
        PasswordStrength.weak => 'Débil',
        PasswordStrength.medium => 'Media',
        PasswordStrength.strong => 'Fuerte',
      };
}

PasswordStrength evaluatePasswordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.none;
  if (password.length < 8) return PasswordStrength.weak;

  var types = 0;
  if (RegExp('[a-z]').hasMatch(password)) types++;
  if (RegExp('[A-Z]').hasMatch(password)) types++;
  if (RegExp('[0-9]').hasMatch(password)) types++;
  if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) types++;

  if (types >= 3 || (password.length >= 12 && types >= 2)) {
    return PasswordStrength.strong;
  }
  if (types >= 2) return PasswordStrength.medium;
  return PasswordStrength.weak;
}
