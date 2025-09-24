import 'package:flutter/material.dart';

import '../../../../configuration/themes/app_colors.dart';
import '../../../requestSnacbar/snackBar_manager.dart';

// Modelos de datos
class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? patientName;
  final String? patientAvatar;
  final Map<String, dynamic>? extraData;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.patientName,
    this.patientAvatar,
    this.extraData,
  });
}

enum NotificationType {
  newPatient,
  newAppointment,
  planUpdate,
  chatMessage,
  appUpdate,
  reminder,
}

class NotificationScreen extends StatefulWidget {
  final List<NotificationItem> notifications;
  final Function(String notificationId)? onMarkAsRead;
  final Function(String notificationId)? onDelete;
  final VoidCallback? onMarkAllAsRead;

  const NotificationScreen({
    super.key,
    required this.notifications,
    this.onMarkAsRead,
    this.onDelete,
    this.onMarkAllAsRead,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  int _currentGroupIndex = 0;
  NotificationFilter _currentFilter = NotificationFilter.all;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  Map<String, List<NotificationItem>> get groupedNotifications {
    final filtered = _getFilteredNotifications();
    final groups = <String, List<NotificationItem>>{};

    for (var notification in filtered) {
      final key = _getGroupKey(notification.timestamp);
      groups[key] = groups[key] ?? [];
      groups[key]!.add(notification);
    }

    // Ordenar por fecha más reciente
    for (var key in groups.keys) {
      groups[key]!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return groups;
  }

  List<NotificationItem> _getFilteredNotifications() {
    switch (_currentFilter) {
      case NotificationFilter.all:
        return widget.notifications;
      case NotificationFilter.patients:
        return widget.notifications.where((n) =>
        n.type == NotificationType.newPatient ||
            n.type == NotificationType.chatMessage
        ).toList();
      case NotificationFilter.appointments:
        return widget.notifications.where((n) =>
        n.type == NotificationType.newAppointment ||
            n.type == NotificationType.reminder
        ).toList();
      case NotificationFilter.plans:
        return widget.notifications.where((n) =>
        n.type == NotificationType.planUpdate
        ).toList();
      case NotificationFilter.unread:
        return widget.notifications.where((n) => !n.isRead).toList();
    }
  }

  String _getGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Hoy';
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    } else if (now.difference(date).inDays < 7) {
      return 'Esta semana';
    } else if (now.difference(date).inDays < 30) {
      return 'Este mes';
    } else {
      return 'Anteriores';
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupedNotifications;
    final groupKeys = groups.keys.toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              color: Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
              if (_showFilters) {
                _filterAnimationController.forward();
              } else {
                _filterAnimationController.reverse();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            onPressed: () => _showOptionsMenu(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros animados
          AnimatedBuilder(
            animation: _filterAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _filterAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildFilterChips(),
                ),
              );
            },
          ),

          // Indicadores de grupo
          if (groupKeys.length > 1) _buildGroupIndicators(groupKeys),

          // Lista de notificaciones
          Expanded(
            child: groupKeys.isEmpty
                ? _buildEmptyState()
                : PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentGroupIndex = index;
                });
              },
              itemCount: groupKeys.length,
              itemBuilder: (context, index) {
                final groupKey = groupKeys[index];
                final notifications = groups[groupKey]!;
                return _buildNotificationGroup(groupKey, notifications);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: NotificationFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getFilterLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _currentFilter = filter;
                  _currentGroupIndex = 0;
                });
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: Colors.grey[100],
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGroupIndicators(List<String> groupKeys) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: groupKeys.asMap().entries.map((entry) {
          final index = entry.key;
          final isActive = index == _currentGroupIndex;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: isActive ? 24 : 8,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationGroup(String groupKey, List<NotificationItem> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              groupKey,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          );
        }

        final notification = notifications[index - 1];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final typeConfig = _getTypeConfig(notification.type);
    final timeAgo = _getTimeAgo(notification.timestamp);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.mark_email_read, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.errorIcon,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _markAsRead(notification);
        } else {
          _deleteNotification(notification);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onNotificationTap(notification),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar o icono
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: typeConfig.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: notification.patientAvatar != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        notification.patientAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            typeConfig.icon,
                            color: typeConfig.color,
                            size: 24,
                          );
                        },
                      ),
                    )
                        : Icon(
                      typeConfig.icon,
                      color: typeConfig.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Contenido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                  color: Colors.grey[900],
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (notification.patientName != null) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                notification.patientName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todas las notificaciones aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  NotificationTypeConfig _getTypeConfig(NotificationType type) {
    switch (type) {
      case NotificationType.newPatient:
        return NotificationTypeConfig(
          icon: Icons.person_add,
          color: Colors.green,
        );
      case NotificationType.newAppointment:
        return NotificationTypeConfig(
          icon: Icons.calendar_today,
          color: AppColors.primary,
        );
      case NotificationType.planUpdate:
        return NotificationTypeConfig(
          icon: Icons.assignment,
          color: Colors.orange,
        );
      case NotificationType.chatMessage:
        return NotificationTypeConfig(
          icon: Icons.message,
          color: Colors.purple,
        );
      case NotificationType.appUpdate:
        return NotificationTypeConfig(
          icon: Icons.system_update,
          color: Colors.teal,
        );
      case NotificationType.reminder:
        return NotificationTypeConfig(
          icon: Icons.alarm,
          color: Colors.red,
        );
    }
  }

  String _getFilterLabel(NotificationFilter filter) {
    switch (filter) {
      case NotificationFilter.all:
        return 'Todas';
      case NotificationFilter.patients:
        return 'Pacientes';
      case NotificationFilter.appointments:
        return 'Citas';
      case NotificationFilter.plans:
        return 'Planes';
      case NotificationFilter.unread:
        return 'No leídas';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}sem';
    }
  }

  void _markAsRead(NotificationItem notification) {
    // Ejecutar callback si está disponible
    widget.onMarkAsRead?.call(notification.id);

    SnackBarManager.showInfo(context, 'Notificación marcada como leída');
  }

  void _deleteNotification(NotificationItem notification) {

    widget.onDelete?.call(notification.id);

    SnackBarManager.showError(context, 'Notificación eliminada');
  }

  void _onNotificationTap(NotificationItem notification) {
    // Implementar navegación según el tipo de notificación
    switch (notification.type) {
      case NotificationType.newPatient:
      // Navegar a perfil del paciente
        break;
      case NotificationType.newAppointment:
      // Navegar a detalles de la cita
        break;
      case NotificationType.planUpdate:
      // Navegar a plan nutricional
        break;
      case NotificationType.chatMessage:
      // Navegar a chat
        break;
      case NotificationType.appUpdate:
      // Mostrar detalles de actualización
        break;
      case NotificationType.reminder:
      // Mostrar recordatorio
        break;
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.mark_email_read),
                title: const Text('Marcar todas como leídas'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar lógica
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configurar notificaciones'),
                onTap: () {
                  Navigator.pop(context);
                  // Navegar a configuración
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class NotificationTypeConfig {
  final IconData icon;
  final Color color;

  NotificationTypeConfig({
    required this.icon,
    required this.color,
  });
}

enum NotificationFilter {
  all,
  patients,
  appointments,
  plans,
  unread,
}

