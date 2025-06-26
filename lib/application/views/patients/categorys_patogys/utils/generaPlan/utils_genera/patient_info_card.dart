import 'package:flutter/material.dart';
import 'package:mottinutnutriotinist/configuration/themes/app_colors.dart';

class ProfessionalPatientInfoCard extends StatefulWidget {
  final Map<String, dynamic> savedData;
  final dynamic patient;

  const ProfessionalPatientInfoCard({
    Key? key,
    required this.savedData,
    required this.patient,
  }) : super(key: key);

  @override
  State<ProfessionalPatientInfoCard> createState() => _ProfessionalPatientInfoCardState();
}

class _ProfessionalPatientInfoCardState extends State<ProfessionalPatientInfoCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expansionController;
  late AnimationController _rotationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // Colores profesionales para nutrición
  static const Color _textPrimary = Color(0xFF2D3748);
  static const Color _textSecondary = Color(0xFF718096);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Controlador principal de expansión
    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    // Controlador de rotación del ícono
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Animación de altura con curva suave
    _heightAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOutCubic,
    );

    // Animación de fade con retraso
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expansionController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    // Animación de escala sutil
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expansionController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    // Animación de deslizamiento suave
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _expansionController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutQuart),
    ));
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expansionController.forward();
        _rotationController.forward();
      } else {
        _expansionController.reverse();
        _rotationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 0.6, color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(15)
      ),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Material(
        color: Colors.white,
        elevation: 0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildExpandableContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpansion,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.backgroundLigth,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 0.9,
              ),
            ),
          ),
          child: Row(
            children: [
              // Ícono profesional con animación
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 56,
                height: 56,
                child: Image.asset('assets/plan/person.png')
              ),
              const SizedBox(width: 6),

              // Información del header
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Paciente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary1,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Historial clínico y evaluación nutricional',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                        letterSpacing: -0.1,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Ícono de expansión con animación
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 3.14159,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundHipertencion,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.iconSecondary,
                        size: 26,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableContent() {
    return SizeTransition(
      sizeFactor: _heightAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100
              ),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(13, 8, 13, 28),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildDataSection('Información Personal', _buildPersonalInfoContent(), Icons.person_outline_rounded),
                  const SizedBox(height: 17),
                  _buildDataSection('Filiación', _buildFiliationContent(), Icons.family_restroom_rounded),
                  const SizedBox(height: 17),
                  _buildDataSection('Antecedentes Médicos', _buildAntecedentsContent(), Icons.medical_services_outlined),
                  const SizedBox(height: 17),
                  _buildDataSection('Comorbilidades', _buildComorbiditiesContent(), Icons.warning_amber_rounded),
                  const SizedBox(height: 17),
                  _buildDataSection('Evaluación Nutricional', _buildNutritionalDataContent(), Icons.restaurant_menu_rounded),
                  const SizedBox(height: 17),
                  _buildDataSection('Factores de Riesgo', _buildRiskFactorsContent(), Icons.health_and_safety_outlined),
                  const SizedBox(height: 17),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildDataSection(String title, Widget content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.backgroundtInput.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: AppColors.textPrimary1,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white60,
              width: 1,
            ),
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: _textSecondary,
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 115,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isEmpty ? 'No especificado' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: value.isEmpty
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF1A1A1A),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoContent() {
    return Column(
      children: [
        _buildInfoRow('Edad', '${widget.savedData['age'] ?? widget.patient.age} años', icon: Icons.cake_outlined),
        _buildInfoRow('Peso', '${widget.savedData['weight'] ?? widget.patient.weight ?? ""} kg', icon: Icons.monitor_weight_outlined),
        _buildInfoRow('Talla', '${widget.savedData['height'] ?? widget.patient.height ?? ""} m', icon: Icons.height_rounded),
        _buildInfoRow('IMC', widget.patient.bmi > 0 ? '${widget.patient.bmi.toStringAsFixed(1)} kg/m²' : '', icon: Icons.analytics_outlined),
        _buildInfoRow('Estado Civil', widget.patient.maritalStatus ?? '', icon: Icons.favorite_outline),
        _buildInfoRow('Dirección', widget.patient.address ?? '', icon: Icons.location_on_outlined),
      ],
    );
  }

  Widget _buildFiliationContent() {
    return Column(
      children: [
        _buildInfoRow('Núcleo Familiar', widget.savedData['nucleoFamiliar'] ?? ''),
        _buildInfoRow('Ocupación', widget.savedData['ocupacionActual'] ?? ''),
        _buildInfoRow('Grado de Instrucción', widget.savedData['gradoInstruccion'] ?? ''),
        _buildInfoRow('Religión', widget.savedData['religion'] ?? ''),
      ],
    );
  }

  Widget _buildAntecedentsContent() {
    return Column(
      children: [
        _buildInfoRow('Diagnóstico Anterior', widget.savedData['diagnosticoMedicoAnterior'] ?? ''),
        _buildInfoRow('Tiempo de Enfermedad', widget.savedData['tiempoEnfermedad'] ?? ''),
        _buildInfoRow('Diagnóstico Reciente', widget.savedData['diagnosticoMedicoReciente'] ?? ''),
        _buildInfoRow('Antecedentes Familiares', widget.savedData['antecedentesFamiliares'] ?? ''),
      ],
    );
  }

  Widget _buildComorbiditiesContent() {
    return Column(
      children: [
        _buildInfoRow('Comorbilidades', widget.savedData['comorbilidades'] ?? ''),
      ],
    );
  }

  Widget _buildNutritionalDataContent() {
    return Column(
      children: [
        _buildInfoRow('Frecuencia de Comidas', widget.savedData['vecesComidaDia'] ?? '', icon: Icons.schedule_rounded),
        _buildInfoRow('Preferencias', widget.savedData['preferencias'] ?? '', icon: Icons.thumb_up_outlined),
        _buildInfoRow('Alimentos Rechazados', widget.savedData['noLeAgrada'] ?? '', icon: Icons.thumb_down_outlined),
        _buildInfoRow('Intolerancias', widget.savedData['intolerancias'] ?? '', icon: Icons.block_rounded),
        _buildInfoRow('Lugar de Comida', widget.savedData['lugarDeIngesta'] ?? '', icon: Icons.restaurant_rounded),
        _buildInfoRow('Hábitos Nocivos', widget.savedData['habitosNocivos'] ?? '', icon: Icons.smoking_rooms_outlined),
        _buildInfoRow('Actividad Física', widget.savedData['tipoActividad'] ?? '', icon: Icons.fitness_center_rounded),
        _buildInfoRow('Consumo de Agua', widget.savedData['consumoAgua'] ?? '', icon: Icons.water_drop_outlined),
      ],
    );
  }

  Widget _buildRiskFactorsContent() {
    return Column(
      children: [
        _buildInfoRow('Mayor de 45 años', widget.savedData['mayor45Anios'] ?? ''),
        _buildInfoRow('Obesidad', widget.savedData['obesidad'] ?? ''),
        _buildInfoRow('Hipertensión', widget.savedData['hipertension'] ?? ''),
        _buildInfoRow('Sedentarismo', widget.savedData['sedentarismo'] ?? ''),
        _buildInfoRow('Hijos Macrosómicos', widget.savedData['hijosMacrosomicos'] ?? ''),
        _buildInfoRow('Diabetes Gestacional', widget.savedData['diabetesGestacional'] ?? ''),
      ],
    );
  }
}