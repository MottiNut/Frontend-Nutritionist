import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import 'package:lottie/lottie.dart';

import 'PatientAvatarWidget.dart';
import 'PatientDetailScreen.dart';

class HypertensionPatientsScreen  extends StatefulWidget {
  const HypertensionPatientsScreen ({Key? key}) : super(key: key);

  @override
  State<HypertensionPatientsScreen > createState() =>
      _HypertensionPatientsScreenState ();
}

class _HypertensionPatientsScreenState extends State<HypertensionPatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';
  String _sortBy = 'fullName';
  String _sortOrder = 'asc';
  List<PatientProfile> _patients = [];
  List<PatientProfile> _filteredPatients = [];
  bool _isLoading = true;
  bool _isGridView = false;

  String? _errorMessage;

  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_filterPatients);
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final nutritionistService = NutritionistService();

      String? token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token de autenticación no encontrado');
      }

      _authToken = token;

      print('🔍 Cargando pacientes con hipertensión con token: ${token.substring(0, 10)}...');

      // Llamada directa al método de hipertensión
      final hypertensionPatients = await nutritionistService.getHypertensionPatients(
        sortBy: _sortBy,
        order: _sortOrder,
        token: token,
      );

      print('🩺 Pacientes con hipertensión encontrados: ${hypertensionPatients.length}');

      setState(() {
        _patients = hypertensionPatients;
        _filteredPatients = hypertensionPatients;
        _isLoading = false;
      });

      if (hypertensionPatients.isEmpty) {
        _showInfoDialog();
      }
    } catch (e) {
      print('❌ Error al cargar pacientes: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      _showErrorSnackBar('Error al cargar pacientes: $e');
    }
  }

  // En _showInfoDialog, mejorar las opciones
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información'),
        content: const Text(
            'Se encontraron pacientes en el sistema, pero ninguno tiene hipertensión registrada como enfermedad crónica.\n\n'
                '¿Deseas ver todos los pacientes o crear un nuevo paciente con hipertensión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToCreatePatient();
            },
            child: const Text('Crear Paciente'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadAllPatientsAsFallback(); // Nueva función
            },
            child: const Text('Ver Todos'),
          ),
        ],
      ),
    );
  }

// Nueva función para cargar todos los pacientes como fallback
  Future<void> _loadAllPatientsAsFallback() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final nutritionistService = NutritionistService();
      String? token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token de autenticación no encontrado');
      }

      // Cargar todos los pacientes sin filtrar
      final allPatients = await nutritionistService.getAllPatients(
        sortBy: _sortBy,
        order: _sortOrder,
        token: token,
      );

      setState(() {
        _patients = allPatients;
        _filteredPatients = allPatients;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mostrando todos los pacientes (modo fallback)'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('❌ Error al cargar todos los pacientes: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar pacientes: ${e.toString()}';
      });
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('❌ Error al obtener token: $e');
      return null;
    }
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _patients.where((patient) {
        final matchesSearch = patient.fullName.toLowerCase().contains(query) ||
            patient.email.toLowerCase().contains(query) ||
            (patient.phone?.toLowerCase().contains(query) ?? false);

        bool matchesFilter = true;
        if (_selectedFilter == 'Grado 1') {
          matchesFilter = patient.chronicDisease?.toLowerCase().contains('grado 1') == true ||
              patient.chronicDisease?.toLowerCase().contains('leve') == true;
        } else if (_selectedFilter == 'Grado 2') {
          matchesFilter = patient.chronicDisease?.toLowerCase().contains('grado 2') == true ||
              patient.chronicDisease?.toLowerCase().contains('moderada') == true;
        } else if (_selectedFilter == 'Grado 3') {
          matchesFilter = patient.chronicDisease?.toLowerCase().contains('grado 3') == true ||
              patient.chronicDisease?.toLowerCase().contains('severa') == true;
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 Pequeña barra superior tipo "handle" para mejor UX
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const Text(
                'Ordenar por',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),

              // 🔹 Opciones más compactas
              ...['fullName', 'age', 'bmi', 'createdAt'].map((field) {
                final labels = {
                  'fullName': 'Nombre',
                  'age': 'Edad',
                  'bmi': 'IMC',
                  'createdAt': 'Fecha de registro'
                };

                final bool isSelected = _sortBy == field;
                final bool isAsc = _sortOrder == 'asc';

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _sortOrder = isAsc ? 'desc' : 'asc';
                      } else {
                        _sortBy = field;
                        _sortOrder = 'asc';
                      }
                    });
                    Navigator.pop(context);
                    _loadPatients();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.backgroundHipertencion.withOpacity(0.08)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          labels[field]!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.backgroundHipertencion : Colors.black87,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            isAsc ? Icons.arrow_upward : Icons.arrow_downward,
                            color: AppColors.backgroundHipertencion,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 4),
            ],
          ),
        ),
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
      _loadPatients();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(PatientProfile patient) {
    if (patient.bmi == null) return Colors.grey;

    // Colores específicos para hipertensión
    if (patient.bmi! < 18.5) return Colors.blue;
    if (patient.bmi! < 25) return Colors.green;
    if (patient.bmi! < 30) return Colors.orange;
    return Colors.red;
  }

  String _getStatusText(PatientProfile patient) {
    if (patient.bmi == null) return 'Sin datos';

    if (patient.bmi! < 18.5) return 'Bajo peso';
    if (patient.bmi! < 25) return 'Controlado';
    if (patient.bmi! < 30) return 'Atención';
    return 'Crítico';
  }

// Función para determinar el tipo de hipertensión
  String _getHypertensionType(String? chronicDisease) {
    if (chronicDisease == null) return 'HTA?';
    final disease = chronicDisease.toLowerCase();

    if (disease.contains('grado 1') || disease.contains('leve')) return 'HT1';
    if (disease.contains('grado 2') || disease.contains('moderada')) return 'HT2';
    if (disease.contains('grado 3') || disease.contains('severa')) return 'HT3';

    return 'HT';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.backgroundHipertencion.withOpacity(0.6),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/images/anterior_icon.svg',
              width: 21,
              height: 21,
              color: AppColors.backgroundHipertencion,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'Pacientes con Hipertensión',
            style: TextStyle(
              color: AppColors.backgroundHipertencion,
              fontSize: 19,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list : Icons.grid_view,
                color: AppColors.backgroundHipertencion,
              ),
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
            /* IconButton(
              icon: const Icon(Icons.info_outline, color: AppColors.backgroundHipertencion),
              onPressed: _showDebugInfo,
            ),*/
          ],
        ),
        body: _buildBodyContent(),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar pacientes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadPatients,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.backgroundHipertencion,
                ),
                child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
              ),
             /* const SizedBox(height: 10),
              TextButton(
                onPressed: _showDebugInfo,
                child: const Text('Ver detalles técnicos'),
              ),*/
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
          child: Column(
            children: [
              /*
              Row(
                children: [
                  _buildFilterChip('Todos', _selectedFilter == 'Todos'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Grado 1', _selectedFilter == 'Grado 1'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Grado 2', _selectedFilter == 'Grado 2'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Grado 3', _selectedFilter == 'Grado 3'),
                ],
              ),
                  const SizedBox(height: 16),*/
              // Barra de búsqueda
              Container(
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Buscar paciente...',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      suffixIcon: Icon(Icons.mic, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${_filteredPatients.length} pacientes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showSortOptions,
                        icon: Icon(
                          _sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                        ),
                        label: const Text(
                          'Ordenar',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          foregroundColor: AppColors.backgroundHipertencion,
                          side: const BorderSide(color: AppColors.backgroundHipertencion, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.white,
                        ),
                      ),

                      /* const SizedBox(width: 8),
                          Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              icon: const Icon(Icons.tune, color: Colors.white),
                              onPressed: _showAdvancedFilters,
                            ),
                          ),*/
                    ],
                  ),
                ],
              )

            ],
          ),
        ),
        // Lista de pacientes mejorada
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPatients,
            color: AppColors.backgroundHipertencion,
            backgroundColor: Colors.white,
            child: _isLoading
                ? Center(
                child: Lottie.asset(
                    'assets/loading/palta_saltarina.json',
                    width: 100,
                    height: 100))
                : _filteredPatients.isEmpty
                ? _buildEmptyState()
                : Padding(
              padding: const EdgeInsets.all(16),
              child: _isGridView
                  ? GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filteredPatients.length,
                itemBuilder: (context, index) {
                  return _buildPatientCard(
                      _filteredPatients[index]);
                },
              )
                  : ListView.builder(
                itemCount: _filteredPatients.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(bottom: 8),
                    child: _buildPatientListItem(
                        _filteredPatients[
                        index]), // Nuevo método para lista
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /*void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de Depuración'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Token: ${_authToken != null ? '${_authToken!.substring(0, 20)}...' : 'Nulo'}'),
              const SizedBox(height: 10),
              Text('Pacientes totales: ${_patients.length}'),
              Text('Pacientes filtrados: ${_filteredPatients.length}'),
              const SizedBox(height: 10),
              const Text('Pacientes crudos:'),
              for (var patient in _patients.take(5))
                Text('- ${patient.fullName}: ${patient.chronicDisease ?? "Sin enfermedad"}'),
              if (_patients.length > 5) const Text('... (más pacientes)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadPatients();
            },
            child: const Text('Recargar'),
          ),
        ],
      ),
    );
  }*/

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isNotEmpty
                ? Icons.search_off
                : Icons.person_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No hay pacientes con hipertensión'
                : 'Agrega tu primer paciente hipertenso',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'Agrega tu primer paciente diabético',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _filterPatients();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.backgroundHipertencion,
                foregroundColor: Colors.white,
              ),
              child: const Text('Limpiar búsqueda'),
            ),
          ],
        ],
      ),
    );
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros Avanzados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildFilterSection('Estado de Salud',
                          ['Controlado', 'Atención', 'Crítico', 'Sin datos']),
                      const SizedBox(height: 20),
                      _buildFilterSection(
                          'Género', ['Masculino', 'Femenino', 'Otro']),
                      const SizedBox(height: 20),
                      _buildFilterSection('Rango de Edad', [
                        '18-30 años',
                        '31-50 años',
                        '51-70 años',
                        '70+ años'
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _filterPatients();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return FilterChip(
              label: Text(option),
              selected: false,
              onSelected: (selected) {},
              selectedColor: Colors.orange.withOpacity(0.2),
              checkmarkColor: Colors.orange,
            );
          }).toList(),
        ),
      ],
    );
  }

  void _navigateToCreatePatient() {
    // Navegar a crear nuevo paciente
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePatientScreen(),
      ),
    );
  }

  /*Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        _filterPatients();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.backgroundHipertencion.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.backgroundHipertencion : Colors.grey[300]!,
            width: isSelected ? 1.5 : 0.7,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.backgroundHipertencion : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
*/
  Widget _buildPatientCard(PatientProfile patient) {
    final diabetesType = _getHypertensionType(patient.chronicDisease);
    final statusColor = _getStatusColor(patient);
    final statusText = _getStatusText(patient);

    Color typeColor;
    String nextIconAsset;

    if (diabetesType == 'T1') {
      typeColor = const Color(0xFF00A693);
      nextIconAsset = 'assets/images/next_icon.svg';
    } else if (diabetesType == 'T2') {
      typeColor = AppColors.backgroundHipertencion;
      nextIconAsset = 'assets/images/next_icon.svg';
    } else {
      typeColor = Colors.grey;
      nextIconAsset = 'assets/images/next_icon.svg';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToPatientDetail(patient),
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
                Expanded(
                  flex: 70,
                  child: Container(
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: PatientAvatarWidget(
                            patient: patient,
                            statusColor: AppColors.backgroundHipertencion,
                            token: _authToken ?? '',
                            isCircular: false,
                            borderRadius: 0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Badge del tipo de diabetes
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundHipertencion,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              diabetesType,
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

                // SECCIÓN DE INFORMACIÓN (sin cambios)
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
                                  '${patient.age ?? 0} años',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (patient.bmi != null) ...[
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.monitor_weight_outlined,
                                    size: 11,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'IMC:${patient.bmi!.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: statusColor,
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

  Widget _buildPatientListItem(PatientProfile patient) {
    final statusColor = _getStatusColor(patient);
    final statusText = _getStatusText(patient);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToPatientDetail(patient),
        child: SizedBox( // 🔑 Forzar a ocupar todo el espacio
          width: double.infinity,
          height: 100,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ---------- Fondo principal ----------
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    width: 0.2,
                    color: AppColors.backgroundHipertencion,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar lateral
                    Container(
                      width: 100,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: PatientAvatarWidget(
                        patient: patient,
                        statusColor: AppColors.backgroundHipertencion,
                        token: _authToken ?? '',
                        isCircular: false,
                        customBorderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Info del paciente
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Nombre
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

                            // Edad / IMC
                            Row(
                              children: [
                                Icon(Icons.person_outline,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${patient.age ?? 0} años',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (patient.bmi != null) ...[
                                  const SizedBox(width: 12),
                                  Icon(Icons.monitor_weight_outlined,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'IMC: ${patient.bmi!.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // Estado
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  width: 1,
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/next_icon.svg',
                      width: 26,
                      height: 26,
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


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}


class CreatePatientScreen extends StatelessWidget {
  const CreatePatientScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Paciente'),
      ),
      body: const Center(
        child: Text('Pantalla para crear nuevo paciente'),
      ),
    );
  }
}
