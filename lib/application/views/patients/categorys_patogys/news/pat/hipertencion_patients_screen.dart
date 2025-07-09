import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:mottinutnutriotinist/application/requestSnacbar/snackBar_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../configuration/themes/app_colors.dart';
import '../../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import '../../../../../../domain/services/auth_provider.dart';
import '../PatientDetailScreen.dart';
import 'create_patient_screen.dart';

class HipertencionPatientsScreen extends StatefulWidget {
  const HipertencionPatientsScreen({Key? key}) : super(key: key);

  @override
  State<HipertencionPatientsScreen> createState() =>
      _HipertencionPatientsScreenState();
}

class _HipertencionPatientsScreenState
    extends State<HipertencionPatientsScreen> {
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

  late final NutritionistService _nutritionistService;

  @override
  void initState() {
    super.initState();
    _nutritionistService = NutritionistService();
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

      final hypertensionPatients = patients.where((p) {
        if (p.chronicDisease == null) return false;

        final disease = p.chronicDisease!.toLowerCase();

        // Lista de términos relacionados con hipertensión
        final hypertensionTerms = [
          'hipertensión',
          'hipertension',
          'hipertenso',
          'hipertensa',
          'presión alta',
          'presion alta',
          'hta',
          'hipertensión arterial',
          'hipertension arterial',
          'alta presión',
          'alta presion'
        ];

        return hypertensionTerms.any((term) => disease.contains(term));
      }).toList();

      // Imprimir detalles para debug
      for (var patient in hypertensionPatients) {
        print(
            '👤 Paciente: ${patient.fullName} - Enfermedad: ${patient.chronicDisease}');
      }

      setState(() {
        _patients = hypertensionPatients;
        _filteredPatients = hypertensionPatients;
        _isLoading = false;
      });

      if (hypertensionPatients.isEmpty && patients.isNotEmpty) {
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
        /*if (_selectedFilter != 'Todos') {
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
        }*/

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
                          color: AppColors.backgroundHipertencion,
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
        builder: (context) => PatientDetailScreens(
          patient: patient,
          diseaseType: DiseaseTypes.hipertension,
        ),
      ),
    ).then((_) {
      _loadPatients();
    });
  }

  void _showErrorSnackBar(String message) {
    SnackBarManager.showError(context, message);
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

  String _getHypertensionType(String? chronicDisease) {
    if (chronicDisease == null) return 'H?';
    final disease = chronicDisease.toLowerCase();
    if (disease.contains('leve') || disease.contains('ligera')) return 'HL';
    if (disease.contains('moderada')) return 'HM';
    if (disease.contains('severa') || disease.contains('grave')) return 'HS';
    return 'HTA';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.backgroundHipertencion.withOpacity(0.5),
        statusBarIconBrightness: Brightness.dark,
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
            'Pacientes con Hipertención',
            style: TextStyle(
              color: AppColors.backgroundHipertencion,
              fontSize: 20,
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
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
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
                              _sortOrder == 'asc'
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 14,
                            ),
                            label: const Text(
                              'Ordenar',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              foregroundColor: AppColors.backgroundHipertencion,
                              side: const BorderSide(
                                  color: AppColors.backgroundHipertencion),
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
                              color: AppColors.backgroundHipertencion,
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
                color: AppColors.backgroundHipertencion,
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/loading/palta_saltarina.json',
                              width: 100,
                              height: 100,
                            ),
                            SizedBox(height: 3),
                            Text("Cargando..."),
                          ],
                        ),
                      )
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
                                            _filteredPatients[index]),
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
          backgroundColor: AppColors.backgroundHipertencion,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Nuevo Paciente',
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
                : 'No hay pacientes con hipertensión',
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
                : 'Agrega tu primer paciente hipertenso',
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePatientScreen(
          diseaseType: DiseaseType.hipertension,
        ),
      ),
    );
  }

  Widget _buildPatientCard(PatientProfile patient) {
    final hypertensionType = _getHypertensionType(patient.chronicDisease);
    final statusColor = _getStatusColor(patient);
    final statusText = _getStatusText(patient);

    // Determinar el color y asset según el tipo de diabetes
    Color typeColor;
    String nextIconAsset;

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
                // SECCIÓN DE IMAGEN - CORREGIDA
                Expanded(
                  flex: 70,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundHipertencion.withOpacity(0.08),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FutureBuilder<Uint8List?>(
                            future: _nutritionistService.getPatientProfileImage(
                              patient.patientId,
                              Provider.of<AuthProvider>(context, listen: false)
                                  .token!,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              }
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundHipertencion
                                      .withOpacity(0.08),
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/images/user_placeholder_esmer.svg',
                                    width: 60,
                                    height: 70,
                                    fit: BoxFit.contain,
                                    color: AppColors.backgroundHipertencion,
                                    placeholderBuilder: (context) => Container(
                                      decoration: BoxDecoration(
                                          color:
                                              AppColors.backgroundHipertencion),
                                      child: Center(
                                        child: Text(
                                          _getInitials(patient.fullName),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors
                                                .backgroundHipertencion,
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

                        // Badge de tipo de diabetes
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
                              hypertensionType,
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
                        color:
                            AppColors.backgroundHipertencion.withOpacity(0.15),
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
                            // STATUS
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IntrinsicWidth(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.3),
                                      width: 0.8,
                                    ),
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
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/images/next_icon.svg',
                              width: 28,
                              height: 28,
                            ),
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
    final hypertensionType = _getHypertensionType(patient.chronicDisease);
    final statusColor = _getStatusColor(patient);
    final statusText = _getStatusText(patient);

    String nextIconAsset = 'assets/images/next_icon.svg';

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
            border:
                Border.all(width: 0.2, color: AppColors.backgroundHipertencion),
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
              // IZQUIERDA: Avatar - CORREGIDO CON IMAGEN ADAPTATIVA
              Container(
                width: 100,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.backgroundHipertencion.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    // Imagen adaptativa usando el patrón del ejemplo
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: FutureBuilder<Uint8List?>(
                          future: _nutritionistService.getPatientProfileImage(
                            patient.patientId,
                            Provider.of<AuthProvider>(context, listen: false)
                                .token!,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                width: 100,
                              );
                            }

                            // Placeholder adaptable - igual que en el ejemplo
                            return Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundHipertencion
                                    .withOpacity(0.1),
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/images/user_placeholder_orange.svg',
                                  width: 50,
                                  height: 60,
                                  fit: BoxFit.contain,
                                  color: AppColors.backgroundHipertencion,
                                  placeholderBuilder: (context) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          statusColor.withOpacity(0.1),
                                          statusColor.withOpacity(0.2),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getInitials(patient.fullName),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
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
                  ],
                ),
              ),

              // DERECHA: Información del paciente
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

                      // STATUS Y BOTÓN DE NAVEGACIÓN
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // STATUS
                          Flexible(
                            child: IntrinsicWidth(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // BOTÓN NEXT
                          Container(
                            width: 28,
                            height: 28,
                            child: Center(
                              child: SvgPicture.asset(
                                nextIconAsset,
                                width: 26,
                                height: 26,
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

  String _getInitials(String fullName) {
    List<String> names = fullName.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0].toUpperCase()}${names[1][0].toUpperCase()}';
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'P';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
