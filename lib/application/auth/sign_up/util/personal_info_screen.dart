import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import '../../../../configuration/themes/app_colors.dart';
import 'impInf/photo_tutorial_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  final String initialNombre;
  final String initialApellido;
  final File? initialPhoto;
  final Function(String nombre, String apellido, File? photo) onDataChanged;

  const PersonalInfoScreen({
    Key? key,
    required this.initialNombre,
    required this.initialApellido,
    this.initialPhoto,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  PersonalInfoScreenState createState() => PersonalInfoScreenState();
}

class PersonalInfoScreenState extends State<PersonalInfoScreen> {
  // Controllers para mantener los valores
  late TextEditingController nombreController;
  late TextEditingController apellidoController;

  // Focus nodes
  FocusNode nombreFocus = FocusNode();
  FocusNode apellidoFocus = FocusNode();

  // Error states
  String nombreError = '';
  String apellidoError = '';
  String photoError = '';

  // Variables locales
  String nombre = '';
  String apellido = '';
  File? selectedPhoto;

  @override
  void initState() {
    super.initState();

    // Inicializar con valores del padre
    nombre = widget.initialNombre;
    apellido = widget.initialApellido;
    selectedPhoto = widget.initialPhoto;

    // Inicializar controllers
    nombreController = TextEditingController(text: nombre);
    apellidoController = TextEditingController(text: apellido);

    // Agregar listeners para detectar cuando se pierde el foco
    nombreFocus.addListener(() {
      if (!nombreFocus.hasFocus) {
        _validateNombre();
      }
    });

    apellidoFocus.addListener(() {
      if (!apellidoFocus.hasFocus) {
        _validateApellido();
      }
    });
  }

  @override
  void dispose() {
    nombreFocus.dispose();
    apellidoFocus.dispose();
    nombreController.dispose();
    apellidoController.dispose();
    super.dispose();
  }

  // Validaciones
  void _validateNombre() {
    setState(() {
      if (nombre.trim().isEmpty) {
        nombreError = '* El nombre es requerido';
      } else if (nombre.trim().length < 2) {
        nombreError = '* El nombre debe tener al menos 2 caracteres';
      } else {
        nombreError = '';
      }
    });
  }

  void _validateApellido() {
    setState(() {
      if (apellido.trim().isEmpty) {
        apellidoError = '* El apellido es requerido';
      } else if (apellido.trim().length < 2) {
        apellidoError = '* El apellido debe tener al menos 2 caracteres';
      } else {
        apellidoError = '';
      }
    });
  }

  void _validatePhoto() {
    setState(() {
      if (selectedPhoto == null) {
        photoError = '* La foto de perfil es requerida';
      } else {
        photoError = '';
      }
    });
  }

  // Método para seleccionar foto
  void _selectPhoto() async {
    try {
      // Navegar a la pantalla de tutorial
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoTutorialScreen(),
        ),
      );

      // Verificar si el resultado es válido
      if (result != null && result is File) {
        // Verificar que el archivo existe
        if (await result.exists()) {
          setState(() {
            selectedPhoto = result;
            photoError = '';
          });

          // Notificar al padre sobre los cambios
          widget.onDataChanged(nombre, apellido, selectedPhoto);

          print('✅ Foto guardada exitosamente en PersonalInfoScreen');
        } else {
          print('❌ El archivo de imagen no existe');
          _showErrorMessage('Error: El archivo de imagen no es válido');
        }
      } else {
        print('⚠️ No se seleccionó ninguna imagen válida');
      }
    } catch (e) {
      print('💥 Error en _selectPhoto: $e');
      _showErrorMessage('Error al seleccionar la foto: ${e.toString()}');
    }
  }

// Método para mostrar mensajes de error
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Método público para validar desde el padre
  bool isValid() {
    _validateNombre();
    _validateApellido();
    _validatePhoto();
    return nombre.trim().isNotEmpty &&
        apellido.trim().isNotEmpty &&
        nombre.trim().length >= 2 &&
        apellido.trim().length >= 2 &&
        selectedPhoto != null &&
        nombreError.isEmpty &&
        apellidoError.isEmpty &&
        photoError.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),

              // Título
              const Center(
                  child: Text(
                'Información Personal',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.88,
                ),
                textAlign: TextAlign.center,
              )),
              SizedBox(height: 3),
              Center(
                child: Text(
                  'Añade tus datos personales',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.36
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),

              // Foto de perfil
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _selectPhoto,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: photoError.isNotEmpty
                                    ? AppColors.errorText
                                    : AppColors.primary,
                                width: photoError.isNotEmpty
                                    ? 3 : 3,
                              ),
                            ),
                            child: selectedPhoto != null
                                ? ClipOval(
                              child: Image.file(
                                selectedPhoto!,
                                fit: BoxFit.cover,
                                width: 140,
                                height: 140,
                              ),
                            )
                                : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.08),
                              ),
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withOpacity(0.1),
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/images/user_icon.svg',
                                    width: 100,
                                    height: 100,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (selectedPhoto != null)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _selectPhoto,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Solo mostrar el botón si no hay foto seleccionada
                    if (selectedPhoto == null) ...[
                      SizedBox(height: 12),
                      GestureDetector(
                        onTap: _selectPhoto,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Agregar foto',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: selectedPhoto == null ? 6 : 6),

                    Text(
                      selectedPhoto == null
                          ? 'Tu foto ayuda a generar confianza con tus pacientes'
                          : 'Toca el ícono de edición para cambiar tu foto',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (photoError.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 6),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.errorText.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.errorText.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 16,
                              color: AppColors.errorText,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                photoError,
                                style: TextStyle(
                                  color: AppColors.errorText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 12),

              // Nombre
              Text(
                'Nombre',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              TextField(
                controller: nombreController,
                focusNode: nombreFocus,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLDark
                ),
                onChanged: (value) {
                  setState(() {
                    nombre = value;
                    if (value.isNotEmpty && nombreError.isNotEmpty) {
                      nombreError = '';
                    }
                  });
                  // Notificar al padre sobre los cambios
                  widget.onDataChanged(nombre, apellido, selectedPhoto);
                },
                decoration: InputDecoration(
                  hintText: 'Ingrese sus nombres',
                  hintStyle:
                      TextStyle(color: AppColors.textInput, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      width: 1.4,
                      color: nombreError.isNotEmpty
                          ? AppColors.errorText
                          : AppColors.textInput,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      width: 1.4,
                      color: nombreError.isNotEmpty
                          ? AppColors.errorText
                          : AppColors.textInput,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      width: 1.4,
                      color: nombreError.isNotEmpty
                          ? AppColors.errorText
                          : AppColors.primary,
                    ),
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
              if (nombreError.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4, left: 16),
                  child: Text(
                    nombreError,
                    style: TextStyle(
                      color: AppColors.errorText,
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(height: 24),

              // Apellido
              Text(
                'Apellidos',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              TextField(
                controller: apellidoController,
                focusNode: apellidoFocus,
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLDark
                ),
                onChanged: (value) {
                  setState(() {
                    apellido = value;
                    if (value.isNotEmpty && apellidoError.isNotEmpty) {
                      apellidoError = '';
                    }
                  });
                  // Notificar al padre sobre los cambios
                  widget.onDataChanged(nombre, apellido, selectedPhoto);
                },
                decoration: InputDecoration(
                  hintText: 'Ingrese sus apellidos',
                  hintStyle:
                      TextStyle(color: AppColors.textInput, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      width: 1.4,
                      color: apellidoError.isNotEmpty
                          ? AppColors.errorText
                          : AppColors.textInput,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      width: 1.4,
                      color: apellidoError.isNotEmpty
                          ? AppColors.errorText
                          : AppColors.textInput,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      width: 1.4,
                      color: apellidoError.isNotEmpty
                          ? AppColors.errorText
                          : AppColors.primary,
                    ),
                  ),

                  contentPadding: EdgeInsets.all(16),
                ),
              ),
              if (apellidoError.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4, left: 16),
                  child: Text(
                    apellidoError,
                    style: TextStyle(
                      color: AppColors.errorText,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
