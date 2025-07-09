import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../../../configuration/themes/app_colors.dart';

enum DiseaseType { diabetes, hipertension, obesity }

class CreatePatientScreen extends StatefulWidget {
  final DiseaseType diseaseType;

  const CreatePatientScreen({
    Key? key,
    required this.diseaseType,
  }) : super(key: key);

  @override
  State<CreatePatientScreen> createState() => _CreatePatientScreenState();
}

class _CreatePatientScreenState extends State<CreatePatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controladores de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _chronicDiseaseController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _dietaryPreferencesController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedGender = 'Masculino';
  bool _hasMedicalCondition = true; // Siempre true ya que viene con una enfermedad específica
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _genders = ['Masculino', 'Femenino', 'Otro'];

  // Obtener configuración según el tipo de enfermedad
  String get _diseaseTitle {
    switch (widget.diseaseType) {
      case DiseaseType.diabetes:
        return 'Diabetes';
      case DiseaseType.hipertension:
        return 'Hipertensión';
      case DiseaseType.obesity:
        return 'Obesidad';
    }
  }

  Color get _diseaseColor {
    switch (widget.diseaseType) {
      case DiseaseType.diabetes:
        return AppColors.secondary; // Anaranjado
      case DiseaseType.hipertension:
        return AppColors.backgroundHipertencion;
      case DiseaseType.obesity:
        return AppColors.backgroundObecidad;
    }
  }

  String get _diseaseValue {
    switch (widget.diseaseType) {
      case DiseaseType.diabetes:
        return 'diabetes';
      case DiseaseType.hipertension:
        return 'hipertension';
      case DiseaseType.obesity:
        return 'obesidad';
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-llenar el campo de enfermedad crónica
    _chronicDiseaseController.text = _diseaseTitle;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _chronicDiseaseController.dispose();
    _allergiesController.dispose();
    _dietaryPreferencesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _diseaseColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createPatient() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    if (_selectedDate == null) {
      _showErrorSnackBar('Por favor selecciona la fecha de nacimiento');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final patientData = {
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "birthDate": _selectedDate!.toIso8601String().split('T')[0],
        "phone": _phoneController.text.trim(),
        "height": double.tryParse(_heightController.text) ?? 0,
        "weight": double.tryParse(_weightController.text) ?? 0,
        "hasMedicalCondition": _hasMedicalCondition,
        "chronicDisease": _chronicDiseaseController.text.trim(),
        "allergies": _allergiesController.text.trim().isEmpty ? null : _allergiesController.text.trim(),
        "dietaryPreferences": _dietaryPreferencesController.text.trim().isEmpty ? null : _dietaryPreferencesController.text.trim(),
        "gender": _selectedGender.toLowerCase() == 'masculino' ? 'male' :
        _selectedGender.toLowerCase() == 'femenino' ? 'female' : 'other',
        "diseaseType": _diseaseValue,
      };

      // LOG: Imprimir datos que se van a enviar
      print('=== DATOS A ENVIAR ===');
      print(json.encode(patientData));
      print('======================');

      final response = await http.post(
        Uri.parse('https://mottinut-backend-2025-djf0f5c0hjckhpgp.centralus-01.azurewebsites.net/api/bff/auth/register/patient'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(patientData),
      );

      // LOG: Imprimir respuesta completa
      print('=== RESPUESTA DEL SERVIDOR ===');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');
      print('==============================');

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        // Mostrar el cuerpo de la respuesta en el error
        String errorMessage = 'Error ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = json.decode(response.body);
            errorMessage = errorData['message'] ?? errorData.toString();
          } catch (e) {
            errorMessage = response.body;
          }
        }
        _showErrorSnackBar('Error: $errorMessage');
      }
    } catch (e) {
      // LOG: Imprimir error de excepción
      print('=== ERROR DE EXCEPCIÓN ===');
      print('Error: $e');
      print('Type: ${e.runtimeType}');
      print('==========================');

      _showErrorSnackBar('Error de conexión: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToFirstError() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorText,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.checkValidation, size: 28),
              const SizedBox(width: 12),
              const Text('¡Éxito!'),
            ],
          ),
          content: Text('El paciente con $_diseaseTitle ha sido creado exitosamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Volver a la pantalla anterior
              },
              child: Text('Aceptar', style: TextStyle(color: _diseaseColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _diseaseColor,
        foregroundColor: Colors.white,
        title: Text(
          'Crear Paciente - $_diseaseTitle',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _diseaseColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: 35,
                        color: _diseaseColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Registro de Paciente - $_diseaseTitle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completa todos los campos para crear el perfil del paciente con $_diseaseTitle',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Información Personal
              _buildSectionTitle('Información Personal'),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _firstNameController,
                label: 'Nombre',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _lastNameController,
                label: 'Apellido',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El apellido es requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Fecha de nacimiento
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: _diseaseColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha de Nacimiento',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Seleccionar fecha',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDate != null ? Colors.black : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Género
              _buildDropdownField(
                value: _selectedGender,
                label: 'Género',
                icon: Icons.wc,
                items: _genders,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Información de Contacto
              _buildSectionTitle('Información de Contacto'),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'Correo Electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El correo es requerido';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _passwordController,
                label: 'Contraseña',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: _diseaseColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es requerida';
                  }
                  if (value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneController,
                label: 'Teléfono',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El teléfono es requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Información Física
              _buildSectionTitle('Información Física'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _heightController,
                      label: 'Altura (cm)',
                      icon: Icons.height,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        final height = double.tryParse(value);
                        if (height == null || height <= 0) {
                          return 'Altura inválida';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _weightController,
                      label: 'Peso (kg)',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0) {
                          return 'Peso inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Información Médica
              _buildSectionTitle('Información Médica'),
              const SizedBox(height: 16),

              // Enfermedad específica (pre-llenado y no editable)
              _buildTextField(
                controller: _chronicDiseaseController,
                label: 'Enfermedad Crónica',
                icon: Icons.local_hospital_outlined,
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La enfermedad es requerida';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _allergiesController,
                label: 'Alergias',
                icon: Icons.warning_outlined,
                maxLines: 2,
                hintText: 'Especifica alergias alimentarias o de medicamentos',
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _dietaryPreferencesController,
                label: 'Preferencias Alimentarias',
                icon: Icons.restaurant_outlined,
                maxLines: 2,
                hintText: 'Vegetariano, vegano, sin gluten, etc.',
              ),

              const SizedBox(height: 32),

              // Botón de crear
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _diseaseColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isLoading
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Creando paciente...'),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Crear Paciente - $_diseaseTitle',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? hintText,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: _diseaseColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _diseaseColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorText, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorText, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _diseaseColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        dropdownColor: Colors.white,
      ),
    );
  }
}