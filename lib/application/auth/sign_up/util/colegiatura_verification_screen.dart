import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/servicesColeg/image_viewer_overlay.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/servicesColeg/validate_services_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../configuration/themes/app_colors.dart';
import 'dart:async';
import '../../../requestSnacbar/snackBar_manager.dart';

import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ColegiaturaVerificationScreen extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String email;
  final String contrasena;
  final Function(String codeCNP, File? licenseFront, File? licenseBack)?
      onValidationComplete;
  final VoidCallback? onVerificationStart;
  final VoidCallback? onCnpValidated;

  const ColegiaturaVerificationScreen({
    Key? key,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.contrasena,
    this.onValidationComplete,
    this.onVerificationStart,
    this.onCnpValidated,
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

  List<File> carneImages = [];
  List<String> imageTypes = [];
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;
  bool isVerifying = false;
  bool colegiaturaVerified = false;
  bool isValidatingImage = false;

  String? _lastExtractedCNP;

  bool showImageViewer = false;
  int currentImageIndex = 0;

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
  static const String _keyColegiaturaVerified = 'colegiatura_verified';

  List<String> imageSides = [];

  bool _wasAutoFilled = false;

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

  bool _isSideAlreadyUploaded(String side) {
    return imageSides.contains(side);
  }

  String? _getMissingSide() {
    if (!imageSides.contains('front')) return 'front';
    if (!imageSides.contains('back')) return 'back';
    return null;
  }

  void _initializeMLKit() {

    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
      //confidenceThreshold: 0.35,
    );
    objectDetector = ObjectDetector(options: options);
  }


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

      // Cargar estado de verificación
      final savedColegiaturaVerified =
          prefs.getBool(_keyColegiaturaVerified) ?? false;
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

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardar dígitos de colegiatura
      await prefs.setStringList(_keyColegiaturaDigits, colegiaturaDigits);

      // Guardar rutas de imágenes
      final imagePaths = carneImages.map((file) => file.path).toList();
      await prefs.setStringList(_keyCarneImagePaths, imagePaths);
      await prefs.setStringList(_keyImageTypes, imageTypes);

      // Guardar estado de verificación
      await prefs.setBool(_keyColegiaturaVerified, colegiaturaVerified);
    } catch (e) {
      print('Error al guardar datos: $e');
    }
  }

  Future<void> _clearSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyColegiaturaDigits);
      await prefs.remove(_keyCarneImagePaths);
      await prefs.remove(_keyImageTypes);
      await prefs.remove(_keyColegiaturaVerified);
    } catch (e) {
      print('Error al limpiar datos: $e');
    }
  }


  void _checkAutoValidation() {
    if (_isFormValid() && !isVerifying && !colegiaturaVerified) {
      // Validar coincidencia si fue autocompletado
      if (_wasAutoFilled && _lastExtractedCNP != null) {
        String currentNumber = colegiaturaDigits.join('');
        if (currentNumber != _lastExtractedCNP) {
          _validateCNPMatch();
        }
      }

      autoValidationEnabled = true;
      _verifyColegiatura();
    }
  }

  Map<String, dynamic> getValidationData() {
    return {
      'codeCNP': colegiaturaDigits.join(''),
      'photoCNP': carneImages,
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

  bool isValid() {
    return _isFormValid();
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
                      leading:
                          Icon(Icons.photo_library, color: AppColors.primary),
                      title: Text(
                        'Galería',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
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
                      leading:
                          Icon(Icons.photo_camera, color: AppColors.primary),
                      title: Text(
                        'Cámara',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
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
      SnackBarManager.showError(context, 'Error al acceder a los permisos: $e');
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

  Future<File> _normalizeImage(File originalImage) async {
    try {
      // 1. Leer los bytes de la imagen original
      final bytes = await originalImage.readAsBytes();

      // 2. Decodificar la imagen usando el paquete image
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return originalImage;

      // 3. Corregir orientación basada en metadata EXIF
      final orientedImage = img.bakeOrientation(decodedImage);

      // 4. Redimensionar manteniendo aspect ratio (máximo 1200px en el lado mayor)
      const maxSize = 1200;
      final resizedImage = orientedImage.width > orientedImage.height
          ? img.copyResize(orientedImage, width: maxSize)
          : img.copyResize(orientedImage, height: maxSize);

      // 5. Mejorar contraste para mejor reconocimiento
      final contrastedImage = img.adjustColor(resizedImage, contrast: 1.3);

      // 6. Guardar la imagen procesada
      final directory = await getTemporaryDirectory();
      final processedPath = '${directory.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(img.encodeJpg(contrastedImage, quality: 90));

      return processedFile;
    } catch (e) {
      print('Error normalizando imagen: $e');
      return originalImage;
    }
  }

  Future<void> _getImageFromSource(ImageSource source, String type) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // NORMALIZAR LA IMAGEN ANTES DE PROCESAR
        setState(() => isUploading = true);
        File normalizedImage = await _normalizeImage(imageFile);

        await showValidationScreen(normalizedImage, type);
      } else {
        setState(() => isUploading = false);
      }
    } catch (e) {
      setState(() => isUploading = false);
      SnackBarManager.showError(context, 'Error al procesar imagen: $e');
    }
  }

  Future<void> showValidationScreen(File imageFile, String type) async {
    // Navegar a la pantalla de validación
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ValidationScreen(
          imageFile: imageFile,
          existingSides: imageSides,
          onValidationComplete: (bool isValid, Map<String, dynamic>? analysisData) async {
            if (isValid && analysisData != null) {
              final String extractedCNP = analysisData['extracted_cnp'] ?? '';
              final bool hasCNP = analysisData['has_cnp'] ?? false;

              if (hasCNP && extractedCNP.length == 4) {
                // Auto-completar los campos si se detectó un CNP válido
                _autoFillCNPFields(extractedCNP);
              }

              Navigator.of(context).pop({
                'isValid': isValid,
                'analysisData': analysisData,
              });
            } else {
              Navigator.of(context).pop({
                'isValid': false,
                'analysisData': analysisData,
              });
            }
          },
        ),
      ),
    );

    // Procesar el resultado
    if (result != null) {
      final bool isValid = result['isValid'] ?? false;
      final Map<String, dynamic>? analysisData = result['analysisData'];

      if (isValid && analysisData != null) {
        // NUEVO: Obtener el lado detectado
        String detectedSide = analysisData['detected_side'] ?? 'unknown';

        // NUEVO: Verificar si el lado ya fue subido
        if (_isSideAlreadyUploaded(detectedSide)) {
          setState(() {
            isUploading = false;
          });

          String sideText = detectedSide == 'front' ? 'frente' : 'reverso';
          String missingSide =
              _getMissingSide() == 'front' ? 'frente' : 'reverso';

          SnackBarManager.showError(context,
              'Ya subiste el $sideText del carnet. Necesitas subir el $missingSide.');
          return;
        }

        // Si es válido y no duplicado, agregarlo
        setState(() {
          carneImages.add(imageFile);
          imageTypes.add(type);
          imageSides.add(detectedSide); // NUEVO: Guardar el lado
          isUploading = false;
        });

        await _saveData();

        // NUEVO: Mensaje más específico
        String sideText = detectedSide == 'front' ? 'frente' : 'reverso';
        SnackBarManager.showSuccess(context,
            'Carnet válido ($sideText) agregado (${carneImages.length}/2)');

        _checkAutoValidation();
      } else if (analysisData?['require_other_side'] == true) {
        // NUEVO: Manejar caso donde se requiere el otro lado
        setState(() {
          isUploading = false;
        });

        String missingSide =
            _getMissingSide() == 'front' ? 'frente' : 'reverso';
        SnackBarManager.showInfo(context,
            'Ahora captura el $missingSide del carnet para completar la validación.');
      } else {
        // Si no es válido
        setState(() {
          isUploading = false;
        });
        SnackBarManager.showError(context,
            'La imagen no es un carnet válido. Intenta con otra imagen.');
      }
    } else {
      // Si el usuario canceló
      setState(() {
        isUploading = false;
      });
    }
  }

  void _autoFillCNPFields(String cnpNumber) {
    if (cnpNumber.length != 4) return;

    setState(() {
      _wasAutoFilled = true;
      _lastExtractedCNP = cnpNumber;
      for (int i = 0; i < 4; i++) {
        colegiaturaDigits[i] = cnpNumber[i];
        if (colegiaturaControllers.length > i) {
          colegiaturaControllers[i].text = cnpNumber[i];
        }
      }
    });

    SnackBarManager.showInfo(
        context,
        'Número CNP detectado: $cnpNumber. Verifica que sea correcto.'
    );

    _saveData();
    _validateColegiatura();
  }

  void _validateCNPMatch() {
    final String fullNumber = colegiaturaDigits.join('');

    if (_lastExtractedCNP != null &&
        _lastExtractedCNP!.isNotEmpty &&
        fullNumber.isNotEmpty &&
        fullNumber.length == 4) {
      if (_lastExtractedCNP != fullNumber) {
        // Mostrar snackbar de advertencia
        SnackBarManager.showWarning(
            context,
            'El número ingresado ($fullNumber) no coincide con el detectado en el carné ($_lastExtractedCNP)'
        );
      } else {
        SnackBarManager.showSuccess(
            context,
            '✓ Número CNP verificado correctamente'
        );
      }
    }
  }

  void removeCarnetImage(int index) {
    setState(() {
      carneImages.removeAt(index);
      imageTypes.removeAt(index);
      if (index < imageSides.length) {
        imageSides.removeAt(index);
      }
    });
    _saveData();
  }

  void _removeImage(int index) {
    setState(() {
      imageTypes.removeAt(index);
      carneImages.removeAt(index);

      // Resetear estado de autocompletado si se eliminan imágenes
      _wasAutoFilled = false;
      _lastExtractedCNP = null;

      // Reset validaciones si se elimina una imagen crítica
      if (carneImages.length < 2) {
        colegiaturaVerified = false;
        autoValidationEnabled = false;
      }
    });

    _saveData();
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

  void startVerification() {
    if (_isFormValid()) {
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

      // NUEVO: Extraer imágenes individualmente
      File? licenseFront = carneImages.isNotEmpty ? carneImages[0] : null;
      File? licenseBack = carneImages.length > 1 ? carneImages[1] : null;

      // MODIFICADO: Usar nuevo callback con tipos individuales
      widget.onValidationComplete?.call(
        fullNumber,
        licenseFront,
        licenseBack,
        //termsAccepted,
      );

      //widget.onVerificationSuccess?.call();

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

  Future<void> clearAllData() async {
    setState(() {
      colegiaturaDigits = ['', '', '', ''];
      carneImages.clear();
      imageTypes.clear();

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
        (autoValidationEnabled && _isFormValid())) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.checkValidation.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle,
                color: AppColors.checkValidation, size: 16),
            SizedBox(width: 8),
            Text(
              'Colegiatura verificada',
              style: TextStyle(
                color: AppColors.checkValidation,
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
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info, color: AppColors.primary, size: 16),
            SizedBox(width: 8),
            Text(
              'Agrega ${2 - carneImages.length} foto más (${carneImages.length}/2)',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
                              color:
                                  hasValue ? Colors.white : Colors.grey[600]!,
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

                                // NUEVA VALIDACIÓN: Si fue autocompletado y el usuario modifica
                                if (_wasAutoFilled && _lastExtractedCNP != null) {
                                  String currentNumber = colegiaturaDigits.join('');
                                  if (currentNumber != _lastExtractedCNP && currentNumber.length == 4) {
                                    _showCNPMismatchDialog(_lastExtractedCNP!, currentNumber);
                                  }
                                }

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

                              // Guardar datos después de cambiar
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
                        _buildImageThumbnails(),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Center(child: _buildValidationStatus()),
                ],
              ),
            ),
          ),
          if (isVerifying) _buildVerificationOverlay(),
        ],
      ),
    );
  }

  void _showCNPMismatchDialog(String detectedCNP, String enteredCNP) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'Diferencia detectada',
                style: TextStyle(
                  color: AppColors.textLDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El número que ingresaste ($enteredCNP) no coincide con el detectado en el carné ($detectedCNP).',
                style: TextStyle(
                  color: AppColors.textLDark,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '¿Deseas conservar el número ingresado o volver al detectado?',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: [
            // Botón para conservar el número ingresado
            TextButton(
              onPressed: () {
                setState(() {
                  _wasAutoFilled = false; // Ya no es autocompletado
                });
                Navigator.of(context).pop();
              },
              child: Text(
                'Conservar $enteredCNP',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Botón para restaurar el número detectado
            TextButton(
              onPressed: () {
                setState(() {
                  _autoFillCNPFields(detectedCNP); // Restaurar el detectado
                });
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.1),
              ),
              child: Text(
                'Usar $detectedCNP',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openImageViewer(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Permite ver a través del fondo
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ImageViewerOverlay(
            images: carneImages, // Tu lista de imágenes
            initialIndex: initialIndex, // Índice de la imagen inicial
            onImageDelete: (index) {
              _removeImageAtIndex(index);
            },
            onClose: () {
              Navigator.of(context).pop();
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  void _removeImageAtIndex(int index) {
    setState(() {
      if (index >= 0 && index < carneImages.length) {
        carneImages.removeAt(index);
      }
    });

    if (carneImages.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  // Método separado para construir las miniaturas
  Widget _buildImageThumbnails() {
    if (carneImages.isEmpty) return SizedBox.shrink();

    return Column(
      children: [
        SizedBox(height: 12),
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: carneImages.length + (carneImages.length < 2 ? 1 : 0),
            itemBuilder: (context, index) {
              // Botón agregar si hay menos de 2 imágenes válidas
              if (index == carneImages.length && carneImages.length < 2) {
                return _buildAddImageButton();
              }

              // Miniaturas de carnets VÁLIDOS únicamente
              return _buildThumbnailItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: isUploading ? null : _pickImage,
        child: Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primary.withOpacity(0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate,
                color: AppColors.primary.withOpacity(0.7),
                size: 20,
              ),
              SizedBox(height: 4),
              Text(
                'Agregar',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.7),
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

  Widget _buildThumbnailItem(int index) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _openImageViewer(index),
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
  }

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
