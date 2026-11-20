/// Réglages du frontend.
class AppConfig {
  AppConfig._();

  /// URL de l'API (backend Node/Express).
  /// - Chrome / Windows / macOS / Linux : http://localhost:3000/api (défaut)
  /// - Émulateur Android : flutter run --dart-define=API_URL=http://10.0.2.2:3000/api
  /// - Téléphone réel : flutter run --dart-define=API_URL=http://IP_DU_PC:3000/api
  /// Accepte avec ou sans le suffixe /api (il est ajouté automatiquement).
  static const String _rawUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  static final String apiBaseUrl =
      '${_rawUrl.replaceFirst(RegExp(r'/+$'), '').replaceFirst(RegExp(r'/api$'), '')}/api';

  /// Délai maximum d'attente d'une réponse du serveur.
  static const Duration requestTimeout = Duration(seconds: 20);
}
