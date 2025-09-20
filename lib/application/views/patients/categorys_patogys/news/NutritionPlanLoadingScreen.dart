import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';

class NutritionPlanLoadingScreen extends StatefulWidget {
  final String patientName;
  final int patientId;
  final int mealsPerDay;
  final String authToken;
  final GeneratePlanRequest planRequest;
  final VoidCallback? onCancel;
  final Function(NutritionPlanResponse)? onPlanGenerated;
  final Function(String)? onError;

  const NutritionPlanLoadingScreen({
    Key? key,
    required this.patientName,
    required this.patientId,
    required this.mealsPerDay,
    required this.authToken,
    required this.planRequest,
    this.onCancel,
    this.onPlanGenerated,
    this.onError,
  }) : super(key: key);

  @override
  State<NutritionPlanLoadingScreen> createState() => NutritionPlanLoadingScreenState();
}

class NutritionPlanLoadingScreenState extends State<NutritionPlanLoadingScreen>
    with TickerProviderStateMixin {

  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successAnimation;
  late AnimationController _particlesController;
  late Animation<double> _particlesAnimation;
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  int _currentStep = 0;
  bool _isGenerating = true;
  bool _showSuccess = false;
  bool _isNavigating = false;
  NutritionPlanResponse? _generatedPlan;
  DetailedNutritionPlan? _detailedPlan;
  String? _errorMessage;

  int _currentTipIndex = 0;
  int _foodCount = 0;
  int _recipeCount = 0;
  Timer? _tipTimer;
  Timer? _counterTimer;

  // Instancia del servicio
  final NutritionistService _nutritionistService = NutritionistService();

  final List<Map<String, String>> _nutritionTips = [
    {
      "icon": "💡",
      "title": "Distribución Óptima",
      "tip": "40% carbohidratos, 30% proteína, 30% grasa para máximo rendimiento"
    },
    {
      "icon": "🌈",
      "title": "Regla del Arcoíris",
      "tip": "5 colores diferentes aseguran diversidad completa de micronutrientes"
    },
    {
      "icon": "⚡",
      "title": "Ventana Anabólica",
      "tip": "Post-entreno: 30 minutos clave para absorción proteica óptima"
    },
    {
      "icon": "🔥",
      "title": "Termogénesis",
      "tip": "Los alimentos queman 8-10% de tu energía solo al procesarlos"
    },
    {
      "icon": "🧠",
      "title": "Neurotransmisores",
      "tip": "Triptófano + carbohidratos = mejor síntesis de serotonina"
    },
  ];

  final List<Map<String, dynamic>> _detailedSteps = [
    {
      "title": "Analizando Perfil Biométrico",
      "detail": "Procesando datos antropométricos y preferencias alimentarias",
      "icon": Icons.analytics_outlined,
      "color": Colors.blue
    },
    {
      "title": "Calculando Requerimientos",
      "detail": "BMR, TDEE y distribución personalizada de macronutrientes",
      "icon": Icons.calculate_outlined,
      "color": Colors.green
    },
    {
      "title": "Seleccionando Alimentos",
      "detail": "Identificando opciones según restricciones y objetivos",
      "icon": Icons.restaurant_outlined,
      "color": Colors.orange
    },
    {
      "title": "Generando Menú Inteligente",
      "detail": "Creando combinaciones balanceadas y variadas",
      "icon": Icons.auto_awesome_outlined,
      "color": Colors.purple
    },
    {
      "title": "Optimizando Plan Final",
      "detail": "Ajustando porciones y sincronización nutricional",
      "icon": Icons.tune_outlined,
      "color": Colors.teal
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startLoadingSequence();
    _startTipRotation();
    _startFoodCounter();
  }

  void _initAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _particlesController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _particlesAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particlesController, curve: Curves.linear),
    );

    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    _floatingAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
  }

  void _startTipRotation() {
    _tipTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _isGenerating) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _nutritionTips.length;
        });
      }
    });
  }

  void _startFoodCounter() {
    _counterTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (mounted && _isGenerating && _foodCount < 1247) {
        setState(() {
          _foodCount += Random().nextInt(18) + 7;
          _recipeCount = (_foodCount / 42).floor();
        });
      }
    });
  }

  void _startLoadingSequence() async {
    try {
      for (int i = 0; i < _detailedSteps.length; i++) {
        if (!mounted) return;

        setState(() {
          _currentStep = i;
        });

        _progressController.animateTo((i + 1) / _detailedSteps.length);
        await Future.delayed(Duration(milliseconds: 700 + (i * 150)));
      }

      if (mounted) {
        await _generatePlanFromBackend();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error en la secuencia de carga: $e';
          _isGenerating = false;
        });
        widget.onError?.call(_errorMessage!);
      }
    }
  }

  String _getEstimatedTimeRemaining() {
    double remaining = (1 - _progressAnimation.value) * 50;
    if (remaining < 8) return "finalizando";
    if (remaining < 25) return "${remaining.toInt()}s";
    return "~1 min";
  }

  Future<void> _generatePlanFromBackend() async {
    try {
      final generatedPlan = await _nutritionistService.generatePlan(
        widget.planRequest,
        widget.authToken,
      );

      if (mounted) {
        setState(() {
          _generatedPlan = generatedPlan;
          _isGenerating = false;
          _showSuccess = true;
        });

        _successController.forward();
        widget.onPlanGenerated?.call(generatedPlan);
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al generar el plan: $e';
          _isGenerating = false;
          _showSuccess = false;
        });
        widget.onError?.call(_errorMessage!);
      }
    }
  }

  void onPlanGenerated(NutritionPlanResponse plan) {
    if (mounted) {
      setState(() {
        _generatedPlan = plan;
        _isGenerating = false;
        _showSuccess = true;
      });
      _successController.forward();
    }
  }

  void onError(String error) {
    if (mounted) {
      setState(() {
        _errorMessage = error;
        _isGenerating = false;
        _showSuccess = false;
      });
    }
  }

  void _retryGeneration() {
    setState(() {
      _isGenerating = true;
      _showSuccess = false;
      _isNavigating = false;
      _errorMessage = null;
      _generatedPlan = null;
      _detailedPlan = null;
      _currentStep = 0;
      _foodCount = 0;
      _recipeCount = 0;
    });
    _progressController.reset();
    _successController.reset();
    _startLoadingSequence();
    _startFoodCounter();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _particlesController.dispose();
    _successController.dispose();
    _floatingController.dispose();
    _tipTimer?.cancel();
    _counterTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final availableHeight = screenHeight - topPadding - bottomPadding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB), // Color del body
        body: Column(
          children: [
            // Header fijo con padding superior igual al SafeArea
            Container(
              padding: EdgeInsets.fromLTRB(20, topPadding + 5, 15, 5),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Generando Plan Nutricional',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: (!_isGenerating && !_showSuccess && !_isNavigating)
                        ? () {
                      widget.onCancel?.call();
                      Navigator.pop(context);
                    }
                        : null,
                    icon: const Icon(Icons.close_rounded, size: 22),
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal con scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: availableHeight - 120,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        if (_isGenerating) ..._buildLoadingContent(),
                        if (_showSuccess && !_isGenerating) ..._buildSuccessContent(),
                        if (_errorMessage != null && !_isGenerating && !_showSuccess) ..._buildErrorContent(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Footer fijo
            _buildPatientInfo(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLoadingContent() {
    return [
      // Animación principal mejorada
      AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatingAnimation.value),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Partículas de fondo
                AnimatedBuilder(
                  animation: _particlesAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(150, 150),
                      painter: EnhancedParticlesPainter(_particlesAnimation.value),
                    );
                  },
                ),

                // Círculos concéntricos
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.orange.withOpacity(0.15),
                              Colors.orange.withOpacity(0.05),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(80),
                        ),
                      ),
                    );
                  },
                ),

                // Contenedor principal
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.orange.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 25,
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white,
                        blurRadius: 10,
                        spreadRadius: -5,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Lottie.asset(
                      'assets/loading/palta_saltarina.json',
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.blue.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$_foodCount',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Alimentos\nCompatibles',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 2,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 8), // Añadido margen
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey.shade300,
                      Colors.grey.shade400,
                      Colors.grey.shade300,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              Expanded( // Añadido Expanded para cada columna
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$_recipeCount',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recetas\nPersonalizadas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 20),

      // Tips educativos mejorados
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Container(
          key: ValueKey(_currentTipIndex),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.shade50,
                Colors.orange.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade300, Colors.orange.shade400],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    _nutritionTips[_currentTipIndex]["icon"]!,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded( // Añadido Expanded para evitar overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nutritionTips[_currentTipIndex]["title"]!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _nutritionTips[_currentTipIndex]["tip"]!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 25),

      // Barra de progreso mejorada
      AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible( // Añadido Flexible para evitar overflow
                      child: Text(
                        '${(_progressAnimation.value * 100).toInt()}% completado',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getEstimatedTimeRemaining(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),

      const SizedBox(height: 25),

      // Indicadores de pasos mejorados
      SingleChildScrollView( // Añadido ScrollView horizontal para los indicadores
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_detailedSteps.length, (index) {
            final isActive = index <= _currentStep;
            final isComplete = index < _currentStep;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: isActive ? 24 : 12,
              height: 12,
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                )
                    : null,
                color: !isActive ? Colors.grey[300] : null,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: isComplete ?
              const Icon(Icons.check, color: Colors.white, size: 10) : null,
            );
          }),
        ),
      ),
    ];
  }

  List<Widget> _buildSuccessContent() {
    return [
      // Icono de éxito con animación
      AnimatedBuilder(
        animation: _successAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _successAnimation.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
          );
        },
      ),

      const SizedBox(height: 24),

      const Text(
        '¡Plan Generado Exitosamente!',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 8),

      Text(
        _isNavigating
            ? 'Preparando tu plan...'
            : 'Tu plan nutricional de ${widget.mealsPerDay} comidas está listo',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 40),

      // Indicador de navegación
      if (_isNavigating) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Abriendo detalles del plan...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ] else ...[
        // Información del plan generado (solo si no está navegando)
        if (_generatedPlan != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
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
                _buildInfoRow('Plan ID:', '${_generatedPlan!.planId}'),
                _buildInfoRow('Estado:', _generatedPlan!.status),
                _buildInfoRow('Calorías:', '${_generatedPlan!.energyRequirement} kcal'),
                _buildInfoRow('Fecha:', _generatedPlan!.weekStartDate),
              ],
            ),
          ),
        ],
      ],
    ];
  }

  List<Widget> _buildErrorContent() {
    return [
      // Icono de error
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Icon(
          Icons.error,
          color: Colors.red,
          size: 60,
        ),
      ),

      const SizedBox(height: 24),

      const Text(
        'Error al Generar Plan',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 8),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          _errorMessage ?? 'Ocurrió un error inesperado',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ),

      const SizedBox(height: 40),

      // Botones de acción
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _retryGeneration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildPatientInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Plan de ${widget.mealsPerDay} comidas diarias',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// Painter personalizado para las partículas animadas
class EnhancedParticlesPainter extends CustomPainter {
  final double animationValue;

  EnhancedParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Partículas naranjas principales
    final orangePaint = Paint()
      ..color = Colors.orange.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Partículas amarillas secundarias
    final yellowPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Partículas rojas terciarias
    final redPaint = Paint()
      ..color = Colors.red.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Dibujar múltiples partículas giratorias en diferentes órbitas
    for (int i = 0; i < 12; i++) {
      final angle = (animationValue * 2 * 3.14159) + (i * 3.14159 / 6);

      // Partículas en órbita exterior
      final outerRadius = maxRadius * 0.8;
      final outerX = center.dx + outerRadius * cos(angle);
      final outerY = center.dy + outerRadius * sin(angle);

      final outerSize = 4.0 + (sin(animationValue * 3 * 3.14159 + i) * 1.5);
      canvas.drawCircle(
        Offset(outerX, outerY),
        outerSize,
        orangePaint,
      );

      // Partículas en órbita media
      final middleRadius = maxRadius * 0.5;
      final middleX = center.dx + middleRadius * cos(angle + 0.5);
      final middleY = center.dy + middleRadius * sin(angle + 0.5);

      final middleSize = 3.0 + (cos(animationValue * 2 * 3.14159 + i) * 1.0);
      canvas.drawCircle(
        Offset(middleX, middleY),
        middleSize,
        yellowPaint,
      );

      // Partículas en órbita interior
      final innerRadius = maxRadius * 0.3;
      final innerX = center.dx + innerRadius * cos(angle + 1.0);
      final innerY = center.dy + innerRadius * sin(angle + 1.0);

      final innerSize = 2.0 + (sin(animationValue * 4 * 3.14159 + i) * 0.8);
      canvas.drawCircle(
        Offset(innerX, innerY),
        innerSize,
        redPaint,
      );
    }

    // Efecto de destello central
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.orange.withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.4))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius * 0.4, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}