
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
  FirebaseNotificationService._internal();
  factory FirebaseNotificationService({Function(Map<String, dynamic>)? onNotificationReceived}) {
    _instance._onNotificationReceived = onNotificationReceived;
    return _instance;
  }
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  Function(Map<String, dynamic>)? _onNotificationReceived;

  Future<void> initialize() async {
    await _setupLocalNotifications();
    await _requestPermissions();
    await _getToken();
    _setupMessageHandlers();
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('ic_notification');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification permissions: ${settings.authorizationStatus}');
  }

  Future<void> _getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleTerminatedMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    _showLocalNotification(message);
    _onNotificationReceived?.call(message.data);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Background message tapped: ${message.notification?.title}');
    _handleNotificationTap(json.encode(message.data));
  }

  static Future<void> _handleTerminatedMessage(RemoteMessage message) async {
    debugPrint('Terminated message: ${message.notification?.title}');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'nutritionist_channel',
      'Notificaciones de Nutricionista',
      channelDescription: 'Canal para notificaciones de pacientes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      color: const Color(0xFF2EC4B6),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(message.notification?.body ?? ''),
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'Notificación',
      message.notification?.body ?? '',
      notificationDetails,
      payload: json.encode(message.data),
    );
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    final data = json.decode(payload);
    debugPrint('Tapped notification payload: $data');
    _onNotificationReceived?.call(data);
  }

  Future<void> unsubscribeFromTopics() async {
    await _firebaseMessaging.unsubscribeFromTopic('all_users');
    await _firebaseMessaging.unsubscribeFromTopic('nutritionists');
  }

  Future<void> subscribeToTopics(String userId) async {
    await _firebaseMessaging.subscribeToTopic('all_users');
    await _firebaseMessaging.subscribeToTopic('nutritionists');
    await _firebaseMessaging.subscribeToTopic('user_$userId');
  }
}

