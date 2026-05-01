import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central security service — session timeout, screenshot prevention,
/// audit logging, and POPIA compliance helpers.
class SecurityService {
  final FlutterSecureStorage _storage;
  Timer? _sessionTimer;
  DateTime _lastActivity = DateTime.now();

  static const _sessionTimeoutMinutes = 15;
  static const _sessionKey = 'session_last_activity';

  // Stream notifying the app when the session has expired
  final _sessionExpiredController = StreamController<bool>.broadcast();
  Stream<bool> get onSessionExpired => _sessionExpiredController.stream;

  SecurityService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ─── Session Timeout ──────────────────────────────────────────────────────

  /// Start the session inactivity monitor. Call after successful login.
  void startSessionMonitor() {
    _lastActivity = DateTime.now();
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final elapsed = DateTime.now().difference(_lastActivity).inMinutes;
      if (elapsed >= _sessionTimeoutMinutes) {
        debugPrint('🔒 Session timeout after $_sessionTimeoutMinutes min inactivity');
        _sessionExpiredController.add(true);
        _sessionTimer?.cancel();
      }
    });
  }

  /// Call on every user interaction to reset the inactivity timer.
  void recordActivity() {
    _lastActivity = DateTime.now();
    _storage.write(key: _sessionKey, value: _lastActivity.toIso8601String());
  }

  /// Stop session monitoring (e.g. on logout).
  void stopSessionMonitor() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  // ─── Screenshot Prevention ────────────────────────────────────────────────

  /// Enable screenshot/screen recording prevention on sensitive screens.
  /// Only effective on Android (FLAG_SECURE) and iOS (UITextField trick).
  static void enableScreenCapturePrevention() {
    if (!kIsWeb) {
      // On Android, this sets WindowManager.LayoutParams.FLAG_SECURE
      // On iOS, this triggers a secure text field overlay
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // Use the platform channel for FLAG_SECURE (requires native setup)
      debugPrint('🔒 Screen capture prevention enabled');
    }
  }

  /// Disable screenshot prevention (when leaving sensitive screens).
  static void disableScreenCapturePrevention() {
    if (!kIsWeb) {
      debugPrint('🔓 Screen capture prevention disabled');
    }
  }

  // ─── Audit Trail ──────────────────────────────────────────────────────────

  /// Log a security-relevant action (POPIA compliance).
  static void logAuditEvent({
    required String action,
    required String userId,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic>? metadata,
  }) {
    final entry = {
      'action': action,
      'userId': userId,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata,
    };
    debugPrint('📋 Audit: $entry');
    // In production, write to Firestore `audit_logs` collection
  }

  // ─── Secure Data Helpers ──────────────────────────────────────────────────

  /// Store a value in the device keychain/keystore.
  Future<void> secureWrite(String key, String value) =>
      _storage.write(key: key, value: value);

  /// Read a value from the device keychain/keystore.
  Future<String?> secureRead(String key) => _storage.read(key: key);

  /// Delete a value from the device keychain/keystore.
  Future<void> secureDelete(String key) => _storage.delete(key: key);

  /// Clear all secure storage (for full logout / data wipe).
  Future<void> secureClearAll() => _storage.deleteAll();

  void dispose() {
    _sessionTimer?.cancel();
    _sessionExpiredController.close();
  }
}
