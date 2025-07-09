import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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
  late AnimationController _successController; // Nueva animación para el éxito
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successAnimation;
  late AnimationController _particlesController;
  late Animation<double> _particlesAnimation;

  int _currentStep = 0;
  bool _isGenerating = true;
  bool _showSuccess = false;
  bool _isNavigating = false; // Nueva variable para mostrar estado de navegación
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
      "title": "💡 Sabías que...",
      "tip": "La distribución 40-30-30 (carbos-proteína-grasa) es óptima para pacientes activos"
    },
    {
      "title": "🥗 Tip Profesional",
      "tip": "5 colores diferentes en el plato aseguran diversidad de micronutrientes"
    },
    {
      "title": "⏰ Timing Nutricional",
      "tip": "Las proteínas post-entreno se absorben mejor en los primeros 30 minutos"
    },
    {
      "title": "🔥 Metabolismo",
      "tip": "El efecto térmico de los alimentos representa el 8-10% del gasto energético"
    },
    {
      "title": "🧠 Neurotransmisores",
      "tip": "El triptófano necesita carbohidratos para atravesar la barrera hematoencefálica"
    },
  ];

  // MEJORAR LA LISTA DE PASOS EXISTENTE - REEMPLAZAR TU _steps:
  final List<Map<String, String>> _detailedSteps = [
    {
      "title": "Analizando perfil del paciente",
      "detail": "Procesando datos antropométricos y preferencias alimentarias"
    },
    {
      "title": "Calculando requerimientos nutricionales",
      "detail": "BMR, TDEE y distribución de macronutrientes personalizada"
    },
    {
      "title": "Seleccionando alimentos compatibles",
      "detail": "Identificando opciones según restricciones y objetivos"
    },
    {
      "title": "Generando menú personalizado",
      "detail": "Creando combinaciones balanceadas y variadas"
    },
    {
      "title": "Optimizando plan nutricional",
      "detail": "Ajustando porciones y tiempos de comida"
    },
  ];

  Timer? _slowProgressTimer;

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
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _particlesController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
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
  }

  void _startTipRotation() {
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _isGenerating) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _nutritionTips.length;
        });
      }
    });
  }

  void _startFoodCounter() {
    _counterTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted && _isGenerating && _foodCount < 847) {
        setState(() {
          _foodCount += Random().nextInt(15) + 5;
          _recipeCount = (_foodCount / 37).floor(); // Simulación realista
        });
      }
    });
  }

  void _startLoadingSequence() async {
    try {
      // Solo mostrar pasos de carga sin animar la barra completamente
      for (int i = 0; i < _detailedSteps.length; i++) {
        if (!mounted) return;

        setState(() {
          _currentStep = i;
        });

        // CAMBIADO: Solo animar hasta el 70% durante los pasos iniciales
        double stepProgress = ((i + 1) / _detailedSteps.length) * 0.7;
        _progressController.animateTo(stepProgress);

        // Simular tiempo de procesamiento para cada paso
        await Future.delayed(Duration(milliseconds: 600 + (i * 100)));
      }

      // CAMBIADO: Iniciar la fase de generación real del backend
      if (mounted) {
        setState(() {
          _currentStep = _detailedSteps.length; // Paso final
        });

        // Animar lentamente del 70% al 95% mientras esperamos el backend
        _animateProgressSlowly(0.7, 0.95, Duration(seconds: 15));

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

  void _animateProgressSlowly(double from, double to, Duration duration) {
    _slowProgressTimer?.cancel();

    final startTime = DateTime.now();
    final totalMs = duration.inMilliseconds;

    _slowProgressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted || !_isGenerating) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = (elapsed / totalMs).clamp(0.0, 1.0);

      final currentProgress = from + (to - from) * progress;
      _progressController.animateTo(currentProgress);

      if (progress >= 1.0) {
        timer.cancel();
      }
    });
  }

  String _getEstimatedTimeRemaining() {
    final currentProgress = _progressAnimation.value;

    if (currentProgress < 0.7) {
      // Fase inicial (pasos de UI)
      double remaining = (0.7 - currentProgress) * 10;
      if (remaining < 5) return "unos segundos";
      return "${remaining.toInt()}s";
    } else if (currentProgress < 0.95) {
      // Fase de generación backend
      return "generando plan...";
    } else {
      // Fase final
      return "finalizando...";
    }
  }

  // Método para generar el plan real desde el backend
  Future<void> _generatePlanFromBackend() async {
    try {
      // Llamar al servicio para generar el plan
      final generatedPlan = await _nutritionistService.generatePlan(
        widget.planRequest,
        widget.authToken,
      );

      if (mounted) {
        // CAMBIADO: Cancelar animación lenta y completar progreso
        _slowProgressTimer?.cancel();
        _progressController.animateTo(1.0);

        // Pequeña pausa para mostrar el 100% antes de mostrar éxito
        await Future.delayed(Duration(milliseconds: 300));

        setState(() {
          _generatedPlan = generatedPlan;
          _isGenerating = false;
          _showSuccess = true;
        });

        // Mostrar animación de éxito
        _successController.forward();

        // Notificar que el plan fue generado
        widget.onPlanGenerated?.call(generatedPlan);
      }

    } catch (e) {
      if (mounted) {
        // CAMBIADO: Cancelar animación lenta en caso de error
        _slowProgressTimer?.cancel();

        setState(() {
          _errorMessage = 'Error al generar el plan: $e';
          _isGenerating = false;
          _showSuccess = false;
        });
        widget.onError?.call(_errorMessage!);
      }
    }
  }

  // Método que será llamado desde NutritionPlanGenerator cuando el plan esté listo
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

  // Método para reintentar la generación
  void _retryGeneration() {
    setState(() {
      _isGenerating = true;
      _showSuccess = false;
      _isNavigating = false;
      _errorMessage = null;
      _generatedPlan = null;
      _detailedPlan = null;
      _currentStep = 0;
    });

    _progressController.reset();
    _successController.reset();
    _slowProgressTimer?.cancel(); // AGREGADO

    _startLoadingSequence();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _particlesController.dispose();
    _successController.dispose();

    _tipTimer?.cancel();
    _counterTimer?.cancel();
    _slowProgressTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header fijo (no scroll)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 14, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Generando Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: (!_isGenerating && !_showSuccess && !_isNavigating) ? () {
                      widget.onCancel?.call();
                      Navigator.pop(context);
                    } : null,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Contenido principal
                    if (_isGenerating) ..._buildLoadingContent(),
                    if (_showSuccess && !_isGenerating) ..._buildSuccessContent(),
                    if (_errorMessage != null && !_isGenerating && !_showSuccess) ..._buildErrorContent(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Footer fijo (no scroll)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildPatientInfo(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLoadingContent() {
    return [

      Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _particlesAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(180, 180),
                painter: ParticlesPainter(_particlesAnimation.value),
              );
            },
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.orange.withOpacity(0.3),
                        Colors.orange.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(70),
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Lottie.asset(
                        'assets/loading/palta_saltarina.json',
                        width: 60,
                        height: 60,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),

      const SizedBox(height: 5),

      // NUEVO: Paso actual con más detalle
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Text(
              _currentStep < _detailedSteps.length
                  ? _detailedSteps[_currentStep]["title"]!
                  : 'Finalizando generación...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _currentStep < _detailedSteps.length
                  ? _detailedSteps[_currentStep]["detail"]!
                  : 'Aplicando últimos ajustes al plan...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),

      const SizedBox(height: 14),

      // NUEVO: Contador de alimentos
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.blue.shade50],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  '$_foodCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Alimentos\nCompatibles',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            Column(
              children: [
                Text(
                  '$_recipeCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'Recetas\nDisponibles',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      const SizedBox(height: 14),

      // NUEVO: Tips educativos rotativos
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Container(
          key: ValueKey(_currentTipIndex),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(
            children: [
              Text(
                _nutritionTips[_currentTipIndex]["title"]!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _nutritionTips[_currentTipIndex]["tip"]!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 20),

      // Barra de progreso mejorada
      AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Column(
            children: [
              // Barra con gradiente
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(_progressAnimation.value * 100).toInt()}% completado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '~${_getEstimatedTimeRemaining()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),

      const SizedBox(height: 14),

      // Indicadores de pasos (mantener igual)
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_detailedSteps.length, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: index <= _currentStep ? Colors.orange : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
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
class ParticlesPainter extends CustomPainter {
  final double animationValue;

  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Dibujar múltiples partículas giratorias
    for (int i = 0; i < 8; i++) {
      final angle = (animationValue * 2 * 3.14159) + (i * 3.14159 / 4);
      final radius = maxRadius * 0.7;

      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      final particleSize = 3.0 + (sin(animationValue * 4 * 3.14159 + i) * 2);
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}