import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import 'package:lottie/lottie.dart';
import 'CreateMedicalHistoryScreen.dart';
import 'NutritionPlanDetailScreen.dart';
import 'NutritionPlanGenerator.dart';
import 'PatientAvatarWidget.dart';
import 'PatientValidationHelper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

enum PatientDisease {
  obesity,
  hypertension,
  diabetes,
  none
}

PatientDisease detectDiseaseFromString(String? diseaseText) {
  if (diseaseText == null || diseaseText.trim().isEmpty || diseaseText.trim().toLowerCase() == 'ninguna') {
    return PatientDisease.none;
  }

  final text = diseaseText.toLowerCase().trim();

  if (text.contains('obesidad') ||
      text.contains('obesity') ||
      text.contains('obeso') ||
      text.contains('obesa') ||
      text.contains('sobrepeso') ||
      text.contains('sobre peso')) {
    print('✅ Detectada: OBESIDAD');
    return PatientDisease.obesity;
  }

  if (text.contains('hipertensión') ||
      text.contains('hipertension') ||
      text.contains('hipertensión arterial') ||
      text.contains('hipertension arterial') ||
      text.contains('presión') ||
      text.contains('presion') ||
      text.contains('arterial') ||
      text.contains('hta') ||
      text.contains('hipertenso') ||
      text.contains('hipertensa') ||
      text.contains('hipertensivo') ||
      text.contains('hipertensiva')) {
    print('✅ Detectada: HIPERTENSIÓN');
    return PatientDisease.hypertension;
  }

  // Detectar diabetes
  if (text.contains('diabetes') ||
      text.contains('diabético') ||
      text.contains('diabética') ||
      text.contains('diabetico') ||
      text.contains('diabetica')) {
    print('✅ Detectada: DIABETES');
    return PatientDisease.diabetes;
  }

  print('❌ No se detectó enfermedad específica, retornando: NONE');
  return PatientDisease.none;
}

Color getDiseaseColor(PatientDisease disease) {
  switch (disease) {
    case PatientDisease.obesity:
      return AppColors.backgroundObecidad;
    case PatientDisease.hypertension:
      return AppColors.backgroundHipertencion;
    case PatientDisease.diabetes:
      return AppColors.secondary;
    case PatientDisease.none:
    default:
      return AppColors.primary;
  }
}

class PatientDetailScreens extends StatefulWidget {
  final PatientProfile patient;

  const PatientDetailScreens({
    Key? key,
    required this.patient,
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

  late PatientDisease _patientDisease;
  late Color _diseaseColor;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(_onScroll);
    _loadPatientDetails();

    _patientDisease = detectDiseaseFromString(widget.patient.chronicDisease);
    _diseaseColor = getDiseaseColor(_patientDisease);
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: _diseaseColor.withOpacity(0.6),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: _buildFixedAppBar(_diseaseColor),
        body: _isLoading
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
            Material(
              color: Colors.white,
              elevation: 2,
              child: _buildTabBar(),
            ),

            Expanded(
              child: Stack(
                children: [
                  CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      _buildTabContent(),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 120),
                      ),
                    ],
                  ),
                  _buildFixedActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildFixedAppBar(Color diseaseColor) {
    final statusColor = PatientValidationHelper.getStatusColor(widget.patient);
    final statusText = PatientValidationHelper.getStatusText(widget.patient);
    final diabetesType =
        PatientValidationHelper.getDiabetesType(widget.patient.chronicDisease);

    return AppBar(
      backgroundColor: diseaseColor,
      elevation: 4,
      toolbarHeight: 165,

      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              diseaseColor,
              diseaseColor.withOpacity(0.8),
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
                        color: Colors.white.withOpacity(0.4), // ✔ color aquí
                        shape: BoxShape.circle,
                      ),
                      child: PatientAvatarWidget(
                        patient: widget.patient,
                        statusColor: Colors.white.withOpacity(0.1),
                        token: _authToken ?? '',
                        size: 50,
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.patient.fullName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.patient.chronicDisease ?? 'Sin enfermedad',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

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

                    /*Tooltip(
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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PatientPlanHistoryScreen(
                                patientId: widget.patient.patientId,
                                patientName: widget.patient.fullName,
                              ),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ),*/
                  ],
                ),

                /*const SizedBox(height: 8),

                // Segunda fila: Email, teléfono y status
                Padding(
                  padding: const EdgeInsets.only(left: 66),
                  // Alineado con el nombre
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
                ),*/

                const SizedBox(height: 8),


                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  // Alineado con el nombre
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
                          'Edad',
                          '${widget.patient.age ?? 0}',
                          'años',
                        ),
                        _buildSvgDivider(),
                        _buildInfoColumn(
                          'Peso',
                          widget.patient.weight?.toStringAsFixed(0) ?? 'N/A',
                          'kg',
                        ),
                        _buildSvgDivider(),
                        _buildInfoColumn(
                          'Talla',
                          widget.patient.height?.toStringAsFixed(0) ?? 'N/A',
                          'cm',
                        ),
                        _buildSvgDivider(),
                        _buildInfoColumn(
                          'IMC',
                          widget.patient.bmi?.toStringAsFixed(1) ?? 'N/A',
                          null,
                        ),
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
              fontSize: 13,
              fontFamily: "Omnes",
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
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: "Omnes",
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Omnes",
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
            style: ElevatedButton.styleFrom(backgroundColor: _diseaseColor),
            child:
                const Text('Reintentar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedActionButtons() {
    final hasHistory =
        PatientValidationHelper.isHistoryComplete(_patientWithHistory);
    final isNewPatient = PatientValidationHelper.isNewPatient(widget.patient);

    return Positioned(
      left: 10,
      right: 10,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
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
                    color: _diseaseColor ,
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

                Row(
                  children: [

                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_diseaseColor, _diseaseColor.withOpacity(0.5)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _planGenerator?.showPlanTypeSelector(),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 11, horizontal: 16),
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
                                        fontSize: 16,
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
                            color: _diseaseColor.withOpacity(0.6),
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
                                  vertical: 13, horizontal: 10),
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
    );
  }

  Widget _buildTabBar() {
    List<Tab> tabs = const [
      Tab(text: 'Información'),
      Tab(text: 'Historial'),
      Tab(text: 'Progreso'),
    ];

    return TabBar(
      controller: _tabController,
      tabs: tabs,
      isScrollable: false,
      labelColor: _diseaseColor,
      unselectedLabelColor: Colors.grey[400],
      labelStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      indicatorColor: _diseaseColor,
      indicatorWeight: 2.5,
      indicatorSize: TabBarIndicatorSize.tab,
    );
  }

  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildInformationTab(),
          _buildHistoryTab(),
          _buildProgressTab(),
        ],
      ),
    );
  }

  Widget _buildInformationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Información Personal',
            [
              _buildInfoRow('Nombre completo', widget.patient.fullName),
              _buildInfoRow('Email', widget.patient.email),
              _buildInfoRow(
                  'Teléfono', widget.patient.phone ?? 'No especificado'),
              _buildInfoRow(
                  'Género', widget.patient.gender ?? 'No especificado'),
              _buildInfoRow(
                  'Fecha de nacimiento',
                  widget.patient.birthDate?.toString().substring(0, 10) ??
                      'No especificado'),
            ],
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          _buildSectionCard(
            'Medidas Corporales',
            [
              _buildInfoRow(
                  'Altura',
                  widget.patient.height != null
                      ? '${widget.patient.height!.toStringAsFixed(1)} cm'
                      : 'No registrada'),
              _buildInfoRow(
                  'Peso',
                  widget.patient.weight != null
                      ? '${widget.patient.weight!.toStringAsFixed(1)} kg'
                      : 'No registrado'),
              _buildInfoRow(
                  'IMC',
                  widget.patient.bmi != null
                      ? widget.patient.bmi!.toStringAsFixed(1)
                      : 'No calculado'),
              _buildInfoRow('Categoría IMC',
                  widget.patient.bmiCategory ?? 'No determinada'),
            ],
          ),
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
              style: ElevatedButton.styleFrom(backgroundColor: _diseaseColor),
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

    return ListView.builder(
      padding: const EdgeInsets.all(11),
      itemCount: _patientWithHistory!.medicalHistories.length,
      itemBuilder: (context, index) {
        final history = _patientWithHistory!.medicalHistories[index];
        final isRecent = index == 0;
        return _buildHistoryCard(history, isRecent: isRecent);
      },
    );
  }


  Widget _buildProgressTab() {
    if (!PatientValidationHelper.hasCompleteHistory(_patientWithHistory)) {
      return _buildEmptyProgressState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressHeader(),
          const SizedBox(height: 20),
          _buildWeightProgressChart(),
          _buildVitalSignsCards(),
          const SizedBox(height: 20),
          _buildHealthMetricsChart(),
          const SizedBox(height: 20),
          _buildRecentAchievements(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildEmptyProgressState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _diseaseColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.trending_up_rounded,
              size: 64,
              color: _diseaseColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Progreso en desarrollo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Una vez que se registren más consultas,\npodrás ver el progreso del paciente aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _diseaseColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _diseaseColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: _diseaseColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Se necesitan al menos 2 consultas',
                  style: TextStyle(
                    color: _diseaseColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    final latestHistory = _patientWithHistory!.medicalHistories.first;
    final daysSinceLastVisit =
        DateTime.now().difference(latestHistory.consultationDate).inDays;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea superior: Progreso + última consulta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(
                      'Última cita: ${latestHistory.consultationDate.day.toString().padLeft(2, '0')}/'
                          '${latestHistory.consultationDate.month.toString().padLeft(2, '0')}/'
                          '${latestHistory.consultationDate.year}',
                      style: TextStyle(
                        color: Colors.blueGrey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),
          // Total de visitas
          Text(
            '${_patientWithHistory!.medicalHistories.length} visitas registradas',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildWeightProgressChart() {
    final histories = _patientWithHistory!.medicalHistories;
    if (histories.length < 2) return const SizedBox.shrink();

    // Obtener datos de peso del paciente y del historial
    List<FlSpot> weightSpots = [];
    double currentWeight = widget.patient.weight ?? 0;

    // Agregar peso inicial del paciente
    weightSpots.add(FlSpot(0, currentWeight));

    // Agregar pesos del historial (si los hay)
    for (int i = 0; i < histories.length; i++) {
      // Como no veo peso en MedicalHistory, usaremos el peso base del paciente
      // En una implementación real, deberías tener peso en cada consulta
      weightSpots.add(FlSpot(i + 1.0, currentWeight + (i * 0.5))); // Simulado
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: _diseaseColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Evolución del Peso',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 5,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value == 0) return const Text('Inicial');
                        return Text('C${value.toInt()}');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 50,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text('${value.toInt()}kg');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                minX: 0,
                maxX: weightSpots.length - 1.0,
                minY: weightSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) - 5,
                maxY: weightSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: weightSpots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        _diseaseColor,
                        _diseaseColor.withOpacity(0.7),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: _diseaseColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _diseaseColor.withOpacity(0.1),
                          _diseaseColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _buildVitalSignsCards() {
    final latestHistory = _patientWithHistory!.medicalHistories.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Signos Vitales Actuales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildVitalCard(
                'Glucosa',
                '${latestHistory.bloodGlucose?.toStringAsFixed(0) ?? '--'}',
                'mg/dL',
                Icons.water_drop,
                _getGlucoseStatus(latestHistory.bloodGlucose),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVitalCard(
                'Presión',
                latestHistory.bloodPressure ?? '--/--',
                'mmHg',
                Icons.favorite,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildVitalCard(
                'Cintura',
                '${latestHistory.waistCircumference?.toStringAsFixed(0) ?? '--'}',
                'cm',
                Icons.straighten,
                _diseaseColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVitalCard(
                'Grasa Corp.',
                '${latestHistory.bodyFatPercentage?.toStringAsFixed(1) ?? '--'}',
                '%',
                Icons.fitness_center,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: color,
                  size: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildHealthMetricsChart() {
    final histories = _patientWithHistory!.medicalHistories;
    if (histories.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: _diseaseColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Métricas de Salud',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        switch (value.toInt()) {
                          case 0: return const Text('Sueño', style: TextStyle(fontSize: 12));
                          case 1: return const Text('Estrés', style: TextStyle(fontSize: 12));
                          case 2: return const Text('Agua', style: TextStyle(fontSize: 12));
                          default: return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 2,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text('${value.toInt()}');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _getBarGroups(histories.first),
                gridData: FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(MedicalHistory latestHistory) {
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: latestHistory.sleepQuality?.toDouble() ?? 0,
            color: Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: latestHistory.stressLevel?.toDouble() ?? 0,
            color: Colors.orange,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: (latestHistory.waterConsumption ?? 0) * 3, // Escalar para visualizar mejor
            color: Colors.cyan,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildRecentAchievements() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Logros Recientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAchievementItem(
            'Consulta Completada',
            'Has registrado ${_patientWithHistory!.medicalHistories.length} consultas',
            Icons.check_circle,
            Colors.green,
          ),
          _buildAchievementItem(
            'Seguimiento Activo',
            'Mantienes un control regular de tu salud',
            Icons.trending_up,
            _diseaseColor,
          ),
          _buildAchievementItem(
            'Datos Completos',
            'Información médica actualizada',
            Icons.data_usage,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getGlucoseStatus(double? glucose) {
    if (glucose == null) return Colors.grey;
    if (glucose < 70) return Colors.red;
    if (glucose > 140) return Colors.orange;
    return Colors.green;
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
                fontWeight: FontWeight.bold,
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
                color: Colors.grey[600],
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

  Widget _buildHistoryCard(MedicalHistory history, {bool isRecent = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Consulta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isRecent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(0xFF24CD4A),
                          borderRadius: BorderRadius.circular(12),

                        ),
                        child: Text(
                          'Reciente',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  history.consultationDate.toString().substring(0, 10),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
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
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
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

  void _onScroll() {
    final shouldShowName = _scrollController.offset > 200;

    if (shouldShowName != _showNameInAppBar) {
      setState(() {
        _showNameInAppBar = shouldShowName;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }
}
