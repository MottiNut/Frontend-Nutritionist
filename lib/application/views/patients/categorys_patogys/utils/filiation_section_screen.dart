import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:lottie/lottie.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '/../../../../domain/patient/pruebaa.dart';
import 'dart:async';

class FiliationSection extends StatefulWidget {
  final Patient patient;
  final bool isEditMode;
  final Function(Map<String, String>) onDataChanged;
  final Map<String, String>? initialData;

  const FiliationSection({
    super.key,
    required this.patient,
    required this.isEditMode,
    required this.onDataChanged,
    this.initialData,
  });

  @override
  State<FiliationSection> createState() => _FiliationSectionState();
}

class _FiliationSectionState extends State<FiliationSection> {
  // Controladores para los campos de filiación
  late TextEditingController _nucleoFamiliarController;
  late SingleSelectController<String?> _ocupacionController;
  late SingleSelectController<String?> _gradoInstruccionController;
  late SingleSelectController<String?> _religionController;

  // Variables para manejo de cambios
  Timer? _changeTimer;
  bool _hasLocalChanges = false;

  // Opciones para los dropdowns
  final List<String> _ocupacionOptions = [
    'Estudiante',
    'Empleado',
    'Profesional independiente',
    'Comerciante',
    'Ama de casa',
    'Jubilado',
    'Desempleado',
    'Otro'
  ];

  final List<String> _gradoInstruccionOptions = [
    'Sin instrucción',
    'Primaria incompleta',
    'Primaria completa',
    'Secundaria incompleta',
    'Secundaria completa',
    'Técnico',
    'Universitario incompleto',
    'Universitario completo',
    'Postgrado'
  ];

  final List<String> _religionOptions = [
    'Católica',
    'Evangélica',
    'Protestante',
    'Judía',
    'Musulmana',
    'Budista',
    'Agnóstico',
    'Ateo',
    'Otra'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupChangeListeners();
  }

  void _initializeControllers() {
    // Inicializar controlador de texto
    _nucleoFamiliarController = TextEditingController(
        text: widget.initialData?['nucleoFamiliar'] ??
            widget.patient.filiation?.nucleoFamiliar ?? ''
    );

    // Inicializar controladores de dropdown
    final ocupacionInicial = widget.initialData?['ocupacionActual'] ??
        widget.patient.filiation?.ocupacionActual;
    final gradoInicial = widget.initialData?['gradoInstruccion'] ??
        widget.patient.filiation?.gradoInstruccion;
    final religionInicial = widget.initialData?['religion'] ??
        widget.patient.filiation?.religion;

    _ocupacionController = SingleSelectController<String?>(
        _ocupacionOptions.contains(ocupacionInicial) ? ocupacionInicial : null
    );
    _gradoInstruccionController = SingleSelectController<String?>(
        _gradoInstruccionOptions.contains(gradoInicial) ? gradoInicial : null
    );
    _religionController = SingleSelectController<String?>(
        _religionOptions.contains(religionInicial) ? religionInicial : null
    );
  }

  void _setupChangeListeners() {
    _nucleoFamiliarController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasLocalChanges) {
      setState(() {
        _hasLocalChanges = true;
      });
    }

    // Cancelar timer anterior y crear uno nuevo para debounce
    _changeTimer?.cancel();
    _changeTimer = Timer(Duration(milliseconds: 500), () {
      _notifyParentOfChanges();
    });
  }

  void _onDropdownChanged() {
    _onFieldChanged();
  }

  void _notifyParentOfChanges() {
    final data = {
      'nucleoFamiliar': _nucleoFamiliarController.text,
      'ocupacionActual': _ocupacionController.value ?? '',
      'gradoInstruccion': _gradoInstruccionController.value ?? '',
      'religion': _religionController.value ?? '',
    };

    widget.onDataChanged(data);

    setState(() {
      _hasLocalChanges = false;
    });
  }

  @override
  void didUpdateWidget(FiliationSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si cambió a modo edición, configurar listeners
    if (widget.isEditMode != oldWidget.isEditMode) {
      if (widget.isEditMode) {
        _setupChangeListeners();
      }
    }
  }

  @override
  void dispose() {
    _changeTimer?.cancel();
    _nucleoFamiliarController.dispose();
    _ocupacionController.dispose();
    _gradoInstruccionController.dispose();
    _religionController.dispose();
    super.dispose();
  }

  Widget _buildSearchDropdownField(
      String label,
      String fallbackValue,
      SingleSelectController<String?> controller,
      List<String> options,
      VoidCallback onChanged,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
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
          const SizedBox(height: 8),
          widget.isEditMode
              ? Container(
            constraints: BoxConstraints(
              minWidth: 200,
              maxWidth: 280,
            ),
            child: CustomDropdown<String>.searchRequest(
                controller: controller,
                hintText: 'Selecciona una opción',
                items: options,
                noResultFoundText: 'No se encontraron resultados',
                searchHintText: 'Buscar...',
                futureRequest: (String filter) async {
                  await Future.delayed(const Duration(milliseconds: 100));
                  return options.where((item) =>
                      item.toLowerCase().contains(filter.toLowerCase())
                  ).toList();
                },
                onChanged: (value) {
                  onChanged();
                },
                decoration: CustomDropdownDecoration(
                  closedFillColor: controller.value?.isNotEmpty == true ? AppColors.primary : Colors.white,
                  expandedFillColor: Colors.white,
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                  headerStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: controller.value?.isNotEmpty == true ? FontWeight.bold : FontWeight.normal,
                    color: controller.value?.isNotEmpty == true ? Colors.white : Colors.black87,
                    letterSpacing: 0.5
                  ),
                  listItemStyle: const TextStyle(
                    fontSize: 13,
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
                    color: controller.value?.isNotEmpty == true ? Colors.white : Colors.grey[600],
                    size: 22,
                  ),
                  expandedSuffixIcon: Icon(
                    Icons.keyboard_arrow_up,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                closedHeaderPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
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
                )
            ),
          )
              : Container(
            constraints: BoxConstraints(
              minWidth: 200,
              maxWidth: 280,
            ),
            child: controller.value?.isNotEmpty == true
                ? // Mostrar como chip cuando hay valor seleccionado
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
                      controller.value!,
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
                : // Mostrar placeholder cuando no hay valor seleccionado
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
                        fallbackValue,
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
        ],
      ),
    );
  }

  Widget _buildTextFieldField(
      String label,
      String fallbackValue,
      TextEditingController controller,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
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
          const SizedBox(height: 8),
          widget.isEditMode
              ? Container(
            constraints: BoxConstraints(
              minWidth: 200,
              maxWidth: 280,
            ),
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
              color: Colors.white,
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Escribe...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          )
              : Container(
            constraints: BoxConstraints(
              minWidth: 200,
              maxWidth: 280,
            ),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                controller.text.isNotEmpty
                    ? controller.text
                    : fallbackValue,
                style: TextStyle(
                  fontSize: 13,
                  color: controller.text.isNotEmpty
                      ? Colors.black87
                      : Colors.grey[500],
                ),
                overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextFieldField(
            'Núcleo familiar',
            'Escribe...',
            _nucleoFamiliarController,
          ),
          _buildSearchDropdownField(
            'Ocupación actual',
            'Selecciona',
            _ocupacionController,
            _ocupacionOptions,
            _onDropdownChanged,
          ),
          _buildSearchDropdownField(
            'Grado de instrucción',
            'Selecciona',
            _gradoInstruccionController,
            _gradoInstruccionOptions,
            _onDropdownChanged,
          ),
          _buildSearchDropdownField(
            'Religión',
            'Selecciona',
            _religionController,
            _religionOptions,
            _onDropdownChanged,
          ),
        ],
      ),
    );
  }

  // Método público para obtener los datos actuales
  Map<String, String> getCurrentData() {
    return {
      'nucleoFamiliar': _nucleoFamiliarController.text,
      'ocupacionActual': _ocupacionController.value ?? '',
      'gradoInstruccion': _gradoInstruccionController.value ?? '',
      'religion': _religionController.value ?? '',
    };
  }

  // Método público para actualizar datos externamente
  void updateData(Map<String, String> newData) {
    _nucleoFamiliarController.text = newData['nucleoFamiliar'] ?? '';

    // Actualizar valores de dropdown solo si están en las opciones
    if (_ocupacionOptions.contains(newData['ocupacionActual'])) {
      _ocupacionController.value = newData['ocupacionActual'];
    }
    if (_gradoInstruccionOptions.contains(newData['gradoInstruccion'])) {
      _gradoInstruccionController.value = newData['gradoInstruccion'];
    }
    if (_religionOptions.contains(newData['religion'])) {
      _religionController.value = newData['religion'];
    }
  }

  // Método para limpiar cambios no guardados
  void resetToOriginal() {
    _nucleoFamiliarController.text = widget.patient.filiation?.nucleoFamiliar ?? '';

    // Resetear dropdowns a valores originales
    final ocupacionOriginal = widget.patient.filiation?.ocupacionActual;
    final gradoOriginal = widget.patient.filiation?.gradoInstruccion;
    final religionOriginal = widget.patient.filiation?.religion;

    _ocupacionController.value = _ocupacionOptions.contains(ocupacionOriginal)
        ? ocupacionOriginal : null;
    _gradoInstruccionController.value = _gradoInstruccionOptions.contains(gradoOriginal)
        ? gradoOriginal : null;
    _religionController.value = _religionOptions.contains(religionOriginal)
        ? religionOriginal : null;

    setState(() {
      _hasLocalChanges = false;
    });
  }
}