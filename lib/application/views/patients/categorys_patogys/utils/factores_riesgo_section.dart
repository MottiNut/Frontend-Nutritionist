import 'dart:async';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '/../../../../domain/patient/pruebaa.dart';

class FactoresRiesgoSection extends StatefulWidget {
  final Patient patient;
  final bool isEditMode;
  final Function(Map<String, String>) onDataChanged;
  final Map<String, String>? initialData;

  const FactoresRiesgoSection({
    super.key,
    required this.patient,
    required this.isEditMode,
    required this.onDataChanged,
    this.initialData,
  });

  @override
  State<FactoresRiesgoSection> createState() => _FactoresRiesgoSectionState();
}

class _FactoresRiesgoSectionState extends State<FactoresRiesgoSection> {
  // Variables para manejo de cambios
  Timer? _changeTimer;
  bool _hasLocalChanges = false;

  // Controller para el diagnóstico médico reciente
  late TextEditingController _diagnosticoMedRecienteController;

  // Estados para los toggles de factores de riesgo
  bool? _mayor45Anios;
  bool? _obesidad;
  bool? _dislipidemia;
  bool? _hipertension;
  bool? _sedentarismo;
  bool? _hijosMacrosomicos;
  bool? _diabetesGestacional;

  @override
  void initState() {
    super.initState();
    _initializeDiagnosticoController();
    _initializeControllers();
  }

  void _initializeDiagnosticoController() {
    _diagnosticoMedRecienteController = TextEditingController(
      text: widget.initialData?['diagnosticoMedicoReciente'] ??
          (widget.patient.medicalConditions.isEmpty
              ? 'No especificado'
              : widget.patient.medicalConditions
              .map((c) => c.displayName)
              .join(', ')),
    );
  }

  void _initializeControllers() {
    // Inicializar factores de riesgo desde initialData o patient
    _mayor45Anios = widget.initialData?['mayor45Anios'] != null
        ? widget.initialData!['mayor45Anios'] == 'Sí'
        : widget.patient.riskFactors?.mayor45Anios;

    _obesidad = widget.initialData?['obesidad'] != null
        ? widget.initialData!['obesidad'] == 'Sí'
        : widget.patient.riskFactors?.obesidad;

    _hipertension = widget.initialData?['hipertension'] != null
        ? widget.initialData!['hipertension'] == 'Sí'
        : widget.patient.riskFactors?.hipertension;

    _sedentarismo = widget.initialData?['sedentarismo'] != null
        ? widget.initialData!['sedentarismo'] == 'Sí'
        : widget.patient.riskFactors?.sedentarismo;

    _hijosMacrosomicos = widget.initialData?['hijosMacrosomicos'] != null
        ? widget.initialData!['hijosMacrosomicos'] == 'Sí'
        : widget.patient.riskFactors?.hijosMacrosomicos;

    _diabetesGestacional = widget.initialData?['diabetesGestacional'] != null
        ? widget.initialData!['diabetesGestacional'] == 'Sí'
        : widget.patient.riskFactors?.diabetesGestacional;
  }

  void _onFactorChanged() {
    if (!_hasLocalChanges) {
      setState(() {
        _hasLocalChanges = true;
      });
    }

    _changeTimer?.cancel();
    _changeTimer = Timer(Duration(milliseconds: 500), () {
      _notifyParentOfChanges();
    });
  }

  void _notifyParentOfChanges() {
    final data = {
      'mayor45Anios': _mayor45Anios == null ? '' : (_mayor45Anios! ? 'Sí' : 'No'),
      'obesidad': _obesidad == null ? '' : (_obesidad! ? 'Sí' : 'No'),
      'dislipidemia': _dislipidemia == null ? '' : (_dislipidemia! ? 'Sí' : 'No'),
      'hipertension': _hipertension == null ? '' : (_hipertension! ? 'Sí' : 'No'),
      'sedentarismo': _sedentarismo == null ? '' : (_sedentarismo! ? 'Sí' : 'No'),
      'hijosMacrosomicos': _hijosMacrosomicos == null ? '' : (_hijosMacrosomicos! ? 'Sí' : 'No'),
      'diabetesGestacional': _diabetesGestacional == null ? '' : (_diabetesGestacional! ? 'Sí' : 'No'),
    };

    widget.onDataChanged(data);

    setState(() {
      _hasLocalChanges = false;
    });
  }

  @override
  void didUpdateWidget(FactoresRiesgoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinicializar si cambian los datos del widget
    if (widget.initialData != oldWidget.initialData) {
      _initializeControllers();
    }
  }

  @override
  void dispose() {
    _changeTimer?.cancel();
    _diagnosticoMedRecienteController.dispose();
    super.dispose();
  }

  // Verifica si el paciente es diabético (condición necesaria para mostrar factores de riesgo)
  bool get _isDiabetic {
    // Verificar si tiene condiciones médicas que incluyan diabetes
    if (widget.patient.medicalConditions.isNotEmpty) {
      return widget.patient.medicalConditions.any((condition) => condition.isDiabetes);
    }

    // Verificar también en el texto del diagnóstico reciente
    String diagnosticoReciente = widget.initialData?['diagnosticoMedicoReciente'] ??
        (widget.patient.medicalConditions.isEmpty
            ? 'No especificado'
            : widget.patient.medicalConditions
            .map((c) => c.displayName)
            .join(', '));

    return diagnosticoReciente.toLowerCase().contains('diabetes');
  }

  // Verifica si el paciente es mujer - CORREGIDO
  bool get _isFemale {
    // Usar widget.patient.gender directamente en lugar de widget.patient.riskFactors?.gender
    return widget.patient.gender == Gender.femenino;
  }

  // Widget para crear una sección con fondo blanco y bordes redondeados
  Widget _buildSection({required Widget child, EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // Widget para toggle personalizado con diseño mejorado
  Widget _buildToggleField(String label, bool? currentValue, Function(bool) onChanged, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          // Botones de toggle centrados
          Row(
            children: [
              Expanded(
                child: _buildToggleButton('SÍ', currentValue == true, () => onChanged(true), enabled),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleButton('NO', currentValue == false, () => onChanged(false), enabled),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap, bool enabled) {
    return GestureDetector(
      onTap: (widget.isEditMode && enabled) ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ?  AppColors.textLight :  AppColors.textInput,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Widget para sección específica de mujeres - MEJORADO
  Widget _buildFemaleSpecificSection() {
    // Solo mostrar si es mujer
    if (!_isFemale) return const SizedBox.shrink();

    return _buildSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.female,
                color:  AppColors.errorText,
                size: 22,
              ),
              const SizedBox(width: 4),
              Text(
                'Factores específicos \npara mujeres',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                  height: 1
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildToggleField(
            '¿Ha tenido hijos que pesaron más de 4 kilos al nacer? (hijos macrosómicos )',
            _hijosMacrosomicos,
                (value) {
              setState(() {
                _hijosMacrosomicos = value;
              });
              _onFactorChanged();
            },
          ),
          _buildToggleField(
            '¿Ha tenido diabetes durante el embarazo (diabetes gestacional)?',
            _diabetesGestacional,
                (value) {
              setState(() {
                _diabetesGestacional = value;
              });
              _onFactorChanged();
            },
          ),
        ],
      ),
    );
  }

  // Widget para mostrar mensaje cuando no es diabético
  Widget _buildNonDiabeticMessage() {
    return _buildSection(
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 45,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Evaluación de Factores de Riesgo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Solo aplica para pacientes con diagnóstico de diabetes.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si no es diabético, mostrar mensaje informativo
    if (!_isDiabetic) {
      return _buildNonDiabeticMessage();
    }

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                '(Solo para pacientes diabéticos)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Mostrar información del diagnóstico actual
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Diagnóstico médico actual:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Mostrar género del paciente
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isFemale ? AppColors.errorText.withOpacity(0.1) : AppColors.backgroundDetail.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isFemale ? Icons.female : Icons.male,
                                size: 16,
                                color: _isFemale ? AppColors.errorText : AppColors.backgroundDetail,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _isFemale ? 'Mujer' : 'Hombre',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _isFemale ? AppColors.errorText : AppColors.backgroundDetail,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _diagnosticoMedRecienteController.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary1,
                        letterSpacing: 0.6
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isDiabetic ? AppColors.primary.withOpacity(0.2) : Colors.grey.shade200 ,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isDiabetic ? AppColors.primary.withOpacity(0.3)  : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _isDiabetic ? '✓ Paciente diabético - Evaluación aplicable' : '⚠ No diabético - Evaluación no aplicable',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _isDiabetic ? AppColors.primary :  AppColors.textInput,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Sección principal de factores de riesgo generales
              _buildSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildToggleField(
                      'Mayor de 45 años',
                      _mayor45Anios,
                          (value) {
                        setState(() {
                          _mayor45Anios = value;
                        });
                        _onFactorChanged();
                      },
                    ),

                    _buildToggleField(
                      'Obesidad',
                      _obesidad,
                          (value) {
                        setState(() {
                          _obesidad = value;
                        });
                        _onFactorChanged();
                      },
                    ),
                    _buildToggleField(
                      'Hipertensión arterial',
                      _hipertension,
                          (value) {
                        setState(() {
                          _hipertension = value;
                        });
                        _onFactorChanged();
                      },
                    ),

                    _buildToggleField(
                      'Sedentarismo',
                      _sedentarismo,
                          (value) {
                        setState(() {
                          _sedentarismo = value;
                        });
                        _onFactorChanged();
                      },
                    ),
                  ],
                ),
              ),
              // Sección específica para mujeres (solo si es mujer)
              _buildFemaleSpecificSection(),

              // Resumen de factores de riesgo
              _buildSection(
                child: _buildRiskSummary(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para mostrar resumen de factores de riesgo
  Widget _buildRiskSummary() {
    int factorsCount = _calculateFactorsCount();
    String riskLevel = _calculateRiskLevel(factorsCount);
    Color riskColor = _getRiskColor(riskLevel);

    return Column(
      children: [
        Text(
          'Resumen de Evaluación',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textInput,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: riskColor, width: 1),
          ),
          child: Column(
            children: [
              Text.rich(
                TextSpan(
                  text: 'Factores de riesgo identificados: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary1,
                  ),
                  children: [
                    TextSpan(
                      text: '$factorsCount',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'Nivel de riesgo: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: riskColor,
                  ),
                  children: [
                    TextSpan(
                      text: riskLevel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isFemale) ...[
                const SizedBox(height: 8),
                Text(
                  '(Incluye factores específicos de mujeres)',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textInput,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Calcula la cantidad de factores de riesgo presentes
  int _calculateFactorsCount() {
    int count = 0;
    if (_mayor45Anios == true) count++;
    if (_obesidad == true) count++;
    if (_dislipidemia == true) count++;
    if (_hipertension == true) count++;
    if (_sedentarismo == true) count++;

    // Solo para mujeres
    if (_isFemale) {
      if (_hijosMacrosomicos == true) count++;
      if (_diabetesGestacional == true) count++;
    }

    return count;
  }

  // Calcula el nivel de riesgo basado en la cantidad de factores
  String _calculateRiskLevel(int factorsCount) {
    if (factorsCount >= 5) return 'ALTO';
    if (factorsCount >= 3) return 'MODERADO';
    if (factorsCount >= 1) return 'BAJO';
    return 'MÍNIMO';
  }

  // Obtiene el color según el nivel de riesgo
  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'ALTO':
        return AppColors.errorIcon;
      case 'MODERADO':
        return AppColors.secondary;
      case 'BAJO':
        return Colors.yellow[700]!;
      default:
        return AppColors.checkValidation;
    }
  }

  // Método público para obtener los datos actuales
  Map<String, String> getCurrentData() {
    return {
      'mayor45Anios': _mayor45Anios == null ? '' : (_mayor45Anios! ? 'Sí' : 'No'),
      'obesidad': _obesidad == null ? '' : (_obesidad! ? 'Sí' : 'No'),
      'dislipidemia': _dislipidemia == null ? '' : (_dislipidemia! ? 'Sí' : 'No'),
      'hipertension': _hipertension == null ? '' : (_hipertension! ? 'Sí' : 'No'),
      'sedentarismo': _sedentarismo == null ? '' : (_sedentarismo! ? 'Sí' : 'No'),
      'hijosMacrosomicos': _hijosMacrosomicos == null ? '' : (_hijosMacrosomicos! ? 'Sí' : 'No'),
      'diabetesGestacional': _diabetesGestacional == null ? '' : (_diabetesGestacional! ? 'Sí' : 'No'),
      'factorsCount': _calculateFactorsCount().toString(),
      'riskLevel': _calculateRiskLevel(_calculateFactorsCount()),
    };
  }

  // Método público para actualizar datos externamente
  void updateData(Map<String, String> newData) {
    setState(() {
      _mayor45Anios = newData['mayor45Anios'] == 'Sí' ? true :
      newData['mayor45Anios'] == 'No' ? false : null;

      _obesidad = newData['obesidad'] == 'Sí' ? true :
      newData['obesidad'] == 'No' ? false : null;

      _dislipidemia = newData['dislipidemia'] == 'Sí' ? true :
      newData['dislipidemia'] == 'No' ? false : null;

      _hipertension = newData['hipertension'] == 'Sí' ? true :
      newData['hipertension'] == 'No' ? false : null;

      _sedentarismo = newData['sedentarismo'] == 'Sí' ? true :
      newData['sedentarismo'] == 'No' ? false : null;

      _hijosMacrosomicos = newData['hijosMacrosomicos'] == 'Sí' ? true :
      newData['hijosMacrosomicos'] == 'No' ? false : null;

      _diabetesGestacional = newData['diabetesGestacional'] == 'Sí' ? true :
      newData['diabetesGestacional'] == 'No' ? false : null;
    });
  }

  // Método para limpiar cambios no guardados
  void resetToOriginal() {
    setState(() {
      _mayor45Anios = widget.patient.riskFactors?.mayor45Anios;
      _obesidad = widget.patient.riskFactors?.obesidad;
      _dislipidemia = null; // Campo nuevo
      _hipertension = widget.patient.riskFactors?.hipertension;
      _sedentarismo = widget.patient.riskFactors?.sedentarismo;
      _hijosMacrosomicos = widget.patient.riskFactors?.hijosMacrosomicos;
      _diabetesGestacional = widget.patient.riskFactors?.diabetesGestacional;
      _hasLocalChanges = false;
    });
  }
}