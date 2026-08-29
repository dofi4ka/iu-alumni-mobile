/// Stub implementation for non-web platforms (Android, iOS, desktop).
/// Reads the API base URL from the compile-time --dart-define value.
String getApiBaseUrl() => const String.fromEnvironment('API_BASE_URL');

/// Telegram bot URL: compile-time --dart-define fallback for non-web platforms.
String getBotUrl() => const String.fromEnvironment(
  'IU_ALUMNI_BOT_URL',
  defaultValue: 'https://t.me/IU_Alumni_Notification_Bot',
);
