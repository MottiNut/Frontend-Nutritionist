import 'package:flutter/material.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '/../../../../domain/patient/pruebaa.dart';
import 'dart:async';

class ComorbolidadesSection extends StatefulWidget {
  final Patient patient;
  final bool isEditMode;
  final Function(Map<String, dynamic>) onDataChanged;
  final Map<String, dynamic>? initialData;

  const ComorbolidadesSection({
    super.key,
    required this.patient,
    required this.isEditMode,
    required this.onDataChanged,
    this.initialData,
  });

  @override
  State<ComorbolidadesSection> createState() => _ComorbolidadesSectionState();
}

class _ComorbolidadesSectionState extends State<ComorbolidadesSection>
    with TickerProviderStateMixin {
  Timer? _changeTimer;
  bool _hasLocalChanges = false;
  bool _isDropdownOpen = false;

  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  List<Comorbidity> _selectedComorbidities = [];
  List<Comorbidity> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeData();
  }

  void _initializeControllers() {
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _filteredOptions = Comorbidity.values.toList();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _searchController.addListener(_onSearchChanged);
  }

  void _initializeData() {
    List<Comorbidity> initialComorbidities = [];

    // Manejar diferentes tipos de datos iniciales
    if (widget.initialData != null && widget.initialData!['comorbilidades'] != null) {
      final comorbilidadesData = widget.initialData!['comorbilidades'];

      if (comorbilidadesData is List<Comorbidity>) {
        // Si ya es una lista de Comorbidity
        initialComorbidities = List.from(comorbilidadesData);
      } else if (comorbilidadesData is String) {
        // Si es un string, parsearlo
        if (comorbilidadesData.isNotEmpty) {
          final names = comorbilidadesData.split(', ');
          initialComorbidities = names
              .map((name) => _getComorbiditaByName(name.trim()))
              .where((comorbidity) => comorbidity != null)
              .cast<Comorbidity>()
              .toList();
        }
      } else if (comorbilidadesData is List) {
        // Si es una lista genérica, convertir cada elemento
        initialComorbidities = comorbilidadesData
            .map((item) {
          if (item is Comorbidity) return item;
          if (item is String) return _getComorbiditaByName(item);
          return null;
        })
            .where((item) => item != null)
            .cast<Comorbidity>()
            .toList();
      }
    } else {
      // Fallback a los datos del paciente
      initialComorbidities = widget.patient.medicalHistory?.comorbilidades ?? [];
    }

    setState(() {
      _selectedComorbidities = initialComorbidities;
    });
  }

  Comorbidity? _getComorbiditaByName(String name) {
    try {
      return Comorbidity.values.firstWhere(
            (comorbidity) => comorbidity.name == name || comorbidity.displayName == name,
      );
    } catch (e) {
      return null;
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredOptions = Comorbidity.values
          .where((comorbidity) =>
          comorbidity.displayName.toLowerCase().contains(query))
          .toList();
    });
  }

  void _onFieldChanged() {
    if (!_hasLocalChanges) {
      setState(() {
        _hasLocalChanges = true;
      });
    }

    _changeTimer?.cancel();
    _changeTimer = Timer(const Duration(milliseconds: 500), () {
      _notifyParentOfChanges();
    });
  }

  void _notifyParentOfChanges() {
    // CAMBIO PRINCIPAL: Convertir los enums a strings para el padre
    final data = {
      'comorbilidades': _selectedComorbidities.map((c) => c.displayName).join(', '),
      'comorbilidadesEnum': _selectedComorbidities, // Mantener también los enums por si se necesitan
    };

    widget.onDataChanged(data);

    setState(() {
      _hasLocalChanges = false;
    });
  }

  void _toggleComorbidity(Comorbidity comorbidity) {
    setState(() {
      if (comorbidity == Comorbidity.ninguna) {
        // Si selecciona "Ninguna", limpiar todas las demás
        _selectedComorbidities.clear();
        _selectedComorbidities.add(comorbidity);
      } else {
        // Si selecciona otra opción, quitar "Ninguna" si está presente
        _selectedComorbidities.remove(Comorbidity.ninguna);

        if (_selectedComorbidities.contains(comorbidity)) {
          _selectedComorbidities.remove(comorbidity);
        } else {
          _selectedComorbidities.add(comorbidity);
        }
      }
    });
    _onFieldChanged();
  }

  void _removeComorbidity(Comorbidity comorbidity) {
    setState(() {
      _selectedComorbidities.remove(comorbidity);
    });
    _onFieldChanged();
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
      if (_isDropdownOpen) {
        _searchController.clear();
        _filteredOptions = Comorbidity.values.toList();
        _searchFocusNode.requestFocus();
        _animationController.forward();
      } else {
        _animationController.reverse();
        _searchFocusNode.unfocus();
      }
    });
  }

  Widget _buildDropdownHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDropdownOpen ? AppColors.primary : Colors.grey[300]!,
          width: _isDropdownOpen ? 2 : 1.5,
        ),
        boxShadow: _isDropdownOpen
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isEditMode ? _toggleDropdown : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _selectedComorbidities.isEmpty
                        ? Colors.grey[100]
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: _selectedComorbidities.isEmpty
                        ? Colors.grey[400]
                        : AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedComorbidities.isEmpty
                            ? 'Selecciona comorbilidades'
                            : '${_selectedComorbidities.length} comorbilidad${_selectedComorbidities.length != 1 ? 'es' : ''} seleccionada${_selectedComorbidities.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _selectedComorbidities.isEmpty
                              ? Colors.grey[600]
                              : Colors.black87,
                        ),
                      ),
                      if (_selectedComorbidities.isNotEmpty)
                        Text(
                          _selectedComorbidities.map((c) => c.displayName).join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (widget.isEditMode)
                  AnimatedRotation(
                    turns: _isDropdownOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _isDropdownOpen ? AppColors.primary : Colors.grey[600],
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              Icons.search,
              color: Colors.grey[400],
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Buscar comorbilidades...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: Colors.grey[400],
                size: 18,
              ),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownOptions() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchField(),
          if (_filteredOptions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No se encontraron resultados',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Intenta con otro término de búsqueda',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _filteredOptions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey[100],
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final comorbidity = _filteredOptions[index];
                  final isSelected = _selectedComorbidities.contains(comorbidity);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleComorbidity(comorbidity),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.08)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: isSelected
                                  ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                comorbidity.displayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '✓',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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

  Widget _buildSelectedChips() {
    if (_selectedComorbidities.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comorbilidades seleccionadas:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedComorbidities.map((comorbidity) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_hospital,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            comorbidity.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.isEditMode) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _removeComorbidity(comorbidity),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
                child: Icon(
                  Icons.medical_information,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comorbilidades',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Condiciones médicas coexistentes',
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
          const SizedBox(height: 16),
          _buildDropdownHeader(),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isDropdownOpen && widget.isEditMode
                ? _buildDropdownOptions()
                : const SizedBox.shrink(),
          ),
          _buildSelectedChips(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _changeTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Métodos públicos para manejo externo
  Map<String, dynamic> getCurrentData() {
    return {
      'comorbilidades': _selectedComorbidities.map((c) => c.displayName).join(', '),
      'comorbilidadesEnum': _selectedComorbidities,
    };
  }

  void updateData(Map<String, dynamic> newData) {
    final newComorbidities = newData['comorbilidades'];
    List<Comorbidity> comorbiditiesList = [];

    if (newComorbidities is List<Comorbidity>) {
      comorbiditiesList = List.from(newComorbidities);
    } else if (newComorbidities is String && newComorbidities.isNotEmpty) {
      final names = newComorbidities.split(', ');
      comorbiditiesList = names
          .map((name) => _getComorbiditaByName(name.trim()))
          .where((comorbidity) => comorbidity != null)
          .cast<Comorbidity>()
          .toList();
    }

    setState(() {
      _selectedComorbidities = comorbiditiesList;
    });
  }

  void resetToOriginal() {
    final originalComorbidities = widget.patient.medicalHistory?.comorbilidades ?? [];
    setState(() {
      _selectedComorbidities = List.from(originalComorbidities);
      _hasLocalChanges = false;
    });
  }
}