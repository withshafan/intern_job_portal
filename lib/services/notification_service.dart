import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final UserService _userService = UserService();

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
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

    // ── Foreground message → show in-app banner ────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FCM] Foreground message: ${message.notification?.title}');
      }
      _showInAppBanner(navigatorKey, message);
    });

    // ── App opened from notification (background/terminated) ───
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FCM] App opened from notification: ${message.data}');
      }
      // Could navigate to a specific screen based on message.data
    });

    // ── Check if app was launched from a terminated notification ─
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && kDebugMode) {
      print('[FCM] Launched from terminated: ${initialMessage.data}');
    }
  }

  void _showInAppBanner(
      GlobalKey<NavigatorState> navigatorKey, RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? 'New Notification';
    final body = message.notification?.body ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: AppTheme.darkSurface,
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryIndigo.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: AppTheme.primaryIndigoLight,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: AppTheme.primaryTeal,
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
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
