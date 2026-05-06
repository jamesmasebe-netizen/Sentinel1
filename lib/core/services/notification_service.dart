import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles FCM device registration, push notifications, and callable function
/// wrappers for email / emergency broadcast.
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ─── Providers ─────────────────────────────────────────────────────────────
  static final provider = Provider<NotificationService>(
    (ref) => NotificationService(),
  );

  // ─── Initialisation ────────────────────────────────────────────────────────

  /// Call once after login. Requests permission, gets token, registers it.
  Future<void> init({required String uid, required String siteId}) async {
    // Request permissions (iOS / macOS / Web)
    if (!kIsWeb && !Platform.isAndroid) {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    } else if (kIsWeb || Platform.isAndroid) {
      await _fcm.requestPermission();
    }

    // Get FCM token
    final token = await _fcm.getToken(
      // For web, provide VAPID key if available
      vapidKey: const String.fromEnvironment(
        'VAPID_PUBLIC_KEY',
        defaultValue: '',
      ),
    );

    if (token != null) {
      await _registerToken(uid: uid, siteId: siteId, token: token);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _registerToken(uid: uid, siteId: siteId, token: newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _registerToken({
    required String uid,
    required String siteId,
    required String token,
  }) async {
    try {
      final callable = _functions.httpsCallable('registerDeviceToken');
      await callable.call({'token': token, 'siteId': siteId});
      debugPrint('✅ FCM token registered for uid=$uid');
    } catch (e) {
      // Fallback: write directly to Firestore
      await FirebaseFirestore.instance.collection('fcm_tokens').doc(uid).set({
        'token': token,
        'siteId': siteId,
        'uid': uid,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      debugPrint('⚠️  FCM token fallback write (Functions unavailable): $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground FCM: ${message.notification?.title}');
    // Show an in-app snackbar/banner via a stream
    _messageStreamController.add(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    _tapStreamController.add(message);
  }

  // ─── Streams (consumed by UI layer) ────────────────────────────────────────
  final _messageStreamController = _StreamController<RemoteMessage>();
  final _tapStreamController = _StreamController<RemoteMessage>();

  Stream<RemoteMessage> get onForegroundMessage =>
      _messageStreamController.stream;
  Stream<RemoteMessage> get onNotificationTap => _tapStreamController.stream;

  // ─── Callable Function Wrappers ─────────────────────────────────────────────

  /// Send an email via Cloud Function.
  Future<void> sendEmail({
    required String to,
    required String subject,
    String? text,
    String? html,
  }) async {
    final callable = _functions.httpsCallable('sendEmail');
    await callable.call({
      'to': to,
      'subject': subject,
      'text': text,
      'html': html,
    });
  }

  /// Send a push to specific device tokens via Cloud Function.
  Future<void> sendPush({
    String? token,
    List<String>? tokens,
    String? topic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final callable = _functions.httpsCallable('sendPushNotification');
    await callable.call({
      if (token != null) 'token': token,
      if (tokens != null) 'tokens': tokens,
      if (topic != null) 'topic': topic,
      'title': title,
      'body': body,
      if (data != null) 'data': data,
    });
  }

  /// Trigger an emergency broadcast to an entire site.
  Future<void> sendEmergencyBroadcast({
    required String siteId,
    required String message,
    required String emergencyType,
  }) async {
    final callable = _functions.httpsCallable('sendEmergencyBroadcast');
    await callable.call({
      'siteId': siteId,
      'message': message,
      'emergencyType': emergencyType,
    });
  }

  void dispose() {
    _messageStreamController.close();
    _tapStreamController.close();
  }
}

// Simple broadcast-stream wrapper
class _StreamController<T> {
  final List<Function(T)> _listeners = [];

  Stream<T> get stream => Stream.multi((controller) {
    void listener(T event) => controller.add(event);
    _listeners.add(listener);
    controller.onCancel = () => _listeners.remove(listener);
  });

  void add(T event) {
    for (final l in _listeners) {
      l(event);
    }
  }

  void close() {
    _listeners.clear();
  }
}
