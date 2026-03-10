// lib/api_config.dart
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8080';
    } else {
      // لأجهزة الأندرويد (المحاكي)
      return 'http://10.0.2.2:8080';
    }
  }
}
