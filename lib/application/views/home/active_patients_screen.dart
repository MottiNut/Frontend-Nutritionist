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
  bool isLoading = true;
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

      // Filtrar solo pacientes activos (asumiendo que no tienen fecha de inactivación)
      activePatients = patients.where((patient) {
        // Aquí puedes agregar la lógica específica para determinar si un paciente está activo
        // Por ahora, consideramos activos a todos los pacientes
        return true;
      }).toList();

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

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('Token')) {
      return 'Sesión expirada. Inicie sesión nuevamente.';
    } else if (error.toString().contains('Connection')) {
      return 'Error de conexión. Verifique su internet.';
    }
    return 'Error al cargar pacientes: ${error.toString()}';
  }

  void _filterPatients() {
    setState(() {
      filteredPatients = activePatients.where((patient) {
        final matchesSearch = patient.fullName
            .toLowerCase()
            .contains(searchQuery.toLowerCase());

        final matchesFilter = selectedFilter == 'all' ||
            (selectedFilter == 'chronic' && patient.chronicDisease != null && patient.chronicDisease!.isNotEmpty && patient.chronicDisease!.toLowerCase() != 'ninguna') ||
            (selectedFilter == 'no_chronic' && (patient.chronicDisease == null || patient.chronicDisease!.isEmpty || patient.chronicDisease!.toLowerCase() == 'ninguna')) ||
            (selectedFilter == 'high_imc' && _hasHighIMC(patient)) ||
            (selectedFilter == 'recent' && _isRecentPatient(patient)) ||
            (selectedFilter == 'diabetes' && _hasDiabetes(patient)) ||
            (selectedFilter == 'hypertension' && _hasHypertension(patient)) ||
            (selectedFilter == 'obesity' && _hasObesity(patient)) ||
            (selectedFilter == 'multiple' && _hasMultipleDiseases(patient));

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  bool _hasHighIMC(PatientProfile patient) {
    // IMC alto: mayor o igual a 25
    return patient.bmi != null && patient.bmi! >= 25.0;
  }

  bool _isRecentPatient(PatientProfile patient) {
    // Paciente reciente: registrado en los últimos 7 días
    final now = DateTime.now();
    final difference = now.difference(patient.createdAt);
    return difference.inDays <= 7;
  }

  bool _hasNoHistory(PatientProfile patient) {
    // Determinar si el paciente no tiene historial médico
    // Esto requeriría una llamada adicional al API o un campo en el perfil
    // Por ahora, asumimos que si no tiene enfermedad crónica registrada, es nuevo
    return patient.chronicDisease == null ||
        patient.chronicDisease!.isEmpty ||
        patient.chronicDisease!.toLowerCase() == 'ninguna';
  }

  bool _hasDiabetes(PatientProfile patient) {
    if (patient.chronicDisease == null || patient.chronicDisease!.isEmpty) {
      return false;
    }

    final disease = patient.chronicDisease!.toLowerCase();
    return disease.contains('diabetes') ||
        disease.contains('diabético') ||
        disease.contains('diabética');
  }

  bool _hasHypertension(PatientProfile patient) {
    if (patient.chronicDisease == null || patient.chronicDisease!.isEmpty) {
      return false;
    }

    final disease = patient.chronicDisease!.toLowerCase();
    return disease.contains('hipertensión') ||
        disease.contains('hipertension') ||
        (disease.contains('presión') && disease.contains('alta')) ||
        (disease.contains('presion') && disease.contains('alta'));
  }

  bool _hasObesity(PatientProfile patient) {
    // Verificar por enfermedad crónica
    if (patient.chronicDisease != null && patient.chronicDisease!.isNotEmpty) {
      final disease = patient.chronicDisease!.toLowerCase();
      if (disease.contains('obesidad') ||
          disease.contains('obeso') ||
          disease.contains('obesa') ||
          disease.contains('sobrepeso')) {
        return true;
      }
    }

    // Verificar por IMC
    if (patient.bmi != null && patient.bmi! >= 25.0) {
      return true;
    }

    // Verificar por categoría de IMC
    if (patient.bmiCategory != null) {
      final category = patient.bmiCategory!.toLowerCase();
      return category.contains('sobrepeso') ||
          category.contains('obesidad') ||
          category.contains('obeso') ||
          category.contains('obesa');
    }

    return false;
  }

  bool _hasMultipleDiseases(PatientProfile patient) {
    if (patient.chronicDisease == null || patient.chronicDisease!.isEmpty) {
      return false;
    }

    final disease = patient.chronicDisease!.toLowerCase();
    int diseaseCount = 0;

    if (disease.contains('diabetes') ||
        disease.contains('diabético') ||
        disease.contains('diabética')) {
      diseaseCount++;
    }

    if (disease.contains('hipertensión') ||
        disease.contains('hipertension')) {
      diseaseCount++;
    }

    if (disease.contains('obesidad') ||
        disease.contains('obeso') ||
        disease.contains('obesa') ||
        disease.contains('sobrepeso')) {
      diseaseCount++;
    }

    return diseaseCount > 1;
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

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      _searchController.clear();
    });
    _filterPatients();
  }

  // Método para obtener solo chips de patologías
  List<Widget> _getPatientInfoChips(PatientProfile patient) {
    List<Widget> chips = [];
    final isNewPatient = _hasNoHistory(patient);

    if (isNewPatient) {
      // Para pacientes nuevos: solo IMC (si tiene)
      if (patient.bmi != null) {
        chips.add(_buildInfoChip('IMC: ${patient.bmi!.toStringAsFixed(1)}', Icons.monitor_weight));
      }
    } else {
      // Para pacientes con historial: máximo 2 patologías
      List<String> diseases = [];
      if (patient.chronicDisease != null &&
          patient.chronicDisease!.isNotEmpty &&
          patient.chronicDisease!.toLowerCase() != 'ninguna') {

        final diseaseText = patient.chronicDisease!.toLowerCase();

        if (diseaseText.contains('diabetes')) diseases.add('Diabetes');
        if (diseaseText.contains('hipertensión') || diseaseText.contains('hipertension')) diseases.add('Hipertensión');
        if (diseaseText.contains('obesidad') || diseaseText.contains('obeso') || diseaseText.contains('obesa')) diseases.add('Obesidad');

        // Si no encontró patologías específicas, usar el texto original (cortado)
        if (diseases.isEmpty) {
          String originalDisease = patient.chronicDisease!;
          if (originalDisease.length > 12) {
            originalDisease = '${originalDisease.substring(0, 12)}...';
          }
          diseases.add(originalDisease);
        }
      }

      // Agregar máximo 2 patologías
      for (int i = 0; i < diseases.length && i < 2; i++) {
        chips.add(_buildInfoChip(diseases[i], Icons.medical_services));
      }
    }

    return chips;
  }

  // Método para obtener texto de edad y género
  String _getAgeGenderText(PatientProfile patient) {
    List<String> info = [];

    if (patient.age != null) {
      info.add('${patient.age} años');
    }

    if (patient.gender != null && patient.gender!.isNotEmpty) {
      info.add(_getGenderText(patient.gender!));
    }

    return info.join(' • ');
  }

  String _getGenderText(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'masculino':
      case 'm':
        return 'Masculino';
      case 'female':
      case 'femenino':
      case 'f':
        return 'Femenino';
      default:
        return gender;
    }
  }

  // Widget para mostrar chips en máximo 2 filas
  Widget _buildChipsGrid(PatientProfile patient) {
    final chips = _getPatientInfoChips(patient);

    if (chips.isEmpty) return const SizedBox.shrink();

    // Si hay 3 o menos chips, mostrar en una fila
    if (chips.length <= 3) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips
              .map((chip) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: chip,
          ))
              .toList(),
        ),
      );
    }

    // Si hay más de 3 chips, dividir en 2 filas
    final firstRow = chips.take(3).toList();
    final secondRow = chips.skip(3).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primera fila
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: firstRow
                .map((chip) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: chip,
            ))
                .toList(),
          ),
        ),
        if (secondRow.isNotEmpty) ...[
          const SizedBox(height: 4),
          // Segunda fila
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: secondRow
                  .map((chip) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: chip,
              ))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 1, 12, 3),
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
          // Barra de búsqueda con X para limpiar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar pacientes...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                  onPressed: _clearSearch,
                  splashRadius: 16,
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Scroll horizontal con iconos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', 'all', Icons.group),
                const SizedBox(width: 8),
                _buildFilterChip('Con condiciones', 'chronic', Icons.medical_services),
                const SizedBox(width: 8),
                _buildFilterChip('Sin condiciones', 'no_chronic', Icons.health_and_safety),
                const SizedBox(width: 8),
                _buildFilterChip('IMC Alto', 'high_imc', Icons.monitor_weight),
                const SizedBox(width: 8),
                _buildFilterChip('Recientes', 'recent', Icons.new_releases),
                const SizedBox(width: 8),
                _buildFilterChip('Diabetes', 'diabetes', Icons.favorite),
                const SizedBox(width: 8),
                _buildFilterChip('Hipertensión', 'hypertension', Icons.favorite_border),
                const SizedBox(width: 8),
                _buildFilterChip('Obesidad', 'obesity', Icons.line_weight),
                const SizedBox(width: 8),
                _buildFilterChip('Múltiples', 'multiple', Icons.assignment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () => _onFilterChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const PatientsListSkeleton();
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
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredPatients.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final patient = filteredPatients[index];
          return _buildPatientCard(patient);
        },
      ),
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
    final isNewPatient = _hasNoHistory(patient);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToPatientDetail(patient),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 0.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                      child: _buildPatientAvatar(patient),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre del paciente
                          Text(
                            patient.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Edad y género en una fila (sin chips)
                          if (_getAgeGenderText(patient).isNotEmpty)
                            Text(
                              _getAgeGenderText(patient),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(height: 8),

                          // Chips en máximo 2 filas
                          Flexible(
                            child: _buildChipsGrid(patient),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isNewPatient)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Nuevo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientAvatar(PatientProfile patient) {
    return FutureBuilder<Uint8List?>(
      future: widget.nutritionistService.getPatientProfileImage(
        patient.patientId,
        Provider.of<AuthProvider>(context, listen: false).token!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2,));
        }

        if (snapshot.hasData && snapshot.data != null) {

          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        }

        try {
          return Container(
            color: AppColors.primary.withOpacity(0.1),
            alignment: Alignment.center,
            child: SizedBox(
              width: 70,
              height: 70,
              child: SvgPicture.asset(
                'assets/images/user_placeholder_esmer.svg',
                fit: BoxFit.contain,
                placeholderBuilder: (context) => _buildInitials(patient),
              ),
            ),
          );
        } catch (e) {

          return _buildInitials(patient);
        }
      },
    );
  }

  Widget _buildInitials(PatientProfile patient) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      alignment: Alignment.center,
      child: Text(
        _getInitials(patient.fullName),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }


  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPatientDetail(PatientProfile patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreens(patient: patient),
      ),
    ).then((_) {
      // _loadPatients();
    });
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