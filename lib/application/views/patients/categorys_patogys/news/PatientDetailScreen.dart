import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import 'package:lottie/lottie.dart';
import 'CreateMedicalHistoryScreen.dart';
import 'NutritionPlanGenerator.dart';
import 'PatientAvatarWidget.dart';
import 'PatientValidationHelper.dart';
import 'package:intl/intl.dart';

enum DiseaseTypes { diabetes, hipertension, obesity, general, none }

class PatientDetailScreens extends StatefulWidget {
  final PatientProfile patient;
  final DiseaseTypes diseaseType;

  const PatientDetailScreens({
    Key? key,
    required this.patient,
    required this.diseaseType,
  }) : super(key: key);

  @override
  State<PatientDetailScreens> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreens>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  PatientWithHistory? _patientWithHistory;
  PatientHealthSummary? _healthSummary;
  bool _isLoading = true;
  String? _errorMessage;
  String? _authToken;
  bool _showNameInAppBar = false;

  bool _isGeneratingPlan = false;
  NutritionPlanResponse? _generatedPlan;
  NutritionPlanGenerator? _planGenerator;

  bool _showActionButtons = true;
  double _lastScrollOffset = 0;
  Timer? _hideTimer;
  static const double _scrollThreshold = 10.0;

  Color get _diseaseColor {
    switch (widget.diseaseType) {
      case DiseaseTypes.diabetes:
        return AppColors.secondary;
      case DiseaseTypes.hipertension:
        return AppColors.backgroundHipertencion;
      case DiseaseTypes.obesity:
        return AppColors.backgroundObecidad;
      case DiseaseTypes.general:
        return AppColors.primary;
      case DiseaseTypes.none:
        return AppColors.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // En initState(), CAMBIAR:
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        // Tab 0: Información - Mostrar botones
        setState(() {
          _showActionButtons = true;
        });
        _cancelHideTimer();
      } else if (_tabController.index == 1) {
        // Tab 1: Historial - Lógica de scroll
        setState(() {
          _showActionButtons = true;
        });
        _cancelHideTimer();
      } else if (_tabController.index == 2) {
        // Tab 2: Progreso - Ocultar botones
        setState(() {
          _showActionButtons = false;
        });
        _cancelHideTimer();
      }
    });

    _loadPatientDetails();
  }

  Future<void> _loadPatientDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Token de autenticación no encontrado');
      }

      _authToken = token;
      final nutritionistService = NutritionistService();

      final patientWithHistory =
          await nutritionistService.getPatientWithHistory(
        widget.patient.patientId,
        token,
      );

      final healthSummary = await nutritionistService.getPatientHealthSummary(
        widget.patient.patientId,
        token,
      );

      setState(() {
        _patientWithHistory = patientWithHistory;
        _healthSummary = healthSummary;
        _isLoading = false;

        _planGenerator = NutritionPlanGenerator(
          context: context,
          patient: widget.patient,
          patientWithHistory: _patientWithHistory,
          authToken: _authToken,
        );
      });
    } catch (e) {
      print('❌ Error al cargar detalles del paciente: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('❌ Error al obtener token: $e');
      return null;
    }
  }

  void _navigateToCreateMedicalHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMedicalHistoryScreen(
          patient: widget.patient,
          onHistoryCreated: () {
            _loadPatientDetails();
          },
        ),
      ),
    );
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final shouldShowName = currentOffset > 200;

    // Solo lógica para mostrar/ocultar nombre en AppBar
    if (shouldShowName != _showNameInAppBar) {
      setState(() {
        _showNameInAppBar = shouldShowName;
      });
    }

    // ✅ NUEVA LÓGICA: Solo para Tab 1 (Historial)
    if (_tabController.index == 1) {
      final scrollDifference = currentOffset - _lastScrollOffset;

      if (currentOffset <= 50) {
        if (!_showActionButtons) {
          setState(() {
            _showActionButtons = true;
          });
        }
      } else if (scrollDifference > _scrollThreshold && _showActionButtons) {
        setState(() {
          _showActionButtons = false;
        });
        _cancelHideTimer();
      } else if (scrollDifference < -_scrollThreshold && !_showActionButtons) {
        setState(() {
          _showActionButtons = true;
        });
        _startHideTimer();
      }
    }

    _lastScrollOffset = currentOffset;
  }

  void _startHideTimer() {
    _cancelHideTimer();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _scrollController.offset > 50) {
        setState(() {
          _showActionButtons = false;
        });
      }
    });
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _onUserInteractionForTabs() {
    // Solo para Tab 0 (Información)
    if (_tabController.index == 0) {
      setState(() {
        _showActionButtons = !_showActionButtons;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: _diseaseColor.withOpacity(0.6),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: _buildFixedAppBar(),
        body: GestureDetector(
          onTap: () => _onUserInteractionForTabs(),
          onPanDown: (_) => _onUserInteractionForTabs(),
          child: _isLoading
              ? Center(
                  child: Lottie.asset(
                    'assets/loading/palta_saltarina.json',
                    width: 100,
                    height: 100,
                  ),
                )
              : _errorMessage != null
                  ? _buildErrorState()
                  : Column(
                      children: [
                        _buildTabBar(),
                        Expanded(
                          child: Stack(
                            children: [
                              TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildInformationTab(),
                                  _buildHistoryTab(),
                                  _buildProgressTab(),
                                ],
                              ),
                              _buildAnimatedActionButtons(),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildFixedAppBar() {
    final statusColor = PatientValidationHelper.getStatusColor(widget.patient);
    final statusText = PatientValidationHelper.getStatusText(widget.patient);
    final diabetesType =
        PatientValidationHelper.getDiabetesType(widget.patient.chronicDisease);

    return AppBar(
      backgroundColor: _diseaseColor,
      elevation: 4,
      toolbarHeight: 225,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _diseaseColor,
              // ✅ Usar el color específico de la enfermedad
              _diseaseColor.withOpacity(0.8),
              // ✅ Usar el color específico de la enfermedad
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    // Flecha de regreso
                    IconButton(
                      icon: SvgPicture.asset(
                        'assets/images/anterior_icon.svg',
                        width: 21,
                        height: 21,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          // ✅ Cambiar a blanco para mejor contraste
                          width: 2,
                        ),
                      ),
                      child: PatientAvatarWidget(
                        patient: widget.patient,
                        statusColor: statusColor,
                        token: _authToken ?? '',
                        size: 45,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Nombre y tipo de paciente (en columna)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.patient.fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.patient.chronicDisease ?? 'Sin enfermedad',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Icono de historial de planes con tooltip
                    Tooltip(
                      message: 'Ver historial de planes',
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.history,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          // Navegar al historial de planes nutricionales
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Segunda fila: Email, teléfono y status
                Padding(
                  padding: const EdgeInsets.only(left: 66),
                  child: Row(
                    children: [
                      // Información de contacto
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email
                            Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.patient.email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.patient.phone != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.patient.phone!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tercera fila: Información médica con fondo y bordes
                Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildInfoColumn(
                            'Edad', '${widget.patient.age ?? 0}', 'años'),
                        _buildSvgDivider(),
                        _buildInfoColumn(
                            'Peso',
                            widget.patient.weight?.toStringAsFixed(0) ?? 'N/A',
                            'kg'),
                        _buildSvgDivider(),
                        _buildInfoColumn(
                            'Talla',
                            widget.patient.height?.toStringAsFixed(0) ?? 'N/A',
                            'cm'),
                        _buildSvgDivider(),
                        _buildInfoColumn(
                            'IMC',
                            widget.patient.bmi?.toStringAsFixed(1) ?? 'N/A',
                            null),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value, String? suffix) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 2),
                Text(
                  suffix,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSvgDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      height: 40,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.6),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error al cargar información',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Error desconocido',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadPatientDetails,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child:
                const Text('Reintentar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedActionButtons() {
    final hasHistory =
        PatientValidationHelper.isHistoryComplete(_patientWithHistory);
    final isNewPatient = PatientValidationHelper.isNewPatient(widget.patient);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 10,
      right: 10,
      bottom: _showActionButtons ? 0 : -120,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showActionButtons ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: _showActionButtons
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ]
                : [],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNewPatient) ...[
                  // Botón principal para paciente nuevo
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _diseaseColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _navigateToCreateMedicalHistory,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 9, horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.medical_services,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Completar Historial Médico',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else if (!hasHistory) ...[
                  // Paciente existente sin historial
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _navigateToCreateMedicalHistory,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.medical_services,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Crear Primera Consulta',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Paciente con historial - Botones principales
                  Row(
                    children: [
                      // Botón generar plan nutricional
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _diseaseColor,
                                _diseaseColor.withOpacity(0.8)
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  _planGenerator?.showPlanTypeSelector(),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.restaurant_menu,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'Generar Plan',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón nueva consulta
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _diseaseColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _navigateToCreateMedicalHistory,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: _diseaseColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Consulta',
                                        style: TextStyle(
                                          color: _diseaseColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      // ✅ Agregar Container con fondo
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: 'Información'),
          Tab(text: 'Historial'),
          Tab(text: 'Progreso'),
        ],
        indicatorColor: _diseaseColor,
        labelColor: _diseaseColor,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelColor: _diseaseColor.withOpacity(0.4),
        indicatorWeight: 3.0,
      ),
    );
  }

  Widget _buildInformationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 10,
      ),
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Información Personal',
            [
              _buildInfoRow('Nombres :', widget.patient.fullName),
              _buildInfoRow('Email :', widget.patient.email),
              _buildInfoRow(
                  'Teléfono :', widget.patient.phone ?? 'No especificado'),
              _buildInfoRow(
                  'Género :', widget.patient.gender ?? 'No especificado'),
              _buildInfoRow(
                  'Fecha de nacimiento :',
                  widget.patient.birthDate?.toString().substring(0, 10) ??
                      'No especificado'),
            ],
          ),
          const SizedBox(height: 8),
          _buildSectionCard(
            'Información Médica',
            [
              _buildInfoRow('Enfermedad crónica',
                  widget.patient.chronicDisease ?? 'Ninguna'),
              _buildInfoRow('Alergias', widget.patient.allergies ?? 'Ninguna'),
              _buildInfoRow('Preferencias dietéticas',
                  widget.patient.dietaryPreferences ?? 'No especificadas'),
              _buildInfoRow('Contacto de emergencia',
                  widget.patient.emergencyContact ?? 'No especificado'),
            ],
          ),
          const SizedBox(height: 8),
          _buildSectionCard(
            'Medidas Corporales',
            [
              _buildInfoRow(
                  'Altura :',
                  widget.patient.height != null
                      ? '${widget.patient.height!.toStringAsFixed(1)} cm'
                      : 'No registrada'),
              _buildInfoRow(
                  'Peso :',
                  widget.patient.weight != null
                      ? '${widget.patient.weight!.toStringAsFixed(1)} kg'
                      : 'No registrado'),
              _buildInfoRow(
                  'IMC :',
                  widget.patient.bmi != null
                      ? widget.patient.bmi!.toStringAsFixed(1)
                      : 'No calculado'),
              _buildInfoRow('Categoría IMC',
                  widget.patient.bmiCategory ?? 'No determinada'),
            ],
          ),
          // 🔥 NUEVO: Espacio adicional para que se pueda hacer scroll completo
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (!PatientValidationHelper.hasCompleteHistory(_patientWithHistory)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Sin historial médico',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              PatientValidationHelper.isNewPatient(widget.patient)
                  ? 'Complete el historial médico para comenzar'
                  : 'Complete la primera consulta para ver el historial',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToCreateMedicalHistory,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text(
                PatientValidationHelper.isNewPatient(widget.patient)
                    ? 'Completar Historial'
                    : 'Crear Primera Consulta',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    // Ordenar por fecha de consulta (más reciente primero)
    final sortedHistories =
    List<MedicalHistory>.from(_patientWithHistory!.medicalHistories)
      ..sort((a, b) => b.consultationDate.compareTo(a.consultationDate));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 130,
      ),
      itemCount: sortedHistories.length,
      itemBuilder: (context, index) {
        final history = sortedHistories[index];
        // La primera (index 0) es la más reciente
        return _buildHistoryCard(history, index == 0);
      },
    );
  }

  Widget _buildProgressTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Gráficos de progreso aquí',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRelativeDateText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final difference = today.difference(dateOnly).inDays;

    switch (difference) {
      case 0:
        return 'hoy';
      case 1:
        return 'ayer';
      case 2:
        return 'anteayer';
      case 3:
        return 'hace 3 días';
      default:
        if (difference <= 7) {
          return 'hace $difference días';
        } else {
          final dateFormat = DateFormat('dd/MM/yyyy');
          return dateFormat.format(date);
        }
    }
  }

  Widget _buildHistoryCard(MedicalHistory history, bool isMostRecent) {
    // Determinar si la consulta ha sido editada
    final isEdited = history.createdAt != history.updatedAt;

    // Formatear fecha y hora
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final consultationDate = dateFormat.format(history.consultationDate);
    final createdTime = timeFormat.format(history.createdAt);

    // Usar el nuevo método para fecha relativa
    final relativeDateText = _getRelativeDateText(history.createdAt);

    // Color de fondo para la última consulta
    final backgroundColor =
    isMostRecent ? AppColors.checkValidation.withOpacity(0.05) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: isMostRecent
            ? Border.all(color: AppColors.checkValidation.withOpacity(0.08), width: 1.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Título principal
                          Text(
                            'Creada el $consultationDate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isMostRecent ? Colors.green[800] : Colors.black,
                            ),
                          ),
                          const Spacer(),

                          if (isMostRecent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundHipertencion,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Reciente',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          // Etiqueta "Editada" solo si NO es la más reciente
                          if (isEdited && !isMostRecent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                'Editada',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Fecha y hora de creación en cursiva y pequeña con formato amigable
                      Text(
                        'últ. vez $relativeDateText a las $createdTime',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEdited && !isMostRecent)
                  Tooltip(
                    message:
                    'Editada el ${dateFormat.format(history.updatedAt)} a las ${timeFormat.format(history.updatedAt)}',
                    child: const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Resto del contenido de la tarjeta...
            if (history.bloodGlucose != null)
              _buildHistoryInfoRow('Glucosa',
                  '${history.bloodGlucose!.toStringAsFixed(1)} mg/dL'),
            if (history.bloodPressure != null)
              _buildHistoryInfoRow('Presión Arterial', history.bloodPressure!),
            if (history.waistCircumference != null)
              _buildHistoryInfoRow('Circunferencia Cintura',
                  '${history.waistCircumference!.toStringAsFixed(1)} cm'),
            if (history.bodyFatPercentage != null)
              _buildHistoryInfoRow('Grasa Corporal',
                  '${history.bodyFatPercentage!.toStringAsFixed(1)}%'),
            if (history.waterConsumption != null)
              _buildHistoryInfoRow('Consumo de Agua',
                  '${history.waterConsumption!.toStringAsFixed(1)} L'),
            if (history.sleepQuality != null)
              _buildHistoryInfoRow(
                  'Calidad del Sueño', '${history.sleepQuality!}/10'),
            if (history.stressLevel != null)
              _buildHistoryInfoRow(
                  'Nivel de Estrés', '${history.stressLevel!}/10'),
            if (history.nutritionalObjectives != null &&
                history.nutritionalObjectives!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Objetivos Nutricionales:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    history.nutritionalObjectives!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            if (history.professionalNotes != null &&
                history.professionalNotes!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Notas Profesionales:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    history.professionalNotes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    _cancelHideTimer(); // 🔥 NUEVO: Cancelar timer
    super.dispose();
  }
}
