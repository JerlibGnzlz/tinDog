class AppConstants {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Key pública de Stream (el Secret solo vive en Nest).
  static const streamApiKey = String.fromEnvironment(
    'STREAM_API_KEY',
    defaultValue: '',
  );

  /// OAuth Client ID tipo **Web** (serverClientId) para Google Sign-In.
  /// Debe coincidir con uno de los IDs en `GOOGLE_CLIENT_IDS` del API.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '865832497533-bkirp180j0gq7ap6frfj7hrqplfccuu3.apps.googleusercontent.com',
  );

  static const tokenKey = 'access_token';
  static const needsPetOnboardingKey = 'needs_pet_onboarding';
}
