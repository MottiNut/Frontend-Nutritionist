import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../configuration/themes/app_colors.dart';
import '../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import '../../../domain/patient/pruebaa.dart';
import '../../../domain/services/auth_provider.dart';
import '../../requestSnacbar/snackBar_manager.dart';
import '../../skeletons/home_skeleton_screen.dart';
import 'active_patients_screen.dart';
import 'citas_detail/weekly_agenda_screen.dart';
import 'notificactions/notification_animation.dart';
import 'notificactions/notification_screen.dart';


class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedDay = DateTime.now().day;

  // Servicios
  final PatientServiceEnhanced patientService = PatientServiceEnhanced();
  final AppointmentServiceEnhanced appointmentService = AppointmentServiceEnhanced();

  // Estados
  bool isLoading = true;
  List<AppointmentEnhanced> todayAppointments = [];
  List<Patient> urgentPatients = [];
  int activePatientCount = 0;
  String? error;

  @override
  void initState() {
    super.initState();
    loadHomeData();
    _precacheUserAvatar();
  }

  void _precacheUserAvatar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _preloadAvatarImage(authProvider);
    });
  }

  void _preloadAvatarImage(AuthProvider authProvider) async {
    if (authProvider.user != null) {
      final userData = authProvider.user!;
      final userId = userData['id'] ?? userData['userId'];

      String? profileImageUrl = userData['profileImageUrl'] ??
          userData['profileImage'] ??
          userData['profile_image'] ??
          userData['avatar'] ??
          userData['photo'] ??
          userData['imageUrl'] ??
          userData['image_url'];

      // Usar el método estático del AuthService para construir la URL
      if ((profileImageUrl == null || profileImageUrl.isEmpty) && userId != null) {
        profileImageUrl = AuthService.buildProfileImageUrl(userId.toString());
      }

      if (profileImageUrl != null && profileImageUrl.isNotEmpty && userId != null) {
        unawaited(AuthService.preloadAvatarImage(
          imageUrl: profileImageUrl,
          token: authProvider.token,
          userId: userId.toString(),
        ));
      }
    }
  }

  @override
  void dispose() {
    patientService.dispose();
    appointmentService.dispose();

    super.dispose();
  }

  Future<void> loadHomeData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Cargar perfil del usuario si no está cargado
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null && authProvider.token != null) {
        await authProvider.loadUserProfile();
      }

      // Cargar datos de forma secuencial para mejor debugging
      await loadActivePatients();
      await loadTodayAppointments();
      await loadUrgentPatients();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading home data', e);
      setState(() {
        isLoading = false;
        error = _getErrorMessage(e);
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      if (error.isNotFound) {
        return 'Servicio no disponible. Verifica la configuración de la API.';
      } else if (error.isNetworkError) {
        return 'Error de conexión. Verifica tu internet.';
      } else if (error.isServerError) {
        return 'Error del servidor. Intenta más tarde.';
      } else {
        return 'Error: ${error.message}';
      }
    }
    return 'Error inesperado: ${error.toString()}';
  }

  // Modifica estos métodos en tu HomeScreen para manejar endpoints faltantes

  Future<void> loadTodayAppointments() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Intenta obtener citas, pero maneja el caso donde el endpoint no existe
      try {
        final appointments = await appointmentService.getAppointmentsByDate(startOfDay);

        todayAppointments = appointments
            .where((apt) =>
        apt.status == AppointmentStatus.confirmada ||
            apt.status == AppointmentStatus.programada)
            .toList()
          ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

        Logger.info('Loaded ${todayAppointments.length} appointments for today');
      } catch (e) {
        // Si el endpoint no existe, usa datos mock o lista vacía
        Logger.warning('Appointments endpoint not available, using empty list');
        todayAppointments = [];

        // Opcional: usar datos de prueba
        // todayAppointments = _getMockAppointments();
      }
    } catch (e) {
      Logger.error('Error loading today appointments', e);
      todayAppointments = [];
    }
  }

  Future<void> loadUrgentPatients() async {
    try {
      try {
        final patients = await patientService.getUrgentPatients();
        final now = DateTime.now();
        final urgentThreshold = now.subtract(const Duration(hours: 72));

        urgentPatients = patients
            .where((patient) =>
        patient.status != PatientStatus.inactivo &&
            (patient.lastVisitDate == null ||
                patient.lastVisitDate!.isBefore(urgentThreshold)))
            .take(3)
            .toList();

        Logger.info('Loaded ${urgentPatients.length} urgent patients');
      } catch (e) {
        // Si el endpoint no existe, usa pacientes activos y simula lógica urgente
        Logger.warning('Urgent patients endpoint not available, using fallback logic');

        final allPatients = await patientService.getAllPatients();
        final now = DateTime.now();
        final urgentThreshold = now.subtract(const Duration(hours: 72));

        urgentPatients = allPatients
            .where((patient) =>
        patient.status != PatientStatus.inactivo &&
            (patient.lastVisitDate == null ||
                patient.lastVisitDate!.isBefore(urgentThreshold)))
            .take(3)
            .toList();

        Logger.info('Loaded ${urgentPatients.length} urgent patients using fallback');
      }
    } catch (e) {
      Logger.error('Error loading urgent patients', e);
      urgentPatients = [];
    }
  }

  Future<void> loadActivePatients() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null) {
        throw Exception('Token de autenticación no disponible');
      }

      // Usar NutritionistService en lugar del servicio anterior
      final nutritionistService = NutritionistService();
      final patients = await nutritionistService.getAllPatients(
        token: authProvider.token!,
        sortBy: 'fullName',
        order: 'asc',
      );

      // Filtrar pacientes activos (puedes ajustar la lógica según tus necesidades)
      final activePatientsList = patients.where((patient) {
        // Considera activos a todos los pacientes por ahora
        // Puedes agregar lógica adicional aquí, como verificar fechas de última visita
        return true;
      }).toList();

      activePatientCount = activePatientsList.length;

      Logger.info('Loaded $activePatientCount active patients from real API');
    } catch (e) {
      Logger.error('Error loading active patients', e);
      activePatientCount = 0;

      // Opcional: mostrar mensaje de error discreto
      if (mounted) {
        SnackBarManager.showError(
          context,
          'No se pudieron cargar los datos de pacientes',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradiente de fondo
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.9, -0.9),
                  radius: 1,
                  colors: [
                    AppColors.primary.withOpacity(0.25),
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.08),
                    AppColors.primary.withOpacity(0.03),
                    AppColors.primary.withOpacity(0.01),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: buildContent(),
          ),
        ],
      ),
    );
  }
  static final List<NotificationItem> _staticNotifications = [
    NotificationItem(
      id: '1',
      type: NotificationType.newPatient,
      title: 'Nuevo paciente registrado',
      message: 'María González se ha registrado como nueva paciente',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      patientName: 'María González',
      patientAvatar: 'https://example.com/avatar1.jpg',
    ),
    NotificationItem(
      id: '2',
      type: NotificationType.newAppointment,
      title: 'Nueva cita programada',
      message: 'Carlos Pérez ha programado una cita para mañana a las 10:00 AM',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      patientName: 'Carlos Pérez',
    ),
    NotificationItem(
      id: '3',
      type: NotificationType.chatMessage,
      title: 'Mensaje de Ana López',
      message: 'Tengo una pregunta sobre mi plan nutricional',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      patientName: 'Ana López',
      patientAvatar: 'https://example.com/avatar2.jpg',
    ),
    NotificationItem(
      id: '4',
      type: NotificationType.planUpdate,
      title: 'Plan nutricional actualizado',
      message: 'Se ha actualizado el plan de Pedro Martínez',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      patientName: 'Pedro Martínez',
    ),
    NotificationItem(
      id: '5',
      type: NotificationType.reminder,
      title: 'Recordatorio de cita',
      message: 'Tienes una cita con Laura García en 30 minutos',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      patientName: 'Laura García',
    ),
    NotificationItem(
      id: '6',
      type: NotificationType.appUpdate,
      title: 'Actualización disponible',
      message: 'Nueva versión de la aplicación disponible con mejoras',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  // Getter que devuelve las notificaciones estáticas
  List<NotificationItem> get notifications => _staticNotifications;

  // Función mejorada para manejar el tap de notificaciones
  void onNotificationTap() {
    // Validar que tenemos notificaciones antes de navegar
    if (notifications.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationScreen(
            notifications: notifications,
          ),
        ),
      );
    } else {
      // Mostrar mensaje si no hay notificaciones
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay notificaciones disponibles'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget buildContent() {
    if (isLoading) {
      return const HomeScreenSkeleton();
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: loadHomeData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadHomeData,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pasar las notificaciones y la función de callback
            _buildHeader(notifications, onNotificationTap),
            const SizedBox(height: 15),
            _buildName(),
            const SizedBox(height: 10),
            _buildCalendar(),
            const SizedBox(height: 30),
            _buildAgendaSection(),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(child: _buildPacientesActivos()),
                const SizedBox(width: 15),
                Expanded(child: _buildUrgenteSection()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List<NotificationItem> notifications, VoidCallback onNotificationTap) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icono de menú con efecto hover
                GestureDetector(
                  onTap: () {
                    // Tu lógica para el menú
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.transparent,
                    ),
                    child: SvgPicture.asset(
                      'assets/images/menu_icon.svg',
                      width: 36,
                      height: 36,
                    ),
                  ),
                ),

                // Avatar con datos reales o placeholder
                Container(
                  width: 73.406,
                  height: 55.14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(width: 2, color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: _buildUserAvatar(authProvider),
                  ),
                ),

                // Icono de notificación animado
                AnimatedNotificationIcon(
                  notifications: notifications,
                  onTap: onNotificationTap,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserAvatar(AuthProvider authProvider) {
    String? profileImageUrl;
    int? userId;

    if (authProvider.user != null) {
      final userData = authProvider.user!;
      userId = userData['id'] ?? userData['userId'];

      // Buscar URL directa de imagen
      profileImageUrl = userData['profileImageUrl'] ??
          userData['profileImage'] ??
          userData['profile_image'] ??
          userData['avatar'] ??
          userData['photo'] ??
          userData['imageUrl'] ??
          userData['image_url'];

      // Usar el método del servicio para construir la URL si no hay una directa
      if ((profileImageUrl == null || profileImageUrl.isEmpty) && userId != null) {
        profileImageUrl = AuthService.buildProfileImageUrl(userId.toString());
      }
    }

    // Mostrar la imagen con caché del servicio
    if (profileImageUrl != null && profileImageUrl.isNotEmpty && userId != null) {
      return FutureBuilder<File?>(
        future: AuthService.getLocalAvatarImage(userId.toString()),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(
              snapshot.data!,
              fit: BoxFit.cover,
            );
          }

          return CachedNetworkImage(
            imageUrl: profileImageUrl!,
            httpHeaders: {
              if (authProvider.token != null)
                'Authorization': 'Bearer ${authProvider.token}',
            },
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              debugPrint('Error cargando imagen de perfil: $error');
              return Image.asset(
                'assets/images/placeholder_nutri.jpg',
                fit: BoxFit.cover,
              );
            },
            cacheManager: AuthService.avatarCacheManager,
          );
        },
      );
    } else {
      return Image.asset(
        'assets/images/placeholder_nutri.jpg',
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildName() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        String displayName = 'Usuario';

        if (authProvider.user != null) {
          final userData = authProvider.user!;

          // Intenta extraer los campos individuales o usar el nombre completo
          String? firstName = userData['firstName'] ?? userData['first_name'];
          String? lastName = userData['lastName'] ?? userData['last_name'];
          String? fullName = userData['name'] ?? userData['fullName'] ?? userData['full_name'];

          if (firstName != null && firstName.isNotEmpty) {
            displayName = firstName;
            if (lastName != null && lastName.isNotEmpty) {
              displayName = '$firstName $lastName';
            }
          } else if (fullName != null && fullName.isNotEmpty) {
            // Dividir y tomar solo el primer nombre y primer apellido
            List<String> parts = fullName.trim().split(' ');
            if (parts.length >= 2) {
              displayName = '${parts[0]} ${parts[1]}';
            } else if (parts.isNotEmpty) {
              displayName = parts[0]; // solo el primer nombre si no hay más
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola!',
              style: TextStyle(
                fontSize: 25,
                height: 1.0,
                color: Colors.grey[600],
                fontWeight: FontWeight.w300,
              ),
            ),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 25,
                height: 1,
                fontWeight: FontWeight.w300,
                color: Colors.black87,
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildCalendar() {
    final now = DateTime.now();
    final currentDay = now.day;
    final currentMonth = _getMonthName(now.month);
    final weekDays = _getWeekDays(now);

    return Stack(
      children: [
        Positioned(
          top: 8,
          right: 10,
          child: Text(
            currentMonth,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((dayInfo) {
              final isToday = dayInfo['day'] == currentDay;
              final Color mainColor = isToday ? Colors.teal : Colors.teal.shade100;
              final Color borderColor = isToday ? Colors.teal : Colors.teal.shade100;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDay = dayInfo['day'] as int;
                  });
                },
                child: Container(
                  width: 42,
                  height: 75.865,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: borderColor),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(25),
                      top: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 43,
                        height: 40,
                        decoration: BoxDecoration(
                          color: mainColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${dayInfo['day']}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                              letterSpacing: 1.2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayInfo['weekday'],
                        style: TextStyle(
                            fontSize: 14,
                            color: isToday ? AppColors.primary : AppColors.textHome,
                            fontWeight: isToday ? FontWeight.w500 : FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month];
  }

  List<Map<String, dynamic>> _getWeekDays(DateTime currentDate) {
    final monday = currentDate.subtract(Duration(days: currentDate.weekday - 1));
    const weekdayNames = ['Lu', 'Ma', 'Mi', 'Jue', 'Vie', 'Sab', 'Dom'];

    return List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      return {
        'day': day.day,
        'weekday': weekdayNames[index],
      };
    });
  }

  Widget _buildAgendaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AGENDA',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryHome,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _navigateToWeeklyAgenda(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.5),
                      width: 0.2
                  ),
                ),
                child: todayAppointments.isEmpty
                    ? _buildNoAppointments()
                    : Column(
                  children: todayAppointments
                      .take(2)
                      .map((appointment) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildAgendaItem(appointment),
                  ))
                      .toList(),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: SvgPicture.asset(
                        'assets/images/next_icon.svg',
                        width: 27,
                        height: 27,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToWeeklyAgenda() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Lottie.asset('assets/loading/palta_saltarina.json',
              width: 80,
              height: 80
          ),
        ),
      );

      // Obtener citas de la semana
      final weeklyAppointments = await appointmentService.getWeeklyAppointments();

      // Cerrar indicador de carga
      Navigator.pop(context);

      // Navegar a la pantalla de agenda semanal
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WeeklyAgendaScreen(
            appointments: weeklyAppointments,
            patientService: patientService,
          ),
        ),
      );
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Mostrar error
      SnackBarManager.showWithAction(
        context,
        message: 'Error al cargar la agenda semanal: ${_getErrorMessage(e)}',
        actionText: 'DESHACER',
        onAction: _navigateToWeeklyAgenda,
        duration: Duration(seconds: 3)
      );

      Logger.error('Error navigating to weekly agenda', e);
    }
  }

  Widget _buildNoAppointments() {
    return Container(
      height: 80,
      child: Center(
        child: Text(
          'No hay citas programadas para hoy',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textLDark,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAgendaItem(AppointmentEnhanced appointment) {
    final time = _formatAppointmentTime(appointment.scheduledDate);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Próxima cita:',
                style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textLDark,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          width: 1.5,
          height: 39,
          margin: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: AppColors.textPrimary1,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        Expanded(
          flex: 2,
          child: FutureBuilder<Patient>(
            future: patientService.getPatientById(appointment.patientId),
            builder: (context, snapshot) {
              final patientName = snapshot.hasData
                  ? snapshot.data!.fullName
                  : 'Cargando...';

              return Text(
                patientName,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHomeLabel,
                    letterSpacing: 0.28
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatAppointmentTime(DateTime dateTime) {
    final now = DateTime.now();
    final isToday = dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year;

    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return isToday ? 'Hoy, $time PM' : '$time PM';
  }

  Widget _buildPacientesActivos() {
    return GestureDetector(
      onTap: () => _navigateToActivePatients(),
      child: Container(
        height: 200,
        width: 158.83,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: LinearGradient(
            begin: Alignment(-0.5, -1.0),
            end: Alignment(0.5, 1.0),
            stops: const [0.0, 0.6235, 1.0],
            colors: [
              Color.lerp(const Color.fromRGBO(245, 245, 245, 0.2), AppColors.primary, 0.15)!,
              Color.lerp(const Color.fromRGBO(243, 243, 243, 0.7), AppColors.primary, 0.45)!,
              Color.lerp(const Color.fromRGBO(182, 181, 181, 0.7019607843137254), AppColors.primary, 0.30)!,
            ],
          ),
          // Agregar sombra para indicar que es clickeable
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'PACIENTES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHomeLabel,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'ACTIVOS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHomeLabel,
                    letterSpacing: 0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Mostrar número real o mensaje si no hay datos
                if (activePatientCount > 0) ...[
                  Text(
                    '$activePatientCount',
                    style: TextStyle(
                        fontSize: 66,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHomeLabel,
                        letterSpacing: 1.32,
                        height: 1.1
                    ),
                  ),
                  Text(
                    'pacientes\nen seguimiento',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHomeLabel,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.26,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Icon(
                    Icons.people_outline,
                    size: 40,
                    color: AppColors.textHomeLabel.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No hay\npacientes\nactivos',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textHomeLabel,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
            // Indicador visual de que es clickeable
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textHomeLabel.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Método para navegar a la lista de pacientes activos
  Future<void> _navigateToActivePatients() async {
    if (activePatientCount == 0) {
      SnackBarManager.showError(
        context,
         'No hay pacientes activos para mostrar',
      );
      return;
    }

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Lottie.asset(
            'assets/loading/palta_saltarina.json',
            width: 80,
            height: 80,
          ),
        ),
      );

      // Navegar a la pantalla de pacientes activos
      final nutritionistService = NutritionistService();

      // Cerrar indicador de carga
      Navigator.pop(context);

      // Navegar a la pantalla
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivePatientsScreen(
            nutritionistService: nutritionistService,
          ),
        ),
      ).then((_) {

        loadHomeData();
      });

    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      SnackBarManager.showWithAction(
        context,
        message: 'Error al abrir lista de pacientes: ${_getErrorMessage(e)}',
        actionText: 'REINTENTAR',
        onAction: _navigateToActivePatients,
        duration: Duration(seconds: 3),
      );

      Logger.error('Error navigating to active patients', e);
    }
  }

  Widget _buildUrgenteSection() {
    return Container(
      height: 200,
      width: 158.83,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.errorText.withOpacity(0.06),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 21, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'URGENTE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.errorText,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: Text(
                      'Pacientes sin registro en 72h',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary1,
                        letterSpacing: 0.28,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: urgentPatients.isEmpty
                        ? Center(
                      child: Text(
                        'No hay pacientes urgentes',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLDark,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: urgentPatients.map((patient) {
                        final daysSinceVisit = patient.lastVisitDate != null
                            ? DateTime.now().difference(patient.lastVisitDate!).inDays
                            : 999;

                        return _buildUrgenteItem(
                          patient.fullName,
                          'Hace ${daysSinceVisit > 1 ? '$daysSinceVisit días' : '1 día'}',
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                'assets/images/alert_icon.svg',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgenteItem(String title, String subtitle) {
    return Container(
      height: 20,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13.125,
                fontWeight: FontWeight.w400,
                color: AppColors.textLDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
          Container(
            width: 1,
            height: 13,
            color: AppColors.iconDark.withOpacity(0.5),
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),
          Expanded(
            flex: 4,
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.errorText,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}