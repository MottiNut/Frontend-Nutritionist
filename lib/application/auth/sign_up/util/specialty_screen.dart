import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../configuration/themes/app_colors.dart';

class SpecialtyScreen extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String email;
  final String contrasena;
  final String codeCNP;
  final File? licenseFrontImage;
  final File? licenseBackImage;
  final String initialEspecialidad;
  final String initialMaestria;
  final String initialOther;
  final Function(String especialidad, String maestria, String other)? onDataChanged;

  const SpecialtyScreen(
      {Key? key,
        required this.nombre,
        required this.apellido,
        required this.email,
        required this.contrasena,
        required this.codeCNP,
        this.licenseFrontImage,
        this.licenseBackImage,
        this.initialEspecialidad = '',
        this.initialMaestria = '',
        this.initialOther = '',
        this.onDataChanged,
      }) : super(key: key);

  @override
  State<SpecialtyScreen> createState() => SpecialtyScreenState();
}

class SpecialtyScreenState extends State<SpecialtyScreen> with TickerProviderStateMixin {
  // Lista de especialidades seleccionadas
  List<String> selectedSpecialties = [];

  // Variables para manejar sub-opciones
  bool showEspecialidadOptions = false;
  List<String> selectedEspecialidades = [];
  bool showMaestriaOptions = false;
  List<String> selectedMaestrias = [];
  bool showOtroField = false;
  String otroText = '';

  // Controllers
  TextEditingController otroController = TextEditingController();

  // Animation controllers
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  // SharedPreferences
  SharedPreferences? prefs;

  // Lista de estudios de postgrado disponibles
  final List<Map<String, dynamic>> postgradoStudies = [
    {
      'name': 'Especialidad',
      'icon': Icons.medical_services_outlined,
      'description': 'Especialización médica en nutrición clínica',
    },
    {
      'name': 'Maestría',
      'icon': Icons.school_outlined,
      'description': 'Maestría en ciencias de la nutrición',
    },
    {
      'name': 'Otro',
      'icon': Icons.psychology_outlined,
      'description': 'Otros estudios de postgrado',
    },
  ];

  // Opciones de especialidades específicas
  final List<Map<String, String>> especialidadOptions = [
    {'name': 'Nutrición Clínica', 'desc': 'Tratamiento nutricional hospitalario'},
    {'name': 'Nutrición Deportiva', 'desc': 'Optimización del rendimiento atlético'},
    {'name': 'Nutrición Pediátrica', 'desc': 'Alimentación en edad pediátrica'},
    {'name': 'Obesidad y Sobrepeso', 'desc': 'Manejo integral del peso corporal'},
    {'name': 'Diabetes', 'desc': 'Control nutricional de la diabetes'},
    {'name': 'Hipertensión', 'desc': 'Dieta para control de presión arterial'},
    {'name': 'Nutrición Geriátrica', 'desc': 'Alimentación en adultos mayores'},
    {'name': 'Trastornos Alimentarios', 'desc': 'Tratamiento de TCA'},
  ];

  // Opciones de maestrías específicas
  final List<Map<String, String>> maestriaOptions = [
    {'name': 'Ciencias de la Nutrición', 'desc': 'Investigación nutricional avanzada'},
    {'name': 'Salud Pública', 'desc': 'Nutrición poblacional y epidemiología'},
    {'name': 'Nutrición Clínica', 'desc': 'Práctica clínica especializada'},
    {'name': 'Alimentación y Nutrición Humana', 'desc': 'Enfoque integral alimentario'},
    {'name': 'Nutrición Deportiva', 'desc': 'Rendimiento y metabolismo deportivo'},
    {'name': 'Seguridad Alimentaria', 'desc': 'Calidad e inocuidad alimentaria'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _initializeSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    await _loadDataFromPreferences();

    // Solo inicializar con datos del widget si NO hay datos en SharedPreferences
    if (selectedSpecialties.isEmpty &&
        selectedEspecialidades.isEmpty &&
        selectedMaestrias.isEmpty &&
        otroText.isEmpty) {
      _initializeWithPreviousData();
    }

    // Asegurar que el estado visual sea consistente
    _updateVisualState();
  }

  Future<void> _loadDataFromPreferences() async {
    if (prefs != null) {
      try {
        // Cargar especialidades seleccionadas
        final especialidadesJson = prefs!.getString('selectedEspecialidades');
        if (especialidadesJson != null && especialidadesJson.isNotEmpty) {
          final decoded = json.decode(especialidadesJson);
          if (decoded is List) {
            selectedEspecialidades = List<String>.from(decoded);
          }
        }

        // Cargar maestrías seleccionadas
        final maestriasJson = prefs!.getString('selectedMaestrias');
        if (maestriasJson != null && maestriasJson.isNotEmpty) {
          final decoded = json.decode(maestriasJson);
          if (decoded is List) {
            selectedMaestrias = List<String>.from(decoded);
          }
        }

        // Cargar texto "Otro"
        otroText = prefs!.getString('otroText') ?? '';
        otroController.text = otroText;

        // Cargar especialidades principales seleccionadas
        final selectedSpecialtiesJson = prefs!.getString('selectedSpecialties');
        if (selectedSpecialtiesJson != null && selectedSpecialtiesJson.isNotEmpty) {
          final decoded = json.decode(selectedSpecialtiesJson);
          if (decoded is List) {
            selectedSpecialties = List<String>.from(decoded);
          }
        }

        // Cargar estados de expansión con valores por defecto más inteligentes
        showEspecialidadOptions = prefs!.getBool('showEspecialidadOptions') ??
            (selectedEspecialidades.isNotEmpty); // Default a true si hay selecciones
        showMaestriaOptions = prefs!.getBool('showMaestriaOptions') ??
            (selectedMaestrias.isNotEmpty); // Default a true si hay selecciones
        showOtroField = prefs!.getBool('showOtroField') ??
            (otroText.trim().isNotEmpty); // Default a true si hay texto

        // Forzar actualización del estado si el widget está montado
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        print('Error al cargar desde SharedPreferences: $e');
        // En caso de error, usar valores por defecto
        selectedEspecialidades = [];
        selectedMaestrias = [];
        otroText = '';
        selectedSpecialties = [];
        showEspecialidadOptions = false;
        showMaestriaOptions = false;
        showOtroField = false;
      }
    }
  }

  void _updateVisualState() {
    setState(() {
      // Asegurar que las opciones principales estén seleccionadas si hay sub-selecciones
      if (selectedEspecialidades.isNotEmpty) {
        if (!selectedSpecialties.contains('Especialidad')) {
          selectedSpecialties.add('Especialidad');
        }
        // Mantener el estado de expansión si hay selecciones
        if (selectedEspecialidades.isNotEmpty) {
          showEspecialidadOptions = prefs?.getBool('showEspecialidadOptions') ?? false;
        }
      }

      if (selectedMaestrias.isNotEmpty) {
        if (!selectedSpecialties.contains('Maestría')) {
          selectedSpecialties.add('Maestría');
        }
        // Mantener el estado de expansión si hay selecciones
        if (selectedMaestrias.isNotEmpty) {
          showMaestriaOptions = prefs?.getBool('showMaestriaOptions') ?? false;
        }
      }

      if (otroText.trim().isNotEmpty) {
        if (!selectedSpecialties.contains('Otro')) {
          selectedSpecialties.add('Otro');
        }
        // Mantener el estado de expansión si hay texto
        if (otroText.trim().isNotEmpty) {
          showOtroField = prefs?.getBool('showOtroField') ?? false;
        }
      }
    });
  }

  Future<void> _saveDataToPreferences() async {
    if (prefs != null) {
      try {
        // Guardar especialidades seleccionadas
        await prefs!.setString('selectedEspecialidades', json.encode(selectedEspecialidades));

        // Guardar maestrías seleccionadas
        await prefs!.setString('selectedMaestrias', json.encode(selectedMaestrias));

        // Guardar texto "Otro"
        await prefs!.setString('otroText', otroText);

        // Guardar especialidades principales seleccionadas
        await prefs!.setString('selectedSpecialties', json.encode(selectedSpecialties));

        // Guardar estados de expansión
        await prefs!.setBool('showEspecialidadOptions', showEspecialidadOptions);
        await prefs!.setBool('showMaestriaOptions', showMaestriaOptions);
        await prefs!.setBool('showOtroField', showOtroField);

        print('Datos guardados correctamente en SharedPreferences'); // Para debug
      } catch (e) {
        print('Error al guardar en SharedPreferences: $e'); // Para debug
      }
    }
  }

  void _initializeWithPreviousData() {
    // Restaurar especialidades seleccionadas (solo si no hay datos en SharedPreferences)
    if (widget.initialEspecialidad.isNotEmpty && selectedEspecialidades.isEmpty) {
      selectedEspecialidades = widget.initialEspecialidad.split(',');
      if (selectedEspecialidades.isNotEmpty) {
        selectedSpecialties.add('Especialidad');
        showEspecialidadOptions = true;
      }
    }

    // Restaurar maestrías seleccionadas (solo si no hay datos en SharedPreferences)
    if (widget.initialMaestria.isNotEmpty && selectedMaestrias.isEmpty) {
      selectedMaestrias = widget.initialMaestria.split(',');
      if (selectedMaestrias.isNotEmpty) {
        selectedSpecialties.add('Maestría');
        showMaestriaOptions = true;
      }
    }

    // Restaurar campo "Otro" (solo si no hay datos en SharedPreferences)
    if (widget.initialOther.isNotEmpty && otroText.isEmpty) {
      otroText = widget.initialOther;
      otroController.text = widget.initialOther;
      selectedSpecialties.add('Otro');
      showOtroField = true;
    }
  }

  @override
  void dispose() {
    otroController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _notifyDataChanged() {
    if (widget.onDataChanged != null) {
      String especialidadString = selectedEspecialidades.join(',');
      String maestriaString = selectedMaestrias.join(',');
      String otherString = otroText.trim();

      widget.onDataChanged!(
        especialidadString,
        maestriaString,
        otherString,
      );
    }
  }

  // Método público para validar si la pantalla está completa
  bool isValid() {
    return canContinue;
  }

  void toggleStudy(String study) {
    setState(() {
      if (selectedSpecialties.contains(study)) {
        selectedSpecialties.remove(study);
        // Limpiar sub-opciones cuando se deselecciona
        if (study == 'Especialidad') {
          showEspecialidadOptions = false;
          selectedEspecialidades.clear();
        } else if (study == 'Maestría') {
          showMaestriaOptions = false;
          selectedMaestrias.clear();
        } else if (study == 'Otro') {
          showOtroField = false;
          otroText = '';
          otroController.clear();
        }
      } else {
        selectedSpecialties.add(study);
        // Mostrar sub-opciones cuando se selecciona
        if (study == 'Especialidad') {
          showEspecialidadOptions = true;
        } else if (study == 'Maestría') {
          showMaestriaOptions = true;
        } else if (study == 'Otro') {
          showOtroField = true;
        }
      }
    });

    // Guardar inmediatamente después del cambio
    _saveDataToPreferences().then((_) {
      _notifyDataChanged();
    });
  }

  void toggleEspecialidad(String especialidad) {
    setState(() {
      if (selectedEspecialidades.contains(especialidad)) {
        selectedEspecialidades.remove(especialidad);
      } else {
        selectedEspecialidades.add(especialidad);
      }
    });
    _saveDataToPreferences();
    _notifyDataChanged();
  }

  void toggleMaestria(String maestria) {
    setState(() {
      if (selectedMaestrias.contains(maestria)) {
        selectedMaestrias.remove(maestria);
      } else {
        selectedMaestrias.add(maestria);
      }
    });
    _saveDataToPreferences();
    _notifyDataChanged();
  }

  void toggleExpansion(String studyName) {
    setState(() {
      switch (studyName) {
        case 'Especialidad':
          showEspecialidadOptions = !showEspecialidadOptions;
          break;
        case 'Maestría':
          showMaestriaOptions = !showMaestriaOptions;
          break;
        case 'Otro':
          showOtroField = !showOtroField;
          break;
      }
    });

    // Guardar el estado y forzar actualización visual
    _saveDataToPreferences().then((_) {
      // Forzar reconstrucción del widget para asegurar consistencia visual
      if (mounted) {
        setState(() {});
      }
    });
  }

  bool get canContinue {
    if (selectedSpecialties.isEmpty) return false;

    // Si seleccionó Especialidad, debe elegir al menos una especialidad específica
    if (selectedSpecialties.contains('Especialidad') && selectedEspecialidades.isEmpty) {
      return false;
    }

    // Si seleccionó Maestría, debe elegir al menos una maestría específica
    if (selectedSpecialties.contains('Maestría') && selectedMaestrias.isEmpty) {
      return false;
    }

    // Si seleccionó Otro, debe escribir algo
    if (selectedSpecialties.contains('Otro') && otroText.trim().isEmpty) {
      return false;
    }

    return true;
  }

  Widget _buildStudyCard(Map<String, dynamic> item, bool isSelected) {
    final hasSubSelections = _getSubSelectionCount(item['name']) > 0;
    final isExpanded = _isExpanded(item['name']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => toggleStudy(item['name']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    AppColors.primary.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[200]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.black.withOpacity(0.04),
                    blurRadius: isSelected ? 8 : 4,
                    offset: Offset(0, isSelected ? 3 : 2),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icono principal
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : null,
                        color: isSelected ? null : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Icon(
                        item['icon'],
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Contenido principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? AppColors.primary : Colors.grey[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasSubSelections)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_getSubSelectionCount(item['name'])}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Mostrar selecciones cuando está contraído
                          if (hasSubSelections && !isExpanded)
                            _buildCompactSelections(item['name']),
                        ],
                      ),
                    ),

                    // Indicadores de estado
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        if (isSelected && _hasSubOptions(item['name']))
                          GestureDetector(
                            onTap: () => toggleExpansion(item['name']),
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: AppColors.primary,
                                size: 18,
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

          // Sub-opciones expandibles
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item['name'] == 'Especialidad' && showEspecialidadOptions)
                  _buildProfessionalSubOptions(
                    especialidadOptions,
                    selectedEspecialidades,
                    toggleEspecialidad,
                    'Especialidades Médicas',
                    Icons.medical_services,
                  ),
                if (item['name'] == 'Maestría' && showMaestriaOptions)
                  _buildProfessionalSubOptions(
                    maestriaOptions,
                    selectedMaestrias,
                    toggleMaestria,
                    'Programas de Maestría',
                    Icons.school,
                  ),
                if (item['name'] == 'Otro' && showOtroField)
                  _buildProfessionalOtroField(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSelections(String studyName) {
    List<String> selections = [];

    // Obtener selecciones directamente desde las variables de estado
    switch (studyName) {
      case 'Especialidad':
        selections = List<String>.from(selectedEspecialidades);
        break;
      case 'Maestría':
        selections = List<String>.from(selectedMaestrias);
        break;
      case 'Otro':
        if (otroText.trim().isNotEmpty) {
          selections = [otroText.trim()];
        }
        break;
    }

    // Debug print para verificar
    print('_buildCompactSelections for $studyName: $selections');

    // Si no hay selecciones, no mostrar nada
    if (selections.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 12,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Seleccionadas (${selections.length}):',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: selections.take(3).map((selection) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  selection.length > 20 ? '${selection.substring(0, 20)}...' : selection,
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          if (selections.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... y ${selections.length - 3} más',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfessionalSubOptions(
      List<Map<String, String>> options,
      List<String> selectedOptions,
      Function(String) toggleFunction,
      String title,
      IconData icon,
      ) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 12, right: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${selectedOptions.length} ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth > 400 ? 2 : 1,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: constraints.maxWidth > 400 ? 2.8 : 5.5,
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = selectedOptions.contains(option['name']);

                  return GestureDetector(
                    onTap: () => toggleFunction(option['name']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : null,
                        color: isSelected ? null : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey[200]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              option['name']!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: isSelected ? Colors.white : Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Flexible(
                            child: Text(
                              option['desc']!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalOtroField() {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 12, right: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Especifica tu Estudio',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 80),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: otroController,
              onChanged: (value) {
                setState(() {
                  otroText = value;
                });
                _saveDataToPreferences();
                _notifyDataChanged();
              },
              decoration: InputDecoration(
                hintText: 'Ej: Doctorado en Nutrición Molecular...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                prefixIcon: Icon(
                  Icons.school_outlined,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              minLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasSubOptions(String studyName) {
    return studyName == 'Especialidad' || studyName == 'Maestría' || studyName == 'Otro';
  }

  bool _isExpanded(String studyName) {
    switch (studyName) {
      case 'Especialidad':
        return showEspecialidadOptions;
      case 'Maestría':
        return showMaestriaOptions;
      case 'Otro':
        return showOtroField;
      default:
        return false;
    }
  }

  int _getSubSelectionCount(String studyName) {
    switch (studyName) {
      case 'Especialidad':
        return selectedEspecialidades.length;
      case 'Maestría':
        return selectedMaestrias.length;
      case 'Otro':
        return otroText.trim().isNotEmpty ? 1 : 0;
      default:
        return 0;
    }
  }

  List<String> _getSelectedSubItems(String studyName) {
    switch (studyName) {
      case 'Especialidad':
        return List<String>.from(selectedEspecialidades);
      case 'Maestría':
        return List<String>.from(selectedMaestrias);
      case 'Otro':
        final texto = otroText.trim();
        return texto.isNotEmpty ? [texto] : [];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header profesional
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Formación Profesional',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecciona tus estudios de postgrado y especialización',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lista de estudios de postgrado
                    ...postgradoStudies.map((study) {
                      final isSelected = selectedSpecialties.contains(study['name']);
                      return _buildStudyCard(study, isSelected);
                    }).toList(),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}