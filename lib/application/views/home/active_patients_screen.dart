import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../../configuration/themes/app_colors.dart';
import '../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import '../../../domain/services/auth_provider.dart';
import '../../skeletons/patients_list_skeleton.dart';
import '../patients/categorys_patogys/news/PatientDetailScreen.dart';

class ActivePatientsScreen extends StatefulWidget {
  final NutritionistService nutritionistService;

  const ActivePatientsScreen({
    Key? key,
    required this.nutritionistService,
  }) : super(key: key);

  @override
  State<ActivePatientsScreen> createState() => _ActivePatientsScreenState();
}

class _ActivePatientsScreenState extends State<ActivePatientsScreen> {
  List<PatientProfile> activePatients = [];
  List<PatientProfile> filteredPatients = [];
  Map<int, bool> patientsWithHistory = {};
  Map<int, MedicalHistory?> latestHistories = {};
  bool isLoading = true;
  bool isSearching = false;
  String? error;
  String searchQuery = '';
  String selectedFilter = 'all';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadActivePatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadActivePatients() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null) {
        throw Exception('Token de autenticación no disponible');
      }

      final patients = await widget.nutritionistService.getAllPatients(
        token: authProvider.token!,
        sortBy: 'fullName',
        order: 'asc',
      );

      activePatients = patients.where((patient) => true).toList();

      // 🆕 NUEVO: Cargar información del historial para cada paciente
      await _loadPatientsHistoryInfo(authProvider.token!);

      filteredPatients = List.from(activePatients);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = _getErrorMessage(e);
      });
    }
  }

  Future<void> _loadPatientsHistoryInfo(String token) async {
    for (final patient in activePatients) {
      try {
        final histories = await widget.nutritionistService.getPatientHistory(
          patient.patientId,
          token,
        );

        patientsWithHistory[patient.patientId] = histories.isNotEmpty;
        if (histories.isNotEmpty) {
          // Ordenar por fecha más reciente
          histories
              .sort((a, b) => b.consultationDate.compareTo(a.consultationDate));
          latestHistories[patient.patientId] = histories.first;
        }
      } catch (e) {
        patientsWithHistory[patient.patientId] = false;
        latestHistories[patient.patientId] = null;
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('Token')) {
      return 'Sesión expirada. Inicie sesión nuevamente.';
    } else if (error.toString().contains('Connection')) {
      return 'Error de conexión. Verifique su internet.';
    }
    return 'Error al cargar pacientes: ${error.toString()}';
  }

  // Método modificado para simular búsqueda con delay
  void _filterPatients() async {
    if (searchQuery.isNotEmpty || selectedFilter != 'all') {
      setState(() {
        isSearching = true;
      });

      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      filteredPatients = activePatients.where((patient) {

        final query = searchQuery.toLowerCase();
        final matchesSearch =
            query.isEmpty || _matchesSearchCriteria(patient, query);

        final matchesFilter = _matchesFilterCriteria(patient);

        return matchesSearch && matchesFilter;
      }).toList();

      isSearching = false;
    });
  }

  bool _matchesSearchCriteria(PatientProfile patient, String query) {
    // Búsqueda en información básica
    if (patient.fullName.toLowerCase().contains(query) ||
        patient.email.toLowerCase().contains(query) ||
        (patient.phone?.toLowerCase().contains(query) ?? false)) {
      return true;
    }

    if ((patient.chronicDisease?.toLowerCase().contains(query) ?? false) ||
        (patient.allergies?.toLowerCase().contains(query) ?? false) ||
        (patient.dietaryPreferences?.toLowerCase().contains(query) ?? false) ||
        (patient.bmiCategory?.toLowerCase().contains(query) ?? false) ||
        (patient.gender?.toLowerCase().contains(query) ?? false)) {
      return true;
    }

    // Búsqueda por edad
    if (patient.age != null && query.contains(patient.age.toString())) {
      return true;
    }

    // Búsqueda en historial más reciente
    final latestHistory = latestHistories[patient.patientId];
    if (latestHistory != null) {
      if ((latestHistory.eatingHabits?.toLowerCase().contains(query) ??
              false) ||
          (latestHistory.nutritionalObjectives?.toLowerCase().contains(query) ??
              false) ||
          (latestHistory.professionalNotes?.toLowerCase().contains(query) ??
              false)) {
        return true;
      }
    }

    return false;
  }

  bool _matchesFilterCriteria(PatientProfile patient) {
    switch (selectedFilter) {
      case 'all':
        return true;
      case 'chronic':
        return patient.chronicDisease != null;
      case 'no_chronic':
        return patient.chronicDisease == null;
      case 'with_history':
        return patientsWithHistory[patient.patientId] == true;
      case 'no_history':
        return patientsWithHistory[patient.patientId] == false;
      case 'high_bmi':
        return patient.bmi != null && patient.bmi! >= 25;
      case 'recent_activity':
        final latestHistory = latestHistories[patient.patientId];
        if (latestHistory == null) return false;
        final daysSinceLastConsultation =
            DateTime.now().difference(latestHistory.consultationDate).inDays;
        return daysSinceLastConsultation <= 30;
      default:
        return true;
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
    });
    _filterPatients();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      selectedFilter = filter;
    });
    _filterPatients();
  }

  DiseaseTypes _getDiseaseTypeFromPatient(PatientProfile patient) {
    final chronicDisease = patient.chronicDisease?.toLowerCase() ?? '';

    if (chronicDisease.contains('diabetes')) {
      return DiseaseTypes.diabetes;
    } else if (chronicDisease.contains('hipertension') || chronicDisease.contains('presión') || chronicDisease.contains('hipertension arterial')) {
      return DiseaseTypes.hipertension;
    } else if (chronicDisease.contains('obesidad') || chronicDisease.contains('sobrepeso')) {
      return DiseaseTypes.obesity;
    } else if (chronicDisease.isNotEmpty) {
      return DiseaseTypes.general;
    } else {
      return DiseaseTypes.none;
    }
  }

  void _navigateToPatientDetail(PatientProfile patient) {
    final diseaseType = _getDiseaseTypeFromPatient(patient);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreens(
          patient: patient,
          diseaseType: diseaseType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary1),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pacientes Activos',
          style: TextStyle(
            color: AppColors.textPrimary1,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${filteredPatients.length}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _buildContent(),
          ),
          SizedBox(
            height: 40,
          )
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Campo de búsqueda mejorado
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: searchQuery.isNotEmpty
                    ? AppColors.primary
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, condición, email, notas...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: searchQuery.isNotEmpty
                      ? AppColors.primary
                      : Colors.grey[500],
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        color: Colors.grey[500],
                      ),
                    if (isSearching)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filtros mejorados con scroll horizontal
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Todos', 'all', Icons.people),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'Con historial', 'with_history', Icons.history),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'Sin historial', 'no_history', Icons.history_outlined),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'Con condiciones', 'chronic', Icons.medical_services),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'Sin condiciones', 'no_chronic', Icons.health_and_safety),
                const SizedBox(width: 8),
                _buildFilterChip('IMC Alto', 'high_bmi', Icons.fitness_center),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'Actividad reciente', 'recent_activity', Icons.trending_up),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = selectedFilter == value;
    final count = _getFilterCount(value);

    return GestureDetector(
      onTap: () => _onFilterChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (count > 0 && !isSelected) ...[
              const SizedBox(width: 4),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getFilterCount(String filter) {
    return activePatients.where((patient) {
      switch (filter) {
        case 'with_history':
          return patientsWithHistory[patient.patientId] == true;
        case 'no_history':
          return patientsWithHistory[patient.patientId] == false;
        case 'chronic':
          return patient.chronicDisease != null;
        case 'no_chronic':
          return patient.chronicDisease == null;
        case 'high_bmi':
          return patient.bmi != null && patient.bmi! >= 25;
        case 'recent_activity':
          final latestHistory = latestHistories[patient.patientId];
          if (latestHistory == null) return false;
          final daysSinceLastConsultation =
              DateTime.now().difference(latestHistory.consultationDate).inDays;
          return daysSinceLastConsultation <= 30;
        default:
          return true;
      }
    }).length;
  }

  Widget _buildContent() {
    // Skeleton para carga inicial
    if (isLoading) {
      return const PatientsListSkeleton();
    }

    // Skeleton para búsqueda
    if (isSearching) {
      return _buildSearchSkeleton();
    }

    if (error != null) {
      return _buildErrorState();
    }

    if (filteredPatients.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: loadActivePatients,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = filteredPatients[index];
          return _buildPatientCard(patient);
        },
      ),
    );
  }

  Widget _buildSearchSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Menos elementos que el skeleton principal
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              // Avatar skeleton
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              // Información skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          height: 20,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 20,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar pacientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade300,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textLDark,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: loadActivePatients,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/empty_patients.svg',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 24),
          const Text(
            'No se encontraron pacientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'No hay pacientes que coincidan con "$searchQuery"'
                : 'No tienes pacientes activos registrados',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textLDark,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(PatientProfile patient) {
    final hasHistory = patientsWithHistory[patient.patientId] ?? false;
    final latestHistory = latestHistories[patient.patientId];

    return GestureDetector(
      onTap: () => _navigateToPatientDetail(patient),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasHistory
                ? AppColors.primary
                : Colors.grey,
            width: 0.4
          ),
        ),
        child: IntrinsicHeight(
          // Permite que la altura se adapte al contenido

          child: Stack(
            children: [
              // Contenido principal
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Foto del paciente
                  _buildPatientPhoto(patient, hasHistory),

                  // Información del paciente
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nombre
                          Padding(
                            padding:
                                EdgeInsets.only(right: !hasHistory ? 60 : 16),
                            child: Text(
                              patient.fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary1,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Género y edad
                          Row(
                            children: [
                              Text(
                                patient.gender ?? 'No especificado',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              _svgDivider(),
                              Text(
                                '• ${patient.age ?? ''} años',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Chips
                          _buildPatientInfoChips(patient),
                          // Última consulta
                          if (hasHistory && latestHistory != null) ...[
                            const SizedBox(height: 12),
                            _buildLastConsultationInfo(latestHistory),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(5),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),

              // Badge "Nuevo"
              if (!hasHistory)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _buildNewPatientBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientPhoto(PatientProfile patient, bool hasHistory) {
    return Container(
      width: 100,
      constraints: const BoxConstraints(minHeight: 100),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
      ),
      child: Stack(
        children: [
          // Imagen que se adapta a la altura completa del contenedor
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: FutureBuilder<Uint8List?>(
                future: widget.nutritionistService.getPatientProfileImage(
                  patient.patientId,
                  Provider.of<AuthProvider>(context, listen: false).token!,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      width: 100,
                    );
                  }

                  // Placeholder adaptable a la altura
                  return Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        hasHistory
                            ? 'assets/images/user_placeholder_orange.svg'
                            : 'assets/images/user_placeholder_esmer.svg',
                        width: 60,
                        height: 70,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.primary.withOpacity(0.2),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(patient.fullName),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /*// Indicador de historial (solo para pacientes recurrentes)
          if (hasHistory)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.history,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),*/
        ],
      ),
    );
  }

  Widget _svgDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SvgPicture.asset(
        'assets/images/line_divider.svg',
        height: 10,
      ),
    );
  }

  Widget _buildLastConsultationInfo(MedicalHistory latestHistory) {
    final daysSince =
        DateTime.now().difference(latestHistory.consultationDate).inDays;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: AppColors.primary.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Última consulta: ${_formatDate(latestHistory.consultationDate)}',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.primary.withOpacity(0.6),
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfoChips(PatientProfile patient) {
    List<Widget> chips = [];

    if (patient.chronicDisease != null && patient.chronicDisease!.isNotEmpty) {
      chips.add(_buildElegantChip(
        patient.chronicDisease!,
        Icons.medical_services_outlined,
        AppColors.errorIcon.withOpacity(0.1),
        AppColors.errorIcon,
      ));
    }

    if (patient.bmi != null) {
      final bmiColor = _getBMIColor(patient.bmi!);
      chips.add(_buildElegantChip(
        'IMC ${patient.bmi!.toStringAsFixed(1)}',
        Icons.monitor_weight_outlined,
        bmiColor.withOpacity(0.1),
        bmiColor,
      ));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }

  Widget _buildElegantChip(
      String text, IconData icon, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.2), width: 0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPatientBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.checkValidation,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nuevo',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

// Función auxiliar para determinar el color del IMC
  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return AppColors.primary;
    if (bmi < 25) return AppColors.checkValidation;
    if (bmi < 30) return AppColors.secondary;
    return AppColors.errorIcon; // Obesidad
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Ayer';
    if (difference < 7) return 'Hace $difference días';
    if (difference < 30) return 'Hace ${(difference / 7).floor()} semanas';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'P';
  }
}
