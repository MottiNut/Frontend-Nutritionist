import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'dart:math';
import '../../../../../../configuration/themes/app_colors.dart';
import '/../../../domain/patient/pruebaa.dart';

class PlanGenerationScreen extends StatefulWidget {
  final Map<String, dynamic> planData;
  final Patient patient;
  final String selectedPlan;

  const PlanGenerationScreen({
    super.key,
    required this.planData,
    required this.patient,
    required this.selectedPlan,
  });

  @override
  State<PlanGenerationScreen> createState() => _PlanGenerationScreenState();
}

class _PlanGenerationScreenState extends State<PlanGenerationScreen>
    with TickerProviderStateMixin {
  late AnimationController _textAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _pulseAnimation;

  Timer? _timer;
  Timer? _timeoutTimer;
  int _currentStep = 0;
  bool _isGenerating = true;
  bool _hasError = false;
  String _errorMessage = '';
  DateTime _startTime = DateTime.now();

  // Estados de generación más detallados y profesionales
  final List<Map<String, dynamic>> _generationSteps = [
    {
      'title': 'Validando datos del paciente',
      'description': 'Verificando información nutricional y médica',
      'duration': 3000,
    },
    {
      'title': 'Analizando perfil metabólico',
      'description': 'Calculando requerimientos energéticos basales',
      'duration': 4000,
    },
    {
      'title': 'Procesando restricciones alimentarias',
      'description': 'Identificando alergias e intolerancias',
      'duration': 2500,
    },
    {
      'title': 'Optimizando selección de alimentos',
      'description': 'Aplicando algoritmos de balanceo nutricional',
      'duration': 5000,
    },
    {
      'title': 'Calculando porciones personalizadas',
      'description': 'Ajustando cantidades según objetivos',
      'duration': 3500,
    },
    {
      'title': 'Generando estructura del plan',
      'description': 'Organizando horarios y distribución de comidas',
      'duration': 4500,
    },
    {
      'title': 'Validando balance nutricional',
      'description': 'Verificando cumplimiento de requerimientos',
      'duration': 3000,
    },
    {
      'title': 'Finalizando plan personalizado',
      'description': 'Aplicando últimos ajustes y optimizaciones',
      'duration': 2000,
    },
  ];

  @override
  void initState() {
    super.initState();
    _preventBackNavigation();
    _initializeAnimations();
    _startGenerationProcess();
    _setTimeoutTimer();
  }

  void _preventBackNavigation() {
    // Prevenir navegación hacia atrás con botones del sistema
    SystemChannels.platform.setMethodCallHandler((call) async {
      if (call.method == 'SystemNavigator.pop' && _isGenerating) {
        _showExitConfirmationDialog();
        return;
      }
      return null;
    });
  }

  void _initializeAnimations() {
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startGenerationProcess() {
    _textAnimationController.forward();
    _processCurrentStep();
  }

  void _processCurrentStep() {
    if (!mounted || _hasError) return;

    final step = _generationSteps[_currentStep];
    final duration = step['duration'] as int;

    // Simular posible fallo aleatorio (5% de probabilidad)
    if (_shouldSimulateError()) {
      _handleGenerationError('Error de conectividad con el servidor');
      return;
    }

    _timer = Timer(Duration(milliseconds: duration), () {
      if (!mounted || _hasError) return;

      if (_currentStep < _generationSteps.length - 1) {
        setState(() {
          _currentStep++;
        });
        _textAnimationController.reset();
        _textAnimationController.forward();
        _processCurrentStep();
      } else {
        _completeGeneration();
      }
    });
  }

  bool _shouldSimulateError() {
    // 5% de probabilidad de error para demostrar manejo de errores
    return Random().nextInt(100) < 5;
  }

  void _setTimeoutTimer() {
    // Timeout de 45 segundos
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (_isGenerating && mounted) {
        _handleGenerationError('Tiempo de espera agotado. Verifique su conexión.');
      }
    });
  }

  void _handleGenerationError(String message) {
    if (!mounted) return;

    setState(() {
      _hasError = true;
      _isGenerating = false;
      _errorMessage = message;
    });

    _timer?.cancel();
    _timeoutTimer?.cancel();
    _pulseAnimationController.stop();

    // Vibración de error
    HapticFeedback.heavyImpact();
  }

  void _retryGeneration() {
    setState(() {
      _hasError = false;
      _isGenerating = true;
      _currentStep = 0;
      _errorMessage = '';
      _startTime = DateTime.now();
    });

    _pulseAnimationController.repeat();
    _textAnimationController.reset();
    _startGenerationProcess();
    _setTimeoutTimer();
  }

  void _completeGeneration() {
    if (!mounted) return;

    _timer?.cancel();
    _timeoutTimer?.cancel();
    _pulseAnimationController.stop();

    setState(() {
      _isGenerating = false;
    });

    // Vibración de éxito
    HapticFeedback.mediumImpact();

    // Navegar al plan generado después de una pausa
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GeneratedPlanViewScreen(
              planData: _generateMockPlanData(),
              patient: widget.patient,
              selectedPlan: widget.selectedPlan,
            ),
          ),
        );
      }
    });
  }

  Map<String, dynamic> _generateMockPlanData() {
    // Generar datos simulados del plan
    return {
      'id': 'plan_${DateTime.now().millisecondsSinceEpoch}',
      'patientId': widget.patient.id,
      'planType': widget.selectedPlan,
      'generatedAt': DateTime.now().toIso8601String(),
      'totalCalories': 1800 + Random().nextInt(400), // 1800-2200
      'macros': {
        'proteins': 25 + Random().nextInt(10), // 25-35%
        'carbs': 45 + Random().nextInt(10), // 45-55%
        'fats': 20 + Random().nextInt(10), // 20-30%
      },
      'meals': _generateMockMeals(),
      'recommendations': _generateMockRecommendations(),
      'duration': _calculateGenerationTime(),
    };
  }

  List<Map<String, dynamic>> _generateMockMeals() {
    return [
      {
        'type': 'Desayuno',
        'time': '07:00',
        'calories': 400,
        'foods': [
          {'name': 'Avena con frutas', 'amount': '1 taza', 'calories': 250},
          {'name': 'Yogurt griego', 'amount': '150g', 'calories': 100},
          {'name': 'Almendras', 'amount': '10 unidades', 'calories': 50},
        ],
      },
      {
        'type': 'Media Mañana',
        'time': '10:00',
        'calories': 150,
        'foods': [
          {'name': 'Manzana verde', 'amount': '1 mediana', 'calories': 80},
          {'name': 'Nueces', 'amount': '5 unidades', 'calories': 70},
        ],
      },
      // Agregar más comidas según el tipo de plan...
    ];
  }

  List<String> _generateMockRecommendations() {
    return [
      'Mantener hidratación constante (2-3 litros diarios)',
      'Realizar actividad física moderada 30 min/día',
      'Respetar horarios de comida establecidos',
      'Evitar procesados y azúcares refinados',
      'Incluir variedad de colores en vegetales',
    ];
  }

  String _calculateGenerationTime() {
    final duration = DateTime.now().difference(_startTime);
    return '${duration.inSeconds}s';
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancelar generación',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          '¿Está seguro que desea cancelar la generación del plan nutricional? Se perderá el progreso actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continuar',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver a pantalla anterior
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeoutTimer?.cancel();
    _textAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
    );
    return WillPopScope(
      onWillPop: () async {
        if (_isGenerating) {
          _showExitConfirmationDialog();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Column(
            children: [
              _buildProfessionalHeader(),
              Expanded(
                child: _hasError ? _buildErrorView() : _buildGenerationView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return  Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology_outlined,
              color: Color(0xFF2D3748),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sistema de IA Nutricional',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  'Generación Inteligente de Planes',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (_isGenerating)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenerationView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Lottie.asset('assets/loading/fruta_rebote.json',
          width:200,
            height: 200
          ),

          const SizedBox(height: 8),

          // Título y subtítulo
          Text(
            _isGenerating ? 'Generando Plan Nutricional' : '¡Plan Generado Exitosamente!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            _isGenerating
                ? 'Creando ${_getPlanDisplayName(widget.selectedPlan)} para ${widget.patient.fullName}'
                : 'Su plan personalizado está listo para revisar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 56),

          // Información del paso actual
          if (_isGenerating) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _textFadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              _generationSteps[_currentStep]['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _generationSteps[_currentStep]['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildProfessionalProgressBar(),
                ],
              ),
            ),
          ],

          const Spacer(),

          // Información adicional
          if (_isGenerating)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Este proceso tarda un poco.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Error en la Generación',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Botones de acción
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _retryGeneration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Reintentar Generación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Volver',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalProgressBar() {
    double progress = (_currentStep + 1) / _generationSteps.length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(_currentStep + 1)}/${_generationSteps.length}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getPlanDisplayName(String planValue) {
    switch (planValue) {
      case 'desayuno':
        return 'Desayuno Energético';
      case 'almuerzo':
        return 'Almuerzo Funcional';
      case 'cena':
        return 'Cena Ligera';
      case 'completo':
        return 'Plan Diario Completo';
      case 'premium':
        return 'Plan Premium Integral';
      default:
        return 'Plan Personalizado';
    }
  }
}

// Pantalla para mostrar el plan generado
class GeneratedPlanViewScreen extends StatelessWidget {
  final Map<String, dynamic> planData;
  final Patient patient;
  final String selectedPlan;

  const GeneratedPlanViewScreen({
    super.key,
    required this.planData,
    required this.patient,
    required this.selectedPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Plan Nutricional Generado',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            onPressed: () => _showShareOptions(context),
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: () => _downloadPlan(context),
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanHeader(),
            const SizedBox(height: 24),
            _buildNutritionalSummary(),
            const SizedBox(height: 24),
            _buildMealsPlan(),
            const SizedBox(height: 24),
            _buildRecommendations(),
            const SizedBox(height: 32),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPlanDisplayName(selectedPlan),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Para ${patient.fullName}',
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Generado en ${planData['duration']}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionalSummary() {
    final macros = planData['macros'] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen Nutricional',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  'Calorías',
                  '${planData['totalCalories']}',
                  'kcal',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard(
                  'Proteínas',
                  '${macros['proteins']}',
                  '%',
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  'Carbohidratos',
                  '${macros['carbs']}',
                  '%',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard(
                  'Grasas',
                  '${macros['fats']}',
                  '%',
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String title, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealsPlan() {
    final meals = planData['meals'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan de Comidas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...meals.map((meal) => _buildMealCard(meal)).toList(),
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    meal['type'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    meal['time'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...((meal['foods'] as List<Map<String, dynamic>>).map((food) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${food['name']} - ${food['amount']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Text(
                      '${food['calories']} kcal',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          )).toList(),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Total: ${meal['calories']} kcal',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = planData['recommendations'] as List<String>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Recomendaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((recommendation) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => _savePlan(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Guardar Plan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => _modifyPlan(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Modificar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => _generateNewPlan(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Generar Nuevo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Compartir Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Enviar por Email'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareByEmail();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Compartir Enlace'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareLink();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.print_outlined),
                  title: const Text('Imprimir'),
                  onTap: () {
                    Navigator.pop(context);
                    _printPlan();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _downloadPlan(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plan descargado exitosamente'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _savePlan(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plan guardado en su biblioteca'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _modifyPlan(BuildContext context) {
    // Navegar a pantalla de modificación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de modificación próximamente'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _generateNewPlan(BuildContext context) {
    // Volver a generar
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PlanGenerationScreen(
              planData: {},
              patient: patient,
              selectedPlan: selectedPlan,
            ),
      ),
    );
  }

  void _shareByEmail() {
    // Implementar compartir por email
  }

  void _shareLink() {
    // Implementar compartir enlace
  }

  void _printPlan() {
    // Implementar impresión
  }

  String _getPlanDisplayName(String planValue) {
    switch (planValue) {
      case 'desayuno':
        return 'Desayuno Energético';
      case 'almuerzo':
        return 'Almuerzo Funcional';
      case 'cena':
        return 'Cena Ligera';
      case 'completo':
        return 'Plan Diario Completo';
      case 'premium':
        return 'Plan Premium Integral';
      default:
        return 'Plan Personalizado';
    }
  }
}