import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/servicesColeg/validate_services_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../configuration/themes/app_colors.dart';
import 'dart:async';

import '../../../requestSnacbar/snackBar_manager.dart';

class ColegiaturaVerificationScreen extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String email;
  final String contrasena;
  final Function(String codeCNP, List<File> photoCNP, bool termsAccepted)?
      onValidationComplete;
  final VoidCallback? onVerificationStart;
  final VoidCallback? onVerificationSuccess;

  const ColegiaturaVerificationScreen({
    Key? key,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.contrasena,
    this.onValidationComplete,
    this.onVerificationStart,
    this.onVerificationSuccess,
  }) : super(key: key);

  @override
  ColegiaturaVerificationScreenState createState() =>
      ColegiaturaVerificationScreenState();
}

class ColegiaturaVerificationScreenState
    extends State<ColegiaturaVerificationScreen> {
  // Variables para colegiatura
  List<String> colegiaturaDigits = ['', '', '', ''];
  List<FocusNode> colegiaturaFocusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ];
  String colegiaturaErrorMessage = '';
  List<TextEditingController> colegiaturaControllers = [];

  // Variables para imágenes - MODIFICADO para requerir exactamente 2 imágenes
  List<File> carneImages = [];
  List<String> imageTypes = []; // Para trackear si es 'galeria' o 'camara'
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;
  bool isVerifying = false;
  bool colegiaturaVerified = false;
  bool isValidatingImage = false;

  // Variables para vista de imagen ampliada
  bool showImageViewer = false;
  int currentImageIndex = 0;

  // Variables para términos
  bool termsAccepted = false;

  // Validación automática está habilitada
  bool autoValidationEnabled = false;

  // ML Kit instances
  late TextRecognizer textRecognizer;
  late ObjectDetector objectDetector;

  bool _showPageIndicator = false;
  bool _showSwipeInstructions = true;
  Timer? _pageIndicatorTimer;
  Timer? _swipeInstructionsTimer;

  // Constantes para SharedPreferences
  static const String _keyColegiaturaDigits = 'colegiatura_digits';
  static const String _keyCarneImagePaths = 'carne_image_paths';
  static const String _keyImageTypes = 'image_types';
  static const String _keyTermsAccepted = 'terms_accepted';
  static const String _keyColegiaturaVerified = 'colegiatura_verified';

  @override
  void initState() {
    super.initState();

    // Inicializar ML Kit
    _initializeMLKit();

    // Cargar datos guardados
    _loadSavedData();

    _swipeInstructionsTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSwipeInstructions = false;
        });
      }
    });

    // Inicializar controllers para colegiatura
    for (int i = 0; i < 4; i++) {
      colegiaturaControllers
          .add(TextEditingController(text: colegiaturaDigits[i]));
    }

    // Listeners para campos de colegiatura
    for (int i = 0; i < colegiaturaFocusNodes.length; i++) {
      colegiaturaFocusNodes[i].addListener(() {
        if (!colegiaturaFocusNodes[i].hasFocus) {
          _validateColegiatura();
          _checkAutoValidation();
        }
      });
    }
  }

  void _initializeMLKit() {
    // Inicializar reconocedor de texto
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    // Configurar detector de objetos
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: false,
    );
    objectDetector = ObjectDetector(options: options);
  }

  // Método para cargar datos guardados
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cargar dígitos de colegiatura
      final savedDigits = prefs.getStringList(_keyColegiaturaDigits);
      if (savedDigits != null && savedDigits.length == 4) {
        setState(() {
          colegiaturaDigits = savedDigits;
          // Actualizar controllers
          for (int i = 0; i < 4; i++) {
            if (colegiaturaControllers.length > i) {
              colegiaturaControllers[i].text = colegiaturaDigits[i];
            }
          }
        });
      }

      // Cargar rutas de imágenes
      final savedImagePaths = prefs.getStringList(_keyCarneImagePaths);
      final savedImageTypes = prefs.getStringList(_keyImageTypes);

      if (savedImagePaths != null && savedImageTypes != null) {
        List<File> validImages = [];
        List<String> validTypes = [];

        // Verificar que los archivos aún existen
        for (int i = 0; i < savedImagePaths.length; i++) {
          final file = File(savedImagePaths[i]);
          if (await file.exists()) {
            validImages.add(file);
            if (i < savedImageTypes.length) {
              validTypes.add(savedImageTypes[i]);
            }
          }
        }

        if (validImages.isNotEmpty) {
          setState(() {
            carneImages = validImages;
            imageTypes = validTypes;
          });
        }
      }

      // Cargar estado de términos
      final savedTermsAccepted = prefs.getBool(_keyTermsAccepted) ?? false;
      setState(() {
        termsAccepted = savedTermsAccepted;
      });

      // Cargar estado de verificación
      final savedColegiaturaVerified = prefs.getBool(_keyColegiaturaVerified) ?? false;
      setState(() {
        colegiaturaVerified = savedColegiaturaVerified;
      });

      // Validar datos después de cargar
      _validateColegiatura();
      _checkAutoValidation();

    } catch (e) {
      print('Error al cargar datos guardados: $e');
    }
  }

  //Método para guardar datos
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardar dígitos de colegiatura
      await prefs.setStringList(_keyColegiaturaDigits, colegiaturaDigits);

      // Guardar rutas de imágenes
      final imagePaths = carneImages.map((file) => file.path).toList();
      await prefs.setStringList(_keyCarneImagePaths, imagePaths);
      await prefs.setStringList(_keyImageTypes, imageTypes);

      // Guardar estado de términos
      await prefs.setBool(_keyTermsAccepted, termsAccepted);

      // Guardar estado de verificación
      await prefs.setBool(_keyColegiaturaVerified, colegiaturaVerified);

    } catch (e) {
      print('Error al guardar datos: $e');
    }
  }

  //Método para limpiar datos guardados
  Future<void> _clearSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyColegiaturaDigits);
      await prefs.remove(_keyCarneImagePaths);
      await prefs.remove(_keyImageTypes);
      await prefs.remove(_keyTermsAccepted);
      await prefs.remove(_keyColegiaturaVerified);
    } catch (e) {
      print('Error al limpiar datos: $e');
    }
  }

  void _checkAutoValidation() {
    if (_isFormValid() &&
        termsAccepted &&
        !isVerifying &&
        !colegiaturaVerified) {
      autoValidationEnabled = true;
      _verifyColegiatura();
    }
  }

  //  Getter público para acceder al estado de términos
  bool get areTermsAccepted => termsAccepted;

  Map<String, dynamic> getValidationData() {
    return {
      'codeCNP': colegiaturaDigits.join(''),
      'photoCNP': carneImages,
      'termsAccepted': termsAccepted,
      'isValid': isValid(),
    };
  }

  // MÉTODO MODIFICADO: Ahora requiere exactamente 2 imágenes
  bool _isFormValid() {
    String fullNumber = colegiaturaDigits.join('');

    // Validar que el número de colegiatura esté completo y sea válido
    bool colegiaturaValid =
        fullNumber.length == 4 && RegExp(r'^[0-9]+$').hasMatch(fullNumber);

    // Validar que tenga exactamente 2 imágenes válidas
    bool imagesValid = carneImages.length == 2;

    return colegiaturaValid && imagesValid;
  }

  // MÉTODO PÚBLICO para que el padre pueda validar
  bool isValid() {
    return _isFormValid() &&
        termsAccepted &&
        (colegiaturaVerified || autoValidationEnabled);
  }

  // Validación de número colegiatura
  void _validateColegiatura() {
    setState(() {
      String fullNumber = colegiaturaDigits.join('');
      if (fullNumber.length < 4) {
        colegiaturaErrorMessage = '* Ingresa tu número de colegiatura completo';
      } else if (!RegExp(r'^[0-9]+$').hasMatch(fullNumber)) {
        colegiaturaErrorMessage = '* Solo se permiten números';
      } else {
        colegiaturaErrorMessage = '';
      }

      // Verificar validación automática
      _checkAutoValidation();
    });

    // NUEVO: Guardar datos después de validar
    _saveData();
  }

  // Mostrar imagen ampliada
  void _showImageViewer(int index) {
    setState(() {
      currentImageIndex = index;
      showImageViewer = true;
    });
  }

  // Cerrar vista de imagen ampliada
  void _closeImageViewer() {
    setState(() {
      showImageViewer = false;
    });
  }

  // Eliminar imagen desde el visor
  void _removeImageFromViewer() {
    setState(() {
      imageTypes.removeAt(currentImageIndex);
      carneImages.removeAt(currentImageIndex);
      showImageViewer = false;
      // Reset validaciones si hay menos de 2 imágenes
      if (carneImages.length < 2) {
        colegiaturaVerified = false;
        autoValidationEnabled = false;
      }
    });
  }

  // MÉTODO MODIFICADO: Lógica mejorada para selección de imágenes
  Future<void> _pickImage() async {
    if (carneImages.length >= 2) {
      SnackBarManager.showInfo(
          context, 'Ya tienes las 2 fotos requeridas del carné');
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      // Mostrar opciones disponibles
      final Map<String, dynamic>? selectedOption =
          await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
            builder: (BuildContext context) {
              return SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: Text(
                                'Foto ${carneImages.length + 1} de 2',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        Divider(height: 0.3, color: Colors.grey, thickness: 0.5),

                        // Opciones
                        ListTile(
                          leading: Icon(Icons.photo_library, color: AppColors.primary),
                          title: Text(
                            'Galería',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Seleccionar desde galería',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          onTap: () => Navigator.pop(context, {
                            'source': ImageSource.gallery,
                            'type': 'galeria',
                          }),
                        ),

                        ListTile(
                          leading: Icon(Icons.photo_camera, color: AppColors.primary),
                          title: Text(
                            'Cámara',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Tomar foto nueva',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          onTap: () => Navigator.pop(context, {
                            'source': ImageSource.camera,
                            'type': 'camara',
                          }),
                        ),

                        SizedBox(height: 5),
                      ],
                    ),
                  ),
                ),
              );
            },
          );

      if (selectedOption == null) {
        setState(() {
          isUploading = false;
        });
        return;
      }

      // Solicitar permisos y proceder
      await _processImageSelection(selectedOption);
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      SnackBarManager.showError(
          context, 'Error al acceder a los permisos: $e');
    }
  }

  Future<void> _processImageSelection(Map<String, dynamic> option) async {
    ImageSource source = option['source'];
    String type = option['type'];

    // Solicitar permisos específicos
    PermissionStatus permissionStatus;

    if (source == ImageSource.camera) {
      permissionStatus = await Permission.camera.request();
      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        setState(() {
          isUploading = false;
        });
        _showPermissionDialog('cámara');
        return;
      }
    } else {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          permissionStatus = await Permission.photos.request();
        } else {
          permissionStatus = await Permission.storage.request();
        }
      } else {
        permissionStatus = await Permission.photos.request();
      }

      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        setState(() {
          isUploading = false;
        });
        _showPermissionDialog('galería');
        return;
      }
    }

    // Proceder con la selección de imagen
    await _getImageFromSource(source, type);
  }

  void _showPermissionDialog(String tipo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permiso requerido'),
          content: Text(
            'Para usar la $tipo, necesitas otorgar los permisos correspondientes. '
            '¿Deseas ir a configuración para habilitarlos?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Configuración'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getImageFromSource(ImageSource source, String type) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // NUEVO: Mostrar pantalla de validación
        await _showValidationScreen(imageFile, type);
      } else {
        setState(() {
          isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      SnackBarManager.showError(context, 'Error al seleccionar imagen: $e');
    }
  }

  Future<void> _showValidationScreen(File imageFile, String type) async {
    // Navegar a la pantalla de validación como una clase/página independiente
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true, // Hace que se abra como pantalla completa
        builder: (context) => ValidationScreen(
          imageFile: imageFile,
          onValidationComplete:
              (bool isValid, Map<String, dynamic>? analysisData) async {
            // Retornar el resultado para procesarlo en la pantalla anterior
            Navigator.of(context).pop({
              'isValid': isValid,
              'analysisData': analysisData,
            });
          },
        ),
      ),
    );

    // Procesar el resultado después de regresar de la pantalla de validación
    if (result != null) {
      final bool isValid = result['isValid'] ?? false;
      final Map<String, dynamic>? analysisData = result['analysisData'];

      if (result != null) {
        final bool isValid = result['isValid'] ?? false;
        final Map<String, dynamic>? analysisData = result['analysisData'];

        if (isValid) {
          // Si es válido, agregarlo a la lista
          setState(() {
            carneImages.add(imageFile);
            imageTypes.add(type);
            isUploading = false;
          });

          // NUEVO: Guardar datos después de agregar imagen
          await _saveData();

          SnackBarManager.showSuccess(
              context, 'Carnet válido agregado (${carneImages.length}/2)');

          _checkAutoValidation();
        } else {
          // Si no es válido, no agregar y mostrar mensaje
          setState(() {
            isUploading = false;
          });
          SnackBarManager.showError(context,
              'La imagen no es un carnet válido. Intenta con otra imagen.');
        }
      } else {
        // Si el usuario canceló o no hay resultado
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      imageTypes.removeAt(index);
      carneImages.removeAt(index);
      // Reset de validación si se elimina una imagen crítica
      if (carneImages.length < 2) {
        colegiaturaVerified = false;
        autoValidationEnabled = false;
      }
    });

    // NUEVO: Guardar datos después de eliminar
    _saveData();

    // Verificar si aún es válido después de eliminar
    _checkAutoValidation();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // MÉTODO PÚBLICO para que el padre pueda iniciar la verificación
  void startVerification() {
    if (_isFormValid() && termsAccepted) {
      _verifyColegiatura();
    } else {
      _showValidationErrors();
    }
  }

  void _showValidationErrors() {
    String message = '';

    if (!_isFormValid()) {
      String fullNumber = colegiaturaDigits.join('');
      if (fullNumber.length < 4) {
        message = 'Completa tu número de colegiatura';
      } else if (carneImages.length < 2) {
        message = 'Agrega 2 fotos del carné (${carneImages.length}/2)';
      }
    } else if (!termsAccepted) {
      message = 'Debes aceptar los términos y condiciones';
    }

    _showSnackBar(message);
  }

  Future<void> _verifyColegiatura() async {
    if (isVerifying) return;

    widget.onVerificationStart?.call();

    setState(() {
      isVerifying = true;
    });

    try {
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        isVerifying = false;
        colegiaturaVerified = true;
      });

      // NUEVO: Guardar datos después de verificar
      await _saveData();

      await Future.delayed(Duration(seconds: 2));

      setState(() {
        colegiaturaVerified = false;
      });

      String fullNumber = colegiaturaDigits.join('');
      // MODIFICADO: Pasar también el estado de términos
      widget.onValidationComplete?.call(fullNumber, carneImages, termsAccepted);
      widget.onVerificationSuccess?.call();

      // NUEVO: Limpiar datos después de completar el proceso
      await _clearSavedData();

    } catch (e) {
      setState(() {
        isVerifying = false;
        colegiaturaVerified = false;
        autoValidationEnabled = false;
      });
      SnackBarManager.showError(
          context, 'Error en la verificación. Inténtalo nuevamente.');
    }
  }

  // NUEVO: Método público para limpiar datos (opcional)
  Future<void> clearAllData() async {
    setState(() {
      colegiaturaDigits = ['', '', '', ''];
      carneImages.clear();
      imageTypes.clear();
      termsAccepted = false;
      colegiaturaVerified = false;
      autoValidationEnabled = false;
      colegiaturaErrorMessage = '';

      // Limpiar controllers
      for (int i = 0; i < colegiaturaControllers.length; i++) {
        colegiaturaControllers[i].clear();
      }
    });

    await _clearSavedData();
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              termsAccepted = !termsAccepted;
            });
            _checkAutoValidation();

            _saveData();
          },
          child: Container(
            width: 55,
            height: 55,
            alignment: Alignment.center,
            child: termsAccepted
                ? SvgPicture.asset(
                    'assets/images/icon_verificado.svg',
                    width: 50,
                    height: 50,
                  )
                : SvgPicture.asset(
                    'assets/images/check_autorization.svg',
                    width: 30,
                    height: 30,
                  ),
          ),
        ),
        Expanded(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                color: AppColors.textInput,
                fontSize: 12,
              ),
              children: [
                TextSpan(
                    text:
                        'Autorizo la verificación de mi colegiatura en el Colegio de Nutricionistas del Perú (CNP), conforme a lo dispuesto en la ',
                    style: TextStyle(height: 1.3)),
                TextSpan(
                  text: 'Ley N.° 29885',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // MÉTODO MODIFICADO: Indicador de estado mejorado
  Widget _buildValidationStatus() {
    if (isValidatingImage) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Validando carnet con IA...',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (isVerifying) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Verificando colegiatura...',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (colegiaturaVerified ||
        (autoValidationEnabled && _isFormValid() && termsAccepted)) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            SizedBox(width: 8),
            Text(
              'Colegiatura verificada',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (carneImages.length > 0 && carneImages.length < 2) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info, color: Colors.blue, size: 16),
            SizedBox(width: 8),
            Text(
              'Agrega ${2 - carneImages.length} foto más (${carneImages.length}/2)',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (_isFormValid() && !termsAccepted) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Text(
                'Acepta los términos para continuar',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),

                  // Título
                  const Center(
                    child: Text(
                      '¿Cuál es tu número de\ncolegiatura?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 8),

                  Center(
                    child: Text(
                      'Verificaremos tu credencial para mantener\nla seguridad de la plataforma',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 40),

                  // Campos de dígitos (código existente)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) {
                      // ... (código existente para los campos de dígitos)
                      bool hasValue = colegiaturaDigits[index].isNotEmpty;
                      bool hasError = colegiaturaErrorMessage.isNotEmpty &&
                          colegiaturaDigits[index].isEmpty;
                      bool hasFocus = colegiaturaFocusNodes[index].hasFocus;

                      Color borderColor;
                      Color backgroundColor;

                      if (hasError) {
                        borderColor = AppColors.errorText;
                        backgroundColor = AppColors.errorText.withOpacity(0.05);
                      } else if (hasFocus || hasValue) {
                        borderColor = AppColors.primary;
                        backgroundColor =
                            hasValue ? AppColors.primary : Colors.white;
                      } else {
                        borderColor = Colors.grey[400]!;
                        backgroundColor = Colors.white;
                      }

                      return Container(
                        width: 72,
                        height: 54,
                        decoration: BoxDecoration(
                          border: Border.all(width: 1, color: borderColor),
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: colegiaturaControllers[index],
                          focusNode: colegiaturaFocusNodes[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: hasValue ? Colors.white : Colors.grey[600]!,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          cursorColor:
                              hasValue ? Colors.white : AppColors.primary,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                          ),
                            onChanged: (value) {
                              setState(() {
                                colegiaturaDigits[index] = value;
                                colegiaturaControllers[index].text = value;

                                if (value.isNotEmpty) {
                                  if (index < 3) {
                                    colegiaturaFocusNodes[index + 1].requestFocus();
                                  } else {
                                    colegiaturaFocusNodes[index].unfocus();
                                  }
                                } else if (value.isEmpty && index > 0) {
                                  colegiaturaFocusNodes[index - 1].requestFocus();
                                }

                                if (colegiaturaErrorMessage.isNotEmpty) {
                                  colegiaturaErrorMessage = '';
                                }
                              });

                              // Verificar validación automática
                              _checkAutoValidation();

                              // NUEVO: Guardar datos después de cambiar
                              _saveData();
                            }
                        ),
                      );
                    }),
                  ),

                  // Mensaje de error (código existente)
                  if (colegiaturaErrorMessage.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4, left: 22),
                      child: Text(
                        colegiaturaErrorMessage,
                        style: const TextStyle(
                          color: AppColors.errorText,
                          fontSize: 10,
                        ),
                      ),
                    ),

                  // Enlace "¿No recuerdas tu número?" (código existente)
                  const SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.only(left: 28),
                    child: Row(
                      children: [
                        const Text(
                          '¿No recuerdas tu número? ',
                          style: TextStyle(
                              color: AppColors.textCuatary,
                              fontWeight: FontWeight.w400),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/buscar');
                          },
                          child: Text(
                            'Consulta aquí',
                            style: TextStyle(
                                color: AppColors.primary.withOpacity(0.6),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 15),

                  // Sección de carné
                  Container(
                    padding:
                        EdgeInsets.only(left: 60, top: 4, right: 16, bottom: 1),
                    child: Column(
                      children: [
                        // Estructura principal con SVG
                        Row(
                          children: [
                            Container(
                              child: carneImages.isNotEmpty
                                  ? Stack(
                                      children: [
                                        // SVG con icono de respaldo cuando hay imágenes
                                        SvgPicture.asset(
                                          'assets/images/file_correct.svg',
                                          placeholderBuilder: (context) => Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 24,
                                          ),
                                        ),
                                      ],
                                    )
                                  : (isUploading
                                      ? Container(
                                          width: 60,
                                          height: 60,
                                          child: Lottie.asset(
                                            'assets/loading/palta_saltarina.json',
                                            width: 60,
                                            height: 60,
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: carneImages.length < 2
                                              ? _pickImage
                                              : null,
                                          child: SvgPicture.asset(
                                            'assets/images/gallery_icon.svg',
                                            placeholderBuilder: (context) =>
                                                Icon(
                                              Icons.photo_library,
                                              color: Colors.grey[600],
                                              size: 24,
                                            ),
                                          ),
                                        )),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PDF/JPG',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    carneImages.isNotEmpty
                                        ? '${carneImages.length}/2 fotos del carné'
                                        : '¿Subir tu carné vigente? (máximo 2 fotos)',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Miniaturas de las imágenes debajo
                        if (carneImages.isNotEmpty) ...[
                          SizedBox(height: 12),
                          Container(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: carneImages.length +
                                  (carneImages.length < 2 ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Botón agregar si hay menos de 2 imágenes válidas
                                if (index == carneImages.length &&
                                    carneImages.length < 2) {
                                  return Container(
                                    margin: EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: isUploading ? null : _pickImage,
                                      child: Container(
                                        width: 80,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.primary
                                                .withOpacity(0.5),
                                            width: 1,
                                          ),
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate,
                                              color: AppColors.primary
                                                  .withOpacity(0.7),
                                              size: 20,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Agregar',
                                              style: TextStyle(
                                                color: AppColors.primary
                                                    .withOpacity(0.7),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                // Miniaturas de carnets VÁLIDOS únicamente
                                return Container(
                                  margin: EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showImageViewer(index),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.primary,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary.withOpacity(0.2),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Stack(
                                              children: [
                                                Image.file(
                                                  carneImages[index],
                                                  width: 80,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                ),
                                                // Overlay sutil para indicar selección
                                                Container(
                                                  width: 80,
                                                  height: 100,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                      colors: [
                                                        AppColors.primary.withOpacity(0.1),
                                                        Colors.transparent,
                                                      ],
                                                      stops: [0.0, 0.3],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Indicador de estado activo/seleccionado
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 2,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            'ACTIVO',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Botón eliminar con mejor contraste
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Center(child: _buildValidationStatus()),

                  SizedBox(height: 20),

                  // Checkbox y texto legal (usando el método modificado)
                  _buildTermsCheckbox(),
                ],
              ),
            ),
          ),
          if (isVerifying) _buildVerificationOverlay(),
          if (colegiaturaVerified) _buildSuccessOverlay(),
          if (showImageViewer) _buildImageViewerOverlay(),
        ],
      ),
    );
  }

  void _showPageIndicatorTemporarily() {
    _pageIndicatorTimer?.cancel();
    setState(() {
      _showPageIndicator = true;
    });

    _pageIndicatorTimer = Timer(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showPageIndicator = false;
        });
      }
    });
  }

  Widget _buildImageViewerOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: Stack(
          children: [
            // PageView para navegación suave entre imágenes
            Center(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: _showPageIndicatorTemporarily, // Mostrar contador al hacer tap
                  child: PageView.builder(
                    controller: PageController(initialPage: currentImageIndex),
                    onPageChanged: (index) {
                      setState(() {
                        currentImageIndex = index;
                      });
                      // Mostrar contador al cambiar de página
                      _showPageIndicatorTemporarily();
                    },
                    itemCount: carneImages.length,
                    itemBuilder: (context, index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Hero(
                            tag: 'image_$index',
                            child: Image.file(
                              carneImages[index],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Barra superior con botones animados
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón eliminar con animación
                  TweenAnimationBuilder(
                    duration: Duration(milliseconds: 200),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: GestureDetector(
                          onTapDown: (_) => _animateButtonPress(true),
                          onTapUp: (_) => _animateButtonPress(false),
                          onTapCancel: () => _animateButtonPress(false),
                          onTap: () {
                            _showDeleteConfirmation();
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 150),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.85),
                              shape: BoxShape.circle,

                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Botón cerrar con animación
                  TweenAnimationBuilder(
                    duration: Duration(milliseconds: 200),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: GestureDetector(
                          onTapDown: (_) => _animateButtonPress(true),
                          onTapUp: (_) => _animateButtonPress(false),
                          onTapCancel: () => _animateButtonPress(false),
                          onTap: _closeImageViewer,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 150),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              shape: BoxShape.circle,

                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Indicador de página con animación suave (solo se muestra temporalmente)
            if (carneImages.length > 1 && _showPageIndicator)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showPageIndicator ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 250),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(0.3, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          '${currentImageIndex + 1} de ${carneImages.length}',
                          key: ValueKey(currentImageIndex),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Indicadores de puntos para navegación visual (permanentes)
            if (carneImages.length > 1)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      carneImages.length,
                          (index) => AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: currentImageIndex == index ? 24 : 8,
                        height: 5,
                        decoration: BoxDecoration(
                          color: currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Instrucción de deslizamiento (solo aparece al inicio)
            if (carneImages.length > 1 && _showSwipeInstructions)
              Positioned(
                bottom: 130,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showSwipeInstructions ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 500),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swipe_left,
                            color: Colors.white.withOpacity(0.6),
                            size: 14,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Desliza para navegar',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.swipe_right,
                            color: Colors.white.withOpacity(0.6),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _animateButtonPress(bool isPressed) {}

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 10),
              Text('Eliminar imagen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar esta imagen? Esta acción no se puede deshacer.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _removeImageFromViewer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorIcon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Eliminar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Overlay de verificación (loading)
  Widget _buildVerificationOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          width: 220,
          height: 170,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Lottie.asset('assets/loading/palta_saltarina.json'),
              ),
              const Text(
                'Verificando...',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }

  // Overlay de éxito
  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.9),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/icon_verificado.svg',
              width: 360,
              height: 360,
            ),
            Transform.translate(
              offset: const Offset(0, -80),
              child: Column(
                children: [
                  const Text(
                    'Colegiatura',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16, height: 1.5),
                  ),
                  Text(
                    'N-${colegiaturaDigits.join('')}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.5),
                  ),
                  const Text(
                    'verificada',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    // Guardar datos antes de dispose (opcional)
    _saveData();

    // Limpiar ML Kit
    textRecognizer.close();
    objectDetector.close();

    _pageIndicatorTimer?.cancel();
    _swipeInstructionsTimer?.cancel();

    for (var controller in colegiaturaControllers) {
      controller.dispose();
    }
    for (var node in colegiaturaFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
