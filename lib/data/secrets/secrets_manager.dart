import 'package:ui_alumni_mobile/data/config/api_config.dart';

class SecretsManager {
  String? webSalt;
  String? appMetricaKey;
  String? hostPath;
  String botUrl = const String.fromEnvironment(
    'IU_ALUMNI_BOT_URL',
    defaultValue: 'https://t.me/IU_Alumni_Notification_Bot',
  );

  Future<void> init() async {
    webSalt = const String.fromEnvironment('IU_ALUMNI_WEB_SALT');
    appMetricaKey = const String.fromEnvironment('APP_METRICA_KEY');
    hostPath = getApiBaseUrl();
  }
}
