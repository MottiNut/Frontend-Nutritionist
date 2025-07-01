import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';

import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/patient/pruebaa.dart';

// Enums para filtros avanzados
enum SortBy { name, age, bmi, lastVisit, glycemicControl }

enum FilterBy { all, controlled, uncontrolled, newPatients, riskPatients }

enum ViewMode { grid, list }

class PatientSearchWidget extends StatefulWidget {
  final MedicalCondition diseaseType;
  final String placeholderAsset;
  final Color primaryColor;
  final Color secondaryColor;
  final PatientServiceEnhanced patientService;

  const PatientSearchWidget({
    super.key,
    required this.diseaseType,
    required this.placeholderAsset,
    required this.primaryColor,
    required this.secondaryColor,
    required this.patientService,
  });

  @override
  State<PatientSearchWidget> createState() => _PatientSearchWidgetState();
}

class _PatientSearchWidgetState extends State<PatientSearchWidget>
    with TickerProviderStateMixin {
  MedicalCondition? selectedFilter;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _refreshController;
  late AnimationController _fabController;

  // Filtros avanzados
  SortBy currentSort = SortBy.name;
  FilterBy currentFilter = FilterBy.all;
  ViewMode viewMode = ViewMode.grid;
  bool isAscending = true;

  // Estados para el manejo de datos
  List<Patient> allPatients = [];
  bool isLoading = true;
  String? errorMessage;
  bool isRefreshing = false;
  bool isRetrying = false;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  // Cargar pacientes según el tipo de enfermedad
  Future<void> _loadPatients() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      List<Patient> patients;
      switch (widget.diseaseType) {
        case MedicalCondition.diabetesTipo1:
        case MedicalCondition.diabetesTipo2:
          patients = await widget.patientService.getDiabeticPatients();
          break;
        case MedicalCondition.hipertension:
          patients = await widget.patientService
              .getPatientsByMedicalCondition(MedicalCondition.hipertension);
          break;
        case MedicalCondition.obesidad:
        case MedicalCondition.sobrepeso:
          patients = await widget.patientService.getOverweightPatients();
          break;
        default:
          patients = await widget.patientService
              .getPatientsByMedicalCondition(widget.diseaseType);
      }

      setState(() {
        allPatients = patients;
        isLoading = false;
      });

      _fabController.forward();
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar pacientes: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Refresh con pull-to-refresh
  Future<void> _onRefresh() async {
    setState(() {
      isRefreshing = true;
    });

    _refreshController.forward();
    await _loadPatients();

    setState(() {
      isRefreshing = false;
    });

    _refreshController.reverse();
  }

  // Filtrar y ordenar pacientes
  List<Patient> get filteredPatients {
    List<Patient> filtered = allPatients;

    // Filtrar por tipo específico de condición médica
    if (selectedFilter != null) {
      filtered = filtered.where((patient) {
        return patient.medicalConditions.contains(selectedFilter);
      }).toList();
    }

    // Filtros avanzados por estado clínico
    switch (currentFilter) {
      case FilterBy.controlled:
        filtered = filtered.where((p) => _isControlled(p)).toList();
        break;
      case FilterBy.uncontrolled:
        filtered = filtered.where((p) => !_isControlled(p)).toList();
        break;
      case FilterBy.newPatients:
        filtered = filtered.where((p) => _isNewPatient(p)).toList();
        break;
      case FilterBy.riskPatients:
        filtered = filtered.where((p) => _isRiskPatient(p)).toList();
        break;
      case FilterBy.all:
      default:
        break;
    }

    // Filtrar por búsqueda
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((patient) {
        final fullName = patient.fullName.toLowerCase();
        final searchLower = searchQuery.toLowerCase();
        final ageString = patient.age.toString();

        return fullName.contains(searchLower) ||
            ageString.contains(searchQuery) ||
            patient.medicalConditions.any((condition) =>
                condition.displayName.toLowerCase().contains(searchLower));
      }).toList();
    }

    // Ordenar
    filtered.sort((a, b) {
      int comparison = 0;
      switch (currentSort) {
        case SortBy.name:
          comparison = a.fullName.compareTo(b.fullName);
          break;
        case SortBy.age:
          comparison = a.age.compareTo(b.age);
          break;
        case SortBy.bmi:
          comparison = a.bmi.compareTo(b.bmi);
          break;
        case SortBy.lastVisit:
          comparison = 0; // Implementar con fecha real
          break;
        case SortBy.glycemicControl:
          comparison = _getGlycemicScore(a).compareTo(_getGlycemicScore(b));
          break;
      }

      return isAscending ? comparison : -comparison;
    });

    return filtered;
  }

  // Métodos auxiliares para evaluación clínica
  bool _isControlled(Patient patient) {
    switch (widget.diseaseType) {
      case MedicalCondition.diabetesTipo1:
      case MedicalCondition.diabetesTipo2:
        return patient.bmi < 25 && patient.age < 65;
      case MedicalCondition.hipertension:
        return patient.bmi < 25 && patient.age < 60;
      case MedicalCondition.obesidad:
      case MedicalCondition.sobrepeso:
        return patient.bmi < 25;
      default:
        return patient.bmi < 25;
    }
  }

  bool _isNewPatient(Patient patient) {
    return true; // Implementar con fecha de registro real
  }

  bool _isRiskPatient(Patient patient) {
    switch (widget.diseaseType) {
      case MedicalCondition.diabetesTipo1:
      case MedicalCondition.diabetesTipo2:
        return patient.bmi > 30 || patient.age > 70;
      case MedicalCondition.hipertension:
        return patient.bmi > 28 || patient.age > 65;
      case MedicalCondition.obesidad:
        return patient.bmi > 35;
      default:
        return patient.bmi > 30;
    }
  }

  int _getGlycemicScore(Patient patient) {
    if (patient.bmi < 25) return 3;
    if (patient.bmi < 30) return 2;
    return 1;
  }

  Color _getRiskColor(Patient patient) {
    if (_isRiskPatient(patient)) return Colors.red;
    if (_isControlled(patient)) return Colors.green;
    return Colors.orange;
  }

  // Obtener filtros específicos según la enfermedad
  List<Widget> _getDiseaseSpecificFilters() {
    switch (widget.diseaseType) {
      case MedicalCondition.diabetesTipo1:
      case MedicalCondition.diabetesTipo2:
        return [
          _buildFilterChip('Todos', null, Colors.grey[600]!),
          const SizedBox(width: 10),
          _buildFilterChip('Tipo 1', MedicalCondition.diabetesTipo1,
              AppColors.backgroundDia),
          const SizedBox(width: 10),
          _buildFilterChip(
              'Tipo 2', MedicalCondition.diabetesTipo2, AppColors.secondary),
        ];
      case MedicalCondition.hipertension:
        return [
          _buildFilterChip('Todos', null, Colors.grey[600]!),
          const SizedBox(width: 10),
          _buildFilterChip(
              'Hipertensión', MedicalCondition.hipertension, Colors.red[400]!),
        ];
      case MedicalCondition.obesidad:
      case MedicalCondition.sobrepeso:
        return [
          _buildFilterChip('Todos', null, Colors.grey[600]!),
          const SizedBox(width: 10),
          _buildFilterChip(
              'Sobrepeso', MedicalCondition.sobrepeso, Colors.orange[400]!),
          const SizedBox(width: 10),
          _buildFilterChip(
              'Obesidad', MedicalCondition.obesidad, Colors.red[400]!),
        ];
      default:
        return [
          _buildFilterChip('Todos', null, Colors.grey[600]!),
        ];
    }
  }

  void _handleRetry() async {
    setState(() {
      isRetrying = true;
      errorMessage = null;
    });

    try {
      await _loadPatients();
    } catch (e) {
      // Si falla nuevamente, se mantendrá el errorMessage
    } finally {
      setState(() {
        isRetrying = false;
      });
    }
  }

  String _getSimpleErrorMessage(String technicalError) {
    String error = technicalError.toLowerCase();

    if (error.contains('network') ||
        error.contains('connection') ||
        error.contains('timeout')) {
      return 'Revisa tu conexión a internet';
    }

    if (error.contains('apiexception') ||
        error.contains('server') ||
        error.contains('500')) {
      return 'Problema con el servidor, intenta más tarde';
    }

    if (error.contains('unauthorized') || error.contains('401')) {
      return 'Sesión expirada, vuelve a iniciar sesión';
    }

    if (error.contains('forbidden') || error.contains('403')) {
      return 'No tienes permisos para ver esta información';
    }

    if (error.contains('not found') || error.contains('404')) {
      return 'Información no disponible';
    }

    return 'Algo salió mal, intenta de nuevo';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: widget.primaryColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 10),
              // Barra de búsqueda
              _buildSearchBar(),

              SizedBox(height: 10),

              // Controles avanzados
              _buildAdvancedControls(),

              SizedBox(height: 10),

              // Contenido principal con RefreshIndicator
              Expanded(
                child: Container(
                  color: Colors.grey[50],
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: widget.primaryColor,
                    child: buildMainContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiseaseFilters() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _getDiseaseSpecificFilters(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [

          Container(
            width: 20,
            height: 40,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.iconDark,
                size: 22,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ),

          Expanded(
            child: Container(
              height: 40,
              margin: EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, edad, IMC o estado clínico...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear,
                        color: Colors.grey[600], size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        searchQuery = '';
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                style: TextStyle(fontSize: 13, color: Colors.black),
              ),
            ),
          ),

          // Botón micrófono fuera del input (solo se muestra si NO hay texto)
          if (searchQuery.isEmpty)
            Container(
              width: 35,
              height: 35,
              margin: EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.mic,
                  color: Colors.grey[600],
                  size: 18,
                ),
                onPressed: () {
                  _showVoiceSearchDialog();
                },
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdvancedControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Filtros clínicos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterButton('Todos', FilterBy.all, Icons.people),
                SizedBox(width: 8),
                _buildFilterButton(
                  'Controlados',
                  FilterBy.controlled,
                  Icons.check_circle,
                ),
                SizedBox(width: 8),
                _buildFilterButton(
                    'Descontrolados', FilterBy.uncontrolled, Icons.warning),
                SizedBox(width: 8),
                _buildFilterButton(
                  'Nuevos',
                  FilterBy.newPatients,
                  Icons.fiber_new,
                ),
                SizedBox(width: 8),
                _buildFilterButton(
                  'Alto Riesgo',
                  FilterBy.riskPatients,
                  Icons.dangerous,
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

          // Controles de ordenamiento y vista
          Row(
            children: [
              Text(
                '${filteredPatients.length} paciente${filteredPatients.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHome,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8),

              // Botón de ordenamiento
              GestureDetector(
                onTap: _showSortDialog,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.primaryColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: widget.primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Ordenar',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Spacer(),

              // Cambio de vista
              GestureDetector(
                onTap: () {
                  setState(() {
                    viewMode = viewMode == ViewMode.grid
                        ? ViewMode.list
                        : ViewMode.grid;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    viewMode == ViewMode.grid
                        ? Icons.view_list
                        : Icons.view_module,
                    size: 18,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, FilterBy filter, IconData icon) {
    final isSelected = currentFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          currentFilter = filter;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[400]!,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.iconSecondary : Colors.grey[600],
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.textLight : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMainContent() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/loading/palta_saltarina.json',
                width: 100, height: 100),
            SizedBox(height: 16),
            Text(
              'Cargando pacientes...',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.errorText,
            ),
            SizedBox(height: 16),
            Text(
              'Error al cargar datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.errorText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _getSimpleErrorMessage(errorMessage!),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            if (!isRetrying)
              ElevatedButton.icon(
                onPressed: _handleRetry,
                icon: Icon(Icons.refresh),
                label: Text('Reintentar',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorIcon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            if (isRetrying)
              Column(
                children: [
                  Lottie.asset('assets/loading/palta_saltarina.json',
                      width: 70, height: 70),
                  SizedBox(height: 8),
                  Text(
                    'Reintentando...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    if (filteredPatients.isEmpty) {
      return _buildEmptyState();
    }

    return viewMode == ViewMode.grid ? _buildGridView() : _buildListView();
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = filteredPatients[index];
        return _buildPatientCard(patient);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = filteredPatients[index];
        return _buildPatientListItem(patient);
      },
    );
  }

  Widget _buildPatientCard(Patient patient) {
    final riskColor = _getRiskColor(patient);
    final isControlled = _isControlled(patient);

    // Determinar colores y etiquetas según el tipo de enfermedad
    Color typeColor = widget.primaryColor;
    String typeLabel = _getTypeLabel(patient);

    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECCIÓN DE IMAGEN
            Expanded(
              flex: 70,
              child: Container(
                child: Stack(
                  children: [
                    // Imagen de fondo o placeholder
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          image: (patient.profileImageUrl != null &&
                                  patient.profileImageUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(patient.profileImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (patient.profileImageUrl == null ||
                                patient.profileImageUrl!.isEmpty)
                            ? Center(
                                child: SvgPicture.asset(
                                  widget.placeholderAsset,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : null,
                      ),
                    ),

                    // Badge del tipo
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Indicador de riesgo
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: riskColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isControlled ? Icons.check : Icons.priority_high,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // SECCIÓN DE INFORMACIÓN
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: typeColor.withOpacity(0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nombre del paciente
                        Text(
                          patient.fullName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 6),

                        // Información clínica
                        Row(
                          children: [
                            Icon(
                              Icons.cake_outlined,
                              size: 11,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 3),
                            Text(
                              '${patient.age}a',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.monitor_weight_outlined,
                              size: 11,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 3),
                            Text(
                              'IMC:${patient.bmi.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 4),

                        // Estado de control
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isControlled ? 'Controlado' : 'Atención',
                            style: TextStyle(
                              fontSize: 9,
                              color: riskColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Método _buildPatientListItem que falta:
  Widget _buildPatientListItem(Patient patient) {
    final riskColor = _getRiskColor(patient);
    final isControlled = _isControlled(patient);
    final typeColor = widget.primaryColor;
    final typeLabel = _getTypeLabel(patient);

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            image: (patient.profileImageUrl != null &&
                    patient.profileImageUrl!.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(patient.profileImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: (patient.profileImageUrl == null ||
                  patient.profileImageUrl!.isEmpty)
              ? SvgPicture.asset(
                  widget.placeholderAsset,
                  width: 30,
                  height: 30,
                )
              : null,
        ),
        title: Text(
          patient.fullName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${patient.age} años',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'IMC: ${patient.bmi.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isControlled ? 'Controlado' : 'Atención',
                style: TextStyle(
                  fontSize: 10,
                  color: riskColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () => _showPatientDetails(patient),
      ),
    );
  }

  // 3. Método _buildEmptyState que falta:
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            widget.placeholderAsset,
            width: 100,
            height: 100,
            color: Colors.grey[400],
          ),
          SizedBox(height: 24),
          Text(
            'No se encontraron pacientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'Agrega pacientes para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          if (searchQuery.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  searchQuery = '';
                });
              },
              icon: Icon(Icons.clear),
              label: Text('Limpiar búsqueda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 4. Método _buildFilterChip que falta:
  Widget _buildFilterChip(
      String label, MedicalCondition? condition, Color color) {
    final isSelected = selectedFilter == condition;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = condition;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // 5. Método _getTypeLabel que falta:
  String _getTypeLabel(Patient patient) {
    switch (widget.diseaseType) {
      case MedicalCondition.diabetesTipo1:
        return 'DM1';
      case MedicalCondition.diabetesTipo2:
        return 'DM2';
      case MedicalCondition.hipertension:
        return 'HTA';
      case MedicalCondition.obesidad:
        return 'OB';
      case MedicalCondition.sobrepeso:
        return 'SP';
      default:
        return 'PAC';
    }
  }

  // 6. Método _showPatientDetails que falta:
  void _showPatientDetails(Patient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreen(
          patient: patient,
          diseaseType: widget.diseaseType,
        ),
      ),
    );
  }

  // 7. Método _showSortDialog que falta:
  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ordenar por',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            ...SortBy.values.map((sort) => ListTile(
                  title: Text(_getSortLabel(sort)),
                  leading: Radio<SortBy>(
                    value: sort,
                    groupValue: currentSort,
                    onChanged: (SortBy? value) {
                      setState(() {
                        currentSort = value!;
                        if (currentSort == sort && currentSort != SortBy.name) {
                          isAscending = !isAscending;
                        }
                      });
                      Navigator.pop(context);
                    },
                    activeColor: widget.primaryColor,
                  ),
                  onTap: () {
                    setState(() {
                      currentSort = sort;
                      if (currentSort == sort && currentSort != SortBy.name) {
                        isAscending = !isAscending;
                      }
                    });
                    Navigator.pop(context);
                  },
                )),
            Divider(),
            ListTile(
              title:
                  Text('Orden ${isAscending ? 'ascendente' : 'descendente'}'),
              leading: Icon(
                isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: widget.primaryColor,
              ),
              onTap: () {
                setState(() {
                  isAscending = !isAscending;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 8. Método _getSortLabel que falta:
  String _getSortLabel(SortBy sort) {
    switch (sort) {
      case SortBy.name:
        return 'Nombre';
      case SortBy.age:
        return 'Edad';
      case SortBy.bmi:
        return 'IMC';
      case SortBy.lastVisit:
        return 'Última visita';
      case SortBy.glycemicControl:
        return 'Control glucémico';
    }
  }

  // 9. Método _showVoiceSearchDialog que falta:
  void _showVoiceSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Búsqueda por voz'),
        content: Text('Función de búsqueda por voz próximamente disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendido',
              style: TextStyle(color: widget.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

// 10. Clase PatientDetailScreen que necesitarás crear por separado:
class PatientDetailScreen extends StatelessWidget {
  final Patient patient;
  final MedicalCondition diseaseType;

  const PatientDetailScreen({
    Key? key,
    required this.patient,
    required this.diseaseType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patient.fullName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Center(
        child: Text('Detalles del paciente: ${patient.fullName}'),
      ),
    );
  }
}
