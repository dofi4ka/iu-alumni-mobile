/// Compile-time configuration for the backend API and Telegram bot.
///
/// Production defaults are hardcoded here. They can be overridden at build
/// time with `--dart-define` (e.g. `--dart-define=API_BASE_URL=http://localhost:8080`
/// for local development). There is no runtime configuration.

/// Backend API origin. Endpoints in [Paths] already include the `/api/v1/...`
/// prefix, so this must be the origin only (no trailing path).
String getApiBaseUrl() => const String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://iu.alumap.ru',
);

/// Telegram bot URL used for notifications.
String getBotUrl() => const String.fromEnvironment(
  'IU_ALUMNI_BOT_URL',
  defaultValue: 'https://t.me/IU_Alumni_Notification_Bot',
);
