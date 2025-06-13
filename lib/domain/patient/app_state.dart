import 'package:flutter/foundation.dart';
import 'package:mottinutnutriotinist/domain/patient/repositories/nutrition_repository.dart';
import 'entity/patient.dart';
import 'enums/gender.dart';

class AppState extends ChangeNotifier {
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  List<NutritionPlan> _selectedPatientPlans = [];
  bool _isLoading = false;
  String? _errorMessage;

  final NutritionRepository _repository = NutritionRepository();

  // Getters
  List<Patient> get patients => _patients;
  Patient? get selectedPatient => _selectedPatient;
  List<NutritionPlan> get selectedPatientPlans => _selectedPatientPlans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cargar pacientes
  Future<void> loadPatients() async {
    _setLoading(true);
    try {
      _patients = await _repository.getPatients();
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Seleccionar paciente y cargar sus planes
  Future<void> selectPatient(String patientId) async {
    _setLoading(true);
    try {
      _selectedPatient = await _repository.getPatientById(patientId);
      _selectedPatientPlans = await _repository.getPlansByPatient(patientId);
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Generar plan nutricional
  Future<void> generatePlan({
    required String goal,
    required int durationWeeks,
    required List<MealType> mealTypes,
    String? specialRequests,
  }) async {
    if (_selectedPatient == null) return;

    _setLoading(true);
    try {
      final newPlan = await _repository.generateNutritionPlan(
        patientId: _selectedPatient!.id,
        goal: goal,
        durationWeeks: durationWeeks,
        mealTypes: mealTypes,
        specialRequests: specialRequests,
      );

      _selectedPatientPlans.insert(0, newPlan);
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Buscar pacientes
  Future<void> searchPatients(String query) async {
    if (query.isEmpty) {
      await loadPatients();
      return;
    }

    _setLoading(true);
    try {
      _patients = await _repository.searchPatients(query);
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Helpers privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}