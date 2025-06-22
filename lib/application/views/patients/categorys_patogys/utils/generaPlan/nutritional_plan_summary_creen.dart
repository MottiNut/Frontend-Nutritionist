import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../configuration/themes/app_colors.dart';
import '../../../../../requestSnacbar/snackBar_manager.dart';
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
  State<NutritionalPlanSummaryScreen> createState() => _NutritionalPlanSummaryScreenState();
}

class _NutritionalPlanSummaryScreenState extends State<NutritionalPlanSummaryScreen>
    with TickerProviderStateMixin {

  // Estados para controlar la expansión de las cards
  bool _isPersonalInfoExpanded = false;
  bool _isFiliationExpanded = false;
  bool _isAntecedentsExpanded = false;
  bool _isComorbiditiesExpanded = false;
  bool _isNutritionalDataExpanded = false;
  bool _isRiskFactorsExpanded = false;
  bool _isCFCAExpanded = false;

  // Plan nutricional seleccionado
  String _selectedPlan = '';

  // Controladores de animación
  late AnimationController _cardAnimationController;
  late Animation<double> _cardExpandAnimation;
  late Animation<double> _cardFadeAnimation;

  // Estados para generar plan
  bool _isGeneratingPlan = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSelectedPlan();

    _debugEnergyCalculation();
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
  
  @override
  void dispose() {
    _cardAnimationController.dispose();
    super.dispose();
  }

  // En el Widget build, envuelve el Scaffold con Stack:
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                      _buildNutritionalTable(),
                      const SizedBox(height: 20),
                      _buildSavedDataSection(),
                      const SizedBox(height: 30),
                      _buildCFCASection(),
                      const SizedBox(height: 30),
                      const SizedBox(height: 100), // Espacio para el botón fijo
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Botón fijo en la parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFixedGenerateButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientHeader() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Íconos claros
        statusBarBrightness: Brightness.dark, // Para iOS
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        height: 220 + MediaQuery.of(context).padding.top, // Altura + padding top de la barra de estado
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
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
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
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20, // Padding top + espacio adicional
            left: 20,
            right: 20,
            bottom: 20,
          ),
          child: Column(
            children: [
              // Información del paciente
              Row(
                children: [
                  // Botón de retroceso
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Avatar del paciente
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: widget.patient.profileImageUrl != null
                          ? ClipOval(
                        child: Image.network(
                          widget.patient.profileImageUrl!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.person, size: 35, color: AppColors.primary),
                        ),
                      )
                          : Icon(Icons.person, size: 35, color: AppColors.primary),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Información del paciente
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patient.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'DNI: ${widget.patient.dni ?? "N/A"}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.patient.age} años • ${widget.patient.gender.displayName}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botón de mensaje/IA
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Acción para generar plan con IA
                        _generateAIPlan();
                      },
                      icon: const Icon(
                        Icons.auto_awesome, // Ícono de IA/estrella mágica
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip: 'Generar Plan con IA',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Indicador de plan nutricional con IA
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Plan Nutricional IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedGenerateButton() {
    final canGenerate = _selectedPlan.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          height: 56,
          child: ElevatedButton(
            onPressed: canGenerate && !_isGeneratingPlan ? _generateNutritionalPlan : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canGenerate ? AppColors.primary : Colors.grey[300],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: canGenerate ? 8 : 0,
              shadowColor: AppColors.primary.withOpacity(0.3),
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
                  'Generando Plan Nutricional...',
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
                  Icons.auto_awesome,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  canGenerate ? 'Generar Plan Nutricional' : 'Selecciona un Plan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Método para generar plan con IA
  void _generateAIPlan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Generar Plan con IA'),
          ],
        ),
        content: Text(
            '¿Deseas generar un plan nutricional personalizado usando inteligencia artificial para ${widget.patient.fullName}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí iría la lógica para generar el plan con IA
              _startAIPlanGeneration();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Generar Plan'),
          ),
        ],
      ),
    );
  }

  void _startAIPlanGeneration() {
    // Mostrar loading o navegar a la pantalla de generación de plan IA
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
            const SizedBox(width: 16),
            Text('Generando plan nutricional con IA...'),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSavedDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Guardada',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textLDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildExpandableCard(
          'Información Personal',
          _isPersonalInfoExpanded,
              () => setState(() => _isPersonalInfoExpanded = !_isPersonalInfoExpanded),
          _buildPersonalInfoContent(),
          Icons.person,
        ),
        _buildExpandableCard(
          'Filiación',
          _isFiliationExpanded,
              () => setState(() => _isFiliationExpanded = !_isFiliationExpanded),
          _buildFiliationContent(),
          Icons.family_restroom,
        ),
        _buildExpandableCard(
          'Antecedentes',
          _isAntecedentsExpanded,
              () => setState(() => _isAntecedentsExpanded = !_isAntecedentsExpanded),
          _buildAntecedentsContent(),
          Icons.history,
        ),
        _buildExpandableCard(
          'Comorbilidades',
          _isComorbiditiesExpanded,
              () => setState(() => _isComorbiditiesExpanded = !_isComorbiditiesExpanded),
          _buildComorbiditiesContent(),
          Icons.local_hospital,
        ),
        _buildExpandableCard(
          'Datos Nutricionales',
          _isNutritionalDataExpanded,
              () => setState(() => _isNutritionalDataExpanded = !_isNutritionalDataExpanded),
          _buildNutritionalDataContent(),
          Icons.restaurant,
        ),
        _buildExpandableCard(
          'Factores de Riesgo',
          _isRiskFactorsExpanded,
              () => setState(() => _isRiskFactorsExpanded = !_isRiskFactorsExpanded),
          _buildRiskFactorsContent(),
          Icons.warning,
        ),
      ],
    );
  }

  Widget _buildExpandableCard(
      String title,
      bool isExpanded,
      VoidCallback onTap,
      Widget content,
      IconData icon,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.05),
                        AppColors.primary.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLDark,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: isExpanded ? null : 0,
              child: isExpanded
                  ? Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                ),
                child: content,
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoContent() {
    return Column(
      children: [
        _buildInfoRow('Edad', '${widget.savedData['age'] ?? widget.patient.age} años'),
        _buildInfoRow('Peso', '${widget.savedData['weight'] ?? widget.patient.weight ?? "N/A"} kg'),
        _buildInfoRow('Talla', '${widget.savedData['height'] ?? widget.patient.height ?? "N/A"} m'),
        _buildInfoRow('IMC', widget.patient.bmi > 0 ? widget.patient.bmi.toStringAsFixed(1) : 'N/A'),
        _buildInfoRow('Estado Civil', widget.patient.maritalStatus ?? 'N/A'),
        _buildInfoRow('Dirección', widget.patient.address ?? 'N/A'),
      ],
    );
  }

  Widget _buildFiliationContent() {
    return Column(
      children: [
        _buildInfoRow('Núcleo Familiar', widget.savedData['nucleoFamiliar'] ?? 'N/A'),
        _buildInfoRow('Ocupación Actual', widget.savedData['ocupacionActual'] ?? 'N/A'),
        _buildInfoRow('Grado de Instrucción', widget.savedData['gradoInstruccion'] ?? 'N/A'),
        _buildInfoRow('Religión', widget.savedData['religion'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildAntecedentsContent() {
    return Column(
      children: [
        _buildInfoRow('Diagnóstico Médico Anterior', widget.savedData['diagnosticoMedicoAnterior'] ?? 'N/A'),
        _buildInfoRow('Tiempo de Enfermedad', widget.savedData['tiempoEnfermedad'] ?? 'N/A'),
        _buildInfoRow('Diagnóstico Médico Reciente', widget.savedData['diagnosticoMedicoReciente'] ?? 'N/A'),
        _buildInfoRow('Antecedentes Familiares', widget.savedData['antecedentesFamiliares'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildComorbiditiesContent() {
    return Column(
      children: [
        _buildInfoRow('Comorbilidades', widget.savedData['comorbilidades'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildNutritionalDataContent() {
    return Column(
      children: [
        _buildInfoRow('Veces que come al día', widget.savedData['vecesComidaDia'] ?? 'N/A'),
        _buildInfoRow('Preferencias', widget.savedData['preferencias'] ?? 'N/A'),
        _buildInfoRow('No le agrada', widget.savedData['noLeAgrada'] ?? 'N/A'),
        _buildInfoRow('Intolerancias', widget.savedData['intolerancias'] ?? 'N/A'),
        _buildInfoRow('Lugar de ingesta', widget.savedData['lugarDeIngesta'] ?? 'N/A'),
        _buildInfoRow('Hábitos nocivos', widget.savedData['habitosNocivos'] ?? 'N/A'),
        _buildInfoRow('Tipo de actividad', widget.savedData['tipoActividad'] ?? 'N/A'),
        _buildInfoRow('Consumo de agua', widget.savedData['consumoAgua'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildRiskFactorsContent() {
    return Column(
      children: [
        _buildInfoRow('Mayor de 45 años', widget.savedData['mayor45Anios'] ?? 'N/A'),
        _buildInfoRow('Obesidad', widget.savedData['obesidad'] ?? 'N/A'),
        _buildInfoRow('Hipertensión', widget.savedData['hipertension'] ?? 'N/A'),
        _buildInfoRow('Sedentarismo', widget.savedData['sedentarismo'] ?? 'N/A'),
        _buildInfoRow('Hijos macrosómicos', widget.savedData['hijosMacrosomicos'] ?? 'N/A'),
        _buildInfoRow('Diabetes gestacional', widget.savedData['diabetesGestacional'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildCFCASection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.assessment, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                'Requerimiento energético',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Requerimiento energético
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requerimiento Energético',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Requerimiento diario de energía = TMB x AF x FE',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),

          _buildDetailedEnergyCalculation(),
        ],
      ),
    );
  }

  Widget _buildNutritionalTable() {
    // Obtener datos con mejor manejo de fallbacks
    final age = int.tryParse(widget.savedData['age']?.toString() ?? '') ??
        widget.patient.age ?? 0;

    final weight = double.tryParse(widget.savedData['weight']?.toString() ?? '') ??
        widget.patient.weight ?? 0.0;

    final height = double.tryParse(widget.savedData['height']?.toString() ?? '') ??
        widget.patient.height ?? 0.0;

    // Debug para ver qué datos estamos recibiendo
    print('Datos para tabla nutricional:');
    print('Edad: $age (de savedData: ${widget.savedData['age']}, de patient: ${widget.patient.age})');
    print('Peso: $weight (de savedData: ${widget.savedData['weight']}, de patient: ${widget.patient.weight})');
    print('Altura: $height (de savedData: ${widget.savedData['height']}, de patient: ${widget.patient.height})');

    double energyRequirement = _calculateEnergyRequirement();
    String bmiText = widget.patient.bmi > 0 ? widget.patient.bmi.toStringAsFixed(1) : 'N/A';
    String perimeterText = widget.patient.abdominalPerimeter?.toStringAsFixed(0) ?? 'N/A';
    String dxNutricional = _getDiagnosticoNutricional();

    // Validar si tenemos datos mínimos
    bool hasValidData = age > 0 && weight > 0 && height > 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Mostrar advertencia si no hay datos válidos
          if (!hasValidData)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Datos incompletos: Edad($age), Peso($weight), Altura($height)',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Primera fila - Datos básicos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(hasValidData ? 12 : 0),
                topRight: Radius.circular(hasValidData ? 12 : 0),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: _buildTableCell('IMC', bmiText, Icons.monitor_weight)),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Expanded(child: _buildTableCell('Per. Abd.', '$perimeterText cm', Icons.straighten)),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Expanded(child: _buildTableCell('Dx Nutr.', dxNutricional, Icons.local_hospital)),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: Colors.grey[200]),

          // Segunda fila - Peso y Talla
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildTableCell('Peso', '${weight > 0 ? weight.toStringAsFixed(1) : "N/A"} kg', Icons.scale)),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Expanded(child: _buildTableCell('Talla', '${height > 0 ? height.toStringAsFixed(2) : "N/A"} m', Icons.height)),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Expanded(child: _buildTableCell('Edad', '$age años', Icons.cake)),
              ],
            ),
          ),

          // Divider especial
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.3), AppColors.primary.withOpacity(0.1)],
              ),
            ),
          ),

          // Requerimiento energético - Destacado
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasValidData ? Colors.green[50] : Colors.red[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasValidData ? Icons.bolt : Icons.error_outline,
                      color: hasValidData ? Colors.orange[600] : Colors.red[600],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Requerimiento Energético Diario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasValidData ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: hasValidData ? Colors.green[300]! : Colors.red[300]!,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (hasValidData ? Colors.green : Colors.red).withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    hasValidData
                        ? '${energyRequirement > 0 ? energyRequirement.toStringAsFixed(0) : "0"} kcal'
                        : 'Sin datos suficientes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: hasValidData ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasValidData
                      ? 'TMB × Factor de Actividad × Factor de Estrés'
                      : 'Necesitas completar: edad, peso y altura',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasValidData ? Colors.green[600] : Colors.red[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textLDark,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getDiagnosticoNutricional() {
    double bmi = widget.patient.bmi;
    if (bmi <= 0) return 'N/A';

    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

// Método para calcular TMB
  double _calculateTMB() {
    final age = int.tryParse(widget.savedData['age']?.toString() ?? '') ?? widget.patient.age;
    final weight = double.tryParse(widget.savedData['weight']?.toString() ?? '') ?? widget.patient.weight ?? 0;
    final height = double.tryParse(widget.savedData['height']?.toString() ?? '') ?? widget.patient.height ?? 0;

    // Convertir altura a cm si está en metros
    double heightInCm = height;
    if (height > 0 && height < 3) {
      heightInCm = height * 100;
    }

    double tmb = 0;
    if (weight > 0 && heightInCm > 0 && age > 0) {
      if (widget.patient.gender.displayName.toLowerCase() == 'masculino') {
        // Fórmula Harris-Benedict para hombres
        tmb = 66.4730 + (13.7516 * weight) + (5.0033 * heightInCm) - (6.7550 * age);
      } else {
        // Fórmula Harris-Benedict para mujeres
        tmb = 655.0955 + (9.5634 * weight) + (1.8449 * heightInCm) - (4.6756 * age);
      }
    }
    return tmb;
  }

// Método para calcular el requerimiento energético completo
  double _calculateEnergyRequirement() {
    double tmb = _calculateTMB();
    double activityFactor = _getActivityFactor();
    double stressFactor = _getStressFactor();

    return tmb * activityFactor * stressFactor;
  }

// Método para obtener el factor de actividad física
  double _getActivityFactor() {
    String tipoActividad = widget.savedData['tipoActividad']?.toString().toLowerCase() ?? '';

    // Factores según nivel de actividad física
    // Sedentario/Muy ligero: 1.2-1.3
    if (tipoActividad.contains('sedentaria') ||
        tipoActividad.contains('menos de 30 min/semana') ||
        tipoActividad.contains('muy ligera') ||
        tipoActividad.contains('caminar ocasionalmente')) {
      return 1.2;
    }

    // Ligero: 1.375
    else if (tipoActividad.contains('ligera (caminar 30 min') ||
        tipoActividad.contains('ligera a moderada') ||
        tipoActividad.contains('tareas domésticas activas') ||
        tipoActividad.contains('trabajo físico ligero') ||
        tipoActividad.contains('oficina de pie') ||
        tipoActividad.contains('actividades de fin de semana') ||
        tipoActividad.contains('yoga/pilates regular')) {
      return 1.375;
    }

    // Moderado: 1.55
    else if (tipoActividad.contains('moderada (30-45 min') ||
        tipoActividad.contains('moderada (gimnasio 3-4') ||
        tipoActividad.contains('trabajo físico moderado') ||
        tipoActividad.contains('caminatas frecuentes') ||
        tipoActividad.contains('natación regular') ||
        tipoActividad.contains('ciclismo recreativo') ||
        tipoActividad.contains('running/trote ocasional') ||
        tipoActividad.contains('baile/danza')) {
      return 1.55;
    }

    // Moderado Alto: 1.725
    else if (tipoActividad.contains('moderada alta') ||
        tipoActividad.contains('ejercicio 45-60 min') ||
        tipoActividad.contains('running/trote regular') ||
        tipoActividad.contains('deportes de equipo') ||
        tipoActividad.contains('artes marciales') ||
        tipoActividad.contains('montañismo/hiking') ||
        tipoActividad.contains('ciclismo intenso')) {
      return 1.725;
    }

    // Intenso: 1.9
    else if (tipoActividad.contains('intensa (ejercicio diario') ||
        tipoActividad.contains('muy intensa') ||
        tipoActividad.contains('entrenamiento deportivo') ||
        tipoActividad.contains('deportista amateur') ||
        tipoActividad.contains('trabajo físico pesado') ||
        tipoActividad.contains('construcción, carga')) {
      return 1.9;
    }

    // Muy Intenso: 2.2
    else if (tipoActividad.contains('deportista semi-profesional') ||
        tipoActividad.contains('deportista profesional') ||
        tipoActividad.contains('trabajo físico muy exigente')) {
      return 2.2;
    }

    // Valor por defecto si no coincide con ninguna opción
    else {
      return 1.375; // Actividad ligera como promedio
    }
  }

// Método mejorado para obtener el factor de estrés
  double _getStressFactor() {
    List<String> comorbilidades = [];

    // Obtener comorbilidades del savedData
    if (widget.savedData['comorbilidades'] != null) {
      String comorbString = widget.savedData['comorbilidades'].toString().toLowerCase();
      comorbilidades = comorbString.split(',').map((e) => e.trim()).toList();
    }

    String diagnostico = widget.savedData['diagnosticoMedicoReciente']?.toString().toLowerCase() ?? '';

    // Factor de estrés alto (1.4-1.5) - Condiciones severas
    bool tieneEstresAlto = comorbilidades.any((c) =>
    c.contains('enfermedad renal') ||
        c.contains('enfermedad hepática') ||
        c.contains('crónica')
    ) || diagnostico.contains('cáncer') ||
        diagnostico.contains('diabetes descompensada') ||
        diagnostico.contains('insuficiencia') ||
        diagnostico.contains('sepsis');

    if (tieneEstresAlto) {
      return 1.45;
    }

    // Factor de estrés moderado (1.2-1.3) - Condiciones moderadas
    bool tieneEstresModerado = comorbilidades.any((c) =>
    c.contains('dislipidemia') ||
        c.contains('artritis') ||
        c.contains('artrosis') ||
        c.contains('trastornos de tiroides') ||
        c.contains('apnea del sueño')
    ) || diagnostico.contains('diabetes') ||
        diagnostico.contains('hipertensión') ||
        diagnostico.contains('obesidad');

    if (tieneEstresModerado) {
      return 1.25;
    }

    // Factor de estrés leve (1.1) - Condiciones menores
    bool tieneEstresLeve = comorbilidades.any((c) =>
    c.contains('asma') ||
        c.contains('reflujo gastroesofágico') ||
        c.contains('ansiedad') ||
        c.contains('depresión') ||
        c.contains('pie plano') ||
        c.contains('escoliosis')
    );

    if (tieneEstresLeve) {
      return 1.1;
    }

    // Sin comorbilidades significativas
    if (comorbilidades.isEmpty ||
        comorbilidades.any((c) => c.contains('ninguna'))) {
      return 1.0;
    }

    // Por defecto, si hay alguna comorbilidad no identificada
    return 1.05;
  }


// Método de debugging para verificar los cálculos
  void _debugEnergyCalculation() {
    final age = int.tryParse(widget.savedData['age']?.toString() ?? '') ?? widget.patient.age;
    final weight = double.tryParse(widget.savedData['weight']?.toString() ?? '') ?? widget.patient.weight ?? 0;
    final height = double.tryParse(widget.savedData['height']?.toString() ?? '') ?? widget.patient.height ?? 0;

    double tmb = _calculateTMB();
    double activityFactor = _getActivityFactor();
    double stressFactor = _getStressFactor();
    double totalRequirement = tmb * activityFactor * stressFactor;

    print('=== DEBUG CÁLCULO ENERGÉTICO DETALLADO ===');
    print('📊 DATOS DEL PACIENTE:');
    print('   Edad: $age años');
    print('   Peso: $weight kg');
    print('   Altura: $height m');
    print('   Género: ${widget.patient.gender.displayName}');
    print('');
    print('🔥 CÁLCULOS:');
    print('   TMB: ${tmb.toStringAsFixed(2)} kcal');
    print('   Factor Actividad: $activityFactor');
    print('   Factor Estrés: $stressFactor');
    print('   Requerimiento Total: ${totalRequirement.toStringAsFixed(2)} kcal');
    print('');
    print('📝 DATOS GUARDADOS:');
    print('   Tipo Actividad: "${widget.savedData['tipoActividad']}"');
    print('   Comorbilidades: "${widget.savedData['comorbilidades']}"');
    print('   Diagnóstico Reciente: "${widget.savedData['diagnosticoMedicoReciente']}"');
    print('');
    print('✅ FÓRMULA: TMB × FA × FE');
    print('   ${tmb.toStringAsFixed(0)} × ${activityFactor} × ${stressFactor} = ${totalRequirement.toStringAsFixed(0)} kcal');
    print('==========================================');
  }


// Método mejorado para mostrar detalles del cálculo en la UI
  Widget _buildDetailedEnergyCalculation() {
    double tmb = _calculateTMB();
    double activityFactor = _getActivityFactor();
    double stressFactor = _getStressFactor();
    double totalRequirement = tmb * activityFactor * stressFactor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalles del Cálculo Energético',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildCalculationRow('TMB (Tasa Metabólica Basal)', '${tmb.toStringAsFixed(1)} kcal'),
          _buildCalculationRow('Factor de Actividad', 'x ${activityFactor.toStringAsFixed(2)}'),
          _buildCalculationRow('Factor de Estrés', 'x ${stressFactor.toStringAsFixed(2)}'),
          const Divider(color: Colors.blue),
          _buildCalculationRow('Requerimiento Total', '${totalRequirement.toStringAsFixed(0)} kcal', isTotal: true),
          const SizedBox(height: 8),
          Text(
            'Fórmula: TMB × FA × FE = ${tmb.toStringAsFixed(0)} × ${activityFactor.toStringAsFixed(2)} × ${stressFactor.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.blue[800] : Colors.blue[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.blue[800] : Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }


  /*Widget _buildNutritionalPlanSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 80), // Espacio para el botón fijo
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecciona tu Plan Nutricional',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Elige el plan que mejor se adapte a tus necesidades',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Opciones de planes
          _buildPlanOptionCard(
            'Solo Desayuno',
            'desayuno',
            Icons.wb_sunny,
            'Plan enfocado en el desayuno con opciones nutritivas para comenzar el día',
            '1 comida',
            Colors.orange,
          ),

          _buildPlanOptionCard(
            'Solo Almuerzo',
            'almuerzo',
            Icons.restaurant,
            'Plan principal del día con comidas balanceadas y nutritivas',
            '1 comida',
            Colors.green,
          ),

          _buildPlanOptionCard(
            'Solo Cena',
            'cena',
            Icons.nightlight_round,
            'Cenas ligeras y saludables para cerrar el día correctamente',
            '1 comida',
            Colors.indigo,
          ),

          _buildPlanOptionCard(
            'Plan Completo',
            'completo',
            Icons.restaurant_outlined,
            'Desayuno, almuerzo y cena balanceados según tus requerimientos',
            '3 comidas',
            Colors.blue,
          ),

          _buildPlanOptionCard(
            'Plan Premium',
            'premium',
            Icons.star,
            'Plan completo con 5 comidas, colaciones y opciones de postres saludables',
            '5 comidas + extras',
            Colors.purple,
            isPremium: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOptionCard(
      String title,
      String value,
      IconData icon,
      String description,
      String meals,
      Color themeColor,
      {bool isPremium = false}
      ) {
    final isSelected = _selectedPlan == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _saveSelectedPlan(value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? themeColor.withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? themeColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: themeColor.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            children: [
              // Icono con badge premium
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? themeColor : Colors.grey[400],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  if (isPremium)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? themeColor : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            meals,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: themeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Indicador de selección
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: isSelected
                    ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                )
                    : Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }*/

  Future<void> _generateNutritionalPlan() async {
    if (_selectedPlan.isEmpty) {
      SnackBarManager.showError(context, 'Por favor selecciona un tipo de plan');
      return;
    }

    setState(() {
      _isGeneratingPlan = true;
    });

    try {
      // Preparar datos para enviar al backend
      Map<String, dynamic> planData = {
        'patientId': widget.patient.id,
        'patientName': widget.patient.fullName,
        'planType': _selectedPlan,
        'patientData': widget.savedData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Guardar datos del plan en SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('nutritional_plan_${widget.patient.id}', jsonEncode(planData));

      // Simular llamada al backend (reemplaza esto con tu llamada real)
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Aquí implementar la llamada real al backend
      // final response = await http.post(
      //   Uri.parse('tu-backend-url/generate-plan'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode(planData),
      // );

      setState(() {
        _isGeneratingPlan = false;
      });

      SnackBarManager.showSuccess(
          context,
          'Plan nutricional generado exitosamente'
      );

      // Opcional: navegar a una nueva pantalla para mostrar el plan generado
      // Navigator.push(context, MaterialPageRoute(
      //   builder: (context) => GeneratedPlanScreen(planData: planData),
      // ));

    } catch (e) {
      setState(() {
        _isGeneratingPlan = false;
      });

      SnackBarManager.showError(
          context,
          'Error al generar el plan nutricional: ${e.toString()}'
      );
      print('Error al generar plan nutricional: $e');
    }
  }
}