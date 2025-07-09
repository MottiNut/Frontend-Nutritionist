import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:lottie/lottie.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/validators/carnet_validations_enum.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

enum CardSide { front, back, unknown }
enum ValidationMode { single, dual }


class ValidationScreen extends StatefulWidget {
  final File imageFile;
  final List<String> existingSides;
  final Function(bool, Map<String, dynamic>?) onValidationComplete;

  const ValidationScreen({
    Key? key,
    required this.imageFile,
    required this.existingSides,
    required this.onValidationComplete,
  }) : super(key: key);

  @override
  _ValidationScreenState createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen>
    with TickerProviderStateMixin {

  // Estado de validación
  ValidationState _currentState = ValidationState.initializing;
  double _progressValue = 0.0;
  List<ValidationStep> _validationSteps = [];
  ValidationResult? _finalResult;
  int _currentStepIndex = -1;

  bool _canPop = false;

  CardSide _currentCardSide = CardSide.unknown;
  ValidationMode _validationMode = ValidationMode.dual;
  bool _frontProcessed = false;
  bool _backProcessed = false;
  Map<String, dynamic> _frontData = {};
  Map<String, dynamic> _backData = {};
  late BarcodeScanner _barcodeScanner;

  // ML Kit components
  late TextRecognizer _textRecognizer;
  late ObjectDetector _objectDetector;

  // Controladores de animación mejorados
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _slideController;

  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // Datos de análisis
  Map<String, dynamic> _analysisData = {};

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _setupValidationSteps();
    _startValidationProcess();
  }

  void _initializeComponents() {
    // Inicializar ML Kit
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: false,
      ),
    );

    _barcodeScanner = BarcodeScanner();

    // Configurar animaciones mejoradas
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _setupValidationSteps() {
    _validationSteps = [
      ValidationStep(
        id: 'image_quality',
        title: 'Análisis de Imagen',
        description: 'Verificando calidad y resolución del carnet CNP',
        icon: Icons.high_quality,
      ),
      ValidationStep(
        id: 'text_extraction',
        title: 'Extracción OCR',
        description: 'Reconociendo texto del documento nutricional',
        icon: Icons.document_scanner,
      ),
      ValidationStep(
        id: 'side_detection',
        title: 'Detección de Lado',
        description: 'Identificando si es frente o reverso del carnet',
        icon: Icons.flip_camera_android,
      ),
      ValidationStep(
        id: 'cnp_validation',
        title: 'Validación CNP',
        description: 'Verificando elementos del Colegio de Nutricionistas',
        icon: Icons.local_dining,
      ),
      ValidationStep(
        id: 'document_verification',
        title: 'Autenticidad',
        description: 'Validando formato y elementos oficiales',
        icon: Icons.security,
      ),
      ValidationStep(
        id: 'final_analysis',
        title: 'Verificación Final',
        description: 'Procesando resultado de validación CNP',
        icon: Icons.verified,
      ),
    ];
  }

  Future<void> _startValidationProcess() async {
    setState(() {
      _currentState = ValidationState.processing;
      _canPop = false;
    });

    try {
      for (int i = 0; i < _validationSteps.length; i++) {
        if (!mounted) return;

        setState(() {
          _currentStepIndex = i;
          _validationSteps[i].status = StepStatus.processing;
        });

        // Ejecutar validación real
        bool stepResult = await _executeValidationStep(_validationSteps[i]);

        if (!mounted) return;

        // Si el paso falla, detener inmediatamente
        if (!stepResult) {
          setState(() {
            _validationSteps[i].status = StepStatus.failed;
          });
          _finalizeValidation(false, 'Error en ${_validationSteps[i].title}');
          return;
        }

        // Actualizar progreso de forma fluida
        double targetProgress = (i + 1) / _validationSteps.length;
        await _animateProgressTo(targetProgress);

        setState(() {
          _validationSteps[i].status = StepStatus.completed;
        });

        // Pausa natural entre pasos
        await Future.delayed(const Duration(milliseconds: 600));
      }

      // Validación completada exitosamente
      bool isValid = _validateOverallResult();
      _finalizeValidation(isValid, null);

    } catch (e) {
      print('Error en validación: $e');
      _finalizeValidation(false, 'Error técnico durante la validación CNP');
    }
  }

  Future<bool> _onWillPop() async {
    if (_canPop) {
      return true; // Permitir retroceso
    }

    // Mostrar diálogo de confirmación si la validación está en progreso
    if (_currentState == ValidationState.processing) {
      return await _showExitConfirmationDialog();
    }

    return true;
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Validación en Progreso',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas cancelar la validación? Se perderá el progreso actual.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Continuar Validación',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 15
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.errorIcon.withOpacity(0.1),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.errorText,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _executeValidationStep(ValidationStep step) async {
    switch (step.id) {
      case 'image_quality':
        return await _validateImageQuality();
      case 'text_extraction':
        return await _extractAndValidateText();
      case 'side_detection':
        return await _detectCardSide();
      case 'cnp_validation':
        return await _validateCNPElements();
      case 'document_verification':
        return await _verifyDocumentAuthenticity();
      case 'final_analysis':
        return await _performFinalAnalysis();
      default:
        return false;
    }
  }

  Future<bool> _validateImageQuality() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return false;

      _analysisData['image_width'] = image.width;
      _analysisData['image_height'] = image.height;
      _analysisData['image_ratio'] = image.width / image.height;
      _analysisData['image_size_bytes'] = bytes.length;

      // Verificaciones de calidad más flexibles
      bool hasMinimumResolution = image.width >= 400 && image.height >= 250;
      bool hasValidRatio = (image.width / image.height) >= 0.8 && (image.width / image.height) <= 2.5;
      bool hasMinimumSize = bytes.length > 10000; // Al menos 10KB

      print('Calidad imagen: ${image.width}x${image.height}, ratio: ${image.width / image.height}, size: ${bytes.length}');

      await Future.delayed(const Duration(milliseconds: 1200));

      return hasMinimumResolution && hasValidRatio && hasMinimumSize;
    } catch (e) {
      print('Error validando calidad: $e');
      return false;
    }
  }

  Future<bool> _extractAndValidateText() async {
    try {
      final inputImage = InputImage.fromFile(widget.imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      String extractedText = recognizedText.text;
      _analysisData['extracted_text'] = extractedText;
      _analysisData['text_blocks'] = recognizedText.blocks.length;
      _analysisData['text_length'] = extractedText.length;

      print('Texto extraído (${extractedText.length} chars):');
      print(extractedText);

      // Verificar que se extrajo texto suficiente
      bool hasMinimumText = extractedText.trim().length > 15;

      // Limpiar texto para análisis
      String cleanText = _cleanText(extractedText);
      _analysisData['clean_text'] = cleanText;

      await Future.delayed(const Duration(milliseconds: 1800));

      return hasMinimumText;
    } catch (e) {
      print('Error extrayendo texto: $e');
      return false;
    }
  }

  Future<bool> _detectCardSide() async {
    try {
      String text = _analysisData['clean_text'] ?? '';

      // Detectar QR code para identificar reverso
      final inputImage = InputImage.fromFile(widget.imageFile);
      final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

      bool hasQRCode = barcodes.isNotEmpty;
      _analysisData['has_qr_code'] = hasQRCode;

      // Patrones para detectar frente y reverso
      List<String> frontPatterns = [
        'apellidos', 'nombres', 'n° cnp', 'carné de colegiado',
        'carne de colegiado', 'n° de dni', 'decana nacional', 'consejo nacional'
      ];

      List<String> backPatterns = [
        'fecha de colegiación', 'fecha de caducidad', 'grupo sanguíneo',
        'secretaria@cnp.org.pe', 'www.cnp.org.pe', 'carnet es personal',
        'intransfenble', 'intransferible', 'firma del titular', 'anexo 102'
      ];

      int frontMatches = _countPatternMatches(text, frontPatterns);
      int backMatches = _countPatternMatches(text, backPatterns);

      // Determinar lado detectado
      CardSide detectedSide = CardSide.unknown;
      String sideString = 'unknown';

      if (hasQRCode && backMatches > 0) {
        detectedSide = CardSide.back;
        sideString = 'back';
      } else if (frontMatches > backMatches && frontMatches > 1) {
        detectedSide = CardSide.front;
        sideString = 'front';
      } else if (backMatches > 0) {
        detectedSide = CardSide.back;
        sideString = 'back';
      }

      // NUEVO: Verificar si el lado ya fue subido
      if (widget.existingSides.contains(sideString)) {
        print('ERROR: El lado $sideString ya fue procesado anteriormente');
        _analysisData['duplicate_side'] = true;
        _analysisData['detected_side'] = sideString;
        return false; // Fallar la validación si es duplicado
      }

      _analysisData['front_matches'] = frontMatches;
      _analysisData['back_matches'] = backMatches;
      _analysisData['detected_side'] = sideString;
      _currentCardSide = detectedSide;

      print('Detección lado - Frente: $frontMatches, Reverso: $backMatches, QR: $hasQRCode');
      print('Lado detectado: $sideString');
      print('Lados existentes: ${widget.existingSides}');

      await Future.delayed(const Duration(milliseconds: 1000));

      return detectedSide != CardSide.unknown;
    } catch (e) {
      print('Error detectando lado: $e');
      return false;
    }
  }

  Future<bool> _validateCNPElements() async {
    try {
      String text = _analysisData['clean_text'] ?? '';
      String side = _currentCardSide.toString().split('.').last;

      Map<String, List<String>> cnpPatterns;

      if (side == 'front') {
        // Patrones para el frente del carnet
        cnpPatterns = {
          'institution': [
            'colegio de nutricionistas',
            'colegio',
            'nutricionistas',
            'nutrición',
            'nutricionist',
            'peru',
            'perú',
            'cnp',
            'consejo nacional'
          ],
          'credential': [
            'carnet',
            'carné',
            'carne',
            'credencial',
            'profesional',
            'colegiado',
            'identificación',
          ],
          'personal_data': [
            'apellidos',
            'nombres',
            'dni',
            'n°',
            'numero',
            'número',
          ],
          'professional': [
            'lic.',
            'licenciado',
            'nutricionista',
            'nutrición',
            'nutricional',
            'decana',
            'nacional'
          ],
        };
      } else {
        // Patrones para el reverso del carnet
        cnpPatterns = {
          'institution': [
            'colegio de nutricionistas',
            'cnp',
            'peru',
            'perú',
            'secretaria@cnp.org.pe',
            'www.cnp.org.pe'
          ],
          'dates': [
            'fecha de colegiación',
            'fecha de caducidad',
            'colegiación',
            'caducidad',
            '2023',
            '2024',
            '2025',
            '2026',
            '2027',
            '2028',
            '2029',
            '2031',
            '2032',
            '2033',
            '2034',
            '2035',
          ],
          'personal_info': [
            'grupo sanguíneo',
            'grupo',
            'sanguíneo',
            'firma del titular',
            'firma',
            'titular'
          ],
          'security': [
            'carnet es personal',
            'intransferible',
            'intransfenble',
            'personal',
            'anexo 102',
            'anexo',
            '463-1761'
          ],
        };
      }

      Map<String, int> categoryMatches = {};
      int totalMatches = 0;

      for (String category in cnpPatterns.keys) {
        int matches = 0;
        for (String pattern in cnpPatterns[category]!) {
          if (text.contains(pattern)) {
            matches++;
            totalMatches++;
            print('Match encontrado: "$pattern" en categoría: $category');
          }
        }
        categoryMatches[category] = matches;
      }

      _analysisData['cnp_matches'] = categoryMatches;
      _analysisData['total_matches'] = totalMatches;

      print('Matches por categoría: $categoryMatches');
      print('Total matches: $totalMatches');

      // Validación más flexible dependiendo del lado
      bool isValid;
      if (side == 'front') {
        bool hasInstitution = categoryMatches['institution']! > 0;
        bool hasPersonalData = categoryMatches['personal_data']! > 0;
        isValid = hasInstitution && hasPersonalData && totalMatches >= 3;
      } else {
        bool hasInstitution = categoryMatches['institution']! > 0;
        bool hasDates = categoryMatches['dates']! > 0;
        isValid = hasInstitution && totalMatches >= 2;
      }

      if (_currentCardSide == CardSide.front) {
        _frontData = Map.from(_analysisData);
        _frontProcessed = true;
      } else if (_currentCardSide == CardSide.back) {
        _backData = Map.from(_analysisData);
        _backProcessed = true;
      }

      await Future.delayed(const Duration(milliseconds: 2200));

      return isValid;
    } catch (e) {
      print('Error validando elementos CNP: $e');
      return false;
    }
  }

  Future<bool> _verifyDocumentAuthenticity() async {
    try {
      String text = _analysisData['clean_text'] ?? '';
      String side = _analysisData['detected_side'] ?? 'front';

      bool hasOfficialTerms = false;
      bool hasValidNumbers = false;
      bool hasValidDates = false;

      if (side == 'front') {
        // Verificaciones para el frente
        hasOfficialTerms = text.contains('colegio') &&
            (text.contains('nutricionistas') || text.contains('nutrición'));

        // Buscar número CNP (formato flexible)
        RegExp cnpPattern = RegExp(r'\b\d{3,5}\b');
        List<String> numbers = cnpPattern.allMatches(text)
            .map((m) => m.group(0)!)
            .toList();
        hasValidNumbers = numbers.isNotEmpty;
        _analysisData['cnp_numbers'] = numbers;

        // Buscar DNI
        RegExp dniPattern = RegExp(r'\b\d{8}\b');
        hasValidDates = dniPattern.hasMatch(text);

      } else {
        // Verificaciones para el reverso
        hasOfficialTerms = text.contains('cnp') ||
            text.contains('colegio') ||
            text.contains('secretaria@cnp.org.pe');

        // Buscar fechas (más flexible)
        RegExp datePattern = RegExp(r'\b\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{4}\b');
        hasValidDates = datePattern.hasMatch(text);

        // Buscar teléfono
        RegExp phonePattern = RegExp(r'\b463[\-\s]?1761\b');
        hasValidNumbers = phonePattern.hasMatch(text) || text.contains('463-1761');
      }

      _analysisData['has_official_terms'] = hasOfficialTerms;
      _analysisData['has_valid_numbers'] = hasValidNumbers;
      _analysisData['has_valid_dates'] = hasValidDates;

      print('Autenticidad - Oficial: $hasOfficialTerms, Números: $hasValidNumbers, Fechas: $hasValidDates');

      await Future.delayed(const Duration(milliseconds: 1800));

      return hasOfficialTerms && (hasValidNumbers || hasValidDates);
    } catch (e) {
      print('Error verificando autenticidad: $e');
      return false;
    }
  }

  Future<bool> _performFinalAnalysis() async {
    try {
      double confidence = _calculateCNPConfidenceScore();
      _analysisData['confidence_score'] = confidence;

      print('Score de confianza final: $confidence');

      await Future.delayed(const Duration(milliseconds: 1500));

      return confidence >= 0.60; // Reducido de 0.75 a 0.60 para ser más flexible
    } catch (e) {
      print('Error en análisis final: $e');
      return false;
    }
  }

  double _calculateCNPConfidenceScore() {
    double confidence = 0.0;
    String side = _analysisData['detected_side'] ?? 'front';

    // Peso por calidad de imagen (20%)
    int imageWidth = _analysisData['image_width'] ?? 0;
    int imageHeight = _analysisData['image_height'] ?? 0;
    if (imageWidth >= 400 && imageHeight >= 250) {
      confidence += 0.20;
    }

    // Peso por texto extraído (15%)
    int textLength = _analysisData['text_length'] ?? 0;
    confidence += math.min(textLength / 100.0, 0.15);

    // Peso por matches CNP (40%)
    int totalMatches = _analysisData['total_matches'] ?? 0;
    double matchWeight = side == 'front' ? 8.0 : 5.0; // Diferentes expectativas por lado
    confidence += math.min(totalMatches / matchWeight, 0.40);

    // Peso por elementos específicos (25%)
    bool hasOfficial = _analysisData['has_official_terms'] ?? false;
    bool hasNumbers = _analysisData['has_valid_numbers'] ?? false;
    bool hasDates = _analysisData['has_valid_dates'] ?? false;

    if (hasOfficial) confidence += 0.15;
    if (hasNumbers) confidence += 0.05;
    if (hasDates) confidence += 0.05;

    return confidence.clamp(0.0, 1.0);
  }

  bool _validateOverallResult() {
    double confidence = _analysisData['confidence_score'] ?? 0.0;
    return confidence >= 0.60;
  }

  // Función auxiliar para limpiar texto
  String _cleanText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\-@\.]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Función auxiliar para contar matches de patrones
  int _countPatternMatches(String text, List<String> patterns) {
    int count = 0;
    for (String pattern in patterns) {
      if (text.contains(pattern.toLowerCase())) {
        count++;
      }
    }
    return count;
  }

  Future<void> _animateProgressTo(double target) async {
    final completer = Completer<void>();

    _progressController.animateTo(target).then((_) {
      if (mounted) {
        setState(() {
          _progressValue = target;
        });
      }
      completer.complete();
    });

    return completer.future;
  }

  void _finalizeValidation(bool isValid, String? errorMessage) {
    if (!mounted) return;

    // Verificar si es lado duplicado
    if (!isValid && _analysisData['duplicate_side'] == true) {
      String detectedSide = _analysisData['detected_side'] ?? 'unknown';
      String sideText = detectedSide == 'front' ? 'frente' : 'reverso';

      // Determinar lado faltante
      String missingSide = 'unknown';
      if (!widget.existingSides.contains('front')) {
        missingSide = 'frente';
      } else if (!widget.existingSides.contains('back')) {
        missingSide = 'reverso';
      }

      widget.onValidationComplete(false, {
        'detected_side': detectedSide,
        'duplicate_side': true,
        'error_message': 'Ya subiste el $sideText del carnet. Necesitas el $missingSide.',
      });
      return;
    }

    // Lógica normal de finalización
    setState(() {
      _currentState = isValid ? ValidationState.success : ValidationState.failed;
      _finalResult = ValidationResult(
        isValid: isValid,
        errorMessage: errorMessage,
        analysisData: _mergeAnalysisData(),
      );
    });

    // Auto-cerrar después de mostrar resultado
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Map<String, dynamic> result = _mergeAnalysisData();
        widget.onValidationComplete(isValid, result);
      }
    });
  }

  // Método para combinar datos de ambos lados
  Map<String, dynamic> _mergeAnalysisData() {
    Map<String, dynamic> merged = Map.from(_analysisData);

    if (_frontProcessed && _backProcessed) {
      merged['front_data'] = _frontData;
      merged['back_data'] = _backData;
      merged['both_sides_validated'] = true;
    }

    return merged;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
    child: Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () async {

            bool canExit = await _onWillPop();
            if (canExit && mounted) {
              widget.onValidationComplete(false, null);
            }
          },
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12),
            const Text(
              'Verificación de carnet CNP',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildContent(),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          if (_currentState == ValidationState.processing) ...[
            _buildProgressSection(),
            const SizedBox(height: 15),
            _buildValidationSteps(),
          ] else ...[
            _buildResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Carnet con animación
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 280,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Header del carnet con logo CIP
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.engineering,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'COLEGIO DE NUTRICIONISTAS DEL \nPERÚ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),

                              ),
                            ),
                          ],
                        ),
                      ),

                      // Contenido del carnet
                      Positioned(
                        top: 60,
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Row(
                          children: [
                            // Foto del carnet
                            Container(
                              width: 100,
                              height: 700,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  widget.imageFile,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Info del carnet
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CARNET CNP', // CAMBIO: Era CIP
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 2,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'VALIDANDO...',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Indicador de estado
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.progress.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF10B981).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'EN PROCESO',
                                          style: TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Porcentaje en esquina
                      Positioned(
                        top: 12,
                        right: 12,
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${(_progressAnimation.value * 100).toInt()}%',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // Descripción
          Text(
            'Verificando documento del Colegio de Nutricionistas del Perú',
            style: TextStyle(
              color: AppColors.textInput.withOpacity(0.7),
              fontSize: 10,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          // Indicador de proceso actual mejorado
          if (_currentStepIndex >= 0 && _currentStepIndex < _validationSteps.length) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Icono animado
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Texto del paso
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _validationSteps[_currentStepIndex].title,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Procesando información...',
                          style: TextStyle(
                            color: AppColors.textLight.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Indicador de carga
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Container(
                      width: 50,
                      height: 50,
                      child: Lottie.asset(
                        'assets/loading/palta_saltarina.json',
                        width: 50,
                        height: 50,
                      ),
                    )
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValidationSteps() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.checklist, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Proceso de Validación',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          ...List.generate(_validationSteps.length, (index) {
            final step = _validationSteps[index];
            final isActive = _currentStepIndex == index;
            final isCompleted = step.status == StepStatus.completed;
            final isFailed = step.status == StepStatus.failed;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 1),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.secondary.withOpacity(0.1)
                    : isCompleted
                    ? AppColors.primary.withOpacity(0.1)
                    : isFailed
                    ? AppColors.errorText.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary.withOpacity(0.3)
                      : isCompleted
                      ? AppColors.secondary.withOpacity(0.3)
                      : isFailed
                      ? AppColors.errorText.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  _buildStepIconProfessional(step, isActive),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            color: isActive
                                ? AppColors.secondary
                                : isCompleted
                                ? AppColors.primary
                                : isFailed
                                ? AppColors.errorText
                                : AppColors.backgroundLigth,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w300
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepIconProfessional(ValidationStep step, bool isActive) {
    switch (step.status) {
      case StepStatus.completed:
        return Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: AppColors.checkValidation,
            shape: BoxShape.circle,
          ),
          child: const Icon(FontAwesomeIcons.check, color: AppColors.iconSecondary, size: 22),
        );
      case StepStatus.processing:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 1),
          ),
          child: const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        );
      case StepStatus.failed:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.errorIcon,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.errorIcon.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.close, color: AppColors.iconSecondary, size: 15),
        );
      default:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: Icon(step.icon, color: Colors.white.withOpacity(0.6), size: 20),
        );
    }
  }

  Widget _buildResult() {
    if (_finalResult == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (_finalResult!.isValid
                ? AppColors.secondary
                : AppColors.errorIcon).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icono de resultado mejorado
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _finalResult!.isValid ? Icons.verified : Icons.error_outline,
              color: _finalResult!.isValid ? AppColors.checkValidation : AppColors.errorIcon,
              size: 50,
            ),
          ),
          const SizedBox(height: 28),

          // Título del resultado
          Text(
            _finalResult!.isValid ? 'Carnet CNP Válido' : 'Validación Fallida',
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Descripción del resultado
          Text(
            _finalResult!.isValid
                ? 'El carnet del Colegio de Nutricionistas del Perú ha sido validado correctamente. Documento auténtico verificado.' // CAMBIO: Era Ingenieros
                : _finalResult!.errorMessage ?? 'No se pudo validar el documento CNP. Verifique la calidad de la imagen.', // CAMBIO: Era CIP
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.9),
              fontSize: 14,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          // Información de confianza mejorada
          if (_finalResult!.isValid && _analysisData['confidence_score'] != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.analytics, color: AppColors.secondary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Nivel de Confianza',
                        style: TextStyle(
                          color: AppColors.textLight.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Barra de confianza visual
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _analysisData['confidence_score'] ?? 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '${((_analysisData['confidence_score'] ?? 0.0) * 100).toInt()}% de confianza',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Información adicional para resultados exitosos
          if (_finalResult!.isValid) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.iconSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Documento verificado mediante análisis OCR y validación de elementos oficiales del CNP.',
                      style: TextStyle(
                        color: AppColors.textLight.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Botón de acción (opcional)
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _finalResult!.isValid ? Icons.check_circle : Icons.refresh,
                  color: AppColors.iconSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _finalResult!.isValid ? 'Validación Completada' : 'Intentar Nuevamente',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _textRecognizer.close();
    _objectDetector.close();
    _barcodeScanner.close();
    super.dispose();
  }
}

