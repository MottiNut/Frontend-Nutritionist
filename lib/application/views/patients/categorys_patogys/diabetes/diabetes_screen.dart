import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';

import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/patient/pruebaa.dart';
import '../person_detail_screen.dart';
import '../search/search_patients_creen.dart';

// Enums para filtros avanzados
enum SortBy { name, age, bmi, lastVisit, glycemicControl }

enum FilterBy { all, controlled, uncontrolled, newPatients, riskPatients }

enum ViewMode { grid, list }

class DiabetesPatientsScreen extends StatefulWidget {
  const DiabetesPatientsScreen({super.key});

  @override
  State<DiabetesPatientsScreen> createState() => _DiabetesPatientsScreenState();
}

class _DiabetesPatientsScreenState extends State<DiabetesPatientsScreen>
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

  final PatientServiceEnhanced patientService = PatientServiceEnhanced();

  // Estados para el manejo de datos
  List<Patient> allPatients = [];
  bool isLoading = true;
  String? errorMessage;
  bool isRefreshing = false;

  //maneja reintentdo
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
    _loadDiabeticPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  // Cargar pacientes con diabetes desde el API
  Future<void> _loadDiabeticPatients() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final patients = await patientService.getDiabeticPatients();

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
    await _loadDiabeticPatients();

    setState(() {
      isRefreshing = false;
    });

    _refreshController.reverse();
  }

  // Filtrar y ordenar pacientes
  List<Patient> get filteredPatients {
    List<Patient> filtered = allPatients;

    // Filtrar por tipo de diabetes
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
          // Implementar lógica de última visita
          comparison = 0;
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
    // Lógica para determinar si está controlado
    return patient.bmi < 25 && patient.age < 65;
  }

  bool _isNewPatient(Patient patient) {
    // Lógica para pacientes nuevos (últimos 30 días)
    return true; // Implementar con fecha de registro
  }

  bool _isRiskPatient(Patient patient) {
    // Pacientes de alto riesgo
    return patient.bmi > 30 || patient.age > 70;
  }

  int _getGlycemicScore(Patient patient) {
    // Puntuación de control glucémico (simulada)
    if (patient.bmi < 25) return 3;
    if (patient.bmi < 30) return 2;
    return 1;
  }

  Color _getRiskColor(Patient patient) {
    if (_isRiskPatient(patient)) return Colors.red;
    if (_isControlled(patient)) return Colors.green;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.secondary.withOpacity(0.6),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [

              // Header con título y estadísticas
              _buildHeader(context),

              // Filtros por tipo de diabetes
              _buildDiabetesTypeFilters(),

              SizedBox(height: 15),

              // Barra de búsqueda mejorada
              _buildSearchBar(context),

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
                    color: AppColors.backgroundDia,
                    child: buildMainContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: ScaleTransition(
          scale: _fabController,
          child: FloatingActionButton.extended(
            onPressed: () {
              //_showAddPatientDialog();
            },
            backgroundColor: AppColors.backgroundDia,
            icon: SvgPicture.asset(
              'assets/images/plus_icon.svg',
              width: 20,
              height: 20,
            ),
            label: Text(
              'Nuevo Paciente',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Botón de retroceso
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/images/anterior_icon.svg',
                width: 21,
                height: 21,
                color: AppColors.secondary,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          // Título centrado
          Align(
            alignment: Alignment.center,
            child: Text(
              'Pacientes con Diabetes',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: AppColors.secondary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Widget invisible para balancear el espacio
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 48,
              height: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiabetesTypeFilters() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterChip('Todos', null, AppColors.backgroundtInput.withOpacity(0.4)),
            const SizedBox(width: 10),
            _buildFilterChip('Tipo 1', MedicalCondition.diabetesTipo1,
                AppColors.backgroundDia),
            const SizedBox(width: 10),
            _buildFilterChip(
                'Tipo 2', MedicalCondition.diabetesTipo2, AppColors.secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 45),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientSearchWidget(
                    diseaseType: MedicalCondition.diabetesTipo2,
                    primaryColor: AppColors.backgroundDia,
                    secondaryColor: AppColors.backgroundDia,
                    placeholderAsset: 'assets/images/user_placeholder_orange.svg',
                    patientService: PatientServiceEnhanced(),
                  ),
                ),
              );
            },
            child: AbsorbPointer(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.textInput,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(width: 0.2, color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: 'Buscar paciente...',
                    hintStyle: TextStyle(
                      color: AppColors.textCuatary,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.iconPrimary,
                      size: 22,
                    ),
                    suffixIcon: Icon(
                      Icons.mic_none_rounded,
                      color: AppColors.iconPrimary,
                      size: 22,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: TextStyle(
                      fontSize: 14, color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
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
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Ordenar',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondary,
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
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    viewMode == ViewMode.grid
                        ? Icons.view_list
                        : Icons.view_module,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
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
            // Mostrar el botón solo si no está reintentando
            if (!isRetrying)
              ElevatedButton.icon(
                onPressed: _handleRetry,
                icon: Icon(Icons.refresh),
                label: Text(
                  'Reintentar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorIcon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            // Mostrar la animación de carga durante el reintento
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
    return viewMode == ViewMode.grid ? _buildGridView() : _buildListView();
  }

  void _handleRetry() async {
    setState(() {
      isRetrying = true;
      errorMessage = null; // Limpiar el mensaje de error anterior
    });

    try {
      await _loadDiabeticPatients();
    } catch (e) {
      // Si falla nuevamente, se mantendrá el errorMessage
    } finally {
      setState(() {
        isRetrying = false;
      });
    }
  }

// Método para convertir errores técnicos en mensajes amigables
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

    // Para cualquier otro error técnico, mostrar mensaje genérico
    return 'Algo salió mal, intenta de nuevo';
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

  Widget _buildPatientListItem(Patient patient) {
    final riskColor = _getRiskColor(patient);
    final isControlled = _isControlled(patient);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: riskColor.withOpacity(0.1),
          child: patient.profileImageUrl != null &&
                  patient.profileImageUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    patient.profileImageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 30,
                  color: riskColor,
                ),
        ),
        title: Text(
          patient.fullName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.cake, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text('${patient.age} años'),
                SizedBox(width: 16),
                Icon(Icons.monitor_weight, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text('IMC: ${patient.bmi.toStringAsFixed(1)}'),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isControlled ? 'Controlado' : 'Requiere Atención',
                    style: TextStyle(
                      fontSize: 11,
                      color: riskColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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

  Widget _buildFilterChip(
      String label, MedicalCondition? condition, Color color) {
    final isSelected = selectedFilter == condition;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = isSelected ? null : condition;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(
              width: 1.2, color: isSelected ? color : Colors.grey[400]!),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    bool hasTipo1 = patient.medicalConditions.contains(MedicalCondition.diabetesTipo1);
    bool hasTipo2 = patient.medicalConditions.contains(MedicalCondition.diabetesTipo2);

    final riskColor = _getRiskColor(patient);
    final isControlled = _isControlled(patient);

    Color typeColor;
    String typeLabel;
    String placeholderAsset;
    String nextIconAsset;

    if (hasTipo1) {
      typeColor = AppColors.backgroundDia;
      typeLabel = 'T1';
      placeholderAsset = 'assets/images/user_placeholder_esmer.svg';
      nextIconAsset = 'assets/images/next_icon.svg';
    } else if (hasTipo2) {
      typeColor = AppColors.secondary;
      typeLabel = 'T2';
      placeholderAsset = 'assets/images/user_placeholder_orange.svg';
      nextIconAsset = 'assets/images/next_orange.svg';
    } else {
      typeColor = Colors.grey;
      typeLabel = 'D';
      placeholderAsset = 'assets/images/user_placeholder_esmer.svg';
      nextIconAsset = 'assets/images/next_icon.svg';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonDetailScreen(
                patient: patient,
              ),
            ),
          );
        },

        child: Card(
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
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              image: (patient.profileImageUrl != null && patient.profileImageUrl!.isNotEmpty)
                                  ? DecorationImage(
                                image: NetworkImage(patient.profileImageUrl!),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: (patient.profileImageUrl == null || patient.profileImageUrl!.isEmpty)
                                ? Center(
                              child: SvgPicture.asset(
                                placeholderAsset,
                                width: 60,
                                height: 60,
                                fit: BoxFit.contain,
                              ),
                            )
                                : null,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                            Row(
                              children: [
                                Text(
                                  '${patient.age} años',
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
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: SvgPicture.asset(nextIconAsset),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: Offset(0, -2),
                blurRadius: 16,
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Ordenar por',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),

                      Spacer(),

                      Tooltip(
                        message: isAscending ? 'Orden ascendente (A-Z)' : 'Orden descendente (Z-A)',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              // ✨ Usar setModalState en lugar de setState
                              setModalState(() {
                                isAscending = !isAscending;
                              });
                              // También actualizar el widget padre
                              setState(() {});
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAscending ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    isAscending ? 'A-Z' : 'Z-A',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),

                  SizedBox(height: 20),

                  // Compact Sort Grid
                  Row(
                    children: [
                      Expanded(child: _buildCompactSortOption('Nombre', SortBy.name, Icons.person_outline, setModalState)),
                      SizedBox(width: 8),
                      Expanded(child: _buildCompactSortOption('Edad', SortBy.age, Icons.cake_outlined, setModalState)),
                    ],
                  ),

                  SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(child: _buildCompactSortOption('IMC', SortBy.bmi, Icons.monitor_weight_outlined, setModalState)),
                      SizedBox(width: 8),
                      Expanded(child: _buildCompactSortOption('Última Visita', SortBy.lastVisit, Icons.access_time_outlined, setModalState)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildCompactSortOption(
                          'Control Glucémico', SortBy.glycemicControl, Icons.bloodtype,setModalState ),)
                    ],
                  ),

                  SizedBox(height: 50),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              // Reset filters logic here
                              setModalState(() {
                                currentSort = SortBy.name;
                                isAscending = true;
                              });
                              setState(() {
                                currentSort = SortBy.name;
                                isAscending = true;
                              });
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.grey[200]!, width: 2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [

                                  Text(
                                    'Limpiar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundDetail,
                                borderRadius: BorderRadius.circular(25),

                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [

                                  Text(
                                    'Aplicar Filtro',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSortOption(String title, SortBy sortBy, IconData icon, StateSetter setModalState) {
    final bool isSelected = currentSort == sortBy;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setModalState(() {
            if (currentSort == sortBy) {
              isAscending = !isAscending;
            } else {
              currentSort = sortBy;
              isAscending = true;
            }
          });
          setState(() {
            if (currentSort == sortBy) {
              isAscending = !isAscending;
            } else {
              currentSort = sortBy;
              isAscending = true;
            }
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: AppColors.primary.withOpacity(0.7), width: 2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // Centrado vertical
            children: [
              AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? AppColors.primary : Colors.grey[400],
                  size: 23,
                ),
              ),
              SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : Colors.grey[400],
                ),
                child: Text(title),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPatientDetails(Patient patient) {
    // Obtener las condiciones médicas del paciente
    String conditions = patient.medicalConditions
        .map((condition) => condition.displayName)
        .join(', ');

    final riskColor = _getRiskColor(patient);
    final isControlled = _isControlled(patient);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: riskColor.withOpacity(0.1),
              child: Icon(Icons.person, color: riskColor),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.fullName,
                    style: TextStyle(fontSize: 18),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isControlled ? 'Controlado' : 'Requiere Atención',
                      style: TextStyle(
                        fontSize: 12,
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información básica
              _buildDetailRow('Edad', '${patient.age} años', Icons.cake),
              _buildDetailRow(
                  'Condiciones',
                  conditions.isNotEmpty
                      ? conditions
                      : 'Sin condiciones registradas',
                  Icons.medical_services),

              if (patient.weight != null)
                _buildDetailRow(
                    'Peso', '${patient.weight} kg', Icons.monitor_weight),

              if (patient.height != null)
                _buildDetailRow('Altura', '${patient.height} cm', Icons.height),

              if (patient.bmi > 0)
                _buildDetailRow(
                    'IMC',
                    '${patient.bmi.toStringAsFixed(1)} - ${patient.bmiCategory}',
                    Icons.analytics),

              _buildDetailRow('Estado', patient.status.name, Icons.info),

              SizedBox(height: 16),

              // Evaluación nutricional
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assessment, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Evaluación Nutricional',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Clasificación BMI: ${patient.bmiCategory}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '• Estado de control: ${isControlled ? 'Objetivo nutricional alcanzado' : 'Requiere ajuste en plan alimentario'}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '• Riesgo cardiovascular: ${_isRiskPatient(patient) ? 'Alto' : 'Moderado'}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showNutritionalPlan(patient);
            },
            icon: Icon(Icons.restaurant_menu),
            label: Text('Plan Nutricional'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.backgroundDia,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navegar a pantalla de historial completo
            },
            icon: Icon(Icons.history),
            label: Text('Historial'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showNutritionalPlan(Patient patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.restaurant_menu, color: Colors.green),
            SizedBox(width: 8),
            Text('Plan Nutricional'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paciente: ${patient.fullName}',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),

              // Recomendaciones calóricas
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recomendaciones Calóricas:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                        '• Calorías diarias: ${_calculateDailyCalories(patient)} kcal'),
                    Text(
                        '• Carbohidratos: 45-60% (${_calculateCarbs(patient)}g)'),
                    Text(
                        '• Proteínas: 15-20% (${_calculateProtein(patient)}g)'),
                    Text('• Grasas: 20-35% (${_calculateFats(patient)}g)'),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Alimentos recomendados
              Text(
                'Alimentos Recomendados:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Verduras de hoja verde y no feculentas'),
              Text('• Proteínas magras (pollo, pescado, legumbres)'),
              Text('• Granos integrales con moderación'),
              Text('• Frutas con bajo índice glucémico'),
              Text('• Grasas saludables (aguacate, frutos secos)'),

              SizedBox(height: 16),

              // Alimentos a evitar
              Text(
                'Alimentos a Limitar:',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.red[700]),
              ),
              SizedBox(height: 8),
              Text('• Azúcares refinados y dulces',
                  style: TextStyle(color: Colors.red[600])),
              Text('• Harinas refinadas',
                  style: TextStyle(color: Colors.red[600])),
              Text('• Bebidas azucaradas',
                  style: TextStyle(color: Colors.red[600])),
              Text('• Alimentos procesados altos en sodio',
                  style: TextStyle(color: Colors.red[600])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Generar PDF del plan nutricional
            },
            icon: Icon(Icons.picture_as_pdf),
            label: Text('Generar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Métodos para cálculos nutricionales
  int _calculateDailyCalories(Patient patient) {
    // Fórmula básica considerando edad, peso y actividad
    double bmr = patient.weight != null
        ? (patient.age > 30 ? 1500 : 1800) + (patient.weight! * 10)
        : 1800;
    return bmr.round();
  }

  int _calculateCarbs(Patient patient) {
    int calories = _calculateDailyCalories(patient);
    return ((calories * 0.50) / 4).round(); // 50% de calorías, 4 kcal/g
  }

  int _calculateProtein(Patient patient) {
    int calories = _calculateDailyCalories(patient);
    return ((calories * 0.20) / 4).round(); // 20% de calorías, 4 kcal/g
  }

  int _calculateFats(Patient patient) {
    int calories = _calculateDailyCalories(patient);
    return ((calories * 0.30) / 9).round(); // 30% de calorías, 9 kcal/g
  }
}
