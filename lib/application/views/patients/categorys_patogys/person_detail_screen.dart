import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mottinutnutriotinist/application/views/patients/categorys_patogys/utils/antecedents_section_screen.dart';
import 'package:mottinutnutriotinist/application/views/patients/categorys_patogys/utils/comorbolidades_section.dart';
import 'package:mottinutnutriotinist/application/views/patients/categorys_patogys/utils/date_input_validate_screen.dart';
import 'package:mottinutnutriotinist/application/views/patients/categorys_patogys/utils/datos_nutricionales_section.dart';
import 'package:mottinutnutriotinist/application/views/patients/categorys_patogys/utils/factores_riesgo_section.dart';
import 'package:mottinutnutriotinist/application/views/patients/categorys_patogys/utils/filiation_section_screen.dart';
import 'package:mottinutnutriotinist/application/views/patients/categorys_patogys/utils/generaPlan/nutritional_plan_summary_creen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../configuration/themes/app_colors.dart';
import '../../../../domain/patient/pruebaa.dart';
import '../../../requestSnacbar/snackBar_manager.dart';

class PersonDetailScreen extends StatefulWidget {
  final Patient patient;

  const PersonDetailScreen({
    super.key,
    required this.patient,
  });

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen>
    with TickerProviderStateMixin {
  // Estados para controlar la expansión de las secciones
  bool _isAffiliationExpanded = false;
  bool _isAntecedentsExpanded = false;
  bool _isComorbiditiesExpanded = false;
  bool _isNutritionalDataExpanded = false;
  bool _isRiskFactorsExpanded = false;

  // Estado para controlar el modo de edición
  bool _isEditMode = false;

  // Controladores existentes
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  // Filiación
  Map<String, String> _filiationData = {};

  // Antecedentes
  Map<String, String> _antecendetesData = {};

  //comorbilidades
  Map<String, dynamic> _comorbilidadesData = {};

  // Datos nutricionales
  Map<String, String> _datosNutricionalesData = {};

  // Factores de riesgo
  Map<String, String> _factorRiesgoData = {};

  //VARIABLES PARA AUTO-GUARDADO
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  DateTime? _lastSaveTime;

  // Agregar después de las variables bool existentes
  late AnimationController _sectionAnimationController;
  late Animation<double> _sectionExpandAnimation;
  late Animation<double> _sectionFadeAnimation;
  late Animation<double> _iconRotationAnimation;

  DateTime? _selectedAttentionDate;
  TimeOfDay? _selectedAttentionTime;

  @override
  void initState() {
    super.initState();
    _selectedAttentionDate = widget.patient?.lastVisitDate;
    _selectedAttentionTime = widget.patient?.lastVisitTime;

    _ageController = TextEditingController(text: widget.patient.age.toString());
    _weightController =
        TextEditingController(text: widget.patient.weight?.toString() ?? '');
    _heightController =
        TextEditingController(text: widget.patient.height?.toString() ?? '');

    // AGREGAR AL FINAL DEL initState():
    _initializeSectionAnimations();

    _loadSavedData();
    _setupAutoSave();
  }

  void _initializeSectionAnimations() {
    _sectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _sectionExpandAnimation = CurvedAnimation(
      parent: _sectionAnimationController,
      curve: Curves.easeInOutCubic,
    );

    _sectionFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sectionAnimationController,
      curve: Curves.easeInOut,
    ));

    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _sectionAnimationController,
      curve: Curves.easeInOutBack,
    ));
  }

  // Reemplazar los métodos de toggle existentes con estos:
  void _toggleAffiliation() {
    setState(() => _isAffiliationExpanded = !_isAffiliationExpanded);
    if (_isAffiliationExpanded) {
      _sectionAnimationController.forward();
    } else {
      _sectionAnimationController.reverse();
    }
  }

  void _toggleAntecedents() {
    setState(() => _isAntecedentsExpanded = !_isAntecedentsExpanded);
    if (_isAntecedentsExpanded) {
      _sectionAnimationController.forward();
    } else {
      _sectionAnimationController.reverse();
    }
  }


  @override
  void dispose() {
    // AGREGAR AL INICIO DEL dispose():
    _autoSaveTimer?.cancel();
    _sectionAnimationController.dispose();
    // Dispose controladores existentes
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();

    super.dispose();
  }

  // MÉTODOS NUEVOS PARA AUTO-GUARDADO
  void _setupAutoSave() {
    // Configurar listeners para detectar cambios
    _ageController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);

  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }

    // Cancelar timer anterior y crear uno nuevo
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(Duration(seconds: 3), () {
      _autoSaveData();
    });
  }

  // filiación
  void _onFiliationDataChanged(Map<String, String> data) {
    _filiationData = data;
    _onFieldChanged(); // Activar auto-guardado
  }

  // antecedentes
  void _onAntecedentesDataChanged(Map<String, String> data) {
    _antecendetesData = data;
    _onFieldChanged();
  }

  // antecedentes
  void _onComorbilidadesDataChanged(Map<String, dynamic> data) {
    setState(() {
      _comorbilidadesData = data;
    });
    _onFieldChanged();
  }

  //datos nutricionalesn
  void _onDatosNutricionalesChanged(Map<String, String> data) {
    _datosNutricionalesData = data;
    _onFieldChanged();
  }

  //factores riesgo
  void _onFactoresRiesgoChanged(Map<String, String> data) {
    _factorRiesgoData = data;
    _onFieldChanged();
  }

  Future<void> _autoSaveData() async {
    if (!_hasUnsavedChanges || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> patientData = {
        'patientId': widget.patient.id,
        'age': _ageController.text,
        'weight': _weightController.text,
        'height': _heightController.text,

        'nucleoFamiliar': _filiationData['nucleoFamiliar'] ?? '',
        'ocupacionActual': _filiationData['ocupacionActual'] ?? '',
        'gradoInstruccion': _filiationData['gradoInstruccion'] ?? '',
        'religion': _filiationData['religion'] ?? '',

        'diagnosticoMedicoAnterior': _filiationData['diagnosticoMedicoAnterior'] ?? '',
        'tiempoEnfermedad': _filiationData['tiempoEnfermedad'] ?? '',
        'diagnosticoMedicoReciente': _filiationData['diagnosticoMedicoReciente'] ?? '',
        'antecedentesFamiliares': _filiationData['antecedentesFamiliares'] ?? '',

        'comorbilidades': _comorbilidadesData['comorbilidades'] ?? '',

        'vecesComidaDia': _datosNutricionalesData['vecesComidaDia'] ?? '',
        'preferencias': _datosNutricionalesData['preferencias'] ?? '',
        'noLeAgrada': _datosNutricionalesData['noLeAgrada'] ?? '',
        'intolerancias': _datosNutricionalesData['intolerancias'] ?? '',
        'lugarDeIngesta': _datosNutricionalesData['lugarDeIngesta'] ?? '',
        'habitosNocivos': _datosNutricionalesData['habitosNocivos'] ?? '',
        'tipoActividad': _datosNutricionalesData['tipoActividad'] ?? '',
        'consumoAgua': _datosNutricionalesData['consumoAgua'] ?? '',
        'consumoAguaDetail': _datosNutricionalesData['consumoAguaDetail'] ?? '',

        'mayor45Anios': _factorRiesgoData['mayor45Anios'] ?? '',
        'obesidad': _factorRiesgoData['obesidad'] ?? '',
        'hipertension': _factorRiesgoData['hipertension'] ?? '',
        'sedentarismo': _factorRiesgoData['sedentarismo'] ?? '',
        'hijosMacrosomicos': _factorRiesgoData['hijosMacrosomicos'] ?? '',
        'diabetesGestacional': _factorRiesgoData['diabetesGestacional'] ?? '',

        'lastSaved': DateTime.now().toIso8601String(),
      };

      await prefs.setString(
          'patient_data_${widget.patient.id}', jsonEncode(patientData));

      setState(() {
        _hasUnsavedChanges = false;
        _isSaving = false;
        _lastSaveTime = DateTime.now();
      });

      /*// Mostrar indicador discreto de guardado
      if (mounted) {
        SnackBarManager.showAutoSave(context);
      }*/
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      print('Error al guardar automáticamente: $e');
    }
  }

  Future<void> _loadSavedData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedDataJson =
          prefs.getString('patient_data_${widget.patient.id}');

      if (savedDataJson != null) {
        Map<String, dynamic> savedData = jsonDecode(savedDataJson);

        // Cargar datos guardados en los controladores
        _ageController.text = savedData['age'] ?? _ageController.text;
        _weightController.text = savedData['weight'] ?? _weightController.text;
        _heightController.text = savedData['height'] ?? _heightController.text;

        // AGREGAR carga de datos de filiación
        _filiationData = {
          'nucleoFamiliar': savedData['nucleoFamiliar'] ?? '',
          'ocupacionActual': savedData['ocupacionActual'] ?? '',
          'gradoInstruccion': savedData['gradoInstruccion'] ?? '',
          'religion': savedData['religion'] ?? '',
        };

        // AGREGAR carga de datos de antecedentes
        _antecendetesData = {
          'diagnosticoMedicoAnterior': savedData['diagnosticoMedicoAnterior'] ?? '',
          'tiempoEnfermedad': savedData['tiempoEnfermedad'] ?? '',
          'diagnosticoMedicoReciente': savedData['diagnosticoMedicoReciente'] ?? '',
          'antecedentesFamiliares': savedData['antecedentesFamiliares'] ?? '',
        };

        _comorbilidadesData = {
          'comorbilidades': savedData['comorbilidades'] ?? '',
        };

        // datos nutricionales
        _datosNutricionalesData = {
          'vecesComidaDia': savedData['vecesComidaDia'] ?? '',
          'preferencias': savedData['preferencias'] ?? '',
          'noLeAgrada': savedData['noLeAgrada'] ?? '',
          'intolerancias': savedData['intolerancias'] ?? '',
          'lugarDeIngesta': savedData['lugarDeIngesta'] ?? '',
          'habitosNocivos': savedData['habitosNocivos'] ?? '',
          'tipoActividad': savedData['tipoActividad'] ?? '',
          'consumoAgua': savedData['consumoAgua'] ?? '',
          'consumoAguaDetail': savedData['consumoAguaDetail'] ?? '',
        };

        // factores riesgo
        _factorRiesgoData = {
          'mayor45Anios': savedData['mayor45Anios'] ?? '',
          'obesidad': savedData['obesidad'] ?? '',
          'hipertension': savedData['hipertension'] ?? '',
          'sedentarismo': savedData['sedentarismo'] ?? '',
          'hijosMacrosomicos': savedData['hijosMacrosomicos'] ?? '',
          'diabetesGestacional': savedData['diabetesGestacional'] ?? '',
        };

        // Establecer tiempo de última carga
        if (savedData['lastSaved'] != null) {
          _lastSaveTime = DateTime.parse(savedData['lastSaved']);
        }

        setState(() {});
      }
    } catch (e) {
      print('Error al cargar datos guardados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Column(
          children: [
            _header(context),
            Expanded(
              child: Container(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _personalInfoPaciente(),
                      _basicInfoCards(),
                      const SizedBox(height: 20),
                      _expandableSections(),
                      _nutritionalEvaluation(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final headerHeight = 280 + MediaQuery.of(context).padding.top;

    return SizedBox(
      width: double.infinity,
      height: headerHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bag.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: headerHeight,
            ),
          ),

          Positioned(
            left: screenWidth / 2 - 85,
            bottom: 15,
            child: Stack(
              children: [
                // Avatar principal
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(width: 0.3, color: Colors.grey)),
                  child: ClipOval(
                    child: widget.patient.profileImageUrl != null
                        ? Image.network(
                            widget.patient.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _defaultAvatar();
                            },
                          )
                        : _defaultAvatar(),
                  ),
                ),

                // Pen icon en la esquina superior derecha del avatar
                Positioned(
                  right: 12,
                  bottom: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditMode = !_isEditMode;
                      });

                      if (_isEditMode) {
                        SnackBarManager.showSuccess(
                            context, 'Modo edición activado');
                      } else {
                        // Aquí puedes guardar los cambios
                        _saveChanges();
                      }
                    },
                    child: Center(
                      child: SvgPicture.asset(
                        _isEditMode
                            ? 'assets/images/pen_active.svg'
                            : 'assets/images/pen_inactive.svg',
                        width: 37,
                        height: 37,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botón de llamada
          Positioned(
            left: 32,
            bottom: 30,
            child: GestureDetector(
              onTap: () {
                print('Llamar');
              },
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/call_icon.svg',
                  width: 50,
                  height: 50,
                ),
              ),
            ),
          ),

          // Botón de mensaje
          Positioned(
            right: 32,
            bottom: 30,
            child: GestureDetector(
              onTap: () {
                print('Enviar mensaje');
              },
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/message_icon.svg',
                  width: 50,
                  height: 50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
        color: Colors.grey[200],
        child: SvgPicture.asset(
          'assets/images/user_placeholder_esmer.svg',
          fit: BoxFit.scaleDown,
        ));
  }

  Widget _personalInfoPaciente() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(
            widget.patient.fullName.isNotEmpty
                ? widget.patient.fullName
                : 'Username',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            widget.patient.dni != null ? 'DNI ${widget.patient.dni}' : 'DNI',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Edad editable
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Edad (editable o no)
              _isEditMode
                  ? _buildEditableField(_ageController, 'años', 'Edad')
                  : Text(
                      widget.patient.age > 0
                          ? '${widget.patient.age} años'
                          : 'Edad',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w300,
                      ),
                    ),

              const SizedBox(width: 8),
              const Text('|',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(width: 8),

              // Estado civil (solo lectura, o puedes hacerlo editable si deseas)
              Text(
                widget.patient.maritalStatus != null &&
                        widget.patient.maritalStatus!.isNotEmpty
                    ? widget.patient.maritalStatus!
                    : 'Estado civil',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w300,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.patient.address != null ? '${widget.patient.address}' : '',
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontWeight: FontWeight.w300),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
      TextEditingController controller, String suffix, String hint) {
    return Container(
      constraints: BoxConstraints(minWidth: 60, maxWidth: 100),
      child: IntrinsicWidth(
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 2,
          // Máximo 2 dígitos
          buildCounter: (context,
                  {required currentLength, required isFocused, maxLength}) =>
              null,
          // Ocultar contador
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w300,
          ),
          // Validaciones de entrada
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // Solo números
            LengthLimitingTextInputFormatter(2), // Máximo 2 caracteres
            TextInputFormatter.withFunction((oldValue, newValue) {
              // Validar rango de edad (35-59)
              if (newValue.text.isEmpty) return newValue;

              final int? age = int.tryParse(newValue.text);
              if (age == null) return oldValue;

              // Si es un solo dígito, permitir (para poder escribir números como 35, 45, etc.)
              if (newValue.text.length == 1) {
                if (age >= 3 && age <= 5) return newValue;
                return oldValue;
              }

              // Si son dos dígitos, validar rango completo
              if (age >= 30 && age <= 65) {
                return newValue;
              }
              return oldValue;
            }),
          ],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w300,
            ),
            // Solo mostrar sufijo si hay contenido válido
            suffix: (controller.text.isNotEmpty && controller.text != '0')
                ? Padding(
                    padding: const EdgeInsets.only(left: 2),
                    // Pequeño espacio entre número y sufijo
                    child: Text(
                      suffix,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  )
                : null,

            // Eliminar bordes y focus visual
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,

            // Eliminar padding interno
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          showCursor: true,
          cursorColor: Colors.grey[400],
          cursorWidth: 1.0,
          // Actualizar el estado cuando cambie el texto
          onChanged: (value) {
            // Forzar rebuild para actualizar el sufijo dinámicamente
            (context as Element).markNeedsBuild();
          },
          // Validación adicional al perder el foco
          onEditingComplete: () {
            final int? age = int.tryParse(controller.text);
            if (age != null && (age < 30 || age > 65)) {
              // Opcional: mostrar mensaje de error o limpiar el campo
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('La edad debe estar entre 35 y 59 años'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                ),
              );
              controller.clear();
            }
          },
        ),
      ),
    );
  }

  Widget _basicInfoCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundDetail,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _infoColumn('Género', widget.patient.gender.initial, null, false),
            _svgDivider(),
            _infoColumn(
              'Peso',
              widget.patient.weight != null
                  ? '${widget.patient.weight} kg'
                  : 'N/A',
              _weightController,
              true,
              suffix: 'kg',
            ),
            _svgDivider(),
            _infoColumn(
              'Talla',
              widget.patient.height != null
                  ? '${widget.patient.height} m'
                  : 'N/A',
              _heightController,
              true,
              suffix: 'm',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(
    String title,
    String value,
    TextEditingController? controller,
    bool isEditable, {
    String? suffix,
  }) {
    final bool isEditing = _isEditMode && isEditable && controller != null;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          if (isEditing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: TextField(
                      controller: controller,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration.collapsed(hintText: ''),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (suffix != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        suffix,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _svgDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SvgPicture.asset(
        'assets/images/line_divider.svg',
        height: 40,
      ),
    );
  }

  Widget _expandableSections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          buildDateInput(),
          _buildExpandableSection(
            'Filiación',
            _isAffiliationExpanded,
            _toggleAffiliation,
            _buildAffiliationContent(),
          ),
          _buildExpandableSection(
            'Antecedentes',
            _isAffiliationExpanded,
            _toggleAffiliation,
            _buildAntecedentsContent(),
          ),
          _buildExpandableSection(
            'Comorbilidades',
            _isAffiliationExpanded,
            _toggleAffiliation,
            buildComorbiditiesContent(),
          ),
          _buildExpandableSection(
            'Datos extra nutricionales',
            _isAffiliationExpanded,
            _toggleAffiliation,
            buildNutritionalDataContent(),
          ),
          _buildExpandableSection(
            'Factores de riesgo',
            _isAffiliationExpanded,
            _toggleAffiliation,
            _buildRiskFactorsContent(),
          ),
        ],
      ),
    );
  }

  //fecha atención
  Widget buildDateInput() {
    return DateInputWidget(
      initialDate: widget.patient.lastVisitDate,
      initialTime: widget.patient.lastVisitTime,
      isFrequentPatient: widget.patient.lastVisitDate != null,
      onDateChanged: (DateTime? newDate) {
        setState(() {
          _selectedAttentionDate = newDate;
        });
      },
      onTimeChanged: (TimeOfDay? newTime) {
        setState(() {
          _selectedAttentionTime = newTime;
        });
      },
    );
  }

  Widget _buildExpandableSection(
      String title, bool isExpanded, VoidCallback onTap, Widget content) {

    return AnimatedBuilder(
      animation: _sectionAnimationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEditMode ? AppColors.primary : Colors.grey.withOpacity(0.3),
              width: _isEditMode ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isEditMode ? AppColors.primary : AppColors.textInput,
                  ),
                ),
                trailing: Transform.rotate(
                  angle: _iconRotationAnimation.value * 3.14159,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: _isEditMode ? AppColors.primary : Colors.grey[600],
                  ),
                ),
                onTap: () {
                  if (isExpanded) {
                    _sectionAnimationController.reverse();
                  } else {
                    _sectionAnimationController.forward();
                  }
                  onTap();
                },
              ),

              // Contenido animado
              SizeTransition(
                sizeFactor: _sectionExpandAnimation,
                child: FadeTransition(
                  opacity: _sectionFadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAffiliationContent() {
    return FiliationSection(
      patient: widget.patient,
      isEditMode: _isEditMode,
      onDataChanged: _onFiliationDataChanged,
      initialData: _filiationData.isNotEmpty ? _filiationData : null,
    );
  }

  String boolToText(bool? value) {
    if (value == true) return 'Sí';
    if (value == false) return 'No';
    return 'No especificado';
  }

  Widget _buildAntecedentsContent() {
    return AntecedentsSectionScreen(
      patient: widget.patient,
      isEditMode: _isEditMode,
      onDataChanged: _onAntecedentesDataChanged,
      initialData: _antecendetesData.isNotEmpty ? _antecendetesData : null,
    );
  }

  Widget buildComorbiditiesContent() {
    return ComorbolidadesSection(
      patient: widget.patient,
      isEditMode: _isEditMode,
      onDataChanged: _onComorbilidadesDataChanged,
      initialData: _comorbilidadesData.isNotEmpty ? _comorbilidadesData : null,
    );
  }

  Widget buildNutritionalDataContent() {
    return DatosNutricionalesSection(
      patient: widget.patient,
      isEditMode: _isEditMode,
      onDataChanged: _onDatosNutricionalesChanged,
      initialData: _datosNutricionalesData.isNotEmpty ? _datosNutricionalesData : null,
    );
  }

// Método auxiliar adicional para mostrar información de seguimiento
  Widget buildFollowUpContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildInfoRow('Prioridad de cita:',
            widget.patient.recommendedAppointmentPriority.displayName),
        buildInfoRow('Días recomendados para seguimiento:',
            '${widget.patient.recommendedFollowUpDays} días'),
        buildInfoRow('Requiere atención urgente:',
            widget.patient.requiresUrgentAttention ? 'Sí' : 'No'),
        buildInfoRow(
            'Última visita:',
            widget.patient.lastVisitDate?.toString().split(' ')[0] ??
                'No registrada'),
        buildInfoRow(
            'Próxima cita:',
            widget.patient.nextAppointmentDate?.toString().split(' ')[0] ??
                'No programada'),
        // Monitoreo específico
        if (widget.patient.requiresGlucoseMonitoring)
          buildInfoRow('Requiere monitoreo de glucosa:', 'Sí'),
        if (widget.patient.requiresHypertensionMonitoring)
          buildInfoRow('Requiere monitoreo de presión:', 'Sí'),
      ],
    );
  }

  Widget _buildRiskFactorsContent() {
    return FactoresRiesgoSection(
      patient: widget.patient,
      isEditMode: _isEditMode,
      onDataChanged: _onFactoresRiesgoChanged,
      initialData: _factorRiesgoData.isNotEmpty ? _factorRiesgoData : null,
    );
  }

  Widget buildInfoRow(String label, String value) {
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionalEvaluation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evaluación nutricional',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: nutritionalCard(
                  'IMC',
                  widget.patient.bmi > 0
                      ? widget.patient.bmi.toStringAsFixed(0)
                      : '15',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: nutritionalCard(
                  'Perímetro abdominal',
                  widget.patient.abdominalPerimeter?.toStringAsFixed(0) ?? '20',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: nutritionalCard(
                  'DX nutricional',
                  widget.patient.bodyFatPercentage?.toStringAsFixed(0) ?? '25',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // BOTÓN DE GUARDADO MANUAL Y ESTADO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Indicador de estado
              Row(
                children: [
                  if (_isSaving)
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Guardando...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  else if (_lastSaveTime != null)
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.checkValidation,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Guardado ${_getTimeAgo(_lastSaveTime!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  else if (_hasUnsavedChanges)
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Cambios sin guardar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[600],
                            ),
                          ),
                        ],
                      ),
                ],
              ),

              // Botón de guardado manual
              ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                  await _manualSave();
                },
                icon: _isSaving
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(Icons.save, size: 18),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          // BOTÓN SIGUIENTE - Solo se muestra si se ha guardado exitosamente
          if (_lastSaveTime != null && !_hasUnsavedChanges && !_isSaving)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _navigateToSummary();
                  },
                  icon: Icon(Icons.arrow_forward, size: 18),
                  label: Text('Siguiente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary, // o el color que prefieras
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Método para navegar a la pantalla de resumen
  void _navigateToSummary() {
    // Recopila todos los datos guardados que necesitas pasar
    Map<String, dynamic> savedData = {
      // Datos básicos del paciente
      'patientId': widget.patient.id,
      'age': _ageController.text,
      'weight': _weightController.text,
      'height': _heightController.text,

      // Datos de filiación
      'nucleoFamiliar': _filiationData['nucleoFamiliar'] ?? '',
      'ocupacionActual': _filiationData['ocupacionActual'] ?? '',
      'gradoInstruccion': _filiationData['gradoInstruccion'] ?? '',
      'religion': _filiationData['religion'] ?? '',

      // Datos de antecedentes
      'diagnosticoMedicoAnterior': _antecendetesData['diagnosticoMedicoAnterior'] ?? '',
      'tiempoEnfermedad': _antecendetesData['tiempoEnfermedad'] ?? '',
      'diagnosticoMedicoReciente': _antecendetesData['diagnosticoMedicoReciente'] ?? '',
      'antecedentesFamiliares': _antecendetesData['antecedentesFamiliares'] ?? '',

      // Datos de comorbilidades
      'comorbilidades': _comorbilidadesData['comorbilidades'] ?? '',

      // Datos nutricionales
      'vecesComidaDia': _datosNutricionalesData['vecesComidaDia'] ?? '',
      'preferencias': _datosNutricionalesData['preferencias'] ?? '',
      'noLeAgrada': _datosNutricionalesData['noLeAgrada'] ?? '',
      'intolerancias': _datosNutricionalesData['intolerancias'] ?? '',
      'lugarDeIngesta': _datosNutricionalesData['lugarDeIngesta'] ?? '',
      'habitosNocivos': _datosNutricionalesData['habitosNocivos'] ?? '',
      'tipoActividad': _datosNutricionalesData['tipoActividad'] ?? '',
      'consumoAgua': _datosNutricionalesData['consumoAgua'] ?? '',
      'consumoAguaDetail': _datosNutricionalesData['consumoAguaDetail'] ?? '',

      // Datos de factores de riesgo
      'mayor45Anios': _factorRiesgoData['mayor45Anios'] ?? '',
      'obesidad': _factorRiesgoData['obesidad'] ?? '',
      'hipertension': _factorRiesgoData['hipertension'] ?? '',
      'sedentarismo': _factorRiesgoData['sedentarismo'] ?? '',
      'hijosMacrosomicos': _factorRiesgoData['hijosMacrosomicos'] ?? '',
      'diabetesGestacional': _factorRiesgoData['diabetesGestacional'] ?? '',

      // Datos de evaluación nutricional
      'bmi': widget.patient.bmi,
      'abdominalPerimeter': widget.patient.abdominalPerimeter,
      'bodyFatPercentage': widget.patient.bodyFatPercentage,

      // Datos de fecha de atención
      'selectedAttentionDate': _selectedAttentionDate,
      'selectedAttentionTime': _selectedAttentionTime,

      // Metadatos
      'lastSaveTime': _lastSaveTime,
      'isEditMode': _isEditMode,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NutritionalPlanSummaryScreen(
          patient: widget.patient,
          savedData: savedData,
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'ahora';
    } else if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours}h';
    } else {
      return 'hace ${difference.inDays}d';
    }
  }

  Future<void> _manualSave() async {
    await _autoSaveData();
    _saveChanges();
  }

  Widget nutritionalCard(String title, String value) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.backgroundDetail,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    SnackBarManager.showSuccess(context, 'Cambios guardados exitosamente');

  }
}
