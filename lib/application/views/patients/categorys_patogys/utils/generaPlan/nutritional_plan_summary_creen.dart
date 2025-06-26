import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mottinutnutriotinist/application/views/patients/categorys_patogys/utils/generaPlan/utils_genera/energy_eequirement_card.dart';
import 'package:mottinutnutriotinist/application/views/patients/categorys_patogys/utils/generaPlan/utils_genera/nutritional_calculator.dart';
import 'package:mottinutnutriotinist/application/views/patients/categorys_patogys/utils/generaPlan/utils_genera/patient_info_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../configuration/themes/app_colors.dart';
import '../../../../../requestSnacbar/snackBar_manager.dart';
import '../plan_gereado/plan_generation_creen.dart';
import '/../../../domain/patient/pruebaa.dart';

class NutritionalPlanSummaryScreen extends StatefulWidget {
  final Patient patient;
  final Map<String, dynamic> savedData;

  const NutritionalPlanSummaryScreen({
    super.key,
    required this.patient,
    required this.savedData,
  });

  @override
  State<NutritionalPlanSummaryScreen> createState() =>
      _NutritionalPlanSummaryScreenState();
}

class _NutritionalPlanSummaryScreenState
    extends State<NutritionalPlanSummaryScreen> with TickerProviderStateMixin {

  // Plan nutricional seleccionado
  String _selectedPlan = '';

  // Controladores de animación
  late AnimationController _cardAnimationController;
  late Animation<double> _cardExpandAnimation;
  late Animation<double> _cardFadeAnimation;

  // Estados para generar plan
  bool _isGeneratingPlan = false;

  bool _isLoading = false;

  late PageController _pageController;
  int _currentPage = 0;

  bool _isDataExpanded = false;

  late NutritionalCalculator _nutritionalCalculator;

  bool _isPlanSectionExpanded = false;
  late AnimationController _planSectionController;
  late Animation<double> _planSectionAnimation;
  late Animation<double> _planSectionFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePlanSectionAnimations();
    _loadSelectedPlan();

    // Inicializar calculadora nutricional
    _nutritionalCalculator = NutritionalCalculator(
      patient: widget.patient,
      savedData: widget.savedData,
    );

    _nutritionalCalculator.debugEnergyCalculation();

    // Usar la calculadora para verificar datos válidos
    bool hasValidEnergyData = _nutritionalCalculator.hasValidEnergyData();
    _currentPage = hasValidEnergyData ? 0 : 1;
    _pageController = PageController(initialPage: _currentPage);

  }

  void _initializeAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _cardExpandAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    );

    _cardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadSelectedPlan() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedPlan = prefs.getString('selected_plan_${widget.patient.id}');
      if (savedPlan != null) {
        setState(() {
          _selectedPlan = savedPlan;
        });
      }
    } catch (e) {
      print('Error al cargar plan seleccionado: $e');
    }
  }

  void _initializePlanSectionAnimations() {
    _planSectionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _planSectionAnimation = CurvedAnimation(
      parent: _planSectionController,
      curve: Curves.easeInOutCubic,
    );

    _planSectionFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _planSectionController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _planSectionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Método para alternar expansión
  void _togglePlanSectionExpansion() {
    setState(() {
      _isPlanSectionExpanded = !_isPlanSectionExpanded;
    });

    if (_isPlanSectionExpanded) {
      _planSectionController.forward();
    } else {
      _planSectionController.reverse();
    }

    // Feedback háptico
    HapticFeedback.selectionClick();
  }

  // En el Widget build, envuelve el Scaffold con Stack:
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Contenido principal
          Column(
            children: [
              // Header que incluye la barra de estado
              _buildPatientHeader(),
              // Resto del contenido
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      ProfessionalPatientInfoCard(
                        savedData: widget.savedData,
                        patient: widget.patient,
                      ),

                     SizedBox(height: 10,),
                      _buildNutritionalPlanSection(),

                      const SizedBox(height: 100), // Espacio para el botón fijo
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Botón fijo en la parte inferior
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _buildFixedGenerateButton(),
          ),
        ],
      ),
    );
  }

  //header
  Widget _buildPatientHeader() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Container(
        // CAMBIO: Altura fija de 300 más el padding del status bar
        height: 250 + MediaQuery.of(context).padding.top,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.9),
              AppColors.primary.withOpacity(0.7)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(35),
            bottomRight: Radius.circular(35),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            15,
            MediaQuery.of(context).padding.top + 8,
            15,
            10,
          ),
          child: Column(
            children: [
              _buildHeaderRow(),
              const SizedBox(height: 12),
              Expanded(
                child: _buildNutritionalTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildBackButton(),
        const SizedBox(width: 12),
        _buildPatientAvatar(),
        const SizedBox(width: 12),
        Expanded(child: _buildPatientInfo()),
        const SizedBox(width: 12),
        _buildNotificationButton(),
      ],
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 18,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildPatientAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        child: widget.patient.profileImageUrl != null
            ? ClipOval(
                child: Image.network(
                  widget.patient.profileImageUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.person, size: 22, color: AppColors.primary),
                ),
              )
            : Icon(Icons.person, size: 22, color: AppColors.primary),
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.patient.fullName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Row(
          children: [
            if (widget.patient.dni != null &&
                widget.patient.dni!.isNotEmpty) ...[
              Text(
                'DNI: ${widget.patient.dni}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '• ${widget.patient.gender.displayName}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: () {},
        icon: const Icon(
          Icons.notifications_outlined,
          color: Colors.white,
          size: 26,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildNutritionalTable() {

    int age = _nutritionalCalculator.age;
    double weight = _nutritionalCalculator.weight;
    double height = _nutritionalCalculator.height;
    double energyRequirement = _nutritionalCalculator.calculateEnergyRequirement();
    String bmiText = widget.patient.bmi > 0 ? widget.patient.bmi.toStringAsFixed(1) : 'N/A';
    String perimeterText = widget.patient.abdominalPerimeter?.toStringAsFixed(0) ?? 'N/A';
    String dxNutricional = _nutritionalCalculator.getDiagnosticoNutricional();
    bool hasValidEnergyData = _nutritionalCalculator.hasValidEnergyData();

    return Column(
      children: [
        // QUITA StatefulBuilder y usa setState directamente
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              EnergyRequirementCard(
                energyRequirement: energyRequirement,
                hasValidData: hasValidEnergyData,
                calculateTMB: () => _nutritionalCalculator.calculateTMB(),
                getActivityFactor: () => _nutritionalCalculator.getActivityFactor(),
                getStressFactor: () => _nutritionalCalculator.getStressFactor(),
                gender: widget.patient.gender.displayName,
                age: age,
                weight: weight,
                height: height,
                patientName: widget.patient.fullName,
                isLoading: _isLoading,
              ),
              _buildBasicDataCard(
                  age, weight, height, bmiText, perimeterText, dxNutricional),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Indicadores
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPageIndicator(_currentPage == 0, true),
            const SizedBox(width: 6),
            _buildPageIndicator(_currentPage == 1, false),
          ],
        ),
      ],
    );
  }

  Widget _buildPageIndicator(bool isActive, bool isFirst) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withOpacity(0.9)
            : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildBasicDataCard(int age, double weight, double height,
      String bmiText, String perimeterText, String dxNutricional) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Expanded(
        child: Column(
          children: [
            // Primera fila
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: _buildCompactDataCard(
                          'IMC',
                          bmiText,
                          'assets/plan/imc.png',
                          weight <= 0 || height <= 0,
                          'Peso y altura requeridos')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildCompactDataCard(
                          'Edad',
                          '$age años',
                          'assets/plan/edad.png',
                          age <= 0,
                          'Edad requerida para cálculo')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildCompactDataCard(
                          'Peso',
                          '${weight > 0 ? weight.toStringAsFixed(1) : "N/A"} kg',
                          'assets/plan/bal.png',
                          weight <= 0,
                          'Peso requerido para cálculo')),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Segunda fila
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: _buildCompactDataCard(
                          'Altura',
                          '${height > 0 ? height.toStringAsFixed(2) : "N/A"} m',
                          'assets/plan/alt.png',
                          height <= 0,
                          'Altura requerida para cálculo')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildCompactDataCard('Dx Nut.', dxNutricional,
                          'assets/plan/dx.png', false, '')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildCompactDataCard(
                          'Per. Abd.',
                          '$perimeterText cm',
                          'assets/plan/per.png',
                          false,
                          '')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Cards individuales con indicadores de error y tooltip
  Widget _buildCompactDataCard(String label, String value, String imagePath,
      bool hasError, String errorMessage) {
    return Tooltip(
      message: hasError ? errorMessage : '',
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                top: BorderSide(
                  color: hasError ? AppColors.errorText : AppColors.primary,
                  width: 3,
                ),
              ),
              boxShadow: hasError
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        child: Image.asset(
                          imagePath,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              _getIconForLabel(label),
                              color: hasError
                                  ? AppColors.errorText.withOpacity(0.8)
                                  : AppColors.primary.withOpacity(0.8),
                              size: 20,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: hasError
                                ? AppColors.errorText.withOpacity(0.9)
                                : AppColors.textCuatary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hasError
                          ? AppColors.errorIcon.withOpacity(0.9)
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Indicador de error en la esquina superior derecha
          if (hasError)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.errorText,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
// Función auxiliar para iconos de fallback
  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'IMC':
        return Icons.monitor_weight_outlined;
      case 'Edad':
        return Icons.cake_outlined;
      case 'Peso':
        return Icons.scale_outlined;
      case 'Altura':
        return Icons.height_outlined;
      case 'Dx Nut.':
        return Icons.local_hospital_outlined;
      case 'Per. Abd':
        return Icons.straighten_outlined;
      default:
        return Icons.info_outline;
    }
  }

  //boton de gerrar plan
  Widget _buildFixedGenerateButton() {
    // Verificar todas las condiciones necesarias
    final hasValidEnergyData = _nutritionalCalculator.hasValidEnergyData();
    /*final hasPatientInfo = widget.patient.fullName.isNotEmpty &&
        widget.patient.age > 0;*/
    final hasPlanSelected = _selectedPlan.isNotEmpty;

    // El botón se habilita solo si todas las condiciones se cumplen
    //final canGenerate = hasValidEnergyData && hasPatientInfo && hasPlanSelected;
    final canGenerate = hasValidEnergyData && hasPlanSelected;

    // Texto dinámico según qué falta
    String buttonText;
    if (!hasValidEnergyData) {
      buttonText = 'Faltan Datos ..';
    /*} else if (!hasPatientInfo) {
      buttonText = 'Faltan Datos del Paciente';*/
    } else if (!hasPlanSelected) {
      buttonText = 'Selecciona un Plan Nutricional';
    } else {
      buttonText = 'Generar Plan Nutricional';
    }

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom,
      left: 10,
      right: 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(16),
          height: 52,
          child: ElevatedButton(
            onPressed: canGenerate && !_isGeneratingPlan
                ? _generateNutritionalPlan
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canGenerate ? AppColors.secondary : Colors.grey[300],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              elevation: canGenerate ? 12 : 0,
              shadowColor: canGenerate ? AppColors.secondary.withOpacity(0.3) : null,
            ),
            child: _isGeneratingPlan
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Generando Plan Nutri...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  canGenerate ? Icons.auto_awesome : Icons.info_outline,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionalPlanSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado expandible
          _buildPlanSectionHeader(),

          // Contenido expandible
          AnimatedBuilder(
            animation: _planSectionAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _planSectionAnimation.value,
                  child: FadeTransition(
                    opacity: _planSectionFadeAnimation,
                    child: child,
                  ),
                ),
              );
            },
            child: _buildExpandablePlanContent(),
          ),

          // Mostrar selección actual si hay una y la sección está colapsada
          if (!_isPlanSectionExpanded && _selectedPlan.isNotEmpty)
            _buildSelectedPlanPreview(),
        ],
      ),
    );
  }

  Widget _buildPlanSectionHeader() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _togglePlanSectionExpansion,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.03),
                AppColors.primary.withOpacity(0.01),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade400,
              width: 0.4,
            ),
          ),
          child: Row(
            children: [
              // Icono mejorado
              Container(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/plan/pla.png',
                  width: 60,
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.restaurant_menu_outlined,
                      color: AppColors.primary,
                      size: 32,
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selección de Plan Nutricional',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary1,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Texto dinámico con color del plan seleccionado
                    _buildPlanStatusText(),
                  ],
                ),
              ),

              // Indicador de expansión
              AnimatedRotation(
                turns: _isPlanSectionExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundHipertencion,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.iconSecondary,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Método para construir el texto del estado del plan con color dinámico
  Widget _buildPlanStatusText() {
    if (_isPlanSectionExpanded) {
      return Text(
        'Selecciona el plan más adecuado para tu paciente',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textInput,
          fontWeight: FontWeight.w400,
          height: 1,
        ),
      );
    }

    if (_selectedPlan.isEmpty) {
      return Text(
        'Toca para ver las opciones disponibles',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textInput,
          fontWeight: FontWeight.w400,
          height: 1,
        ),
      );
    }

    // Obtener información del plan seleccionado
    final planInfo = _getPlanInfo(_selectedPlan);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Plan seleccionado: ',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textInput,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          TextSpan(
            text: _getPlanDisplayName(_selectedPlan),
            style: TextStyle(
              fontSize: 12,
              color: planInfo['color'],
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPlanInfo(String planValue) {
    switch (planValue) {
      case 'desayuno':
        return {
          'title': 'Desayuno Energético',
          'subtitle': 'Ideal para comenzar el día con energía',
          'image': 'assets/plan/des.png',
          'color': const Color(0xFFEA580C),
        };
      case 'almuerzo':
        return {
          'title': 'Almuerzo Funcional',
          'subtitle': 'Nutrición óptima para tu jornada activa',
          'image': 'assets/plan/alm.png',
          'color': const Color(0xFF059669),
        };
      case 'cena':
        return {
          'title': 'Cena Ligera',
          'subtitle': 'Favorece el descanso y metabolismo nocturno',
          'image': 'assets/plan/cen.png',
          'color': const Color(0xFF7C3AED), // Azul cielo vibrante
        };
      case 'completo':
        return {
          'title': 'Plan Diario Completo',
          'subtitle': 'Tres comidas principales balanceadas',
          'image': 'assets/plan/tr.png',
          'color': const Color(0xFF0284C7),
        };
      case 'premium':
        return {
          'title': 'Plan Premium Integral',
          'subtitle': 'Programa completo con 5 comidas',
          'image': 'assets/plan/pr.png',
          'color': const Color(0xFF9333EA),
        };
      default:
        return {
          'title': 'Plan Personalizado',
          'subtitle': 'Plan adaptado a necesidades específicas',
          'image': 'assets/plan/alm.png',
          'color': AppColors.primary,
        };
    }
  }

// Contenido expandible con las opciones de planes
  Widget _buildExpandablePlanContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Animación en cascada para cada plan
          _buildAnimatedPlanCard(
            'Desayuno Energético',
            'desayuno',
            'assets/plan/des.png',
            'Incluye proteínas de alta calidad, carbohidratos complejos y grasas saludables.',
            const Color(0xFFEA580C),
            delay: 0,
          ),

          const SizedBox(height: 16),

          _buildAnimatedPlanCard(
            'Almuerzo Funcional',
            'almuerzo',
            'assets/plan/alm.png',
            'Combinación perfecta de macronutrientes para el rendimiento sostenido.',
            const Color(0xFF059669),
            delay: 100,
          ),

          const SizedBox(height: 16),

          _buildAnimatedPlanCard(
            'Cena Ligera',
            'cena',
            'assets/plan/cen.png',
            'Opciones ligeras y nutritivas que promueven la recuperación y el descanso.',
            const Color(0xFF7C3AED),
            delay: 200,
          ),

          const SizedBox(height: 16),

          _buildAnimatedPlanCard(
            'Plan Diario Completo',
            'completo',
            'assets/plan/tr.png',
            'Desayuno, almuerzo y cena diseñados específicamente para tus necesidades.',
            const Color(0xFF0284C7),
            delay: 300,
          ),

          const SizedBox(height: 16),

          _buildAnimatedPlanCard(
            'Plan Premium Integral',
            'premium',
            'assets/plan/pr.png',
            'Incluye desayuno, colación matutina, almuerzo, merienda y cena con seguimiento detallado.',
            const Color(0xFF9333EA),
            delay: 400,
            isSpecialized: true,
          ),
        ],
      ),
    );
  }

// Card con animación en cascada
  Widget _buildAnimatedPlanCard(
      String title,
      String value,
      String imagePath,
      String description,
      Color accentColor,
      {required int delay, bool isSpecialized = false}
      ) {
    return AnimatedBuilder(
      animation: _planSectionAnimation,
      builder: (context, child) {
        // Calcular el progreso de animación con delay
        double animationProgress = _planSectionAnimation.value;
        double delayedProgress = ((animationProgress * 1000) - delay) / 100;
        delayedProgress = delayedProgress.clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, 20 * (1 - delayedProgress)),
          child: Opacity(
            opacity: delayedProgress,
            child: _buildProfessionalPlanCard(
              title,
              value,
              imagePath,
              description,
              accentColor,
              isSpecialized: isSpecialized,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfessionalPlanCard(
      String title,
      String value,
      String imagePath,
      String description,
      Color accentColor,
      {bool isSpecialized = false}
      ) {
    final isSelected = _selectedPlan == value;

    return Container(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _saveSelectedPlan(value),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? accentColor.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),

            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icono principal
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        imagePath,
                        width: 40,
                        height: 40,
                        color: isSelected ? null : Colors.grey[400],
                      ),

                    ),

                    const SizedBox(width: 16),

                    // Título y badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? accentColor : AppColors.textInput,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              if (isSpecialized) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF4EE1FF),
                                        const Color(0xFF32D8F5),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Indicador de selección
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? accentColor : Colors.grey.withOpacity(0.4),
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: isSelected
                          ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                          : null,
                    ),
                  ],
                ),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textInput,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Preview del plan seleccionado cuando está colapsado
  Widget _buildSelectedPlanPreview() {
    if (_selectedPlan.isEmpty) return const SizedBox.shrink();

    final planInfo = _getPlanInfo(_selectedPlan);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 5, 20, 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: planInfo['color'].withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: planInfo['color'].withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            planInfo['image'],
            width: 40,
            height: 40,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planInfo['title'],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: planInfo['color'],
                    letterSpacing: 0.5
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  planInfo['subtitle'],
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textInput,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            Icons.check_circle,
            color: planInfo['color'],
            size: 24,
          ),
        ],
      ),
    );
  }

// Métodos auxiliares
  String _getPlanDisplayName(String planValue) {
    switch (planValue) {
      case 'desayuno':
        return 'Desayuno Energético';
      case 'almuerzo':
        return 'Almuerzo Funcional';
      case 'cena':
        return 'Cena Ligera';
      case 'completo':
        return 'Plan Diario Completo';
      case 'premium':
        return 'Plan Premium Integral';
      default:
        return 'Plan Personalizado';
    }
  }

  Future<void> _saveSelectedPlan(String planType) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_plan_${widget.patient.id}', planType);

      setState(() {
        _selectedPlan = planType;
      });

      // Opcional: mostrar feedback visual
      HapticFeedback.lightImpact();

    } catch (e) {
      print('Error al guardar plan seleccionado: $e');
      SnackBarManager.showError(context, 'Error al seleccionar el plan');
    }
  }

  // SOLUCIÓN 1: Función helper para limpiar datos recursivamente
  Map<String, dynamic> _sanitizeDataForJson(Map<String, dynamic> data) {
    Map<String, dynamic> sanitized = {};

    data.forEach((key, value) {
      if (value is DateTime) {
        sanitized[key] = value.toIso8601String();
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeDataForJson(value);
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is DateTime) {
            return item.toIso8601String();
          } else if (item is Map<String, dynamic>) {
            return _sanitizeDataForJson(item);
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  Future<void> _generateNutritionalPlan() async {
    if (_selectedPlan.isEmpty) {
      SnackBarManager.showError(
          context, 'Por favor selecciona un tipo de plan');
      return;
    }

    // Verificar todas las condiciones antes de proceder
    final hasValidEnergyData = _nutritionalCalculator.hasValidEnergyData();

    if (!hasValidEnergyData) {
      SnackBarManager.showError(
          context, 'Faltan datos necesarios para generar el plan');
      return;
    }

    setState(() {
      _isGeneratingPlan = true;
    });

    try {
      // Preparar datos para enviar al backend - ASEGURAR SERIALIZACIÓN
      Map<String, dynamic> planData = {
        'patientId': widget.patient.id,
        'patientName': widget.patient.fullName,
        'planType': _selectedPlan,
        'patientData': _sanitizeDataForJson(widget.savedData), // Limpiar datos
        'energyRequirement': _nutritionalCalculator.calculateEnergyRequirement(),
        'nutritionalData': {
          'age': _nutritionalCalculator.age,
          'weight': _nutritionalCalculator.weight,
          'height': _nutritionalCalculator.height,
          'bmi': widget.patient.bmi,
          'gender': widget.patient.gender.displayName,
          'activityLevel': widget.savedData['activityLevel'] ?? 'moderate',
          'stressLevel': widget.savedData['stressLevel'] ?? 'normal',
        },
        'timestamp': DateTime.now().toIso8601String(), // Ya está bien
      };

      // Limpiar todos los datos antes de serializar
      planData = _sanitizeDataForJson(planData);

      // Guardar datos del plan en SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'nutritional_plan_${widget.patient.id}', jsonEncode(planData));

      setState(() {
        _isGeneratingPlan = false;
      });

      // Navegar a la pantalla de generación con Lottie
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlanGenerationScreen(
            planData: planData,
            patient: widget.patient,
            selectedPlan: _selectedPlan,
          ),
        ),
      );

    } catch (e) {
      setState(() {
        _isGeneratingPlan = false;
      });

      SnackBarManager.showError(
          context, 'Error al generar el plan nutricional: ${e.toString()}');
      print('Error al generar plan nutricional: $e');

      // Debug: Imprimir qué datos están causando el problema
      print('Datos que causan el error:');
      print('Patient data keys: ${widget.savedData.keys}');
      widget.savedData.forEach((key, value) {
        print('$key: ${value.runtimeType} = $value');
      });
    }
  }

}
