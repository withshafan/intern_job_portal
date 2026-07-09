import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../services/user_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final UserService _userService = UserService();

  Future<void> initialize() async {
    // Request permission (iOS / Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _saveToken();
    }

    // Handle token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _userService.saveFcmToken(newToken);
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FCM] Foreground message: ${message.notification?.title}');
      }
    });

    // Background / terminated message handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FCM] App opened from notification: ${message.data}');
      }
    });
  }

  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _userService.saveFcmToken(token);
        if (kDebugMode) print('[FCM] Token saved: $token');
      }
    } catch (e) {
      if (kDebugMode) print('[FCM] Error saving token: $e');
    }
  }
}

// Top-level handler for background messages (required by FCM)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('[FCM] Background message: ${message.notification?.title}');
  }
}
