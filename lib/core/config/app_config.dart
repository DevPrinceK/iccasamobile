import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment(
    'ICCASA_API_URL',
    defaultValue: 'http://127.0.0.1:8002/api/v1',
  );

  static const deviceName = String.fromEnvironment(
    'ICCASA_DEVICE_ID',
    defaultValue: 'ICCASA-FIELD',
  );

  static bool get showPreviewAccess => kDebugMode;
}
