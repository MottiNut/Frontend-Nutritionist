import 'package:flutter/foundation.dart';

import '../rutadirectaaa/nutritionist_notification_service.dart';


class NotificationProvider with ChangeNotifier {
  final NutritionistNotificationService _notificationService;
  int _unreadCount = 0;
  List<dynamic> _notifications = [];

  NotificationProvider(this._notificationService);

  int get unreadCount => _unreadCount;
  List<dynamic> get notifications => _notifications;

  // Cargar historial de notificaciones
  Future<void> loadNotificationHistory() async {
    try {
      _notifications = await _notificationService.getNotificationHistory();
      _unreadCount = _notifications.where((n) => n['isRead'] == false).length;
      notifyListeners();
    } catch (e) {
      print('Error loading notification history: $e');
    }
  }

  // Marcar notificación como leída
  Future<void> markAsRead(String notificationId) async {
    // Aquí podrías llamar a un endpoint para marcar como leído
    _unreadCount--;
    notifyListeners();
  }

  // Registrar device token
  Future<bool> registerDeviceToken(String token, String platform) async {
    return await _notificationService.registerDeviceToken(token, platform);
  }
}