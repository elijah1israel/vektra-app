class Env {
  /// The URL prefix every request is issued against. Override at build time
  /// with `--dart-define=API_BASE_URL=https://your.host/api`; the default
  /// points at the production web host that fronts the Django backend.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://vektrapro.com/api',
  );
}
