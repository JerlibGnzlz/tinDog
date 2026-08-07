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

  static const tokenKey = 'access_token';
}
