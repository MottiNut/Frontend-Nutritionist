
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TooltipGuideOverlay extends StatefulWidget {
  final List<TooltipStep> steps;
  final VoidCallback? onComplete;
  final String guideKey;

  const TooltipGuideOverlay({
    Key? key,
    required this.steps,
    required this.guideKey,
    this.onComplete,
  }) : super(key: key);

  @override
  _TooltipGuideOverlayState createState() => _TooltipGuideOverlayState();
}

class _TooltipGuideOverlayState extends State<TooltipGuideOverlay>
    with TickerProviderStateMixin {
  int currentStep = 0;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (currentStep < widget.steps.length - 1) {
      setState(() {
        currentStep++;
      });
    } else {
      _completeGuide();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  void _skipGuide() {
    _completeGuide();
  }

  void _completeGuide() async {
    // Marcar la guía como completada
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.guideKey, true);

    _animationController.reverse().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return SizedBox.shrink();

    final currentStepData = widget.steps[currentStep];

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Material(
            color: Colors.black.withOpacity(0.7),
            child: Stack(
              children: [
                // Área clickeable para saltar
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {}, // Prevenir clics accidentales
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // Spotlight circular sobre el elemento
                if (currentStepData.targetKey != null)
                  _buildSpotlight(currentStepData),

                // Tooltip
                _buildTooltip(currentStepData),

                // Botón de saltar en la esquina superior derecha
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: _buildSkipButton(),
                ),

                // Indicador de progreso
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: _buildProgressIndicator(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpotlight(TooltipStep step) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: SpotlightPainter(
            targetKey: step.targetKey!,
            pulseScale: _pulseAnimation.value,
          ),
          child: Container(),
        );
      },
    );
  }

  Widget _buildTooltip(TooltipStep step) {
    return Positioned(
      top: step.tooltipPosition.dy,
      left: step.tooltipPosition.dx,
      right: step.tooltipPosition.dx,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono y título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: step.iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    step.icon,
                    color: step.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Descripción
            Text(
              step.description,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // Botones de navegación
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón anterior (si no es el primer paso)
                if (currentStep > 0)
                  TextButton.icon(
                    onPressed: _previousStep,
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    label: const Text('Anterior'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  )
                else
                  const SizedBox.shrink(),

                // Botón siguiente/finalizar
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: step.iconColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentStep == widget.steps.length - 1
                            ? 'Finalizar'
                            : 'Siguiente',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        currentStep == widget.steps.length - 1
                            ? Icons.check
                            : Icons.arrow_forward_ios,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: _skipGuide,
        child: const Text(
          'Saltar',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.steps.length, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= currentStep
                    ? widget.steps[currentStep].iconColor
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }
}

// Painter para crear el efecto spotlight
class SpotlightPainter extends CustomPainter {
  final GlobalKey targetKey;
  final double pulseScale;

  SpotlightPainter({
    required this.targetKey,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final RenderBox? renderBox =
    targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final targetPosition = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;

    // Centro del spotlight
    final center = Offset(
      targetPosition.dx + targetSize.width / 2,
      targetPosition.dy + targetSize.height / 2,
    );

    // Radio del spotlight con efecto pulse
    final baseRadius = (targetSize.width > targetSize.height
        ? targetSize.width
        : targetSize.height) / 2 + 20;
    final radius = baseRadius * pulseScale;

    // Crear path con agujero circular
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    // Pintar overlay oscuro con agujero transparente
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7);

    canvas.drawPath(path, paint);

    // Agregar un anillo brillante alrededor del spotlight
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Modelo para cada paso del tooltip
class TooltipStep {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final GlobalKey? targetKey; // Para hacer spotlight sobre el elemento
  final Offset tooltipPosition; // Posición del tooltip

  TooltipStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.tooltipPosition,
    this.targetKey,
  });
}

// Servicio para manejar el estado de las guías
class TooltipGuideService {
  static const String _homeGuideKey = 'home_guide_shown';
  static const String _patientsGuideKey = 'patients_guide_shown';
  static const String _agendaGuideKey = 'agenda_guide_shown';

  static Future<bool> hasShownGuide(String guideKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(guideKey) ?? false;
  }

  static Future<void> markGuideAsShown(String guideKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(guideKey, true);
  }

  static Future<void> resetAllGuides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeGuideKey, false);
    await prefs.setBool(_patientsGuideKey, false);
    await prefs.setBool(_agendaGuideKey, false);
  }

  // Guías predefinidas para cada pantalla
  static List<TooltipStep> getHomeGuideSteps() {
    return [
      TooltipStep(
        title: '¡Bienvenido a tu Dashboard!',
        description: 'Este es tu panel principal donde puedes ver un resumen de toda tu actividad como nutricionista.',
        icon: Icons.home_outlined,
        iconColor: Colors.teal,
        tooltipPosition: const Offset(0, 120),
      ),
      TooltipStep(
        title: 'Tu Perfil',
        description: 'Aquí puedes acceder a tu información personal y configuraciones de cuenta.',
        icon: Icons.person_outline,
        iconColor: Colors.blue,
        tooltipPosition: const Offset(0, 200),
        // targetKey: profileKey, // Debes pasar la key desde la pantalla
      ),
      TooltipStep(
        title: 'Notificaciones',
        description: 'Mantente al día con todas las notificaciones importantes de tus pacientes y citas.',
        icon: Icons.notifications_outlined,
        iconColor: Colors.orange,
        tooltipPosition: const Offset(0, 200),
        // targetKey: notificationsKey,
      ),
      TooltipStep(
        title: 'Tu Agenda',
        description: 'Revisa y gestiona todas tus citas programadas. Toca para ver la vista semanal completa.',
        icon: Icons.calendar_today_outlined,
        iconColor: Colors.purple,
        tooltipPosition: const Offset(0, 300),
        // targetKey: agendaKey,
      ),
      TooltipStep(
        title: 'Pacientes Activos',
        description: 'Ve el número de pacientes que tienes en seguimiento actualmente. Toca para ver la lista completa.',
        icon: Icons.people_outline,
        iconColor: Colors.green,
        tooltipPosition: const Offset(0, 500),
        // targetKey: activePatientsKey,
      ),
      TooltipStep(
        title: 'Casos Urgentes',
        description: 'Pacientes que requieren atención prioritaria aparecerán aquí.',
        icon: Icons.priority_high,
        iconColor: Colors.red,
        tooltipPosition: const Offset(0, 500),
        // targetKey: urgentKey,
      ),
    ];
  }
}

// Widget helper para mostrar guías automáticamente
class AutoTooltipWrapper extends StatefulWidget {
  final Widget child;
  final String guideKey;
  final List<TooltipStep> guideSteps;

  const AutoTooltipWrapper({
    Key? key,
    required this.child,
    required this.guideKey,
    required this.guideSteps,
  }) : super(key: key);

  @override
  _AutoTooltipWrapperState createState() => _AutoTooltipWrapperState();
}

class _AutoTooltipWrapperState extends State<AutoTooltipWrapper> {
  bool showGuide = false;

  @override
  void initState() {
    super.initState();
    _checkIfShouldShowGuide();
  }

  _checkIfShouldShowGuide() async {
    final hasShown = await TooltipGuideService.hasShownGuide(widget.guideKey);
    if (!hasShown) {
      // Esperar a que la pantalla se construya completamente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            showGuide = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (showGuide)
          TooltipGuideOverlay(
            steps: widget.guideSteps,
            guideKey: widget.guideKey,
            onComplete: () {
              setState(() {
                showGuide = false;
              });
            },
          ),
      ],
    );
  }
}