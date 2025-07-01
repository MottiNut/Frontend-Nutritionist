import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import 'package:lottie/lottie.dart';

import 'PatientAvatarWidget.dart';
import 'PatientDetailScreen.dart';

class DiabetesPatientsScreenn extends StatefulWidget {
  const DiabetesPatientsScreenn({Key? key}) : super(key: key);

  @override
  State<DiabetesPatientsScreenn> createState() =>
      _DiabetesPatientsScreenState();
}

class _DiabetesPatientsScreenState extends State<DiabetesPatientsScreenn> {
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

      // Obtener y guardar el token
      String? token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token de autenticación no encontrado');
      }

      _authToken = token;

      print('🔍 Cargando pacientes con token: ${token.substring(0, 10)}...');

      final patients = await nutritionistService.getAllPatients(
        chronicDisease: _selectedFilter == 'Todos' ? null : _selectedFilter,
        sortBy: _sortBy,
        order: _sortOrder,
        token: token,
      );

      print('📊 Total de pacientes obtenidos: ${patients.length}');

      // 🔧 SOLUCIÓN 2: Filtrado más flexible para diabetes
      final diabetesPatients = patients.where((p) {
        if (p.chronicDisease == null) return false;

        final disease = p.chronicDisease!.toLowerCase();

        // Lista de términos relacionados con diabetes
        final diabetesTerms = [
          'diabetes',
          'diabético',
          'diabética',
          'diabetico',
          'diabetica',
          'tipo 1',
          'tipo 2',
          'type 1',
          'type 2',
          'dm1',
          'dm2',
          'dmt1',
          'dmt2',
          'diabetes mellitus',
          'diabetes tipo',
          'diabetes type'
        ];

        return diabetesTerms.any((term) => disease.contains(term));
      }).toList();

      print(
          '🩺 Pacientes con diabetes encontrados: ${diabetesPatients.length}');

      // Imprimir detalles para debug
      for (var patient in diabetesPatients) {
        print(
            '👤 Paciente: ${patient.fullName} - Enfermedad: ${patient.chronicDisease}');
      }

      setState(() {
        _patients = diabetesPatients;
        _filteredPatients = diabetesPatients;
        _isLoading = false;
      });

      if (diabetesPatients.isEmpty && patients.isNotEmpty) {
        // Si no hay pacientes con diabetes pero sí hay pacientes en general
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

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información'),
        content: const Text(
            'Se encontraron pacientes en el sistema, pero ninguno tiene diabetes registrada como enfermedad crónica.\n\n'
            '¿Deseas ver todos los pacientes o crear un nuevo paciente con diabetes?'),
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
              /*Navigator.of(context).pop();
              // Navegar a vista de todos los pacientes
              _navigateToAllPatients();*/
            },
            child: const Text('Ver Todos'),
          ),
        ],
      ),
    );
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
        if (_selectedFilter != 'Todos') {
          if (_selectedFilter == 'Tipo 1') {
            matchesFilter =
                patient.chronicDisease?.toLowerCase().contains('tipo 1') ==
                        true ||
                    patient.chronicDisease?.toLowerCase().contains('type 1') ==
                        true;
          } else if (_selectedFilter == 'Tipo 2') {
            matchesFilter =
                patient.chronicDisease?.toLowerCase().contains('tipo 2') ==
                        true ||
                    patient.chronicDisease?.toLowerCase().contains('type 2') ==
                        true;
          }
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ordenar por',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...['fullName', 'age', 'bmi', 'createdAt'].map((field) {
                final labels = {
                  'fullName': 'Nombre',
                  'age': 'Edad',
                  'bmi': 'IMC',
                  'createdAt': 'Fecha de registro'
                };
                return ListTile(
                  title: Text(labels[field]!),
                  trailing: _sortBy == field
                      ? Icon(
                    _sortOrder == 'asc'
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: Colors.orange,
                  )
                      : null,
                  onTap: () {
                    setState(() {
                      if (_sortBy == field) {
                        _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
                      } else {
                        _sortBy = field;
                        _sortOrder = 'asc';
                      }
                    });
                    Navigator.pop(context);
                    _loadPatients();
                  },
                );
              }).toList(),
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

  String _getDiabetesType(String? chronicDisease) {
    if (chronicDisease == null) return 'T?';
    final disease = chronicDisease.toLowerCase();
    if (disease.contains('tipo 1') || disease.contains('type 1')) return 'T1';
    if (disease.contains('tipo 2') || disease.contains('type 2')) return 'T2';
    return 'TD';
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
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
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
          title: const Text(
            'Pacientes con Diabetes',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list : Icons.grid_view,
                color: Colors.orange,
              ),
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
          ],
        ),
        body: Column(
          children: [
            // Filtros superiores (mantén el código existente)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Botones de filtro de tipo de diabetes
                  Row(
                    children: [
                      _buildFilterChip('Todos', _selectedFilter == 'Todos'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tipo 1', _selectedFilter == 'Tipo 1'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tipo 2', _selectedFilter == 'Tipo 2'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Barra de búsqueda
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar paciente...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        suffixIcon: Icon(Icons.mic, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                              size: 14,
                            ),
                            label: const Text(
                              'Ordenar',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          ),
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
                color: Colors.orange,
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
                                            const EdgeInsets.only(bottom: 12),
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
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToCreatePatient,
          backgroundColor: const Color(0xFF00A693),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Nuevo Paciente',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

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
                ? 'No se encontraron pacientes'
                : 'No hay pacientes con diabetes',
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
                backgroundColor: Colors.orange,
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

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        _filterPatients();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.orange.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.orange : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(PatientProfile patient) {
    final diabetesType = _getDiabetesType(patient.chronicDisease);
    final statusColor = _getStatusColor(patient);
    final statusText = _getStatusText(patient);

    // Determinar el color y asset según el tipo de diabetes
    Color typeColor;
    String nextIconAsset;

    if (diabetesType == 'T1') {
      typeColor = const Color(0xFF00A693);
      nextIconAsset = 'assets/images/next_icon.svg';
    } else if (diabetesType == 'T2') {
      typeColor = const Color(0xFFFF6B35);
      nextIconAsset = 'assets/images/next_orange.svg';
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
                            ),
                            child: Center(
                              child: PatientAvatarWidget(
                                patient: patient,
                                statusColor: statusColor,
                                token: _authToken ?? '',
                                size: 60,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: typeColor,
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
    final diabetesType = _getDiabetesType(patient.chronicDisease);
    final statusColor = _getStatusColor(patient);
    final statusText = _getStatusText(patient);

    // Determinar el asset del ícono según el tipo de diabetes
    String nextIconAsset;
    if (diabetesType == 'T1') {
      nextIconAsset = 'assets/images/next_orange.svg';
    } else if (diabetesType == 'T2') {
      nextIconAsset = 'assets/images/next_orange.svg';
    } else {
      nextIconAsset = 'assets/images/next_orange.svg';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToPatientDetail(patient),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(width: 0.2, color: AppColors.secondary),
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
              // IZQUIERDA: Avatar (30% del ancho)
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar usando tu PatientAvatarWidget
                    PatientAvatarWidget(
                      patient: patient,
                      statusColor: statusColor,
                      token: _authToken ?? '',
                      size: 50,
                    ),
                  ],
                ),
              ),

              // DERECHA: Información del paciente (70% del ancho)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                      // Información adicional
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
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
                            Icon(
                              Icons.monitor_weight_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: statusColor.withOpacity(0.3)),
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
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                nextIconAsset,
                                width: 30,
                                height: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

// Pantalla de crear paciente (placeholder)
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
