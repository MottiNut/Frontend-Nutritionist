import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import 'package:lottie/lottie.dart';

import 'PatientDetailScreen.dart';

class CreateMedicalHistoryScreen extends StatefulWidget {
  final PatientProfile patient;
  final VoidCallback? onHistoryCreated;

  const CreateMedicalHistoryScreen({
    Key? key,
    required this.patient,
    this.onHistoryCreated,
  }) : super(key: key);

  @override
  State<CreateMedicalHistoryScreen> createState() => _CreateMedicalHistoryScreenState();
}

class _CreateMedicalHistoryScreenState extends State<CreateMedicalHistoryScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _authToken;

  late PatientDisease _patientDisease;
  late Color _diseaseColor;

  // Controllers para los campos del formulario
  final _bloodGlucoseController = TextEditingController();
  final _bloodPressureController = TextEditingController();
  final _waistCircumferenceController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _waterConsumptionController = TextEditingController();
  final _nutritionalObjectivesController = TextEditingController();
  final _professionalNotesController = TextEditingController();

  // Controllers para el cálculo de calorías (editables)
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  // Valores para sliders
  double _sleepQuality = 7.0;
  double _stressLevel = 5.0;

  // Variables para cálculo de calorías
  String _selectedGender = 'Mujer';
  String _selectedActivityLevel = 'Sedentario';
  double _calculatedCalories = 0.0;

  // Opciones para los dropdowns
  final List<String> _genderOptions = ['Hombre', 'Mujer'];
  final List<String> _activityLevels = [
    'Sedentario',
    'Ligeramente activo',
    'Moderadamente activo',
    'Muy activo',
    'Extremadamente activo'
  ];

  @override
  void initState() {
    super.initState();

    // Detectar enfermedad y color
    _patientDisease = detectDiseaseFromString(widget.patient.chronicDisease);
    _diseaseColor = getDiseaseColor(_patientDisease);

    _loadAuthToken();
    _loadPatientDataAndPreferences();
    // Agregar listeners para recalcular calorías automáticamente
    _weightController.addListener(_calculateAndSaveCalories);
    _heightController.addListener(_calculateAndSaveCalories);
    _ageController.addListener(_calculateAndSaveCalories);
  }

  Future<void> _loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
    } catch (e) {
      print('❌ Error al cargar token: $e');
    }
  }

  Future<void> _loadPatientDataAndPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cargar datos guardados en SharedPreferences
      final savedWeight = prefs.getDouble('patient_${widget.patient.patientId}_weight');
      final savedHeight = prefs.getDouble('patient_${widget.patient.patientId}_height');
      final savedAge = prefs.getInt('patient_${widget.patient.patientId}_age');
      final savedGender = prefs.getString('patient_${widget.patient.patientId}_gender');
      final savedActivityLevel = prefs.getString('patient_${widget.patient.patientId}_activity_level');

      setState(() {
        // Peso: prioridad a datos guardados, luego datos del paciente
        _weightController.text = savedWeight?.toString() ??
            (widget.patient.weight?.toString() ?? '');

        // Altura: prioridad a datos guardados, luego datos del paciente
        _heightController.text = savedHeight?.toString() ??
            (widget.patient.height?.toString() ?? '');

        // Edad: prioridad a datos guardados, luego datos del paciente
        _ageController.text = savedAge?.toString() ??
            (widget.patient.age?.toString() ?? '');

        // Género: prioridad a datos guardados, luego inferir del paciente, luego default
        _selectedGender = savedGender ??
            _inferGenderFromPatient() ??
            'Mujer'; // Valor por defecto

        // Nivel de actividad: prioridad a datos guardados, luego default
        _selectedActivityLevel = savedActivityLevel ?? 'Sedentario';
      });


      // Calcular calorías con los datos cargados
      _calculateAndSaveCalories();

    } catch (e) {
      _usePatientDefaultData();
    }
  }


// Método mejorado para usar datos por defecto del paciente
  void _usePatientDefaultData() {

    setState(() {
      _weightController.text = widget.patient.weight?.toString() ?? '';
      _heightController.text = widget.patient.height?.toString() ?? '';
      _ageController.text = widget.patient.age?.toString() ?? '';

      // Asegurar que el género se infiera correctamente
      _selectedGender = _inferGenderFromPatient() ?? 'Mujer';
      _selectedActivityLevel = 'Sedentario'; // Valor por defecto
    });

  }

  String? _inferGenderFromPatient() {
    if (widget.patient.gender != null && widget.patient.gender!.isNotEmpty) {
      final gender = widget.patient.gender!.toLowerCase().trim();

      // Mapear diferentes variaciones de género a nuestros valores
      if (gender.contains('masculino') ||
          gender.contains('hombre') ||
          gender.contains('male') ||
          gender.contains('m') && gender.length <= 2) {
        return 'Hombre';
      } else if (gender.contains('femenino') ||
          gender.contains('mujer') ||
          gender.contains('female') ||
          gender.contains('f') && gender.length <= 2) {
        return 'Mujer';
      }
    }
  }

  // Método para calcular calorías y guardar en SharedPreferences
  Future<void> _calculateAndSaveCalories() async {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final age = double.tryParse(_ageController.text);

    if (weight != null && height != null && age != null) {
      double tmb; // Tasa Metabólica Basal (TMB)

      // Fórmula de Harris-Benedict (versión revisada)
      if (_selectedGender == 'Hombre') {
        // TMB = 66.4730 + (13.7516 × peso en kg) + (5.0033 × altura en cm) - (6.7550 × edad en años)
        tmb = 66.4730 + (13.7516 * weight) + (5.0033 * height) - (6.7550 * age);
      } else {
        // TMB = 655.0955 + (9.5634 × peso en kg) + (1.8496 × altura en cm) - (4.6756 × edad en años)
        tmb = 655.0955 + (9.5634 * weight) + (1.8496 * height) - (4.6756 * age);
      }

      // Factor de actividad física (AF) - según la imagen
      double activityFactor;
      switch (_selectedActivityLevel) {
        case 'Sedentario': // Encamados: 1.20
          activityFactor = 1.20;
          break;
        case 'Ligeramente activo': // Ambulatorios: 1.1 a 1.5 (promedio 1.3)
          activityFactor = 1.30;
          break;
        case 'Moderadamente activo': // Estrés leve: 1.1 a 1.3 (promedio 1.2)
          activityFactor = 1.20;
          break;
        case 'Muy activo': // Estrés moderado: 1.2 a 1.3 (promedio 1.25)
          activityFactor = 1.25;
          break;
        case 'Extremadamente activo': // Estrés severo: 1.4 a 1.5 (promedio 1.45)
          activityFactor = 1.45;
          break;
        default:
          activityFactor = 1.20;
      }

      // Factor de estrés (FE) - puedes ajustar según necesidades clínicas
      double stressFactor = 1.0; // Por defecto sin estrés adicional

      // Requerimiento diario de energía = TMB × AF × FE
      final calculatedCalories = tmb * activityFactor * stressFactor;

      setState(() {
        _calculatedCalories = calculatedCalories;
      });

      // Guardar en SharedPreferences
      await _saveCalorieDataToPreferences(weight, height, age.toInt(), calculatedCalories);

    } else {
      setState(() {
        _calculatedCalories = 0.0;
      });
    }
  }

  Future<void> _saveCalorieDataToPreferences(double weight, double height, int age, double calories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('patient_${widget.patient.patientId}_weight', weight);
      await prefs.setDouble('patient_${widget.patient.patientId}_height', height);
      await prefs.setInt('patient_${widget.patient.patientId}_age', age);
      await prefs.setString('patient_${widget.patient.patientId}_gender', _selectedGender);
      await prefs.setString('patient_${widget.patient.patientId}_activity_level', _selectedActivityLevel);
      await prefs.setDouble('patient_${widget.patient.patientId}_daily_calories', calories);

      print('✅ Datos de calorías guardados en SharedPreferences');
    } catch (e) {
      print('❌ Error al guardar datos de calorías: $e');
    }
  }

  Future<void> _saveHistory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_authToken == null) {
      _showErrorDialog('Error', 'Token de autenticación no disponible');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear el objeto CreateMedicalHistoryRequest sin los campos de calorías
      final request = CreateMedicalHistoryRequest(
        consultationDate: DateTime.now(),
        bloodGlucose: _bloodGlucoseController.text.isNotEmpty
            ? double.tryParse(_bloodGlucoseController.text)
            : null,
        bloodPressure: _bloodPressureController.text.isNotEmpty
            ? _bloodPressureController.text
            : null,
        waistCircumference: _waistCircumferenceController.text.isNotEmpty
            ? double.tryParse(_waistCircumferenceController.text)
            : null,
        bodyFatPercentage: _bodyFatController.text.isNotEmpty
            ? double.tryParse(_bodyFatController.text)
            : null,
        waterConsumption: _waterConsumptionController.text.isNotEmpty
            ? double.tryParse(_waterConsumptionController.text)
            : null,
        sleepQuality: _sleepQuality.toInt(),
        stressLevel: _stressLevel.toInt(),
        nutritionalObjectives: _nutritionalObjectivesController.text.isNotEmpty
            ? _nutritionalObjectivesController.text
            : null,
        professionalNotes: _professionalNotesController.text.isNotEmpty
            ? _professionalNotesController.text
            : null,
        // Eliminar estos campos si el backend no los soporta:
        // weight, height, age, gender, activityLevel, dailyCalories
      );

      // Llamar al servicio con los parámetros correctos
      final nutritionistService = NutritionistService();
      await nutritionistService.createMedicalHistory(
          widget.patient.patientId,
          request,
          _authToken!
      );

      setState(() {
        _isLoading = false;
      });

      // Mostrar éxito y regresar
      _showSuccessDialog();

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Error al guardar historial: $e');
      _showErrorDialog('Error al guardar', e.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.checkValidation, size: 60),
            const SizedBox(height: 16),
            const Text(
              '¡Historial creado exitosamente!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.checkValidation,
              ),
              textAlign: TextAlign.center,
            ),

            Text(
              'El historial médico de ${widget.patient.fullName} ha sido guardado correctamente.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_calculatedCalories > 0)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:_diseaseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Calorías calculadas: ${_calculatedCalories.toStringAsFixed(0)} kcal/día',
                  style: TextStyle(
                    fontSize: 12,
                    color: _diseaseColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              widget.onHistoryCreated?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.checkValidation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Continuar',
                style: TextStyle(color: Colors.white,
                fontSize: 14
                )),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: _diseaseColor),
            child: Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: _diseaseColor.withOpacity(0.6),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/images/anterior_icon.svg',
              width: 21,
              height: 21,
              color: _diseaseColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Nuevo Historial Médico',
            style: TextStyle(
              color: _diseaseColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/loading/palta_saltarina.json',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'Guardando historial médico...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              _buildPatientHeader(),
              _buildCalorieCalculatorSection(),
              _buildForm(),
            ],
          ),
        ),
        bottomNavigationBar: _isLoading
            ? null
            : SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade500),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Cancelar',
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 16
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveHistory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.checkValidation,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Guardar Historial',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: _diseaseColor.withOpacity(0.2),
            child: Text(
              widget.patient.fullName.isNotEmpty
                  ? widget.patient.fullName[0].toUpperCase()
                  : 'P',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _diseaseColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patient.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Creando primer historial médico',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (_calculatedCalories > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _diseaseColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_calculatedCalories.toStringAsFixed(0)} kcal/día',
                      style: TextStyle(
                        fontSize: 12,
                        color: _diseaseColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieCalculatorSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_diseaseColor.withOpacity(0.2), _diseaseColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _diseaseColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _diseaseColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Calculadora de Energía Diaria',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _usePatientDefaultData,
                icon: Icon(Icons.refresh, size: 16, color: _diseaseColor),
                label: Text(
                  'Restaurar',
                  style: TextStyle(fontSize: 12, color: _diseaseColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Datos precargados del paciente. Puedes editarlos si es necesario.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Datos básicos en fila
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _weightController,
                  label: 'Peso (kg)',
                  hint: '70',
                  keyboardType: TextInputType.number,
                  icon: Icons.monitor_weight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _heightController,
                  label: 'Altura (cm)',
                  hint: '170',
                  keyboardType: TextInputType.number,
                  icon: Icons.height,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _ageController,
                  label: 'Edad',
                  hint: '30',
                  keyboardType: TextInputType.number,
                  icon: Icons.cake,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  label: 'Sexo',
                  value: _selectedGender,
                  options: _genderOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                      _calculateAndSaveCalories();
                    });
                  },
                  icon: Icons.person,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildDropdownField(
            label: 'Nivel de Actividad',
            value: _selectedActivityLevel,
            options: _activityLevels,
            onChanged: (value) {
              setState(() {
                _selectedActivityLevel = value!;
                _calculateAndSaveCalories();
              });
            },
            icon: Icons.fitness_center,
          ),

          const SizedBox(height: 20),

          // Resultado del cálculo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_diseaseColor, _diseaseColor.withOpacity(0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),

            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_fire_department,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Energía Diaria Necesaria',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _calculatedCalories > 0
                      ? '${_calculatedCalories.toStringAsFixed(0)} kcal/día'
                      : 'Completa los datos para calcular',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_calculatedCalories > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Basado en fórmula Harris-Benedict\nGuardado localmente',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: _diseaseColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _diseaseColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos Médicos Adicionales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Glucosa en sangre
            _buildTextField(
              controller: _bloodGlucoseController,
              label: 'Glucosa en Sangre (mg/dL)',
              hint: 'Ej: 120',
              keyboardType: TextInputType.number,
              icon: Icons.bloodtype,
            ),

            const SizedBox(height: 16),

            // Presión arterial
            _buildTextField(
              controller: _bloodPressureController,
              label: 'Presión Arterial',
              hint: 'Ej: 120/80',
              icon: Icons.favorite,
            ),

            const SizedBox(height: 16),

            // Circunferencia de cintura
            _buildTextField(
              controller: _waistCircumferenceController,
              label: 'Circunferencia de Cintura (cm)',
              hint: 'Ej: 85',
              keyboardType: TextInputType.number,
              icon: Icons.straighten,
            ),

            const SizedBox(height: 16),

            // Porcentaje de grasa corporal
            _buildTextField(
              controller: _bodyFatController,
              label: 'Porcentaje de Grasa Corporal (%)',
              hint: 'Ej: 25',
              keyboardType: TextInputType.number,
              icon: Icons.monitor_weight,
            ),

            const SizedBox(height: 16),

            // Consumo de agua
            _buildTextField(
              controller: _waterConsumptionController,
              label: 'Consumo de Agua (Litros/día)',
              hint: 'Ej: 2.5',
              keyboardType: TextInputType.number,
              icon: Icons.water_drop,
            ),

            const SizedBox(height: 20),

            // Calidad del sueño
            _buildSliderField(
              label: 'Calidad del Sueño',
              value: _sleepQuality,
              onChanged: (value) => setState(() => _sleepQuality = value),
              icon: Icons.bedtime,
              min: 1,
              max: 10,
            ),

            const SizedBox(height: 20),

            // Nivel de estrés
            _buildSliderField(
              label: 'Nivel de Estrés',
              value: _stressLevel,
              onChanged: (value) => setState(() => _stressLevel = value),
              icon: Icons.psychology,
              min: 1,
              max: 10,
            ),

            const SizedBox(height: 20),

            // Objetivos nutricionales
            _buildTextArea(
              controller: _nutritionalObjectivesController,
              label: 'Objetivos Nutricionales',
              hint: 'Describe los objetivos nutricionales del paciente...',
              icon: Icons.track_changes,
            ),

            const SizedBox(height: 16),

            // Notas profesionales
            _buildTextArea(
              controller: _professionalNotesController,
              label: 'Notas Profesionales',
              hint: 'Observaciones adicionales, recomendaciones...',
              icon: Icons.note_alt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: _diseaseColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _diseaseColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required IconData icon,
    required double min,
    required double max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: _diseaseColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _diseaseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${value.toInt()}/10',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _diseaseColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _diseaseColor,
            inactiveTrackColor: _diseaseColor.withOpacity(0.3),
            thumbColor: _diseaseColor,
            overlayColor: _diseaseColor.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            label: value.toInt().toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: _diseaseColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _diseaseColor),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _bloodGlucoseController.dispose();
    _bloodPressureController.dispose();
    _waistCircumferenceController.dispose();
    _bodyFatController.dispose();
    _waterConsumptionController.dispose();
    _nutritionalObjectivesController.dispose();
    _professionalNotesController.dispose();
    super.dispose();
  }
}