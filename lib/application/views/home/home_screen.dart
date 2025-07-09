import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:mottinutnutriotinist/application/views/home/patient_urgency_screen.dart';
import 'package:provider/provider.dart';
import '../../../configuration/themes/app_colors.dart';
import '../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import '../../../domain/patient/pruebaa.dart';
import '../../../domain/services/auth_provider.dart';
import '../../requestSnacbar/snackBar_manager.dart';
import '../../skeletons/home_skeleton_screen.dart';
import '../patients/categorys_patogys/news/PatientDetailScreen.dart';
import '../patients/categorys_patogys/search/search_patients_creen.dart';
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

  //citas
  List<PatientProfile> patientsNeedingAppointment = [];
  bool isLoadingPatients = false;

  // Servicios
  final PatientServiceEnhanced patientService = PatientServiceEnhanced();

  // Estados
  bool isLoading = true;
  List<AppointmentEnhanced> todayAppointments = [];
  List<Patient> urgentPatients = [];
  int activePatientCount = 0;
  String? error;

  final NutritionistService _nutritionistService = NutritionistService();
  List<PatientUrgency> _urgentPatients = [];
  bool _loadingUrgencies = false;

  @override
  void initState() {
    super.initState();
    loadHomeData();
  }

  @override
  void dispose() {
    patientService.dispose();
    _loadUrgentPatients();
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

      // ✅ AGREGAR: Verificar que el token siga siendo válido
      if (authProvider.token == null) {
        throw Exception('Token de autenticación no disponible');
      }

      // Cargar datos de forma secuencial para mejor debugging
      await loadActivePatients();
      await _loadPatientsNeedingAppointment();
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

      // ✅ AGREGAR: Manejo específico de errores de autenticación
      if (e.toString().contains('Token de autenticación')) {
        SnackBarManager.showError(
          context,
          'Sesión expirada. Por favor, inicia sesión nuevamente.',
        );
      }
    }
  }
  
  
  Future<void> _loadUrgentPatients() async {
    if (!mounted) return;

    setState(() {
      _loadingUrgencies = true;
    });

    try {
      // Obtener token del AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Token de autenticación no disponible');
      }

      final allUrgencies = await _nutritionistService.getPatientsWithUrgency(
          token: token // Usar el token obtenido del AuthProvider
      );

      if (mounted) {
        setState(() {
          // Ordenar por nivel de urgencia y tomar solo los 3 primeros
          _urgentPatients = allUrgencies
            ..sort((a, b) {
              final urgencyOrder = {
                UrgencyLevel.critical: 0,
                UrgencyLevel.high: 1,
                UrgencyLevel.medium: 2,
                UrgencyLevel.low: 3,
              };
              return urgencyOrder[a.urgencyLevel]!.compareTo(urgencyOrder[b.urgencyLevel]!);
            });

          // Tomar solo los 3 más urgentes
          _urgentPatients = _urgentPatients.take(3).toList();
          _loadingUrgencies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingUrgencies = false;
        });
        print('Error loading urgent patients: $e');
      }
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

  Future<void> _loadPatientsNeedingAppointment() async {
    if (isLoadingPatients) return;

    setState(() {
      isLoadingPatients = true;
    });

    try {
      // Obtener token directamente del AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Token de autenticación no disponible');
      }

      // Obtener todos los pacientes
      final allPatients = await _nutritionistService.getAllPatients(token: token);

      // 🔍 DEBUG: Agregar logs para ver qué datos tenemos
      print('📊 Total de pacientes obtenidos: ${allPatients.length}');

      // Filtrar pacientes que necesitan cita
      final now = DateTime.now();
      final patientsNeedingCita = <PatientProfile>[];

      for (var patient in allPatients) {
        print('👤 Paciente: ${patient.fullName}');
        print('   📅 Fecha de registro: ${patient.createdAt}');

        if (patient.createdAt == null) {
          print('   ⚠️ Sin fecha de registro');
          continue;
        }

        final daysSinceRegistration = now.difference(patient.createdAt!).inDays;
        print('   📆 Días desde registro: $daysSinceRegistration');

        if (daysSinceRegistration >= 5 && daysSinceRegistration >= 6 && daysSinceRegistration <= 7) {
          print('   ✅ Paciente agregado a próximas citas');
          patientsNeedingCita.add(patient);
        } else {
          print('   ❌ Paciente no cumple criterio de días');
        }
      }

      print('🎯 Pacientes que necesitan cita: ${patientsNeedingCita.length}');

      if (mounted) {
        setState(() {
          patientsNeedingAppointment = patientsNeedingCita.take(2).toList();
          isLoadingPatients = false;
        });
      }

    } catch (e) {
      print('❌ Error en _loadPatientsNeedingAppointment: $e');
      if (mounted) {
        setState(() {
          isLoadingPatients = false;
        });

        if (e.toString().contains('Token de autenticación')) {
          SnackBarManager.showError(
            context,
            'Sesión expirada. Por favor, inicia sesión nuevamente.',
          );
        } else {
          Logger.error('Error al cargar pacientes que necesitan cita', e);
        }
      }
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
              icon: const Icon(Icons.refresh, color: AppColors.backgroundHipertencion,),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.backgroundLigth,
      onRefresh: loadHomeData,
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
    // Obtener la URL de la imagen del provider
    final profileImageUrl = authProvider.getProfileImageUrl();
    final userId = authProvider.user?['id'] ?? authProvider.user?['userId'];
    final token = authProvider.token;

    // Mostrar la imagen si tenemos URL y userId
    if (profileImageUrl != null && profileImageUrl.isNotEmpty && userId != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.network(
          profileImageUrl,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Accept': 'image/*',
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error cargando imagen de perfil: $error');
            debugPrint('URL intentada: $profileImageUrl');
            return _buildPlaceholderImage();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingIndicator(loadingProgress);
          },
        ),
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: Image.asset(
        'assets/images/placeholder_nutri.jpg',
        fit: BoxFit.cover,
        width: 100,
        height: 100,
      ),
    );
  }

  Widget _buildLoadingIndicator(ImageChunkEvent loadingProgress) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(50),
      ),
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(AppColors.primary),
        ),
      ),
    );
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
                fontSize: 30,
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
                child: isLoadingPatients
                    ? _buildLoadingState()
                    : patientsNeedingAppointment.isEmpty
                    ? _buildNoAppointments()
                    : Column(
                  children: patientsNeedingAppointment
                      .map((patient) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildPatientNeedingAppointment(patient),
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

  Widget _buildLoadingState() {
    return Container(
      height: 80,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cargando pacientes...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLDark,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAppointments() {
    return Container(
      height: 80,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 24,
              color: AppColors.textLDark.withOpacity(0.4),
            ),
            const SizedBox(height: 6),
            Text(
              'No hay citas pendientes por programar',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLDark.withOpacity(0.5),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientNeedingAppointment(PatientProfile patient) {
    final daysSinceRegistration = DateTime.now().difference(patient.createdAt!).inDays;

    // 🔧 CAMBIO: Ajustar la lógica de urgencia
    final urgencyText = daysSinceRegistration >= 5 ? 'Urgente' : 'Próximo';
    final urgencyColor = daysSinceRegistration >= 5 ? AppColors.errorIcon : AppColors.primary;

    return InkWell(
      onTap: () => _navigateToPatientDetail(patient),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próxima cita:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textLDark,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: urgencyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: urgencyColor.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      urgencyText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                        color: urgencyColor,
                      ),
                    ),
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
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHomeLabel,
                      letterSpacing: 0.28,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Registro: ${_formatRegistrationDate(patient.createdAt!)} ($daysSinceRegistration días)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textLDark.withOpacity(0.7),
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRegistrationDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;

    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Ayer';
    if (difference < 7) return 'hace $difference días';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> _navigateToWeeklyAgenda() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/loading/palta_saltarina.json',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 4),
                Text(
                  'Cargando agenda...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Simular carga de datos (reemplaza con tu lógica real)
      await Future.delayed(const Duration(seconds: 1));

      // Cerrar indicador de carga
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WeeklyAgendaScreen(
            appointments: todayAppointments,
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
        message: 'Error al cargar la agenda: ${_getErrorMessage(e)}',
        actionText: 'REINTENTAR',
        onAction: _navigateToWeeklyAgenda,
        duration: const Duration(seconds: 3),
      );

      Logger.error('Error navigating to weekly agenda', e);
    }
  }

  Future<void> _navigateToPatientDetail(PatientProfile patient) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreens(
          patient: patient,
          diseaseType: DiseaseTypes.diabetes,
        ),
      ),
    );
  }

//////////////////////7

  Widget _buildPacientesActivos() {
    return GestureDetector(
      onTap: () => _navigateToActivePatients(),
      child: Container(
        height: 200,
        width: 158.83,

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
            Center(
              child: Column(
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
                    Center(
                      child: Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                        ),
                      ),
                    )
                  ],
                ],
              ),
            ),

            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 31,
                height: 31,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: SvgPicture.asset(
                      'assets/images/next_icon.svg',
                      width: 29,
                      height: 29,
                    ),
                  ),
                )
              ),
            )

          ],
        ),
      ),
    );
  }

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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return GestureDetector(
          onTap: () {
            final token = authProvider.token;
            if (token == null) {
              SnackBarManager.showError(
                context,
                'Error de autenticación. Por favor, inicia sesión nuevamente.',
              );
              return;
            }

            // Navegar a la pantalla de urgencias
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientUrgencyScreen(
                  token: token, // Usar el token del AuthProvider
                ),
              ),
            );
          },
          child: Container(
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
                        const SizedBox(height: 8),
                        Expanded(
                          child: _loadingUrgencies
                              ? Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.errorText,
                                ),
                              ),
                            ),
                          )
                              : _urgentPatients.isEmpty
                              ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icono cuando no hay urgencias
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.errorText.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 24,
                                  color: AppColors.errorText.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No hay pacientes con urgencia',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLDark.withOpacity(0.6),
                                  fontWeight: FontWeight.w400,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ],
                          )
                              : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mensaje cuando hay urgencias
                              Container(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Pacientes que requieren atención',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textPrimary1,
                                    letterSpacing: 0.28,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Lista de pacientes urgentes
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: _urgentPatients.map((urgency) {
                                    return _buildUrgenteItem(urgency);
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Badge con icono de alerta
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        SvgPicture.asset(
                          'assets/images/alert_icon.svg',
                        ),
                        // Badge con número de urgencias si hay más de 0
                        if (_urgentPatients.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.errorText,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                _urgentPatients.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUrgenteItem(PatientUrgency urgency) {
    // Obtener configuración de urgencia
    Color urgencyColor;
    IconData urgencyIcon;

    switch (urgency.urgencyLevel) {
      case UrgencyLevel.critical:
        urgencyColor = Colors.red;
        urgencyIcon = Icons.emergency;
        break;
      case UrgencyLevel.high:
        urgencyColor = Colors.orange;
        urgencyIcon = Icons.warning;
        break;
      case UrgencyLevel.medium:
        urgencyColor = Colors.amber;
        urgencyIcon = Icons.priority_high;
        break;
      case UrgencyLevel.low:
        urgencyColor = Colors.green;
        urgencyIcon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            urgencyIcon,
            size: 12,
            color: urgencyColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urgency.patientName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Hace ${urgency.daysSinceLastConsultation} días',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textLDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}