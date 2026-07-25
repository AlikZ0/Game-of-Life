/// Compile-time environment configuration.
///
/// Values are injected via `--dart-define` at build/run time:
/// ```
/// flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
/// ```
abstract final class Env {
  const Env._();

  /// Base URL of the Life Quest REST API (NestJS, `/api/v1`).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// Base URL for realtime (Socket.IO) — guilds chat, PvP live scores.
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// OAuth client ids.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Toggles verbose Dio logging + Riverpod observers.
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
