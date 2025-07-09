import 'package:flutter/material.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import '../../../../requestSnacbar/snackBar_manager.dart';

class EditNutritionPlanScreen extends StatefulWidget {
  final DetailedNutritionPlan plan;
  final String authToken;
  final Function(DetailedNutritionPlan) onPlanUpdated;

  const EditNutritionPlanScreen({
    Key? key,
    required this.plan,
    required this.authToken,
    required this.onPlanUpdated,
  }) : super(key: key);

  @override
  State<EditNutritionPlanScreen> createState() => _EditNutritionPlanScreenState();
}

class _EditNutritionPlanScreenState extends State<EditNutritionPlanScreen> {
  final NutritionistService _nutritionistService = NutritionistService();
  final _formKey = GlobalKey<FormState>();
  final _reviewNotesController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic> _editedPlanContent = {};

  // Controladores para información general del plan
  late TextEditingController _goalController;
  late TextEditingController _specialRequirementsController;
  late TextEditingController _energyRequirementController;

  // Lista de días de la semana
  final List<String> _daysOfWeek = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializePlanContent();
  }

  void _initializeControllers() {
    _goalController = TextEditingController(text: widget.plan.goal);
    _specialRequirementsController = TextEditingController(text: widget.plan.specialRequirements);
    _energyRequirementController = TextEditingController(text: widget.plan.energyRequirement.toString());
    _reviewNotesController.text = 'Plan editado por el nutricionista - ${DateTime.now().toString()}';
  }

  void _initializePlanContent() {
    // Crear una copia profunda del contenido del plan
    _editedPlanContent = Map<String, dynamic>.from(widget.plan.planContent);

    // Si no hay días, crear estructura básica
    if (!_editedPlanContent.containsKey('days') || _editedPlanContent['days'] == null) {
      _editedPlanContent['days'] = List.generate(7, (index) => {
        'day': index + 1,
        'meals': [],
        'nutrition_summary': {}
      });
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    _specialRequirementsController.dispose();
    _energyRequirementController.dispose();
    _reviewNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Editar Plan Nutricional'),
        centerTitle: true,
        backgroundColor: AppColors.backgroundLigth,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppColors.primary),
            onPressed: _isLoading ? null : _savePlan,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientInfo(),
              const SizedBox(height: 20),
              _buildGeneralInfo(),
              const SizedBox(height: 20),
              _buildWeeklyPlanEditor(),
              const SizedBox(height: 20),
              _buildReviewNotes(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildPatientInfo() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Información del Paciente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Paciente: ${widget.plan.patientName}'),
            Text('Semana: ${widget.plan.weekStartDate}'),
            Text('Estado: ${_getStatusText(widget.plan.status)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfo() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.edit, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Información General',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _goalController,
              decoration: const InputDecoration(
                labelText: 'Objetivo del Plan',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el objetivo del plan';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specialRequirementsController,
              decoration: const InputDecoration(
                labelText: 'Requerimientos Especiales',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese los requerimientos especiales';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _energyRequirementController,
              decoration: const InputDecoration(
                labelText: 'Requerimiento Energético (kcal)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el requerimiento energético';
                }
                if (int.tryParse(value) == null) {
                  return 'Por favor ingrese un número válido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyPlanEditor() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  'Plan Semanal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(
              (_editedPlanContent['days'] as List?)?.length ?? 0,
                  (index) => _buildDayEditor(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayEditor(int dayIndex) {
    final dayName = dayIndex < _daysOfWeek.length ? _daysOfWeek[dayIndex] : 'Día ${dayIndex + 1}';
    final dayData = _editedPlanContent['days'][dayIndex];
    final meals = List<Map<String, dynamic>>.from(dayData['meals'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ExpansionTile(
        title: Text(dayName),
        subtitle: Text('${meals.length} comidas'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...meals.asMap().entries.map((entry) {
                  final mealIndex = entry.key;
                  final meal = entry.value;
                  return _buildMealEditor(dayIndex, mealIndex, meal);
                }).toList(),
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  onPressed: () => _addMeal(dayIndex),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Comida', style: TextStyle(fontSize: 14),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.checkValidation,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealEditor(int dayIndex, int mealIndex, Map<String, dynamic> meal) {
    final mealNameController = TextEditingController(text: meal['name'] ?? _getMealName(mealIndex));
    final mealDescriptionController = TextEditingController(text: meal['description'] ?? '');
    final mealCaloriesController = TextEditingController(text: meal['calories']?.toString() ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: mealNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la comida',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      _updateMealField(dayIndex, mealIndex, 'name', value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: mealCaloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calorías',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _updateMealField(dayIndex, mealIndex, 'calories', int.tryParse(value));
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeMeal(dayIndex, mealIndex),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: mealDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción / Alimentos',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              onChanged: (value) {
                _updateMealField(dayIndex, mealIndex, 'description', value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewNotes() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Notas de Revisión',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reviewNotesController,
              decoration: const InputDecoration(
                labelText: 'Notas sobre la edición',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese notas sobre la edición';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
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
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancelar', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _savePlan,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Guardando...' : 'Guardar Cambios', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.backgroundHipertencion,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addMeal(int dayIndex) {
    final meals = List<Map<String, dynamic>>.from(_editedPlanContent['days'][dayIndex]['meals'] ?? []);
    meals.add({
      'name': _getMealName(meals.length),
      'description': '',
      'calories': 0,
      'foods': []
    });

    setState(() {
      _editedPlanContent['days'][dayIndex]['meals'] = meals;
    });
  }

  void _removeMeal(int dayIndex, int mealIndex) {
    final meals = List<Map<String, dynamic>>.from(_editedPlanContent['days'][dayIndex]['meals'] ?? []);
    if (mealIndex < meals.length) {
      meals.removeAt(mealIndex);
      setState(() {
        _editedPlanContent['days'][dayIndex]['meals'] = meals;
      });
    }
  }

  void _updateMealField(int dayIndex, int mealIndex, String field, dynamic value) {
    final meals = List<Map<String, dynamic>>.from(_editedPlanContent['days'][dayIndex]['meals'] ?? []);
    if (mealIndex < meals.length) {
      meals[mealIndex][field] = value;
      _editedPlanContent['days'][dayIndex]['meals'] = meals;
    }
  }

  String _getMealName(int index) {
    const mealNames = ['Desayuno', 'Media mañana', 'Almuerzo', 'Merienda', 'Cena', 'Colación nocturna'];
    return index < mealNames.length ? mealNames[index] : 'Comida ${index + 1}';
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

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Actualizar el contenido del plan con los valores editados
      _editedPlanContent['goal'] = _goalController.text;
      _editedPlanContent['specialRequirements'] = _specialRequirementsController.text;
      _editedPlanContent['energyRequirement'] = int.parse(_energyRequirementController.text);

      // Crear el request para editar el plan
      final editRequest = EditPlanRequest(
        planContent: _editedPlanContent,
        reviewNotes: _reviewNotesController.text,
      );

      // Llamar al servicio para editar el plan
      final updatedPlan = await _nutritionistService.editPlan(
        widget.plan.planId,
        editRequest,
        widget.authToken,
      );

      if (mounted) {
        SnackBarManager.showSuccess(context, 'Plan editado exitosamente');

        // Crear un nuevo DetailedNutritionPlan con los cambios
        final updatedDetailedPlan = widget.plan.copyWith(
          goal: _goalController.text,
          specialRequirements: _specialRequirementsController.text,
          energyRequirement: int.parse(_energyRequirementController.text),
          planContent: _editedPlanContent,
          reviewNotes: _reviewNotesController.text,
        );

        // Llamar al callback para actualizar la pantalla padre
        widget.onPlanUpdated(updatedDetailedPlan);

        // Regresar a la pantalla anterior
        Navigator.pop(context);
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
}