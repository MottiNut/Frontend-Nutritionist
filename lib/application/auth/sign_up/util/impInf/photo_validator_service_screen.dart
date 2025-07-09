import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/validators/photo_validations_enum.dart';

class PhotoValidationScreen extends StatefulWidget {
  final String imagePath;

  const PhotoValidationScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  _PhotoValidationScreenState createState() => _PhotoValidationScreenState();
}

class _PhotoValidationScreenState extends State<PhotoValidationScreen>
    with TickerProviderStateMixin {
  bool isProcessing = true;
  bool hasValidFace = false;
  String? errorMessage;
  late File imageFile;
  List<Face> detectedFaces = [];
  double progress = 0.0;
  String currentStep = 'Iniciando análisis...';
  bool _isRetrying = false;
  bool _isDisposed = false;

  // Lista de validaciones para mostrar progreso
  List<ValidationStep> validationSteps = [
    ValidationStep('Detectando rostro', ValidationStatus.pending),
    ValidationStep('Verificando centrado', ValidationStatus.pending),
    ValidationStep('Analizando calidad', ValidationStatus.pending),
    ValidationStep('Validando orientación', ValidationStatus.pending),
    ValidationStep('Revisando nitidez', ValidationStatus.pending),
  ];

  // Controladores de animación
  late AnimationController _progressController;
  late AnimationController _resultController;
  late AnimationController _pulseController;
  late AnimationController _counterController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    imageFile = File(widget.imagePath);
    _initializeAnimations();
    _validatePhotoSafely();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _progressController.dispose();
    _resultController.dispose();
    _pulseController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  bool get _isMounted => mounted && !_isDisposed;

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _resultController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _counterController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOutBack,
    ));

    if (isProcessing) {
      _pulseController.repeat(reverse: true);
    }
  }

  Future<void> _validatePhotoSafely() async {
    try {
      await _validatePhoto();
    } catch (e) {
      print('💥 Error durante la validación: $e');
      if (_isMounted) {
        setState(() {
          isProcessing = false;
          hasValidFace = false;
          errorMessage = 'Error al procesar la imagen: ${e.toString()}';
          currentStep = 'Error en el análisis';
        });
        _pulseController.stop();
        await _resultController.forward();
        _showErrorModal();
      }
    }
  }

  Future<void> _validatePhoto() async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('El archivo de imagen no existe');
      }

      // Paso 1: Detectar rostros
      await _updateValidationStep(0, 'Detectando rostro...', null);
      await _animateCounterToStep(1);

      final inputImage = InputImage.fromFile(imageFile);
      final faceDetector = GoogleMlKit.vision.faceDetector(
        FaceDetectorOptions(
          enableContours: true,
          enableLandmarks: true,
          enableClassification: true,
          enableTracking: true,
          minFaceSize: 0.10,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);

      if (!_isMounted) {
        await faceDetector.close();
        return;
      }

      // Validar cada paso individualmente
      bool step1Valid = faces.isNotEmpty && faces.length == 1;
      await _updateValidationStep(0, 'Detectando rostro...',
          step1Valid ? ValidationStatus.success : ValidationStatus.failed);

      // Paso 2: Verificar posición
      await _updateValidationStep(1, 'Verificando posición...', null);
      await _animateCounterToStep(2);
      bool step2Valid = await _checkPosition(faces);
      await _updateValidationStep(1, 'Verificando posición...',
          step2Valid ? ValidationStatus.success : ValidationStatus.failed);

      // Paso 3: Analizar calidad
      await _updateValidationStep(2, 'Analizando calidad...', null);
      await _animateCounterToStep(3);
      bool step3Valid = await _checkQuality(faces);
      await _updateValidationStep(2, 'Analizando calidad...',
          step3Valid ? ValidationStatus.success : ValidationStatus.failed);

      // Paso 4: Validar ángulos
      await _updateValidationStep(3, 'Validando ángulos...', null);
      await _animateCounterToStep(4);
      bool step4Valid = await _checkAngles(faces);
      await _updateValidationStep(3, 'Validando ángulos...',
          step4Valid ? ValidationStatus.success : ValidationStatus.failed);

      // Paso 5: Revisar nitidez
      await _updateValidationStep(4, 'Revisando nitidez...', null);
      await _animateCounterToStep(5);
      bool step5Valid = await _checkSharpness(faces);
      await _updateValidationStep(4, 'Revisando nitidez...',
          step5Valid ? ValidationStatus.success : ValidationStatus.failed);

      // Resultado final
      String? validationError = await _validateFaces(faces);
      bool allValid =
          step1Valid && step2Valid && step3Valid && step4Valid && step5Valid;

      if (_isMounted) {
        setState(() {
          detectedFaces = faces;
          isProcessing = false;
          hasValidFace = allValid && validationError == null;
          errorMessage = validationError;
          progress = 1.0;
        });

        _pulseController.stop();
        await _resultController.forward();

        // Si la validación es exitosa, retornar automáticamente
        if (hasValidFace) {
          await Future.delayed(Duration(seconds: 1));
          if (_isMounted) {
            print('✅ Foto validada exitosamente, regresando con archivo');
            Navigator.pop(context, imageFile);
          }
        } else {
          // Mostrar modal de error
          _showErrorModal();
        }
      }

      await faceDetector.close();
    } catch (e) {
      print('💥 Error en _validatePhoto: $e');
      rethrow;
    }
  }

  Future<void> _animateCounterToStep(int targetStep) async {
    int currentCount = (progress * 100).toInt();
    int targetCount = (targetStep * 20).toInt();

    // Animación más fluida: avanza de 1 en 1 con delay más corto
    while (currentCount < targetCount && _isMounted) {
      await Future.delayed(Duration(milliseconds: 25)); // Más fluido
      currentCount = (currentCount + 1).clamp(0, targetCount); // De 1 en 1
      if (_isMounted) {
        setState(() {
          progress = currentCount / 100.0;
        });
      }
    }
  }

  Future<void> _updateValidationStep(
      int stepIndex, String message, ValidationStatus? status) async {
    if (_isMounted && stepIndex < validationSteps.length) {
      setState(() {
        if (status != null) {
          validationSteps[stepIndex] =
              ValidationStep(validationSteps[stepIndex].title, status);
        }
        currentStep = message;
      });

      // Agregar más pasos intermedios para fluidez
      List<String> intermediateMessages = _getIntermediateMessages(stepIndex);
      for (String msg in intermediateMessages) {
        await Future.delayed(Duration(milliseconds: 200));
        if (_isMounted) {
          setState(() {
            currentStep = msg;
          });
        }
      }

      await Future.delayed(Duration(milliseconds: 300));
    }
  }

  List<String> _getIntermediateMessages(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return [
          'Buscando tu cara...',
          'Encontrando tu rostro...',
          'Confirmando que eres tú...'
        ];
      case 1:
        return [
          'Revisando si estás centrado...',
          'Viendo tu posición...',
          'Verificando que estés bien ubicado...'
        ];
      case 2:
        return [
          'Revisando que se vea bien...',
          'Comprobando la calidad...',
          'Verificando que esté clara...'
        ];
      case 3:
        return [
          'Viendo si miras de frente...',
          'Revisando la posición de tu cabeza...',
          'Verificando que no esté inclinada...'
        ];
      case 4:
        return [
          'Revisando que no esté borrosa...',
          'Verificando que se vea nítido...',
          'Comprobando la claridad...'
        ];
      default:
        return [];
    }
  }

  // Métodos de validación individuales
  Future<bool> _checkPosition(List<Face> faces) async {
    if (faces.isEmpty || faces.length > 1) return false;

    try {
      final imageSize = await _getImageSize();
      final face = faces.first;
      final boundingBox = face.boundingBox;

      final centerX = boundingBox.left + (boundingBox.width / 2);
      final centerY = boundingBox.top + (boundingBox.height / 2);
      final imageCenterX = imageSize.width / 2;
      final imageCenterY = imageSize.height / 2;

      final offsetX = (centerX - imageCenterX).abs() / imageCenterX;
      final offsetY = (centerY - imageCenterY).abs() / imageCenterY;

      return offsetX <= 0.45 && offsetY <= 0.45;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkQuality(List<Face> faces) async {
    if (faces.isEmpty) return false;

    try {
      final imageSize = await _getImageSize();
      final face = faces.first;
      final boundingBox = face.boundingBox;

      final faceArea = boundingBox.width * boundingBox.height;
      final imageArea = imageSize.width * imageSize.height;
      final faceRatio = faceArea / imageArea;

      return faceRatio >= 0.05 &&
          faceRatio <= 0.75 &&
          boundingBox.width >= 100 &&
          boundingBox.height >= 100;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkAngles(List<Face> faces) async {
    if (faces.isEmpty) return false;

    final face = faces.first;
    final rotY = face.headEulerAngleY ?? 0;
    final rotZ = face.headEulerAngleZ ?? 0;
    final rotX = face.headEulerAngleX ?? 0;

    return rotY.abs() <= 35 && rotZ.abs() <= 35 && rotX.abs() <= 30;
  }

  Future<bool> _checkSharpness(List<Face> faces) async {
    if (faces.isEmpty) return false;

    final face = faces.first;

    if (face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null) {
      return face.leftEyeOpenProbability! >= 0.2 &&
          face.rightEyeOpenProbability! >= 0.2;
    }

    return true; // Si no hay información de ojos, asumimos que está bien
  }

  void _showErrorModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: Offset(0, -8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 10, 20, MediaQuery.of(context).viewInsets.bottom + 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador de arrastre (handle)
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 15),

                    // Icono de error con animación
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.7 + (0.3 * value),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.errorText.withOpacity(0.1),
                                  AppColors.errorText.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: AppColors.errorText.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.face_retouching_off_rounded,
                              size: 36,
                              color: AppColors.errorIcon,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 12),

                    // Título
                    Text(
                      'Error de reconocimiento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 12),

                    // Descripción
                    Text(
                      'No se logró reconocer tu cara. Por favor, inténtalo de nuevo asegurándote de tener buena iluminación.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                        height: 1.2,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 20),

                    // Botón Reintentar
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.secondary,
                            AppColors.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _retryPhoto,
                          child: Container(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Reintentar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Botón Cancelar
                    Container(
                      width: double.infinity,
                      height: 52,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Solo cerrar
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFFF8FAFC),
                          foregroundColor: Color(0xFF64748B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // [Mantener todos los métodos de validación originales: _validateFaces, _getImageSize, etc.]
  Future<String?> _validateFaces(List<Face> faces) async {
    if (faces.isEmpty) {
      return 'No se detectó ningún rostro.\nAsegúrese de que su cara sea claramente visible.';
    }

    if (faces.length > 1) {
      return 'Se detectaron ${faces.length} rostros.\nSolo debe aparecer una persona en la foto.';
    }

    Face face = faces.first;
    final boundingBox = face.boundingBox;

    if (boundingBox.width < 100 || boundingBox.height < 100) {
      return 'El rostro es demasiado pequeño.\nAcérquese más a la cámara.';
    }

    try {
      final imageSize = await _getImageSize();
      final faceArea = boundingBox.width * boundingBox.height;
      final imageArea = imageSize.width * imageSize.height;
      final faceRatio = faceArea / imageArea;

      if (faceRatio < 0.05) {
        return 'El rostro ocupa muy poco espacio en la imagen.\nAcérquese más a la cámara.';
      }

      if (faceRatio > 0.75) {
        return 'El rostro está demasiado cerca.\nAléjese un poco de la cámara.';
      }

      final centerX = boundingBox.left + (boundingBox.width / 2);
      final centerY = boundingBox.top + (boundingBox.height / 2);
      final imageCenterX = imageSize.width / 2;
      final imageCenterY = imageSize.height / 2;

      final offsetX = (centerX - imageCenterX).abs() / imageCenterX;
      final offsetY = (centerY - imageCenterY).abs() / imageCenterY;

      if (offsetX > 0.45 || offsetY > 0.45) {
        return 'Centre su rostro en la imagen.\nAsegúrese de estar en el centro del encuadre.';
      }

      final rotY = face.headEulerAngleY ?? 0;
      final rotZ = face.headEulerAngleZ ?? 0;
      final rotX = face.headEulerAngleX ?? 0;

      if (rotY.abs() > 35) {
        return 'Mire directamente a la cámara.\nEvite girar la cabeza hacia los lados.';
      }

      if (rotZ.abs() > 35) {
        return 'Mantenga la cabeza derecha.\nEvite inclinar la cabeza.';
      }

      if (rotX.abs() > 30) {
        return 'Mantenga la cabeza en posición neutral.\nEvite inclinar hacia arriba o abajo.';
      }

      if (face.leftEyeOpenProbability != null &&
          face.rightEyeOpenProbability != null) {
        if (face.leftEyeOpenProbability! < 0.2 ||
            face.rightEyeOpenProbability! < 0.2) {
          return 'Mantenga los ojos completamente abiertos.\nEvite parpadear durante la captura.';
        }
      }
    } catch (e) {
      print('⚠️ Error en validación avanzada: $e');
    }

    return null;
  }

  Future<Size> _getImageSize() async {
    final Completer<Size> completer = Completer<Size>();

    try {
      final Image image = Image.file(imageFile);
      final ImageStream stream = image.image.resolve(ImageConfiguration());

      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          if (!completer.isCompleted) {
            completer.complete(Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            ));
          }
          stream.removeListener(listener);
        },
        onError: (dynamic error, StackTrace? stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
          stream.removeListener(listener);
        },
      );

      stream.addListener(listener);

      Timer(Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          stream.removeListener(listener);
          completer.completeError(
              TimeoutException('Timeout obteniendo tamaño de imagen'));
        }
      });
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    return completer.future;
  }

  void _retryPhoto() async {
    if (_isRetrying || !_isMounted) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      // PRIMERO: Cerrar el modal de error si está abierto
      Navigator.of(context).pop(); // Cierra el modal de error

      final ImageSource? source = await _showImageSourceSelection();

      if (source != null && _isMounted) {
        final ImagePicker picker = ImagePicker();
        final XFile? newImage = await picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 80,
          requestFullMetadata: false,
        );

        if (newImage != null && _isMounted) {
          final result = await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoValidationScreen(
                imagePath: newImage.path,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error al reintentar foto: $e');
      if (_isMounted) {
        _showErrorSnackBar(
            'Error al seleccionar nueva imagen: ${e.toString()}');
      }
    } finally {
      if (_isMounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  Future<ImageSource?> _showImageSourceSelection() async {
    if (!_isMounted) return null;

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Seleccionar imagen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Cámara',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildSourceOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Galería',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 0.3),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: AppColors.primary,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textLDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!_isMounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0F172A),
      statusBarIconBrightness: Brightness.light,

      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,

      // Opcional para iOS
      statusBarBrightness: Brightness.dark,
    ));

    return WillPopScope(
      onWillPop: () async => !isProcessing,
      child: Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: SafeArea(
          child: Column(
            children: [
              // Header con botón de cerrar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Validación de foto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
                    if (!isProcessing)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Imagen con overlay de progreso
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Fondo principal
                          Container(
                            width: 320,
                            height: 370,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),

                          // Contenido principal
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Contenedor para imagen circular con progreso y overlay
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Barra de progreso circular
                                  Container(
                                    width: 220,
                                    height: 220,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 6,
                                      backgroundColor:
                                          AppColors.primary.withOpacity(0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),

                                  // Imagen circular con overlay de escaneo
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 800),
                                    curve: Curves.easeInOut,
                                    width: isProcessing ? 200 : 205,
                                    height: isProcessing ? 200 : 205,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: Stack(
                                        children: [
                                          // Imagen de fondo
                                          Image.file(
                                            imageFile,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: double.infinity,
                                                height: double.infinity,
                                                color: AppColors.primary,
                                                child: Icon(
                                                  Icons.error_outline,
                                                  size: 50,
                                                  color: AppColors.errorText,
                                                ),
                                              );
                                            },
                                          ),

                                          // Overlay negro opaco sobre toda la imagen
                                          Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.7),
                                            ),
                                          ),

                                          // Efecto de escaneo animado
                                          if (isProcessing)
                                            AnimatedPositioned(
                                              duration:
                                                  Duration(milliseconds: 2000),
                                              curve: Curves.easeInOut,
                                              top: (progress * 200) - 10,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                height: 3,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.transparent,
                                                      AppColors.primary
                                                          .withOpacity(0.8),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Contador de porcentaje centrado
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Text(
                                      '${(progress * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: '',
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20),

                              // Indicador de estado con animación
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.secondary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Continuación del build method desde donde se cortó:

                                    if (isProcessing)
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        currentStep,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textLight,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 8),
                              // Texto secundario
                              Text(
                                'Procesamiento biométrico',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textQuintary,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 15),

                      // Lista de pasos de validación
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progreso de validación',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLight,
                              ),
                            ),
                            SizedBox(height: 16),
                            ...validationSteps.asMap().entries.map((entry) {
                              int index = entry.key;
                              ValidationStep step = entry.value;
                              return _buildValidationStepItem(step, index);
                            }).toList(),
                          ],
                        ),
                      ),
                  /*  SizedBox(height: 30),

                      // Botones de acción (solo visible cuando no está procesando)
                      if (!isProcessing)
                        Column(
                          children: [
                            if (hasValidFace) ...[
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _confirmPhoto,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Confirmar foto',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _retryPhoto,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textLight,
                                  side: BorderSide(
                                    color: AppColors.textLight.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  hasValidFace ? 'Tomar otra foto' : 'Intentar de nuevo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      SizedBox(height: 20),*/
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidationStepItem(ValidationStep step, int index) {
    Color iconColor;
    IconData iconData;
    Color textColor = AppColors.textLight;

    switch (step.status) {
      case ValidationStatus.success:
        iconColor = AppColors.checkValidation;
        iconData = Icons.check_circle;
        break;
      case ValidationStatus.failed:
        iconColor = AppColors.errorIcon;
        iconData = Icons.cancel;
        break;
      case ValidationStatus.pending:
      default:
        iconColor = AppColors.textLight.withOpacity(0.5);
        iconData = Icons.radio_button_unchecked;
        textColor = AppColors.textLight.withOpacity(0.7);
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            child: Icon(
              iconData,
              size: 20,
              color: iconColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              step.title,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

