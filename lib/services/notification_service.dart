import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? _navigatorKey;

  bool _initialized = false;
  int _nextId = 1;
  static const String _messagesChannelId = 'teenworkly_messages_v2';

  static const AndroidNotificationChannel _messagesChannel =
      AndroidNotificationChannel(
    _messagesChannelId,
    'TeenWorkly Messages',
    description: 'Notifications for new messages and updates',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const linuxInit = LinuxInitializationSettings(
      defaultActionName: 'Open TeenWorkly',
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
      linux: linuxInit,
    );
    await _plugin.initialize(settings);

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_messagesChannel);
    await androidImpl?.requestNotificationsPermission();

    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    final macImpl =
        _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    await macImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  void attachNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> showMessageNotification({
    required String title,
    required String body,
  }) async {
    if (_initialized && !kIsWeb) {
    const androidDetails = AndroidNotificationDetails(
      _messagesChannelId,
      'TeenWorkly Messages',
      channelDescription: 'Notifications for new messages and updates',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      category: AndroidNotificationCategory.message,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );
    const linuxDetails = LinuxNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );
    await _plugin.show(_nextId++, title, body, details);
    }
    _showInAppTopBanner(title: title, body: body);
  }

  void _showInAppTopBanner({
    required String title,
    required String body,
  }) {
    // Add an explicit in-app sound cue for foreground notifications.
    unawaited(SystemSound.play(SystemSoundType.alert));

    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        forceActionsBelow: false,
        leading: const Icon(
          Icons.notifications_active_rounded,
          size: 28,
          color: Color(0xFF4F46E5),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              body,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEFF6FF),
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: const Text(
              'Dismiss',
              style: TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(seconds: 4), () {
      messenger.hideCurrentMaterialBanner();
    });
  }
}
