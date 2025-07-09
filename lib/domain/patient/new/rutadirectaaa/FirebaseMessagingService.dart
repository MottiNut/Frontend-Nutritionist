// firebase_messaging_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../application/views/home/notificactions/notification_screen.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Callback para manejar notificaciones cuando la app está abierta
  static Function(NotificationItem)? onNotificationReceived;

  /// Inicializa Firebase Messaging y notificaciones locales
  static Future<void> initialize() async {
    // Configurar notificaciones locales
    await _initializeLocalNotifications();

    // Solicitar permisos
    await _requestPermissions();

    // Obtener token FCM
    await _getToken();

    // Configurar listeners
    _setupMessageHandlers();
  }

  /// Configura las notificaciones locales
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Solicita permisos para notificaciones
  static Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
    }

    // Para Android 13+
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Obtiene el token FCM del dispositivo
  static Future<String?> _getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print('🔑 FCM Token: $token');

      // Aquí deberías enviar el token a tu backend
      await _sendTokenToBackend(token);

      return token;
    } catch (e) {
      print('❌ Error obteniendo token FCM: $e');
      return null;
    }
  }

  /// Envía el token al backend
  static Future<void> _sendTokenToBackend(String? token) async {
    if (token == null) return;

    try {
      // Aquí implementarías el envío del token a tu backend
      // Por ejemplo, usando tu NutritionistService
      print('📤 Enviando token al backend: $token');

      // Ejemplo de cómo sería la llamada:
      // await NutritionistService.updateFcmToken(token, userToken);

    } catch (e) {
      print('❌ Error enviando token al backend: $e');
    }
  }

  /// Configura los handlers de mensajes
  static void _setupMessageHandlers() {
    // Cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Mensaje recibido en foreground: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // Cuando la app está en background pero no cerrada
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App abierta desde notificación: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // Cuando la app está completamente cerrada
   /* FirebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📱 App iniciada desde notificación: ${message.notification?.title}');
        _handleNotificationTap(message);
      }
    });*/
  }

  /// Maneja mensajes cuando la app está en foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = _createNotificationFromFCM(message);

    // Mostrar notificación local
    _showLocalNotification(message);

    // Llamar al callback si existe
    if (onNotificationReceived != null) {
      onNotificationReceived!(notification);
    }
  }

  /// Muestra una notificación local
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'nutri_app_channel',
      'Nutri App Notifications',
      channelDescription: 'Notificaciones de la app de nutrición',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      // Usar sonido del sistema
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nueva notificación',
      message.notification?.body ?? 'Tienes una nueva notificación',
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  /// Maneja cuando se toca una notificación
  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        print('🔔 Notificación tocada: $data');

        // Aquí puedes manejar la navegación según el tipo de notificación
        _handleNotificationNavigation(data);
      } catch (e) {
        print('❌ Error procesando payload de notificación: $e');
      }
    }
  }

  /// Maneja la navegación cuando se toca una notificación
  static void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Notificación FCM tocada: ${message.data}');
    _handleNotificationNavigation(message.data);
  }

  /// Maneja la navegación según el tipo de notificación
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    final patientId = data['patient_id'];
    final planId = data['plan_id'];

    switch (type) {
      case 'new_patient':
      // Navegar a la lista de pacientes o perfil específico
        print('🏥 Navegando a nuevo paciente: $patientId');
        break;
      case 'plan_accepted':
      // Navegar a los detalles del plan
        print('📋 Navegando a plan aceptado: $planId');
        break;
      case 'plan_rejected':
      // Navegar a planes rechazados
        print('❌ Navegando a plan rechazado: $planId');
        break;
      default:
        print('🔔 Tipo de notificación no reconocido: $type');
    }
  }

  /// Convierte un mensaje FCM en NotificationItem
  static NotificationItem _createNotificationFromFCM(RemoteMessage message) {
    final data = message.data;
    final type = _getNotificationTypeFromString(data['type'] ?? 'reminder');

    return NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: message.notification?.title ?? 'Nueva notificación',
      message: message.notification?.body ?? 'Tienes una nueva notificación',
      timestamp: DateTime.now(),
      isRead: false,
      patientName: data['patient_name'],
      patientAvatar: data['patient_avatar'],
      extraData: data,
    );
  }

  /// Convierte string a NotificationType
  static NotificationType _getNotificationTypeFromString(String type) {
    switch (type) {
      case 'new_patient':
        return NotificationType.newPatient;
      case 'new_appointment':
        return NotificationType.newAppointment;
      case 'plan_update':
      case 'plan_accepted':
      case 'plan_rejected':
        return NotificationType.planUpdate;
      case 'chat_message':
        return NotificationType.chatMessage;
      case 'app_update':
        return NotificationType.appUpdate;
      case 'reminder':
      default:
        return NotificationType.reminder;
    }
  }

  /// Obtiene el token actual
  static Future<String?> getCurrentToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Actualiza el token en el backend
  static Future<void> refreshToken() async {
    await _getToken();
  }
}

// Manejador de mensajes en background (debe estar en el nivel superior)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Mensaje recibido en background: ${message.notification?.title}');
}