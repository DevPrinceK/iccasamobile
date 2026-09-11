import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment(
    'ICCASA_API_URL',
    defaultValue: 'https://iccasa.pkaylabs.com/api/v1',
  );

  static String appVersion = '1.1.4 (6)';

  static const deviceName = String.fromEnvironment(
    'ICCASA_DEVICE_ID',
    defaultValue: 'ICCASA-FIELD',
  );

  static bool get showPreviewAccess => kDebugMode;

  static Future<void> initialize() async {
    try {
      final package = await PackageInfo.fromPlatform();
      appVersion = package.buildNumber.isEmpty
          ? package.version
          : '${package.version} (${package.buildNumber})';
    } catch (_) {
      // The fallback remains available in tests and unsupported environments.
    }
  }

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
