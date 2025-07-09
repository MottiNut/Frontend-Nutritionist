import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import 'NutritionPlanDetailScreen.dart';
import 'NutritionPlanLoadingScreen.dart';
import 'PatientValidationHelper.dart';

class NutritionPlanGenerator {
  final BuildContext context;
  final PatientProfile patient;
  final PatientWithHistory? patientWithHistory;
  final String? authToken;

  NutritionPlanGenerator({
    required this.context,
    required this.patient,
    required this.patientWithHistory,
    required this.authToken,
  });

  /// Muestra el selector de tipo de plan (3, 4 o 5 comidas)
  void showPlanTypeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPlanTypeSelector(),
    );
  }

  /// Construye el widget del selector de tipo de plan
  Widget _buildPlanTypeSelector() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Selecciona el tipo de plan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            'Elige cuántas comidas incluir en el plan nutricional',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildPlanTypeCard(
                  title: 'Plan Básico - 3 Comidas',
                  subtitle: 'Desayuno • Almuerzo • Cena',
                  imagePath: 'assets/plan/des.png',
                  color: Colors.green,
                  mealCount: 3,
                ),
                const SizedBox(height: 10),
                _buildPlanTypeCard(
                  title: 'Plan Completo - 4 Comidas',
                  subtitle: 'Desayuno • Almuerzo • Snack • Cena',
                  imagePath: 'assets/plan/alm.png',
                  color: Colors.orange,
                  mealCount: 4,
                ),
                const SizedBox(height: 10),
                _buildPlanTypeCard(
                  title: 'Plan Premium - 5 Comidas',
                  subtitle: 'Desayuno • Media Mañana • Almuerzo • Merienda • Cena',
                  imagePath: 'assets/plan/cen.png',
                  color: Colors.purple,
                  mealCount: 5,
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTypeCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required Color color,
    required int mealCount,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _navigateToCreatePlan(mealCount);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {

                    return const Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 24,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  /// Navega al proceso de creación del plan
  void _navigateToCreatePlan(int mealCount) async {
    // Validar token de autenticación
    if (authToken == null) {
      _showErrorDialog('Sesión no válida', 'Por favor, inicia sesión nuevamente para continuar');
      return;
    }

    // Verificar que tenga historial médico completo
    if (!PatientValidationHelper.isHistoryComplete(patientWithHistory)) {
      _showMedicalHistoryRequiredDialog();
      return;
    }

    // Mostrar advertencia si faltan datos, pero permitir continuar
    final missingFields = PatientValidationHelper.getMissingFields(patientWithHistory);
    if (missingFields.isNotEmpty) {
      _showMissingDataWarning(mealCount, missingFields);
    } else {
      _showGeneratePlanDialog(mealCount);
    }
  }

  /// Muestra diálogo cuando se requiere historial médico
  void _showMedicalHistoryRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text('Historial Médico Requerido'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para generar un plan nutricional, el paciente debe tener al menos un historial médico registrado.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete primero una consulta médica con el historial del paciente.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí deberías llamar al callback para crear historial médico
              print('📋 Navegar a crear historial médico');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Crear Historial', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Muestra advertencia sobre datos faltantes
  void _showMissingDataWarning(int mealCount, List<String> missingFields) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            const Text('Datos Incompletos'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Algunos datos del paciente no están disponibles:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...missingFields.map((field) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(field, style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
                ],
              ),
            )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El plan se creará con la información disponible. Podrás completar los datos restantes más tarde.',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showGeneratePlanDialog(mealCount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Continuar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Muestra el diálogo principal de generación del plan
  void _showGeneratePlanDialog(int mealCount) {
    bool isGeneratingPlan = false;
    NutritionPlanResponse? generatedPlan;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con icono
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getHeaderColor(isGeneratingPlan, generatedPlan, errorMessage).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      _getHeaderIcon(isGeneratingPlan, generatedPlan, errorMessage),
                      color: _getHeaderColor(isGeneratingPlan, generatedPlan, errorMessage),
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Título
                  Text(
                    _getDialogTitle(isGeneratingPlan, generatedPlan, errorMessage),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    _getDialogDescription(isGeneratingPlan, generatedPlan, errorMessage, mealCount),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Indicador de progreso o resultado
                  if (isGeneratingPlan) ...[
                    Lottie.asset(
                      'assets/loading/palta_saltarina.json',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(
                      backgroundColor: Color(0xFFE0E0E0),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ] else if (generatedPlan != null) ...[
                    // Mostrar resultado exitoso
                    _buildSuccessContainer(generatedPlan!),
                  ] else if (errorMessage != null) ...[
                    // Mostrar error
                    _buildErrorContainer(errorMessage),
                  ],

                  const SizedBox(height: 20),

                  // Botones
                  _buildDialogButtons(
                    isGeneratingPlan,
                    generatedPlan,
                    errorMessage,
                    mealCount,
                    setDialogState,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Obtiene el color del header según el estado
  Color _getHeaderColor(bool isGenerating, NutritionPlanResponse? plan, String? error) {
    if (error != null) return Colors.red;
    if (plan != null) return Colors.green;
    return Colors.orange;
  }

  /// Obtiene el icono del header según el estado
  IconData _getHeaderIcon(bool isGenerating, NutritionPlanResponse? plan, String? error) {
    if (error != null) return Icons.error;
    if (plan != null) return Icons.check_circle;
    if (isGenerating) return Icons.auto_awesome;
    return Icons.restaurant_menu;
  }

  String _getDialogTitle(bool isGenerating, NutritionPlanResponse? plan, String? error) {
    if (error != null) return 'Error en la Creación';
    if (plan != null) return '¡Plan Creado Exitosamente!';
    if (isGenerating) return 'Creando Plan Nutricional';
    return 'Crear Plan Nutricional';
  }

  String _getDialogDescription(bool isGenerating, NutritionPlanResponse? plan, String? error, int mealCount) {
    if (error != null) return 'No se pudo completar la generación del plan. Por favor, verifica la información e inténtalo nuevamente.';
    if (plan != null) return 'El plan nutricional se ha creado exitosamente y está listo para su revisión.';
    if (isGenerating) return 'Creando un plan nutricional personalizado con $mealCount comidas para ${patient.fullName}...';
    return '¿Confirmas que deseas crear un plan nutricional personalizado con $mealCount comidas para ${patient.fullName}?';
  }

  /// Construye el container de éxito
  Widget _buildSuccessContainer(NutritionPlanResponse plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 40),
          const SizedBox(height: 8),
          const Text(
            '¡Plan generado exitosamente!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Plan ID: ${plan.planId}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estado: ${plan.status}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContainer(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          const Text(
            'No se pudo crear el plan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Verifica la información del paciente e inténtalo nuevamente.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construye los botones del diálogo
  Widget _buildDialogButtons(
      bool isGeneratingPlan,
      NutritionPlanResponse? generatedPlan,
      String? errorMessage,
      int mealCount,
      StateSetter setDialogState,
      ) {
    return Row(
      children: [
        if (!isGeneratingPlan) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancelar',
                style: TextStyle(fontSize: 12,
                color: Colors.black
                ),),
            ),
          ),
          const SizedBox(width: 12),
        ],

        Expanded(
          child: ElevatedButton(
            onPressed: isGeneratingPlan
                ? null
                : (generatedPlan != null
                ? () {
              Navigator.pop(context);
              _showPlanDetailsDialog(generatedPlan);
            }
                : (errorMessage != null
                ? () => _startPlanGenerationWithLoading(mealCount)
                : () => _startPlanGenerationWithLoading(mealCount))),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getButtonColor(generatedPlan, errorMessage),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _getButtonText(isGeneratingPlan, generatedPlan, errorMessage),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  void _startPlanGenerationWithLoading(int mealCount) {
    // Cerrar el diálogo actual
    Navigator.pop(context);

    final planRequest = _buildPlanRequest(mealCount);

    // Navegar a la pantalla de carga con todos los parámetros necesarios
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NutritionPlanLoadingScreen(
          patientName: patient.fullName,
          patientId: patient.patientId,
          mealsPerDay: mealCount,
          authToken: authToken!,
          planRequest: planRequest,
          onCancel: () {
            Navigator.pop(context);
            _showSuccessMessage('Creación de plan cancelada');
          },
          onPlanGenerated: (NutritionPlanResponse plan) {

            Navigator.pop(context);
            _showPlanDetailsDialog(plan);
          },
          onError: (String error) {
            Navigator.pop(context);
            _showErrorDialog('Error en la creación', 'No se pudo completar el plan nutricional. Inténtalo nuevamente.');
          },
        ),
      ),
    );
  }

  GeneratePlanRequest _buildPlanRequest(int mealCount) {
    // Usar datos disponibles o valores por defecto usando el helper
    final energyRequirement = PatientValidationHelper.calculateEnergyRequirement(patient);
    final goal = PatientValidationHelper.prepareGoalDescription(patient, patientWithHistory);
    final specialRequirements = PatientValidationHelper.prepareSpecialRequirements(patient, patientWithHistory);

    return GeneratePlanRequest(
      patientId: patient.patientId,
      weekStartDate: DateTime.now().toIso8601String().split('T')[0],
      energyRequirement: energyRequirement,
      goal: goal,
      specialRequirements: specialRequirements,
      mealsPerDay: mealCount,
    );
  }

  Color _getButtonColor(NutritionPlanResponse? plan, String? error) {
    if (plan != null) return Colors.green;
    if (error != null) return Colors.orange;
    return Colors.orange;
  }

  String _getButtonText(bool isGenerating, NutritionPlanResponse? plan, String? error) {
    if (plan != null) return 'Ver Plan';
    if (error != null) return 'Intentar Nuevamente';
    if (isGenerating) return 'Creando...';
    return 'Crear Plan';
  }

  void _showPlanDetailsDialog(NutritionPlanResponse plan) {
    // Navegar directamente con indicador de carga
    _navigateToDetailScreenWithQuickLoading(plan);
  }

  void _navigateToDetailScreenWithQuickLoading(NutritionPlanResponse plan) async {
    // Mostrar indicador de carga superpuesto
    _showQuickLoadingOverlay();

    try {
      // Simular una pequeña carga (opcional, solo si necesitas preparar datos)
      await Future.delayed(const Duration(milliseconds: 300));

      // Cerrar el indicador de carga
      Navigator.pop(context);

      // Navegar directamente a la pantalla de detalles
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NutritionPlanDetailScreen(
            plan: plan,
            patientId: patient.patientId,
            authToken: authToken!,
            onCancel: () {
              // Callback opcional
            },
          ),
        ),
      );
    } catch (e) {
      // Cerrar loading en caso de error
      Navigator.pop(context);
      _showErrorDialog('Error', 'No se pudo acceder a los detalles del plan');
    }
  }
  void _showQuickLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Colors.orange,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Cargando detalles...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Plan para ${patient.fullName}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye una fila de detalles
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo para editar el plan
  void _showEditPlanDialog(NutritionPlanResponse plan) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue, size: 28),
            const SizedBox(width: 8),
            const Text('Editar Plan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Plan ID: ${plan.planId} - ${plan.patientName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notas de edición',
                hintText: 'Describe los cambios realizados al plan...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los cambios se aplicarán al contenido del plan nutricional.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editPlan(plan, notesController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Guardar Cambios', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Edita el plan nutricional
  Future<void> _editPlan(NutritionPlanResponse plan, String notes) async {
    try {
      if (authToken == null) {
        throw Exception('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.');
      }

      // ✅ CORRECCIÓN: Preparar request de edición correctamente
      final editRequest = EditPlanRequest(
        planContent: plan.planContent, // Usar el contenido actual del plan
        reviewNotes: notes.isNotEmpty ? notes : 'Plan editado por el nutricionista',
      );

      print('🔄 Editando plan ${plan.planId}...');

      final nutritionistService = NutritionistService();
      final updatedPlan = await nutritionistService.editPlan(
        plan.planId,
        editRequest,
        authToken!,
      );

      print('✅ Plan editado exitosamente: ${updatedPlan.planId}');

      _showSuccessMessage('Plan actualizado correctamente');

    } catch (e) {
      print('❌ Error al editar plan: $e');
      _showErrorDialog('Error al actualizar', 'No se pudieron guardar los cambios en el plan. Inténtalo nuevamente.');
    }
  }

  /// Muestra mensaje de éxito
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Muestra diálogo de error
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.red, size: 28), // Cambiado de error a info_outline
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}