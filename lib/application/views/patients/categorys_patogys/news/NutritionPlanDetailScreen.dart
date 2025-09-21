import 'package:flutter/material.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import '../../../../requestSnacbar/snackBar_manager.dart';
import 'PatientDetailScreen.dart';
import 'edit_nutrition_plan_screen.dart';

class NutritionPlanDetailScreen extends StatefulWidget {
  final NutritionPlanResponse plan;
  final int patientId;
  final String authToken;
  final VoidCallback? onCancel;
  final String? patientDisease;

  const NutritionPlanDetailScreen({
    Key? key,
    required this.plan,
    required this.patientId,
    required this.authToken,
    this.onCancel,
    this.patientDisease,
  }) : super(key: key);

  @override
  State<NutritionPlanDetailScreen> createState() =>
      _NutritionPlanDetailScreenState();
}

class _NutritionPlanDetailScreenState extends State<NutritionPlanDetailScreen> {
  final NutritionistService _nutritionistService = NutritionistService();
  bool _isLoading = false;
  bool _isLoadingDetails = true;
  DetailedNutritionPlan? _detailedPlan;
  String? _errorMessage;

  late PatientDisease _patientDisease;
  late Color _diseaseColor;

  // Días de la semana en español
  final List<String> _daysOfWeek = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];

  @override
  void initState() {
    super.initState();

    // Detectar la enfermedad y establecer el color
    _patientDisease = detectDiseaseFromString(widget.patientDisease);
    _diseaseColor = getDiseaseColor(_patientDisease);

    _loadPlanDetails();
  }

  Future<void> _loadPlanDetails() async {
    try {
      setState(() {
        _isLoadingDetails = true;
        _errorMessage = null;
      });

      final detailedPlan = await _nutritionistService.getPlanDetails(
        widget.plan.planId,
        widget.authToken,
      );

      if (mounted) {
        setState(() {
          _detailedPlan = detailedPlan;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar detalles del plan: $e';
          _isLoadingDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Plan Nutricional',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        backgroundColor: _diseaseColor,
        centerTitle: true,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            widget.onCancel?.call();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlanDetails,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPlanHeader(),
          Expanded(
            child: _isLoadingDetails
                ? _buildLoadingWidget()
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPlanSummary(),

                            const SizedBox(height: 24),

                            // Plan semanal
                            _buildWeeklyPlan(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _detailedPlan != null ? _buildActionButtons() : null,
    );
  }

  Widget _buildPlanHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: _diseaseColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paciente: ${widget.plan.patientName}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'últ. vez ${widget.plan.weekStartDate}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.plan.energyRequirement} kcal',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _diseaseColor),
          SizedBox(height: 16),
          Text(
            'Cargando detalles del plan...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Error desconocido',
            style: const TextStyle(fontSize: 16, color: AppColors.errorIcon),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPlanDetails,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _diseaseColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummary() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        // Encabezado
        title: Row(
          children: [
            Icon(Icons.info_outline, color: _diseaseColor, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Información del Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        // 🔹 Contenido expandible
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 🔹 Todo a la izquierda
              mainAxisSize: MainAxisSize.min,               // 🔹 Solo alto necesario
              children: [
                _buildInfoRow('Objetivo:', widget.plan.goal),
                _buildInfoRow(
                    'Requerimientos especiales:', widget.plan.specialRequirements),
                _buildInfoRow('Nutricionista:', widget.plan.nutritionistName),

                if (_detailedPlan != null) ...[
                  _buildInfoRow('Días del plan:', '${_detailedPlan!.daysCount}'),
                  _buildInfoRow('Estado:', _getStatusText(_detailedPlan!.status)),
                  if (_detailedPlan!.reviewNotes != null &&
                      _detailedPlan!.reviewNotes!.isNotEmpty)
                    _buildInfoRow(
                        'Notas de revisión:', _detailedPlan!.reviewNotes!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }


  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pendiente';
      case 'PENDING_REVIEW':
        return 'Pendiente de revisión';
      case 'APPROVED':
        return 'Aprobado';
      case 'REJECTED':
        return 'Rechazado';
      case 'ACTIVE':
        return 'Activo';
      case 'NEEDS_REVISION':
        return 'Necesita revisión';
      default:
        return status;
    }
  }

  Widget _buildWeeklyPlan() {
    if (_detailedPlan == null || _detailedPlan!.daysCount == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Column(
            children: [
              Icon(Icons.schedule, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No hay detalles del plan disponibles',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, color: _diseaseColor, size: 24),
            SizedBox(width: 8),
            Text(
              'Plan Semanal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lista de días
        ...List.generate(
          _detailedPlan!.daysCount.clamp(0, 7),
          (index) => _buildDayCard(index),
        ),
      ],
    );
  }

  Widget _buildDayCard(int dayIndex) {
    final dayName = dayIndex < _daysOfWeek.length
        ? _daysOfWeek[dayIndex]
        : 'Día ${dayIndex + 1}';
    final meals = _detailedPlan!.getMealsForDay(dayIndex);
    final nutrition = _detailedPlan!.getNutritionInfoForDay(dayIndex);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            '${dayIndex + 1}',
            style: TextStyle(
              color: _diseaseColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          dayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${meals.length} comidas planificadas',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // Comidas del día
          if (meals.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.restaurant, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Comidas:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mostrar cada comida
            ...meals.asMap().entries.map((entry) {
              final mealIndex = entry.key;
              final meal = entry.value;
              return _buildMealCard(meal, mealIndex);
            }).toList(),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'No hay comidas planificadas para este día',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],

          // Información nutricional
          if (nutrition != null && nutrition.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Información Nutricional:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                children: nutrition.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_translateNutritionKey(entry.key)}:',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, int mealIndex) {
    final mealName = meal['name'] ?? meal['type'] ?? _getMealName(mealIndex);
    final description = meal['description'] ?? meal['foods'] ?? '';
    final foods = meal['foods'] ?? [];
    final calories = meal['calories'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mealName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.checkValidation,
            ),
          ),
          if (description.toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description.toString(),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
          if (foods is List && foods.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Alimentos:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            ...foods
                .map((food) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.green[300],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              food.toString(),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
          if (calories != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _diseaseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Calorías: $calories kcal',
                style: TextStyle(
                  color: _diseaseColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getMealName(int index) {
    const mealNames = [
      'Desayuno',
      'Media mañana',
      'Almuerzo',
      'Merienda',
      'Cena',
      'Colación nocturna'
    ];
    return index < mealNames.length ? mealNames[index] : 'Comida ${index + 1}';
  }

  String _translateNutritionKey(String key) {
    const translations = {
      'calories': 'Calorías',
      'protein': 'Proteínas',
      'carbs': 'Carbohidratos',
      'fat': 'Grasas',
      'fiber': 'Fibra',
      'sugar': 'Azúcar',
      'sodium': 'Sodio',
      'total_calories': 'Calorías totales',
      'total_protein': 'Proteínas totales',
      'total_carbs': 'Carbohidratos totales',
      'total_fat': 'Grasas totales',
    };
    return translations[key.toLowerCase()] ?? key;
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botón Editar
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _editPlan,
                icon: const Icon(Icons.edit),
                label: Text('Editar Plan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  side: const BorderSide(color: Colors.orange),
                  foregroundColor: Colors.orange,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Botón Enviar
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendPlan,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Enviando...' : 'Enviar Plan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final List<String> requirements = value
        .split(RegExp(r',|\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 🔹 Muy importante
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 4),
          ...requirements.map((req) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Text(
              '- $req',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.left,
            ),
          )),
        ],
      ),
    );
  }


  void _editPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNutritionPlanScreen(
          plan: _detailedPlan!,
          patientId: widget.patientId,
          authToken: widget.authToken,
          onPlanUpdated: _loadPlanDetails,
        ),
      ),
    );
  }

  void _sendPlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Evita cerrar tocando fuera
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Fondo limpio y profesional
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Confirmar envío',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas enviar este plan al paciente?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.checkValidation,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text(
              'Enviar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _handleSendPlan();
    }
  }

  Future<void> _handleEditPlan() async {
    try {
      setState(() => _isLoading = true);

      // Crear el request para editar el plan
      final editRequest = EditPlanRequest(
        planContent: _detailedPlan?.planContent ?? widget.plan.planContent ?? {}, // Validar nulls
        reviewNotes: 'Plan editado por el nutricionista - ${DateTime.now().toString()}',
        planContentValid: true,
      );

      // Llamar al servicio para editar el plan
      final updatedPlan = await _nutritionistService.editPlan(
        widget.plan.planId,
        editRequest,
        widget.authToken,
      );

      if (mounted) {
        SnackBarManager.showSuccess(context, 'Plan editado exitosamente');

        // Recargar los detalles del plan
        await _loadPlanDetails();
      }
    } catch (e) {
      if (mounted) {
        SnackBarManager.showError(context, 'Error al editar el plan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSendPlan() async {
    try {
      setState(() => _isLoading = true);

      // Crear el request para aprobar/enviar el plan
      final reviewRequest = ReviewPlanRequest(
        action: 'approve',
        reviewNotes:
            'Plan aprobado y enviado al paciente - ${DateTime.now().toString()}',
      );

      // Llamar al servicio para revisar/aprobar el plan
      final reviewedPlan = await _nutritionistService.reviewPlan(
        widget.plan.planId,
        reviewRequest,
        widget.authToken,
      );

      if (mounted) {
        SnackBarManager.showSuccess(
            context, 'Plan enviado exitosamente al paciente');

        // Esperar un momento para mostrar el mensaje
        await Future.delayed(const Duration(seconds: 1));

        // Regresar a la pantalla anterior
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarManager.showError(context, 'Error al enviar el plan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
