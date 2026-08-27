import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment(
    'ICCASA_API_URL',
    defaultValue: 'https://iccasa.pkaylabs.com/api/v1',
  );

  static const appVersion = '1.1.0';

  static const deviceName = String.fromEnvironment(
    'ICCASA_DEVICE_ID',
    defaultValue: 'ICCASA-FIELD',
  );

  static bool get showPreviewAccess => kDebugMode;

  static String absoluteUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return value;
    if (uri.hasScheme) return uri.toString();
    return Uri.parse(apiUrl).resolveUri(uri).toString();
  }

  static void validate() {
    final uri = Uri.tryParse(apiUrl);
    if (kReleaseMode && (uri == null || uri.scheme != 'https')) {
      throw StateError('Release builds require an HTTPS ICCASA_API_URL.');
    }
  }
}
