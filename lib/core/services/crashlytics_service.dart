import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final crashlyticsServiceProvider = Provider<CrashlyticsService>((ref) {
  return CrashlyticsService();
});

class CrashlyticsService {
  Future<void> initialize() async {
    // Stub for Firebase Crashlytics & Performance Monitoring
    if (kDebugMode) {
      print('Crashlytics: Initialized in debug mode');
    }
  }

  Future<void> logError(dynamic error, StackTrace stackTrace, {String? reason}) async {
    // Stub for logging errors
    if (kDebugMode) {
      print('Crashlytics Error: $reason - $error');
    }
  }

  Future<void> setCustomKey(String key, dynamic value) async {
    // Stub for setting custom tenant keys (e.g., tenantId)
  }
}
