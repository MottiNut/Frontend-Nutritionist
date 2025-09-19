import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import '../../../../configuration/themes/app_colors.dart';
import '../../../../domain/patient/pruebaa.dart';
import '../../../requestSnacbar/snackBar_manager.dart';

class WeeklyAgendaScreen extends StatefulWidget {
  final List<AppointmentEnhanced> appointments;
  final PatientServiceEnhanced patientService;

  const WeeklyAgendaScreen({
    Key? key,
    required this.appointments,
    required this.patientService,
  }) : super(key: key);

  @override
  State<WeeklyAgendaScreen> createState() => _WeeklyAgendaScreenState();
}

class _WeeklyAgendaScreenState extends State<WeeklyAgendaScreen> with SingleTickerProviderStateMixin {
  int selectedDayIndex = 0;
  int currentDesignIndex = 0; // 0 = Diseño Grid, 1 = Diseño Horizontal
  List<DateTime> weekDays = [];
  List<String> dayNames = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
  List<String> monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  final Map<String, Patient> _patientsCache = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isSearchExpanded = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _generateWeekDays();
    _preloadPatients();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _generateWeekDays() {
    final today = DateTime.now();
    weekDays.clear();

    for (int i = 0; i < 7; i++) {
      weekDays.add(today.add(Duration(days: i)));
    }
  }

  Future<void> _preloadPatients() async {
    try {
      final uniquePatientIds = widget.appointments
          .map((appointment) => appointment.patientId)
          .toSet()
          .toList();

      for (String patientId in uniquePatientIds) {
        if (!_patientsCache.containsKey(patientId)) {
          final patient = await widget.patientService.getPatientById(patientId);
          _patientsCache[patientId] = patient;
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error precargando pacientes: $e');
    }
  }

  List<AppointmentEnhanced> _getAppointmentsForDay(DateTime day) {
    final dayAppointments = widget.appointments.where((appointment) {
      final appointmentDate = appointment.scheduledDate;
      return appointmentDate.year == day.year &&
          appointmentDate.month == day.month &&
          appointmentDate.day == day.day;
    }).toList()..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    if (_searchQuery.isEmpty) return dayAppointments;

    return dayAppointments.where((appointment) {
      final patient = _patientsCache[appointment.patientId];
      if (patient == null) return false;

      return patient.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          appointment.type.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (patient.phone?.contains(_searchQuery) ?? false);
    }).toList();
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDate(DateTime date) {
    return '${date.day} de ${monthNames[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 0, 
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeaderWithDaySelector(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildModernAppointmentsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeaderWithDaySelector() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: Column(
        children: [
          // Header superior con botones y título
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isSearchExpanded ? _buildExpandedSearch() : _buildCollapsedHeader(),
            ),
          ),

          // Información del mes y contador de citas
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${monthNames[DateTime.now().month - 1]} ${DateTime.now().year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_getAppointmentsForSelectedDay().length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Citas del día',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Day Selector integrado en el header
          Container(
            height: 70,
            margin: const EdgeInsets.only(bottom: 15),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: weekDays.length,
              itemBuilder: (context, index) {
                final day = weekDays[index];
                final isSelected = selectedDayIndex == index;
                final isToday = DateTime.now().day == day.day &&
                    DateTime.now().month == day.month &&
                    DateTime.now().year == day.year;
                final appointmentCount = _getAppointmentsForDay(day).length;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDayIndex = index;
                    });
                    _animationController.reset();
                    _animationController.forward();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 65,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected ? Border.all(width: 1, color: AppColors.backgroundHipertencion) : Border.all(width: 0.4, color: AppColors.primary)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNames[day.weekday - 1],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          /*const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isToday)
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (appointmentCount > 0 && !isToday)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.6)
                                        : Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),*/
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedHeader() {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        const SizedBox(width: 16),

        // Título
        const Expanded(
          child: Text(
            'Próximas Citas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
          ),
        ),

        // Botón de búsqueda
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 24),
            onPressed: () {
              setState(() {
                _isSearchExpanded = true;
              });
              _searchFocusNode.requestFocus();
            },
          ),
        ),

        const SizedBox(width: 8),

        // Botón de filtros
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.tune, color: Colors.white, size: 22),
            onPressed: (){},
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedSearch() {
    return Row(
      children: [
        // Botón de retroceso (siempre visible)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
            onPressed: () {
              _searchFocusNode.unfocus();
              _searchController.clear();
              setState(() {
                _isSearchExpanded = false;
                _searchQuery = '';
              });
            },
          ),
        ),

        const SizedBox(width: 12),

        // Campo de búsqueda expandido
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar pacientes o citas...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 17,
                      color: Color(0xFF64748B),
                    ),
                  ),
                )
                    : null,
              ),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Botón de filtros (mantenido)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.tune, color: Colors.white, size: 24),
            onPressed: (){},
          ),
        ),
      ],
    );
  }

// Método para obtener citas del día seleccionado
  List<dynamic> _getAppointmentsForSelectedDay() {
    if (selectedDayIndex >= 0 && selectedDayIndex < weekDays.length) {
      return _getAppointmentsForDay(weekDays[selectedDayIndex]);
    }
    return [];
  }

  Widget _buildModernAppointmentsList() {
    final selectedDay = weekDays[selectedDayIndex];
    final dayAppointments = _getAppointmentsForDay(selectedDay);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dayAppointments.isNotEmpty)
            const Text(
              'Citas de hoy:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textInput
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: dayAppointments.isEmpty
                ? _buildModernEmptyState()
                : ListView.separated(
              itemCount: dayAppointments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildCompactAppointmentCard(dayAppointments[index], index);
              },
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildCompactAppointmentCard(AppointmentEnhanced appointment, int index) {
    return Dismissible(
      key: Key('appointment_${appointment.id}'),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.errorIcon,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: const [
                  Icon(Icons.warning_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    '¿Eliminar cita?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: const Text(
                '¿Estás seguro de que deseas eliminar esta cita? Esta acción no se puede deshacer.',
                style: TextStyle(fontSize: 16),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 13),),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorIcon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Eliminar', style: TextStyle(fontSize: 13),),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        // Aquí implementarías la lógica para eliminar la cita
        SnackBarManager.showInfo(context, 'Cita eliminada');

      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(width: 0.3, color: AppColors.iconPrimary)
        ),
        child: _buildPatientInfoOptimized(appointment),
      ),
    );
  }

  Widget _buildPatientInfoOptimized(AppointmentEnhanced appointment) {
    if (_patientsCache.containsKey(appointment.patientId)) {
      final patient = _patientsCache[appointment.patientId]!;
      return _buildCompactPatientInfo(patient, appointment);
    }

    return FutureBuilder<Patient>(
      future: _loadAndCachePatient(appointment.patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPatientInfo();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorPatientInfo();
        }

        final patient = snapshot.data!;
        return _buildCompactPatientInfo(patient, appointment);
      },
    );
  }

  Widget _buildCompactPatientInfo(Patient patient, AppointmentEnhanced appointment) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.1),
                const Color(0xFF3B82F6).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            image: patient.profileImageUrl != null
                ? DecorationImage(
              image: NetworkImage(patient.profileImageUrl!),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: patient.profileImageUrl == null
              ? Center(
            child: Text(
              patient.fullName.isNotEmpty
                  ? patient.fullName[0].toUpperCase()
                  : 'P',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3B82F6),
              ),
            ),
          )
              : null,
        ),
        const SizedBox(width: 12),
        // Info del paciente
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              Text(
                patient.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Tipo de cita
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getAppointmentTypeColor(appointment.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  appointment.type.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getAppointmentTypeColor(appointment.type),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Teléfono y edad
              Row(
                children: [
                  if (patient.phone != null && patient.phone!.isNotEmpty) ...[
                    const Icon(Icons.phone, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      patient.phone!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (patient.age > 0) ...[
                    if (patient.phone != null && patient.phone!.isNotEmpty)
                      Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      '${patient.age} años',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Hora y menú
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatTime(appointment.scheduledDate),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                _showPatientQuickActions(context, patient, appointment);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF475569),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<Patient> _loadAndCachePatient(String patientId) async {
    if (_patientsCache.containsKey(patientId)) {
      return _patientsCache[patientId]!;
    }

    final patient = await widget.patientService.getPatientById(patientId);
    _patientsCache[patientId] = patient;
    return patient;
  }

  Widget _buildModernEmptyState() {
    final isToday = selectedDayIndex == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 130,
            height: 130,

            child: Lottie.asset(
              'assets/loading/empty_calendar.json',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isToday ? 'Sin citas para hoy' : 'Sin citas programadas',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isToday
                ? 'Tu agenda de hoy está libre'
                : 'No hay citas programadas para este día',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textInput,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              // Navigator.pushNamed(context, '/create-appointment');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Programar cita',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLoadingPatientInfo() {
    return Row(
      children: [
        Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: SvgPicture.asset('assets/loading/palta_saltarina.json')
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPatientInfo() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.errorIcon.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.error_outline,
            color: Color(0xFFEF4444),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error al cargar paciente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
              Text(
                'No se pudo cargar la información',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getAppointmentTypeColor(AppointmentType type) {
    switch (type) {
      case AppointmentType.primeraConsulta:
        return const Color(0xFF3B82F6);
      case AppointmentType.evaluacion:
        return const Color(0xFF10B981);
      case AppointmentType.control:
        return const Color(0xFFF59E0B);
      case AppointmentType.seguimiento:
        return const Color(0xFFEF4444);
      case AppointmentType.urgencia:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _showPatientQuickActions(BuildContext context, Patient patient, AppointmentEnhanced appointment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de arrastre
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Información del paciente
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.1),
                        const Color(0xFF3B82F6).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    image: patient.profileImageUrl != null
                        ? DecorationImage(
                      image: NetworkImage(patient.profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: patient.profileImageUrl == null
                      ? Center(
                    child: Text(
                      patient.fullName.isNotEmpty
                          ? patient.fullName[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        _formatTime(appointment.scheduledDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Acciones rápidas
            Column(
              children: [
                _buildQuickAction(
                  icon: Icons.edit,
                  title: 'Editar cita',
                  subtitle: 'Modificar horario o tipo',
                  onTap: () {
                    Navigator.pop(context);
                    // Navegar a editar cita
                  },
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.person,
                  title: 'Ver perfil del paciente',
                  subtitle: 'Información completa',
                  onTap: () {
                    Navigator.pop(context);
                    // Navegar al perfil del paciente
                  },
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.phone,
                  title: 'Llamar',
                  subtitle: patient.phone ?? 'Sin teléfono',
                  onTap: patient.phone != null ? () {
                    Navigator.pop(context);
                    // Hacer llamada
                  } : null,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.history,
                  title: 'Historial médico',
                  subtitle: 'Ver consultas anteriores',
                  onTap: () {
                    Navigator.pop(context);
                    // Navegar al historial médico
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: onTap != null ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: onTap != null
                    ? const Color(0xFF3B82F6).withOpacity(0.1)
                    : const Color(0xFF94A3B8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: onTap != null
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: onTap != null
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: onTap != null
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFF94A3B8),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

