import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '/../../../../domain/patient/pruebaa.dart';
import 'dart:async';

class AntecedentsSectionScreen extends StatefulWidget {
  final Patient patient;
  final bool isEditMode;
  final Function(Map<String, String>) onDataChanged;
  final Map<String, String>? initialData;

  const AntecedentsSectionScreen({
    super.key,
    required this.patient,
    required this.isEditMode,
    required this.onDataChanged,
    this.initialData,
  });

  @override
  State<AntecedentsSectionScreen> createState() => _AntecedentsSectionScreenState();
}

class _AntecedentsSectionScreenState extends State<AntecedentsSectionScreen> {
  // Controladores para los campos
  late TextEditingController _diagnosticoMedRecienteController;
  late SingleSelectController<String?> _tiempoEnfermedadController;

  // Variables para manejo de cambios
  Timer? _changeTimer;
  bool _hasLocalChanges = false;

  // Estados para los toggles
  bool? _diagnosticoAnterior;
  bool? _antecedentesFamiliares;

  // Controlador para el detalle del diagnóstico anterior
  late TextEditingController _detalleController;

  // Opciones para los dropdowns
  final List<String> _tiempoEnfermedadOptions = [
    'Menos de 1 año',
    'Entre 1 y 2 años',
    'Entre 2 y 3 años',
    'Entre 3 y 4 años',
    'Entre 4 y 5 años',
    'Más de 5 años',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupChangeListeners();
  }

  void _initializeControllers() {
    // Inicializar estados de toggles
    _diagnosticoAnterior = widget.initialData?['diagnosticoMedicoAnterior'] != null
        ? widget.initialData!['diagnosticoMedicoAnterior'] == 'Sí'
        : widget.patient.medicalHistory?.diagnosticoMedicoAnterior;

    _antecedentesFamiliares = widget.initialData?['antecedentesFamiliares'] != null
        ? widget.initialData!['antecedentesFamiliares'] == 'Sí'
        : widget.patient.medicalHistory?.antecendentesFamiliares;

    // Inicializar controlador de detalle
    _detalleController = TextEditingController(
      text: widget.initialData?['detalleDiagnostico'] ?? '',
    );

    // Inicializar controlador de diagnóstico médico reciente
    _diagnosticoMedRecienteController = TextEditingController(
      text: widget.initialData?['diagnosticoMedicoReciente'] ??
          (widget.patient.medicalConditions.isEmpty
              ? 'No especificado'
              : widget.patient.medicalConditions
              .map((c) => c.displayName)
              .join(', ')),
    );

    // Inicializar controlador de tiempo de enfermedad
    _tiempoEnfermedadController = SingleSelectController<String?>(
      widget.initialData?['tiempoEnfermedad'] ??
          widget.patient.medicalHistory?.tiempoEnfermedad,
    );
  }

  void _setupChangeListeners() {
    _diagnosticoMedRecienteController.addListener(_onFieldChanged);
    _detalleController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
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
      'diagnosticoMedicoAnterior': _diagnosticoAnterior == null ? '' : (_diagnosticoAnterior! ? 'Sí' : 'No'),
      'detalleDiagnostico': _detalleController.text,
      'tiempoEnfermedad': _tiempoEnfermedadController.value ?? '',
      'diagnosticoMedicoReciente': _diagnosticoMedRecienteController.text,
      'antecedentesFamiliares': _antecedentesFamiliares == null ? '' : (_antecedentesFamiliares! ? 'Sí' : 'No'),
    };

    widget.onDataChanged(data);

    setState(() {
      _hasLocalChanges = false;
    });
  }

  // Método para limpiar campos dependientes cuando cambia la condición principal
  void _clearDependentFields(String parentField) {
    switch (parentField) {
      case 'diagnosticoAnterior':
        if (_diagnosticoAnterior != true) {
          _detalleController.clear();
          _tiempoEnfermedadController.value = null;
        }
        break;
    }
  }

  @override
  void didUpdateWidget(AntecedentsSectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isEditMode != oldWidget.isEditMode) {
      if (widget.isEditMode) {
        _setupChangeListeners();
      }
    }
  }

  @override
  void dispose() {
    _changeTimer?.cancel();
    _diagnosticoMedRecienteController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  // Widget para crear una sección con fondo blanco y bordes redondeados
  Widget _buildSection({required Widget child, EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // Widget para toggle personalizado
  Widget _buildToggleField(String label, String sublabel, bool? currentValue, Function(bool) onChanged, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
        if (sublabel.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 14,
              color: enabled ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Centramos los botones de toggle
        Center(
          child: Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton('SÍ', currentValue == true, () => onChanged(true), enabled),
                const SizedBox(width: 16),
                _buildToggleButton('NO', currentValue == false, () => onChanged(false), enabled),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap, bool enabled) {
    return GestureDetector(
      onTap: (widget.isEditMode && enabled) ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Widget para campo de texto editable con visibilidad condicional
  Widget _buildConditionalEditableTextField(String label, TextEditingController controller, bool shouldShow) {
    if (!shouldShow) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: widget.isEditMode,
            decoration: InputDecoration(
              hintText: 'Describe el diagnóstico...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyTextField(String label, TextEditingController controller) {
    return Column(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  controller.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget mejorado para el dropdown con visibilidad condicional
  Widget _buildConditionalTimeDropdownField(bool shouldShow) {
    if (!shouldShow) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 20), // Separación cuando aparece
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiempo de enfermedad',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8), // Reducido para coincidir con el otro diseño
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: BoxConstraints(
              minWidth: 200,
              maxWidth: 280,
            ),
            child: widget.isEditMode
                ? CustomDropdown<String>.searchRequest(
              controller: _tiempoEnfermedadController,
              hintText: 'Selecciona una opción',
              items: _tiempoEnfermedadOptions,
              noResultFoundText: 'No se encontraron resultados',
              searchHintText: 'Buscar...',
              futureRequest: (String filter) async {
                await Future.delayed(const Duration(milliseconds: 100));
                return _tiempoEnfermedadOptions.where((item) =>
                    item.toLowerCase().contains(filter.toLowerCase())
                ).toList();
              },
              onChanged: (value) {
                _onFieldChanged();
              },
              decoration: CustomDropdownDecoration(
                closedFillColor: _tiempoEnfermedadController.value?.isNotEmpty == true
                    ? AppColors.primary
                    : Colors.white, // Cambiado a blanco para coincidir
                expandedFillColor: Colors.white,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13, // Ajustado para coincidir
                ),
                headerStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: _tiempoEnfermedadController.value?.isNotEmpty == true
                      ? FontWeight.bold // Cambiado a bold para coincidir
                      : FontWeight.normal,
                  color: _tiempoEnfermedadController.value?.isNotEmpty == true
                      ? Colors.white
                      : Colors.black87,
                  letterSpacing: 0.5, // Añadido para coincidir
                ),
                listItemStyle: const TextStyle(
                  fontSize: 13, // Ajustado para coincidir
                  color: Colors.black87,
                ),
                noResultFoundStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                searchFieldDecoration: SearchFieldDecoration(
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                listItemDecoration: ListItemDecoration(
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  highlightColor: AppColors.primary.withOpacity(0.08),
                  splashColor: AppColors.primary.withOpacity(0.1),
                ),
                closedSuffixIcon: Icon(
                  Icons.keyboard_arrow_down,
                  color: _tiempoEnfermedadController.value?.isNotEmpty == true
                      ? Colors.white
                      : Colors.grey[600],
                  size: 22, // Añadido para coincidir
                ),
                expandedSuffixIcon: Icon(
                  Icons.keyboard_arrow_up,
                  color: AppColors.primary,
                  size: 22, // Añadido para coincidir
                ),
                closedBorder: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
                expandedBorder: Border.all(
                  color: AppColors.primary,
                  width: 1,
                ),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorderRadius: BorderRadius.circular(12),
              ),
              closedHeaderPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8, // Ajustado para coincidir
              ),
              listItemPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              searchRequestLoadingIndicator: Center(
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: Lottie.asset(
                    'assets/loading/palta_saltarina.json',
                    width: 50,
                    height: 50,
                  ),
                ),
              ),
            )
                : Container(
              constraints: BoxConstraints(
                minWidth: 200,
                maxWidth: 280,
              ),
              child: _tiempoEnfermedadController.value?.isNotEmpty == true
                  ? // Mostrar como chip cuando hay valor seleccionado (estilo del segundo dropdown)
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _tiempoEnfermedadController.value!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
                  : // Mostrar placeholder cuando no hay valor seleccionado (estilo del segundo dropdown)
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selecciona una opción',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(3),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sección 1: Diagnóstico médico anterior
                _buildSection(
                  child: Column(
                    children: [
                      _buildToggleField(
                        'Diagnóstico médico anterior',
                        '',
                        _diagnosticoAnterior,
                            (value) {
                          setState(() {
                            _diagnosticoAnterior = value;
                            // Limpiar campos dependientes cuando cambia a No o null
                            _clearDependentFields('diagnosticoAnterior');
                          });
                          _onFieldChanged();
                        },
                      ),
                      // Campo de detalle - solo visible si diagnóstico anterior es Sí
                      _buildConditionalEditableTextField(
                        'Detalle del diagnóstico',
                        _detalleController,
                        _diagnosticoAnterior == true,
                      ),
                    ],
                  ),
                ),

                // Sección 2: Tiempo de enfermedad - solo visible si diagnóstico anterior es Sí
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: _diagnosticoAnterior == true ? null : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _diagnosticoAnterior == true ? 1.0 : 0.0,
                    child: _diagnosticoAnterior == true
                        ? _buildSection(
                      child: _buildConditionalTimeDropdownField(_diagnosticoAnterior == true),
                    )
                        : const SizedBox.shrink(),
                  ),
                ),

                // Sección 3: Diagnóstico médico reciente (siempre visible)
                _buildSection(
                  child: _buildReadOnlyTextField(
                    'Diagnóstico médico reciente',
                    _diagnosticoMedRecienteController,
                  ),
                ),

                // Sección 4: Antecedentes familiares (siempre visible)
                _buildSection(
                  child: _buildToggleField(
                    'Antecedentes familiares',
                    '',
                    _antecedentesFamiliares,
                        (value) {
                      setState(() {
                        _antecedentesFamiliares = value;
                      });
                      _onFieldChanged();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Método público para obtener los datos actuales
  Map<String, String> getCurrentData() {
    return {
      'diagnosticoMedicoAnterior': _diagnosticoAnterior == null ? '' : (_diagnosticoAnterior! ? 'Sí' : 'No'),
      'detalleDiagnostico': _detalleController.text,
      'tiempoEnfermedad': _tiempoEnfermedadController.value ?? '',
      'diagnosticoMedicoReciente': _diagnosticoMedRecienteController.text,
      'antecedentesFamiliares': _antecedentesFamiliares == null ? '' : (_antecedentesFamiliares! ? 'Sí' : 'No'),
    };
  }

  // Método público para actualizar datos externamente
  void updateData(Map<String, String> newData) {
    setState(() {
      _diagnosticoAnterior = newData['diagnosticoMedicoAnterior'] == 'Sí' ? true :
      newData['diagnosticoMedicoAnterior'] == 'No' ? false : null;

      _antecedentesFamiliares = newData['antecedentesFamiliares'] == 'Sí' ? true :
      newData['antecedentesFamiliares'] == 'No' ? false : null;

      _detalleController.text = newData['detalleDiagnostico'] ?? '';

      if (_tiempoEnfermedadOptions.contains(newData['tiempoEnfermedad'])) {
        _tiempoEnfermedadController.value = newData['tiempoEnfermedad'];
      }

      _diagnosticoMedRecienteController.text = newData['diagnosticoMedicoReciente'] ?? '';
    });
  }

  // Método para limpiar cambios no guardados
  void resetToOriginal() {
    setState(() {
      _diagnosticoAnterior = widget.patient.medicalHistory?.diagnosticoMedicoAnterior;
      _antecedentesFamiliares = widget.patient.medicalHistory?.antecendentesFamiliares;

      _detalleController.clear();
      _tiempoEnfermedadController.value = widget.patient.medicalHistory?.tiempoEnfermedad;

      _diagnosticoMedRecienteController.text = widget.patient.medicalConditions.isEmpty
          ? 'No especificado'
          : widget.patient.medicalConditions
          .map((c) => c.displayName)
          .join(', ');

      _hasLocalChanges = false;
    });
  }
}