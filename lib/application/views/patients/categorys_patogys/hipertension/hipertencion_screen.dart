import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../configuration/themes/app_colors.dart';


// Enums para mejor organización
enum HypertensionRisk { bajo, moderado, alto, muy_alto }
enum PatientStatuss { controlado, descontrolado, nuevo, seguimiento }

// Modelo ampliado para pacientes con hipertensión
class HipertensionPatient {
  final String name;
  final int age;
  final String diagnosis;
  final String avatarUrl;
  final HypertensionRisk riskLevel;
  final PatientStatuss status;
  final String lastVisit;
  final String systolicBP; // Presión sistólica
  final String diastolicBP; // Presión diastólica
  final bool hasNutritionalPlan;
  final int appointmentsPending;
  final String nextAppointment;

  HipertensionPatient({
    required this.name,
    required this.age,
    required this.diagnosis,
    required this.avatarUrl,
    required this.riskLevel,
    required this.status,
    required this.lastVisit,
    required this.systolicBP,
    required this.diastolicBP,
    this.hasNutritionalPlan = false,
    this.appointmentsPending = 0,
    required this.nextAppointment,
  });
}

// Pantalla principal de Pacientes con Hipertensión
class HipertensionPatientsScreen extends StatefulWidget {
  const HipertensionPatientsScreen({super.key});

  @override
  State<HipertensionPatientsScreen> createState() => _HipertensionPatientsScreenState();
}

class _HipertensionPatientsScreenState extends State<HipertensionPatientsScreen> {
  String searchQuery = '';
  HypertensionRisk? selectedRiskFilter;
  PatientStatuss? selectedStatusFilter;
  final TextEditingController _searchController = TextEditingController();

  // Lista ampliada de pacientes
  final List<HipertensionPatient> allPatients = [
    HipertensionPatient(
      name: 'Nicol Quispe Payano',
      age: 52,
      diagnosis: 'Hipertensión Arterial',
      avatarUrl: '',
      riskLevel: HypertensionRisk.alto,
      status: PatientStatuss.descontrolado,
      lastVisit: '15 Mar 2024',
      systolicBP: '160',
      diastolicBP: '95',
      hasNutritionalPlan: false,
      appointmentsPending: 2,
      nextAppointment: '20 Jun 2024',
    ),
    HipertensionPatient(
      name: 'Carlos Mendoza Silva',
      age: 45,
      diagnosis: 'Hipertensión Esencial',
      avatarUrl: 'https://emtstatic.com/2017/07/iStock-587923496-696x465.jpg',
      riskLevel: HypertensionRisk.moderado,
      status: PatientStatuss.controlado,
      lastVisit: '10 Jun 2024',
      systolicBP: '135',
      diastolicBP: '85',
      hasNutritionalPlan: true,
      appointmentsPending: 0,
      nextAppointment: '25 Jun 2024',
    ),
    HipertensionPatient(
      name: 'María López García',
      age: 38,
      diagnosis: 'Hipertensión Secundaria',
      avatarUrl: 'https://emtstatic.com/2017/07/iStock-587923496-696x465.jpg',
      riskLevel: HypertensionRisk.muy_alto,
      status: PatientStatuss.seguimiento,
      lastVisit: '08 Jun 2024',
      systolicBP: '170',
      diastolicBP: '100',
      hasNutritionalPlan: true,
      appointmentsPending: 1,
      nextAppointment: 'Hoy',
    ),
    HipertensionPatient(
      name: 'José Rodríguez Peña',
      age: 67,
      diagnosis: 'Hipertensión Arterial',
      avatarUrl: '',
      riskLevel: HypertensionRisk.alto,
      status: PatientStatuss.controlado,
      lastVisit: '12 Jun 2024',
      systolicBP: '140',
      diastolicBP: '90',
      hasNutritionalPlan: true,
      appointmentsPending: 0,
      nextAppointment: '18 Jun 2024',
    ),
    HipertensionPatient(
      name: 'Ana Flores Morales',
      age: 29,
      diagnosis: 'Hipertensión Gestacional',
      avatarUrl: 'https://emtstatic.com/2017/07/iStock-587923496-696x465.jpg',
      riskLevel: HypertensionRisk.moderado,
      status: PatientStatuss.nuevo,
      lastVisit: 'Primera vez',
      systolicBP: '145',
      diastolicBP: '92',
      hasNutritionalPlan: false,
      appointmentsPending: 3,
      nextAppointment: 'Mañana',
    ),
    HipertensionPatient(
      name: 'Roberto Santos Cruz',
      age: 55,
      diagnosis: 'Hipertensión Esencial',
      avatarUrl: 'https://emtstatic.com/2017/07/iStock-587923496-696x465.jpg',
      riskLevel: HypertensionRisk.bajo,
      status: PatientStatuss.controlado,
      lastVisit: '11 Jun 2024',
      systolicBP: '125',
      diastolicBP: '80',
      hasNutritionalPlan: true,
      appointmentsPending: 0,
      nextAppointment: '30 Jun 2024',
    ),
  ];

  // Filtrar pacientes
  List<HipertensionPatient> get filteredPatients {
    List<HipertensionPatient> filtered = allPatients;

    // Filtrar por búsqueda
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((patient) {
        return patient.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            patient.diagnosis.toLowerCase().contains(searchQuery.toLowerCase()) ||
            patient.age.toString().contains(searchQuery);
      }).toList();
    }

    // Filtrar por riesgo
    if (selectedRiskFilter != null) {
      filtered = filtered.where((patient) => patient.riskLevel == selectedRiskFilter).toList();
    }

    // Filtrar por estado
    if (selectedStatusFilter != null) {
      filtered = filtered.where((patient) => patient.status == selectedStatusFilter).toList();
    }

    return filtered;
  }

  // Obtener estadísticas rápidas
  Map<String, int> get quickStats {
    return {
      'total': allPatients.length,
      'controlados': allPatients.where((p) => p.status == PatientStatuss.controlado).length,
      'descontrolados': allPatients.where((p) => p.status == PatientStatuss.descontrolado).length,
      'alto_riesgo': allPatients.where((p) => p.riskLevel == HypertensionRisk.muy_alto || p.riskLevel == HypertensionRisk.alto).length,
      'sin_plan': allPatients.where((p) => !p.hasNutritionalPlan).length,
      'citas_pendientes': allPatients.map((p) => p.appointmentsPending).reduce((a, b) => a + b),
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = quickStats;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.backgroundIconNav,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 15),

              // Título principal con estadísticas
              Center(
                child: Column(
                  children: [
                    Text(
                      'Pacientes con Hipertensión',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        color: AppColors.textTitleCateg,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${stats['controlados']}/${stats['total']} controlados • ${stats['alto_riesgo']} alto riesgo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Panel de estadísticas rápidas
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondary.withOpacity(0.1), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Icon(Icons.people, color: AppColors.secondary, size: 20),
                          SizedBox(height: 4),
                          Text('${stats['total']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                          Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(height: 4),
                          Text('${stats['controlados']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                          Text('Controlados', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 20),
                          SizedBox(height: 4),
                          Text('${stats['alto_riesgo']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                          Text('Alto Riesgo', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Icon(Icons.restaurant_menu, color: Colors.orange, size: 20),
                          SizedBox(height: 4),
                          Text('${stats['sin_plan']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                          Text('Sin Plan', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
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
                      hintText: 'Buscar por nombre, edad o diagnóstico...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 22),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Filtros rápidos
              Container(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('Todos', selectedRiskFilter == null && selectedStatusFilter == null, () {
                      setState(() {
                        selectedRiskFilter = null;
                        selectedStatusFilter = null;
                      });
                    }),
                    SizedBox(width: 8),
                    _buildFilterChip('Alto Riesgo', selectedRiskFilter == HypertensionRisk.alto, () {
                      setState(() {
                        selectedRiskFilter = selectedRiskFilter == HypertensionRisk.alto ? null : HypertensionRisk.alto;
                        selectedStatusFilter = null;
                      });
                    }),
                    SizedBox(width: 8),
                    _buildFilterChip('Descontrolados', selectedStatusFilter == PatientStatuss.descontrolado, () {
                      setState(() {
                        selectedStatusFilter = selectedStatusFilter == PatientStatuss.descontrolado ? null : PatientStatuss.descontrolado;
                        selectedRiskFilter = null;
                      });
                    }),
                    SizedBox(width: 8),
                    _buildFilterChip('Sin Plan Nutricional', false, () {
                      // Implementar filtro para pacientes sin plan nutricional
                    }),
                    SizedBox(width: 8),
                    _buildFilterChip('Nuevos', selectedStatusFilter == PatientStatuss.nuevo, () {
                      setState(() {
                        selectedStatusFilter = selectedStatusFilter == PatientStatuss.nuevo ? null : PatientStatuss.nuevo;
                        selectedRiskFilter = null;
                      });
                    }),
                  ],
                ),
              ),

              SizedBox(height: 8),

              // Contador de resultados
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      '${filteredPatients.length} paciente${filteredPatients.length != 1 ? 's' : ''} encontrado${filteredPatients.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHome,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    if (stats['citas_pendientes']! > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 12, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              '${stats['citas_pendientes']} citas pendientes',
                              style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              // Lista de pacientes
              Expanded(
                child: Container(
                  color: Colors.grey[50],
                  child: filteredPatients.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.70, // Ajustado para más contenido
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
                      return _buildEnhancedPatientCard(patient);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddPatientDialog();
          },
          backgroundColor: AppColors.secondary,
          shape: const CircleBorder(),
          child: Align(
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/images/plus_icon.svg',
              width: 30,
              height: 30,
              fit: BoxFit.scaleDown,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedPatientCard(HipertensionPatient patient) {
    Color riskColor = _getRiskColor(patient.riskLevel);
    Color statusColor = _getStatusColor(patient.status);

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
              flex: 60,
              child: Container(
                child: Stack(
                  children: [
                    // Imagen de fondo
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          image: patient.avatarUrl.isNotEmpty
                              ? DecorationImage(
                            image: NetworkImage(patient.avatarUrl),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: patient.avatarUrl.isEmpty
                            ? Center(
                          child: SvgPicture.asset(
                            'assets/images/user_placeholder_orange.svg',
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                        )
                            : null,
                      ),
                    ),

                    // Badge de riesgo
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: riskColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getRiskText(patient.riskLevel),
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Presión arterial
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${patient.systolicBP}/${patient.diastolicBP}',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Indicadores de plan nutricional y citas
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Row(
                        children: [
                          if (patient.hasNutritionalPlan)
                            Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 8,
                                color: Colors.white,
                              ),
                            ),
                          if (patient.appointmentsPending > 0) ...[
                            SizedBox(width: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${patient.appointmentsPending}',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // SECCIÓN DE INFORMACIÓN
            Expanded(
              flex: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: statusColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nombre y estado
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  patient.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 4),

                          // Edad y última visita
                          Row(
                            children: [
                              Icon(Icons.cake_outlined, size: 10, color: Colors.grey[600]),
                              SizedBox(width: 2),
                              Text(
                                '${patient.age} años',
                                style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                              ),
                            ],
                          ),

                          SizedBox(height: 2),

                          // Próxima cita
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 10, color: Colors.grey[600]),
                              SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  patient.nextAppointment,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: patient.nextAppointment == 'Hoy' || patient.nextAppointment == 'Mañana'
                                        ? Colors.orange[700]
                                        : Colors.grey[700],
                                    fontWeight: patient.nextAppointment == 'Hoy' || patient.nextAppointment == 'Mañana'
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Botón de acción
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: GestureDetector(
                        onTap: () {
                          _showPatientDetails(patient);
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/images/next_orange.svg',
                              width: 12,
                              height: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No se encontraron pacientes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty ? 'Intenta con otros términos de búsqueda' : 'No hay pacientes registrados',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                searchQuery = '';
                selectedRiskFilter = null;
                selectedStatusFilter = null;
                _searchController.clear();
              });
            },
            icon: Icon(Icons.refresh),
            label: Text('Limpiar filtros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(HypertensionRisk risk) {
    switch (risk) {
      case HypertensionRisk.bajo:
        return Colors.green;
      case HypertensionRisk.moderado:
        return Colors.orange;
      case HypertensionRisk.alto:
        return Colors.red;
      case HypertensionRisk.muy_alto:
        return Colors.red[900]!;
    }
  }

  String _getRiskText(HypertensionRisk risk) {
    switch (risk) {
      case HypertensionRisk.bajo:
        return 'BAJO';
      case HypertensionRisk.moderado:
        return 'MOD';
      case HypertensionRisk.alto:
        return 'ALTO';
      case HypertensionRisk.muy_alto:
        return 'M.ALTO';
    }
  }

  Color _getStatusColor(PatientStatuss status) {
    switch (status) {
      case PatientStatuss.controlado:
        return Colors.green;
      case PatientStatuss.descontrolado:
        return Colors.red;
      case PatientStatuss.nuevo:
        return Colors.blue;
      case PatientStatuss.seguimiento:
        return Colors.orange;
    }
  }

  void _showPatientDetails(HipertensionPatient patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del modal con foto y nombre
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withOpacity(0.1),
                    image: patient.avatarUrl.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(patient.avatarUrl),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: patient.avatarUrl.isEmpty
                      ? Icon(Icons.person, color: AppColors.secondary, size: 30)
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${patient.age} años • ${patient.diagnosis}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRiskColor(patient.riskLevel),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRiskText(patient.riskLevel),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Información clínica
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información Clínica',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Presión Arterial',
                          '${patient.systolicBP}/${patient.diastolicBP} mmHg',
                          Icons.favorite,
                          Colors.red,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          'Estado',
                          _getStatusText(patient.status),
                          Icons.circle,
                          _getStatusColor(patient.status),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Última Visita',
                          patient.lastVisit,
                          Icons.calendar_today,
                          Colors.blue,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          'Próxima Cita',
                          patient.nextAppointment,
                          Icons.schedule,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Plan nutricional
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: patient.hasNutritionalPlan ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: patient.hasNutritionalPlan ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    patient.hasNutritionalPlan ? Icons.check_circle : Icons.warning,
                    color: patient.hasNutritionalPlan ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan Nutricional',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          patient.hasNutritionalPlan
                              ? 'Paciente cuenta con plan nutricional activo'
                              : 'Paciente requiere plan nutricional',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Citas pendientes
            if (patient.appointmentsPending > 0)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.amber[700], size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Citas Pendientes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${patient.appointmentsPending} cita${patient.appointmentsPending > 1 ? 's' : ''} pendiente${patient.appointmentsPending > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Spacer(),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Implementar navegación al plan nutricional
                    },
                    icon: Icon(Icons.restaurant_menu),
                    label: Text('Plan Nutricional'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Implementar navegación al historial médico
                    },
                    icon: Icon(Icons.history),
                    label: Text('Ver Historial'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _getStatusText(PatientStatuss status) {
    switch (status) {
      case PatientStatuss.controlado:
        return 'Controlado';
      case PatientStatuss.descontrolado:
        return 'Descontrolado';
      case PatientStatuss.nuevo:
        return 'Nuevo';
      case PatientStatuss.seguimiento:
        return 'Seguimiento';
    }
  }

  void _showAddPatientDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: AppColors.secondary),
            SizedBox(width: 8),
            Text('Agregar Paciente'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Funcionalidad para agregar nuevo paciente con hipertensión.'),
            SizedBox(height: 16),
            Text(
              'Se incluirá formulario completo con:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Datos personales'),
                Text('• Mediciones de presión arterial'),
                Text('• Nivel de riesgo cardiovascular'),
                Text('• Historial médico'),
                Text('• Asignación de plan nutricional'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

}