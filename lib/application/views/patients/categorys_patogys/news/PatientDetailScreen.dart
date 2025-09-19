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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(_onScroll);

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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.secondary.withOpacity(0.6),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: _buildFixedAppBar(),
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
            // 🔥 TabBar fijo arriba
            Material(
              color: Colors.white,
              elevation: 2,
              child: _buildTabBar(),
            ),
            // 👇 El contenido ocupa el resto de la pantalla
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

  PreferredSizeWidget _buildFixedAppBar() {
    final statusColor = PatientValidationHelper.getStatusColor(widget.patient);
    final statusText = PatientValidationHelper.getStatusText(widget.patient);
    final diabetesType =
        PatientValidationHelper.getDiabetesType(widget.patient.chronicDisease);

    return AppBar(
      backgroundColor: AppColors.secondary,
      elevation: 4,
      toolbarHeight: 165,
      // Altura final aumentada
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondary,
              AppColors.secondary.withOpacity(0.8),
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
                    PatientAvatarWidget(
                      patient: widget.patient,
                      statusColor: statusColor,
                      token: _authToken ?? '',
                      size: 55,
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
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Color(0xFFFF8A50)],
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
                            color: Colors.orange.withOpacity(0.3),
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
                                    color: Colors.orange[600],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      'Consulta',
                                      style: TextStyle(
                                        color: Colors.orange,
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
      labelColor: AppColors.secondary,
      unselectedLabelColor: Colors.grey[400],
      labelStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      indicatorColor: AppColors.secondary,
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 6),
          Text(
            'Aún no hay gráficos disponibles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cuando tengas datos, verás tu progreso aquí',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
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
