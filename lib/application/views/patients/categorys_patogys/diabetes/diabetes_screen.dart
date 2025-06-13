import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../configuration/themes/app_colors.dart';


// Enum para los tipos de diabetes
enum DiabetesTypes { tipo1, tipo2 }

// Modelo para la información del paciente
class Patients {
  final String name;
  final int age;
  final String diagnosis;
  final DiabetesTypes diabetesType;
  final String avatarUrl;

  Patients({
    required this.name,
    required this.age,
    required this.diagnosis,
    required this.diabetesType,
    required this.avatarUrl,
  });
}

// Pantalla principal de Pacientes con Diabetes
class DiabetesPatientsScreen extends StatefulWidget {
  const DiabetesPatientsScreen({super.key});

  @override
  State<DiabetesPatientsScreen> createState() => _DiabetesPatientsScreenState();
}

class _DiabetesPatientsScreenState extends State<DiabetesPatientsScreen> {
  DiabetesTypes? selectedFilter;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Lista de pacientes de ejemplo con más variedad
  final List<Patients> allPatients = [
    Patients(
      name: 'Nicol Quispe Payano',
      age: 52,
      diagnosis: 'Diabetes Tipo 1',
      diabetesType: DiabetesTypes.tipo1,
      avatarUrl: '',
    ),
    Patients(
      name: 'Carlos Mendoza Silva',
      age: 45,
      diagnosis: 'Diabetes Tipo 2',
      diabetesType: DiabetesTypes.tipo2,
      avatarUrl: 'https://emtstatic.com/2017/07/iStock-587923496-696x465.jpg',
    ),
    Patients(
      name: 'María López García',
      age: 38,
      diagnosis: 'Diabetes Tipo 1',
      diabetesType: DiabetesTypes.tipo1,
      avatarUrl: 'https://emtstatic.com/2017/07/iStock-587923496-696x465.jpg',
    ),
    Patients(
      name: 'José Rodríguez Peña',
      age: 67,
      diagnosis: 'Diabetes Tipo 2',
      diabetesType: DiabetesTypes.tipo2,
      avatarUrl: '',
    ),
    Patients(
      name: 'Ana Flores Morales',
      age: 29,
      diagnosis: 'Diabetes Tipo 1',
      diabetesType: DiabetesTypes.tipo1,
      avatarUrl: 'https://emtstatic.com/2017/07/iStock-587923496-696x465.jpg',
    ),
    Patients(
      name: 'Roberto Santos Cruz',
      age: 55,
      diagnosis: 'Diabetes Tipo 2',
      diabetesType: DiabetesTypes.tipo2,
      avatarUrl: 'https://emtstatic.com/2017/07/iStock-587923496-696x465.jpg',
    ),
  ];

  // Filtrar pacientes según búsqueda y tipo seleccionado
  List<Patients> get filteredPatients {
    List<Patients> filtered = allPatients;

    // Filtrar por tipo si hay uno seleccionado
    if (selectedFilter != null) {
      filtered = filtered
          .where((patient) => patient.diabetesType == selectedFilter)
          .toList();
    }

    // Filtrar por búsqueda
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((patient) {
        return patient.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            patient.diagnosis
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            patient.age.toString().contains(searchQuery);
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.backgroundIconNav,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light, // Para iOS
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 15),

              // Título principal
              Center(
                child: Text(
                  'Personas con Diabetes',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: AppColors.textTitleCateg),
                ),
              ),

              SizedBox(height: 10),

              // Filtros por tipo
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterChip('Todos', null, Colors.grey[600]!),
                    const SizedBox(width: 10),
                    _buildFilterChip(
                        'Tipo 1', DiabetesTypes.tipo1, AppColors.backgroundDia),
                    const SizedBox(width: 10),
                    _buildFilterChip(
                        'Tipo 2', DiabetesTypes.tipo2, AppColors.secondary),
                  ],
                ),
              ),

              SizedBox(height: 20),

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
                      hintText:
                      'Buscar paciente por nombre, edad o diagnóstico...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[600],
                        size: 22,
                      ),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
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
                    if (selectedFilter != null || searchQuery.isNotEmpty) ...[
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFilter = null;
                            searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        child: Container(
                          padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.errorText),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Limpiar filtros',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.errorText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.clear,
                                size: 14,
                                color: AppColors.errorIcon,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 10),

              // Lista de pacientes filtrados
              Expanded(
                child: Container(
                  color: Colors.grey[50],
                  child: filteredPatients.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
                      return _buildPatientCard(patient);
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
          backgroundColor: AppColors.backgroundDia,
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

  Widget _buildFilterChip(String label, DiabetesTypes? type, Color color) {
    final isSelected = selectedFilter == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = isSelected ? null : type;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(
              width: 1.5, color: isSelected ? color : Colors.grey[400]!),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
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
                : 'No hay pacientes que coincidan con los filtros',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                selectedFilter = null;
                searchQuery = '';
                _searchController.clear();
              });
            },
            icon: Icon(Icons.refresh),
            label: Text('Mostrar todos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Patients patient) {
    final typeColor = patient.diabetesType == DiabetesTypes.tipo1
        ? AppColors.backgroundDia
        : AppColors.secondary;

    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECCIÓN DE IMAGEN - Flexible para ocupar espacio disponible
            Expanded(
              flex: 75, // 75% del espacio disponible
              child: Container(
                child: Stack(
                  children: [
                    // Imagen de fondo o placeholder
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          // Fondo según tipo de diabetes
                          color: patient.diabetesType == DiabetesTypes.tipo2
                              ? AppColors.secondary.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.2),
                          image: patient.avatarUrl.isNotEmpty
                              ? DecorationImage(
                            image: NetworkImage(patient.avatarUrl),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        // Si no hay imagen, mostrar icono centrado según tipo
                        child: patient.avatarUrl.isEmpty
                            ? Center(
                          child: patient.diabetesType == DiabetesTypes.tipo2
                              ? SvgPicture.asset(
                            'assets/images/user_placeholder_orange.svg',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          )
                              : SvgPicture.asset(
                            'assets/images/user_placeholder_esmer.svg',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        )
                            : null,
                      ),
                    ),

                    // Badge del tipo - esquina superior izquierda
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
                          patient.diabetesType == DiabetesTypes.tipo1 ? 'T1' : 'T2',
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

            // SECCIÓN DE INFORMACIÓN - Flexible con tamaño mínimo
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
                          patient.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 4),

                        // Edad y ubicación
                        Row(
                          children: [
                            Icon(
                              Icons.cake_outlined,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${patient.age}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            SizedBox(width: 12),

                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Lima',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
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

                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: () => _showPatientDetails(patient),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: patient.diabetesType == DiabetesTypes.tipo2
                              ? SvgPicture.asset(
                            'assets/images/next_orange.svg',

                          )
                              : SvgPicture.asset(
                            'assets/images/next_icon.svg',

                          ),
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
    );
  }

  void _showAddPatientDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: Colors.teal),
            SizedBox(width: 8),
            Text('Agregar Paciente'),
          ],
        ),
        content: Text(
            'Funcionalidad para agregar nuevo paciente.\n\nAquí podrías implementar un formulario completo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPatientDetails(Patients patient) {
    // Resto del código igual que antes...
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(patient.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edad: ${patient.age} años'),
            Text('Diagnóstico: ${patient.diagnosis}'),
            Text(
                'Tipo: ${patient.diabetesType == DiabetesTypes.tipo1 ? 'Diabetes Tipo 1' : 'Diabetes Tipo 2'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {

            },
            child: const Text('Ver Información'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      String title, List<String> items, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items
            .map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6.0, left: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ))
            .toList(),
      ],
    );
  }
}