abstract final class ApiConfig {
  /// Change this URL to point the app at a different backend.
  ///
  /// Keep the `/api/v1/` suffix. For local Android emulators, use
  /// `http://10.0.2.2:8000/api/v1/`; for iOS simulators, use
  /// `http://127.0.0.1:8000/api/v1/` or your local `.test` domain.
  static const baseUrl = 'http://ajoplus-backend.test/api/v1/';
}
