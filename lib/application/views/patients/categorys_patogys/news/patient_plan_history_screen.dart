import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';

class PatientPlanHistoryScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  const PatientPlanHistoryScreen({
    Key? key,
    required this.patientId,
    required this.patientName,
  }) : super(key: key);

  @override
  State<PatientPlanHistoryScreen> createState() => _PatientPlanHistoryScreenState();
}

class _PatientPlanHistoryScreenState extends State<PatientPlanHistoryScreen>
    with TickerProviderStateMixin {
  final NutritionistService _nutritionService = NutritionistService();

  late TabController _tabController;

  List<NutritionPlanResponse> _allPlans = [];
  List<NutritionPlanResponse> _filteredPlans = [];
  PatientPlanStats? _planStats;

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _token;

  String _selectedStatus = 'TODOS';
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _statusOptions = [
    'TODOS',
    'APPROVED',
    'PENDING',
    'REJECTED_BY_NUTRITIONIST',
    'REJECTED_BY_PATIENT',
    'ACTIVE'
  ];

  final Map<String, String> _statusLabels = {
    'TODOS': 'Todos los planes',
    'APPROVED': 'Aprobados',
    'PENDING': 'Pendientes',
    'REJECTED_BY_NUTRITIONIST': 'Rechazados por nutricionista',
    'REJECTED_BY_PATIENT': 'Rechazados por paciente',
    'ACTIVE': 'Activos',
  };

  final Map<String, Color> _statusColors = {
    'APPROVED': Colors.green,
    'PENDING': Colors.orange,
    'REJECTED_BY_NUTRITIONIST': Colors.red,
    'REJECTED_BY_PATIENT': Colors.purple,
    'ACTIVE': Colors.blue,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      if (_token == null) {
        throw Exception('Token no encontrado. Inicie sesión nuevamente.');
      }

      await Future.wait([
        _loadPlanHistory(),
        _loadPlanStats(),
      ]);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPlanHistory() async {
    try {
      final plans = await _nutritionService.getPatientNutritionHistory(
        widget.patientId,
        _token!,
      );

      setState(() {
        _allPlans = plans;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      throw Exception('Error al cargar historial: $e');
    }
  }

  Future<void> _loadPlanStats() async {
    try {
      final stats = await _nutritionService.getPatientPlanStats(
        widget.patientId,
        _token!,
      );

      setState(() {
        _planStats = stats;
      });
    } catch (e) {
      print('Error al cargar estadísticas: $e');
    }
  }

  void _applyFilters() {
    _filteredPlans = _allPlans.where((plan) {
      // Filtro por estado
      if (_selectedStatus != 'TODOS' && plan.status != _selectedStatus) {
        return false;
      }

      // Filtro por búsqueda
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!plan.goal.toLowerCase().contains(query) &&
            !plan.specialRequirements.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Filtro por fechas
      final planDate = DateTime.parse(plan.createdAt);
      if (_startDate != null && planDate.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && planDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF2E7D32),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _applyFilters();
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _applyFilters();
    });
  }

  String _getStatusText(String status) {
    return _statusLabels[status] ?? status;
  }

  Color _getStatusColor(String status) {
    return _statusColors[status] ?? Colors.grey;
  }

  Widget _buildStatsTab() {
    if (_planStats == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildGoalDistribution(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total de Planes',
          _planStats!.totalPlans.toString(),
          Icons.assignment,
          const Color(0xFF1976D2),
        ),
        _buildStatCard(
          'Aprobados',
          _planStats!.approvedPlans.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Pendientes',
          _planStats!.pendingPlans.toString(),
          Icons.schedule,
          Colors.orange,
        ),
        _buildStatCard(
          'Activos',
          _planStats!.activePlans.toString(),
          Icons.trending_up,
          const Color(0xFF2E7D32),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalDistribution() {
    if (_planStats!.goalDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución de Objetivos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          ..._planStats!.goalDistribution.entries.map((entry) {
            final percentage = (entry.value / _planStats!.totalPlans * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '${entry.value} ($percentage%)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: entry.value / _planStats!.totalPlans,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Adicional',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          if (_planStats!.lastPlanDate != null) ...[
            _buildInfoRow(
              'Último plan:',
              DateFormat('dd/MM/yyyy').format(DateTime.parse(_planStats!.lastPlanDate!)),
              Icons.calendar_today,
            ),
            const SizedBox(height: 8),
          ],
          if (_planStats!.averageEnergyRequirement != null) ...[
            _buildInfoRow(
              'Requerimiento energético promedio:',
              '${_planStats!.averageEnergyRequirement!.toInt()} kcal',
              Icons.local_fire_department,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _filteredPlans.isEmpty
              ? _buildEmptyState()
              : _buildPlansList(),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar por objetivo o requerimientos...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2E7D32)),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Filtros en fila
          Row(
            children: [
              // Filtro de estado
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                      _applyFilters();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        _getStatusText(status),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),

              // Botón de filtro de fechas
              Expanded(
                child: TextButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _startDate != null ? 'Fechas' : 'Filtrar',
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ),

              // Botón limpiar filtros
              if (_startDate != null || _endDate != null || _searchQuery.isNotEmpty || _selectedStatus != 'TODOS')
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _searchQuery = '';
                        _selectedStatus = 'TODOS';
                        _applyFilters();
                      });
                    },
                    icon: const Icon(Icons.clear, color: Colors.red),
                    tooltip: 'Limpiar filtros',
                  ),
                ),
            ],
          ),

          // Mostrar rango de fechas seleccionado
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Desde ${DateFormat('dd/MM/yyyy').format(_startDate!)} hasta ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
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
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron planes',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedStatus != 'TODOS' || _startDate != null
                ? 'Intenta ajustar los filtros'
                : 'Este paciente no tiene planes nutricionales',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPlans.length,
      itemBuilder: (context, index) {
        final plan = _filteredPlans[index];
        return _buildPlanCard(plan);
      },
    );
  }

  Widget _buildPlanCard(NutritionPlanResponse plan) {
    final createdDate = DateTime.parse(plan.createdAt);
    final weekStartDate = DateTime.parse(plan.weekStartDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewPlanDetails(plan),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estado y fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(plan.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getStatusColor(plan.status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getStatusText(plan.status),
                      style: TextStyle(
                        color: _getStatusColor(plan.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(createdDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Información principal
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Objetivo: ${plan.goal}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Semana del ${DateFormat('dd/MM/yyyy').format(weekStartDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Requerimiento energético
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${plan.energyRequirement} kcal',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Requerimientos especiales
              if (plan.specialRequirements.isNotEmpty) ...[
                Text(
                  'Requerimientos: ${plan.specialRequirements}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Notas de revisión si existen
              if (plan.reviewNotes != null && plan.reviewNotes!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 14, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          plan.reviewNotes!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Footer con nutricionista y acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Por: ${plan.nutritionistName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _viewPlanDetails(plan),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Ver detalles', style: TextStyle(fontSize: 11)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewPlanDetails(NutritionPlanResponse plan) async {
    try {
      // Mostrar loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
        ),
      );

      // Obtener detalles del plan
      final detailedPlan = await _nutritionService.getPlanDetails(plan.planId, _token!);

      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar loading dialog

      // Navegar a pantalla de detalles
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PlanDetailScreen(
            plan: detailedPlan,
            isReadOnly: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar detalles: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Planes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.patientName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.analytics_outlined),
              text: 'Estadísticas',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Historial',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
        ),
      )
          : _hasError
          ? _buildErrorWidget()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Ocurrió un error inesperado',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla simple de detalles del plan (puedes expandir según necesites)
class PlanDetailScreen extends StatelessWidget {
  final DetailedNutritionPlan plan;
  final bool isReadOnly;

  const PlanDetailScreen({
    Key? key,
    required this.plan,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plan #${plan.planId}'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanHeader(),
            const SizedBox(height: 20),
            _buildPlanContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plan para ${plan.patientName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getStatusColor().withOpacity(0.3)),
                ),
                child: Text(
                  plan.status,
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Objetivo:', plan.goal),
          _buildInfoRow('Semana:', plan.weekStartDate),
          _buildInfoRow('Energía requerida:', '${plan.energyRequirement} kcal'),
          _buildInfoRow('Creado:', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(plan.createdAt))),
          if (plan.reviewNotes != null)
            _buildInfoRow('Notas:', plan.reviewNotes!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contenido del Plan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          Text('Días planificados: ${plan.daysCount}'),
          const SizedBox(height: 8),
          Text('Requerimientos especiales: ${plan.specialRequirements}'),
          // Aquí puedes agregar más detalles del contenido del plan
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (plan.status) {
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED_BY_NUTRITIONIST':
        return Colors.red;
      case 'REJECTED_BY_PATIENT':
        return Colors.purple;
      case 'ACTIVE':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}