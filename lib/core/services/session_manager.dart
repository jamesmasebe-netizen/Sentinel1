import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the app is locked due to inactivity
final isAppLockedProvider = StateProvider<bool>((ref) => false);

/// Provides the session manager
final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager(ref);
});

class SessionManager {
  final Ref _ref;
  Timer? _inactivityTimer;
  static const _timeoutDuration = Duration(minutes: 30);

  SessionManager(this._ref);

  void startSession() {
    // Intentional: uninterrupted local development is the desired default,
    // so the inactivity auto-lock never fires in a debug build. See F-504.
    if (!kDebugMode) {
      _startTimer();
    }
  }

  void userInteracted() {
    // Intentional — see startSession().
    if (kDebugMode) return;
    if (_ref.read(isAppLockedProvider)) return; // Don't reset if already locked
    _startTimer();
  }

  void _startTimer() {
    // Intentional — see startSession().
    if (kDebugMode) return;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeoutDuration, _onTimeout);
  }

  void _onTimeout() {
    _ref.read(isAppLockedProvider.notifier).state = true;
  }

  void unlockSession() {
    _ref.read(isAppLockedProvider.notifier).state = false;
    _startTimer();
  }

  void stopSession() {
    _inactivityTimer?.cancel();
  }

  void endSession() {
    stopSession();
  }
}
