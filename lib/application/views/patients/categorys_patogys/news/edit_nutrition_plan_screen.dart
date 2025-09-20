import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import '../../../../requestSnacbar/snackBar_manager.dart';
import 'package:intl/intl.dart';

class EditNutritionPlanScreen extends StatefulWidget {
  final DetailedNutritionPlan plan;
  final int patientId;
  final String authToken;
  final VoidCallback onPlanUpdated;

  const EditNutritionPlanScreen({
    Key? key,
    required this.plan,
    required this.patientId,
    required this.authToken,
    required this.onPlanUpdated,
  }) : super(key: key);

  @override
  State<EditNutritionPlanScreen> createState() => _EditNutritionPlanScreenState();
}

class _EditNutritionPlanScreenState extends State<EditNutritionPlanScreen>
    with SingleTickerProviderStateMixin {
  final NutritionistService _nutritionistService = NutritionistService();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _isEditingPlanInfo = false;
  Set<int> _editingDays = {};

  // Controladores para los campos editables
  late TextEditingController _goalController;
  late TextEditingController _specialRequirementsController;
  late TextEditingController _energyRequirementController;
  late TextEditingController _weekStartDateController;

  // Estructura para almacenar los días del plan
  List<Map<String, dynamic>> _days = [];

  int _currentCarouselIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Inicializar controladores con los valores actuales del plan
    _goalController = TextEditingController(text: widget.plan.goal ?? '');
    _specialRequirementsController = TextEditingController(text: widget.plan.specialRequirements ?? '');
    _energyRequirementController = TextEditingController(text: widget.plan.energyRequirement?.toString() ?? '0');
    _weekStartDateController = TextEditingController(text: widget.plan.weekStartDate ?? '');

    // Agregar listeners para detectar cambios
    _setupChangeListeners();

    // Cargar la estructura de días desde el planContent
    _loadPlanDays();

    // Cargar estados de edición guardados
    _loadEditingStates();

    _animationController.forward();
  }

  void _setupChangeListeners() {
    _goalController.addListener(_onFieldChanged);
    _specialRequirementsController.addListener(_onFieldChanged);
    _energyRequirementController.addListener(_onFieldChanged);
    _weekStartDateController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _loadEditingStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEditingPlanInfo = prefs.getBool('editing_plan_info_${widget.plan.planId}') ?? false;
      final editingDaysString = prefs.getStringList('editing_days_${widget.plan.planId}') ?? [];
      _editingDays = editingDaysString.map((e) => int.parse(e)).toSet();
    });
  }

  Future<void> _saveEditingState(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveEditingDays() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('editing_days_${widget.plan.planId}',
        _editingDays.map((e) => e.toString()).toList());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _goalController.dispose();
    _specialRequirementsController.dispose();
    _energyRequirementController.dispose();
    _weekStartDateController.dispose();
    super.dispose();
  }

  void _loadPlanDays() {
    if (widget.plan.planContent != null &&
        widget.plan.planContent!.containsKey('days') &&
        widget.plan.planContent!['days'] is List) {
      setState(() {
        _days = List<Map<String, dynamic>>.from(widget.plan.planContent!['days']);
      });
    } else {
      // Inicializar con 7 días vacíos si no hay datos
      setState(() {
        _days = List.generate(7, (index) => {
          'dayNumber': index + 1,
          'meals': <Map<String, dynamic>>[]
        });
      });
    }
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Construir el planContent actualizado con validación
      final updatedPlanContent = {
        'days': _days.map((day) => {
          ...day,
          'meals': (day['meals'] as List).map((meal) => {
            'name': meal['name'] ?? 'Comida sin nombre',
            'description': meal['description'] ?? '',
            'foods': meal['foods'] ?? [],
            'calories': meal['calories'] ?? 0,
          }).toList(),
        }).toList(),
        'goal': _goalController.text.trim(),
        'specialRequirements': _specialRequirementsController.text.trim(),
        'energyRequirement': int.tryParse(_energyRequirementController.text) ?? 0,
        'weekStartDate': _weekStartDateController.text.trim(),
      };

      // Crear el request para editar el plan
      final editRequest = EditPlanRequest(
        planContent: updatedPlanContent,
        reviewNotes: 'Plan editado manualmente - ${DateTime.now().toLocal().toString().substring(0, 19)}',
        planContentValid: true,
      );

      print('🔄 Enviando actualización del plan ${widget.plan.planId}...');
      print('📝 Datos a enviar: ${json.encode(editRequest.toJson())}');

      // Llamar al servicio para editar el plan
      final updatedPlan = await _nutritionistService.editPlan(
        widget.plan.planId,
        editRequest,
        widget.authToken,
      );

      // Limpiar estados de edición guardados
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('editing_plan_info_${widget.plan.planId}');
      await prefs.remove('editing_days_${widget.plan.planId}');

      if (mounted) {
        SnackBarManager.showSuccess(context, 'Plan nutricional actualizado exitosamente');
        setState(() {
          _hasChanges = false;
          _isEditingPlanInfo = false;
          _editingDays.clear();
        });
        widget.onPlanUpdated();
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error al guardar el plan: $e');
      if (mounted) {
        SnackBarManager.showError(
            context,
            'Error al guardar el plan: ${e.toString().replaceAll('Exception: ', '')}'
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '¿Descartar cambios?',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        content: Text(
          'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?',
          style: TextStyle(fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600, fontSize: 14),),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Descartar',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ) ?? false;
  }

  void _addMealToDay(int dayIndex) {
    setState(() {
      if (!_days[dayIndex].containsKey('meals')) {
        _days[dayIndex]['meals'] = <Map<String, dynamic>>[];
      }

      _days[dayIndex]['meals'].add({
        'name': 'Nueva comida',
        'description': '',
        'foods': <String>[],
        'calories': 0,
      });
      _hasChanges = true;
    });
  }

  void _removeMealFromDay(int dayIndex, int mealIndex) {
    setState(() {
      _days[dayIndex]['meals'].removeAt(mealIndex);
      _hasChanges = true;
    });
  }

  void _updateMeal(int dayIndex, int mealIndex, String field, dynamic value) {
    setState(() {
      _days[dayIndex]['meals'][mealIndex][field] = value;
      _hasChanges = true;
    });
  }

  void _addFoodToMeal(int dayIndex, int mealIndex) {
    setState(() {
      _days[dayIndex]['meals'][mealIndex]['foods'].add('Nuevo alimento');
      _hasChanges = true;
    });
  }

  void _removeFoodFromMeal(int dayIndex, int mealIndex, int foodIndex) {
    setState(() {
      _days[dayIndex]['meals'][mealIndex]['foods'].removeAt(foodIndex);
      _hasChanges = true;
    });
  }

  void _updateFoodInMeal(int dayIndex, int mealIndex, int foodIndex, String value) {
    setState(() {
      _days[dayIndex]['meals'][mealIndex]['foods'][foodIndex] = value;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header con información del paciente
                _buildPatientHeader(),
                const SizedBox(height: 8),

                // Contenido scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWeeklyPlanSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Editar Plan Nutricional',
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 19),
      ),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      leading: IconButton(
        onPressed: () async {
          if (await _onWillPop()) Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_ios, size: 20),
      ),
      // Removido el actions con el indicador "Edi.."
    );
  }

  Widget _buildPatientHeader() {
    // Convierte el String a DateTime
    DateTime createdAt = DateTime.tryParse(widget.plan.createdAt ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('yyyy/MM/dd   hh:mm a').format(createdAt);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 7),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plan.patientName ?? 'Paciente',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: getStatusColor(widget.plan.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              formatStatus(widget.plan.status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: getStatusColor(widget.plan.status),
              ),
            ),
          )
        ],
      ),
    );
  }

  String formatStatus(String? status) {
    switch (status) {
      case 'pending_review':
        return 'Pendiente';
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      default:
        return 'Desconocido';
    }
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'pending_review':
        return AppColors.secondary;
      case 'approved':
        return AppColors.checkValidation;
      case 'rejected':
        return AppColors.errorIcon;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 15, ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13,  ),
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildWeeklyPlanSection() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Icon(Icons.restaurant_menu, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Plan Semanal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                // Mostrar indicador de edición si está editando información del plan o días
                if (_isEditingPlanInfo || _editingDays.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          'Editando',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Carrusel
          _buildPlanCarousel(),
        ],
      ),
    );
  }

  Widget _buildPlanCarousel() {
    return Container(
      height: 500,
      child: Column(
        children: [
          // Indicadores de página
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCarouselIndicator(0, 'Información'),
              const SizedBox(width: 24),
              _buildCarouselIndicator(1, 'Días'),
            ],
          ),

          const SizedBox(height: 16),

          // Carrusel de contenido
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
              children: [
                _buildPlanInfoCard(),
                _buildWeekDaysCard(),
              ],
            ),
          ),

          // Navegación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flecha izquierda
                IconButton(
                  onPressed: _currentCarouselIndex > 0
                      ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                      : null,
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: _currentCarouselIndex > 0
                        ? AppColors.primary
                        : Colors.grey.shade400,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _currentCarouselIndex > 0
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey.shade100,
                    shape: const CircleBorder(),
                  ),
                ),

                // Texto central
                Text(
                  _currentCarouselIndex == 0
                      ? 'Información del Plan'
                      : 'Días de la Semana',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),

                // Flecha derecha
                IconButton(
                  onPressed: _currentCarouselIndex < 1
                      ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                      : null,
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: _currentCarouselIndex < 1
                        ? AppColors.primary
                        : Colors.grey.shade400,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _currentCarouselIndex < 1
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey.shade100,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselIndicator(int index, String label) {
    final isActive = _currentCarouselIndex == index;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppColors.primary : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _openPlanInfoEditor(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Toca para editar información',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // Mostrar lápiz si está editando esta sección
                    if (_isEditingPlanInfo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit,
                            color: AppColors.secondary, size: 14),
                      ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios,
                        color: AppColors.primary, size: 16),
                  ],
                ),

                const SizedBox(height: 20),

                // Objetivo
                _buildInfoRow(
                  icon: Icons.flag,
                  label: 'Objetivo',
                  value: _goalController.text.isEmpty
                      ? 'No definido'
                      : _goalController.text,
                ),

                const SizedBox(height: 16),

                // Requerimientos especiales
                _buildInfoRow(
                  icon: Icons.medical_services,
                  label: 'Requerimientos',
                  value: _specialRequirementsController.text.isEmpty
                      ? 'Ninguno'
                      : _specialRequirementsController.text,
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Calorías y fecha en fila
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.local_fire_department,
                        label: 'Calorías',
                        value: '${_energyRequirementController.text} kcal',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.calendar_today,
                        label: 'Inicio',
                        value: _weekStartDateController.text.isEmpty
                            ? 'No definido'
                            : _weekStartDateController.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPlanInfoEditor() {
    setState(() {
      _isEditingPlanInfo = true;
    });
    _saveEditingState('editing_plan_info_${widget.plan.planId}', true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _buildPlanInfoEditor(scrollController),
        ),
      ),
    ).whenComplete(() {
      setState(() {
        _isEditingPlanInfo = false;
      });
      _saveEditingState('editing_plan_info_${widget.plan.planId}', false);
    });
  }

  void _openDayEditor(int dayIndex, String dayName) {
    setState(() {
      _editingDays.add(dayIndex);
    });
    _saveEditingDays();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _buildDayEditor(dayIndex, dayName, scrollController),
        ),
      ),
    ).whenComplete(() {
      setState(() {
        _editingDays.remove(dayIndex);
      });
      _saveEditingDays();
    });
  }

  Widget _buildPlanInfoEditor(ScrollController scrollController) {
    return Column(
      children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                'Editar Información del Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),

        // Contenido
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTextField(
                  controller: _goalController,
                  label: 'Objetivo del Plan',
                  icon: Icons.flag,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese el objetivo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _specialRequirementsController,
                  label: 'Requerimientos Especiales',
                  icon: Icons.medical_services,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _energyRequirementController,
                  label: 'Requerimiento Energético (kcal)',
                  icon: Icons.local_fire_department,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese el requerimiento energético';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Por favor ingrese un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _weekStartDateController,
                  label: 'Fecha de Inicio (YYYY-MM-DD)',
                  icon: Icons.calendar_today,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese la fecha de inicio';
                    }
                    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                    if (!regex.hasMatch(value)) {
                    return 'Formato de fecha inválido (Use YYYY-MM-DD)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _hasChanges = true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Guardar Cambios',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayEditor(int dayIndex, String dayName, ScrollController scrollController) {
    final day = _days[dayIndex];
    final meals = day['meals'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Editar $dayName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),

        // Contenido
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Lista de comidas
                ...meals.asMap().entries.map((mealEntry) {
                  final mealIndex = mealEntry.key;
                  final meal = mealEntry.value as Map<String, dynamic>;
                  return _buildMealCard(dayIndex, mealIndex, meal);
                }).toList(),

                // Botón para añadir comida
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _addMealToDay(dayIndex),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Añadir Comida'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildWeekDaysCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.calendar_view_week, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Selecciona un día para editar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de días con scroll mejorado
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _days.length,
                itemBuilder: (context, index) => _buildDayItem(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayItem(int dayIndex) {
    final dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final dayName = dayIndex < dayNames.length ? dayNames[dayIndex] : 'Día ${dayIndex + 1}';
    final day = _days[dayIndex];
    final meals = day['meals'] as List<dynamic>? ?? [];
    final isEditing = _editingDays.contains(dayIndex);

    // Calcular total de calorías del día
    int totalCalories = meals.fold<int>(0, (sum, meal) {
      return sum + ((meal['calories'] as int?) ?? 0);
    });

    return GestureDetector(
      onTap: () => _openDayEditor(dayIndex, dayName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono del día
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${dayIndex + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Información del día
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mostrar lápiz si está editando este día
                      if (isEditing)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.edit,
                              color: AppColors.secondary, size: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${meals.length} comidas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$totalCalories kcal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Flecha
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(int dayIndex, int mealIndex, Map<String, dynamic> meal) {
    final foods = meal['foods'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: meal['name'] ?? 'Comida ${mealIndex + 1}',
                    decoration: InputDecoration(
                      labelText: 'Nombre de la comida',
                      prefixIcon: Icon(Icons.restaurant, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => _updateMeal(dayIndex, mealIndex, 'name', value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  onPressed: () => _showDeleteMealDialog(dayIndex, mealIndex),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextFormField(
              initialValue: meal['description'] ?? '',
              decoration: InputDecoration(
                labelText: 'Descripción',
                prefixIcon: Icon(Icons.description, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 2,
              onChanged: (value) => _updateMeal(dayIndex, mealIndex, 'description', value),
            ),

            const SizedBox(height: 12),

            TextFormField(
              initialValue: meal['calories']?.toString() ?? '0',
              decoration: InputDecoration(
                labelText: 'Calorías',
                prefixIcon: Icon(Icons.local_fire_department, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final calories = int.tryParse(value) ?? 0;
                _updateMeal(dayIndex, mealIndex, 'calories', calories);
              },
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Icon(Icons.fastfood, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Alimentos:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lista de alimentos
            ...foods.asMap().entries.map((foodEntry) {
              final foodIndex = foodEntry.key;
              final food = foodEntry.value.toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: food,
                        decoration: InputDecoration(
                          labelText: 'Alimento ${foodIndex + 1}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        onChanged: (value) => _updateFoodInMeal(dayIndex, mealIndex, foodIndex, value),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                      onPressed: () => _removeFoodFromMeal(dayIndex, mealIndex, foodIndex),
                    ),
                  ],
                ),
              );
            }).toList(),

            // Botón para añadir alimento
            Container(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addFoodToMeal(dayIndex, mealIndex),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir Alimento'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.green.shade400),
                  foregroundColor: Colors.green.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (!_hasChanges) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _savePlan,
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        icon: _isSaving
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          _isSaving ? 'Guardando...' : 'Guardar Cambios',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showDeleteMealDialog(int dayIndex, int mealIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Comida'),
        content: const Text('¿Estás seguro de que quieres eliminar esta comida?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeMealFromDay(dayIndex, mealIndex);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}