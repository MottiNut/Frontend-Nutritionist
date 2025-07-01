import 'package:flutter/foundation.dart';
import '../patient_models.dart';
import '../services/patient_api_service.dart';

class PatientProvider with ChangeNotifier {
  final PatientApiService _apiService;

  PatientProvider(this._apiService);

  // Estado para la lista de pacientes
  List<PatientProfileDto> _patients = [];
  List<PatientProfileDto> get patients => _patients;

  // Estado para el paciente seleccionado
  PatientProfileDto? _selectedPatient;
  PatientProfileDto? get selectedPatient => _selectedPatient;

  // Estado para el historial médico
  List<MedicalHistoryDto> _medicalHistory = [];
  List<MedicalHistoryDto> get medicalHistory => _medicalHistory;

  // Estado para paciente con historial
  PatientWithHistoryDto? _patientWithHistory;
  PatientWithHistoryDto? get patientWithHistory => _patientWithHistory;

  // Estado para filtros y opciones
  List<ChronicDiseaseFilterDto> _chronicDiseaseFilters = [];
  List<ChronicDiseaseFilterDto> get chronicDiseaseFilters => _chronicDiseaseFilters;

  PatientSortOptionsDto? _sortOptions;
  PatientSortOptionsDto? get sortOptions => _sortOptions;

  // Estado para resumen de salud
  PatientHealthSummaryDto? _healthSummary;
  PatientHealthSummaryDto? get healthSummary => _healthSummary;

  // Estado para progreso
  PatientProgressDto? _progress;
  PatientProgressDto? get progress => _progress;

  // Estados de carga y error
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Cargar todos los pacientes
  Future<void> loadAllPatients({
    String chronicDisease = 'all',
    String sortBy = 'name',
    String order = 'asc',
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      _patients = await _apiService.getAllPatients(
        chronicDisease: chronicDisease,
        sortBy: sortBy,
        order: order,
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar paciente por ID
  Future<void> loadPatientById(int patientId) async {
    _setLoading(true);
    _setError(null);

    try {
      _selectedPatient = await _apiService.getPatientById(patientId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar paciente con historial
  Future<void> loadPatientWithHistory(int patientId) async {
    _setLoading(true);
    _setError(null);

    try {
      _patientWithHistory = await _apiService.getPatientWithHistory(patientId);
      _selectedPatient = _patientWithHistory?.patient;
      _medicalHistory = _patientWithHistory?.medicalHistories ?? [];
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar historial médico
  Future<void> loadPatientHistory(
      int patientId, {
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    _setLoading(true);
    _setError(null);

    try {
      _medicalHistory = await _apiService.getPatientHistory(
        patientId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Crear historial médico
  Future<MedicalHistoryDto?> createMedicalHistory(
      int patientId,
      CreateMedicalHistoryRequest request,
      ) async {
    _setLoading(true);
    _setError(null);

    try {
      final newHistory = await _apiService.createMedicalHistory(patientId, request);

      // Actualizar la lista local
      _medicalHistory.insert(0, newHistory);

      // Si tenemos el paciente con historial cargado, actualizarlo
      if (_patientWithHistory != null) {
        _patientWithHistory = PatientWithHistoryDto(
          patient: _patientWithHistory!.patient,
          medicalHistories: _medicalHistory,
          latestHistory: newHistory,
          totalHistories: (_patientWithHistory!.totalHistories ?? 0) + 1,
        );
      }

      notifyListeners();
      return newHistory;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Actualizar historial médico
  Future<MedicalHistoryDto?> updateMedicalHistory(
      int historyId,
      UpdateMedicalHistoryRequest request,
      ) async {
    _setLoading(true);
    _setError(null);

    try {
      final updatedHistory = await _apiService.updateMedicalHistory(historyId, request);

      // Actualizar en la lista local
      final index = _medicalHistory.indexWhere((h) => h.historyId == historyId);
      if (index != -1) {
        _medicalHistory[index] = updatedHistory;
      }

      // Actualizar en patientWithHistory si está cargado
      if (_patientWithHistory != null) {
        final updatedHistories = _patientWithHistory!.medicalHistories?.map((h) {
          return h.historyId == historyId ? updatedHistory : h;
        }).toList();

        _patientWithHistory = PatientWithHistoryDto(
          patient: _patientWithHistory!.patient,
          medicalHistories: updatedHistories,
          latestHistory: _patientWithHistory!.latestHistory?.historyId == historyId
              ? updatedHistory
              : _patientWithHistory!.latestHistory,
          totalHistories: _patientWithHistory!.totalHistories,
        );
      }

      notifyListeners();
      return updatedHistory;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar filtros de enfermedades crónicas
  Future<void> loadChronicDiseaseFilters() async {
    _setLoading(true);
    _setError(null);

    try {
      _chronicDiseaseFilters = await _apiService.getChronicDiseaseFilters();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar opciones de ordenamiento
  Future<void> loadSortOptions() async {
    _setLoading(true);
    _setError(null);

    try {
      _sortOptions = await _apiService.getSortOptions();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar resumen de salud
  Future<void> loadHealthSummary(int patientId) async {
    _setLoading(true);
    _setError(null);

    try {
      _healthSummary = await _apiService.getPatientHealthSummary(patientId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar progreso del paciente
  Future<void> loadPatientProgress(int patientId, {int days = 30}) async {
    _setLoading(true);
    _setError(null);

    try {
      _progress = await _apiService.getPatientProgress(patientId, days: days);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Limpiar datos
  void clearData() {
    _patients.clear();
    _selectedPatient = null;
    _medicalHistory.clear();
    _patientWithHistory = null;
    _chronicDiseaseFilters.clear();
    _sortOptions = null;
    _healthSummary = null;
    _progress = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Buscar pacientes por nombre
  List<PatientProfileDto> searchPatients(String query) {
    if (query.isEmpty) return _patients;

    return _patients.where((patient) {
      final fullName = patient.fullName?.toLowerCase() ?? '';
      final firstName = patient.firstName?.toLowerCase() ?? '';
      final lastName = patient.lastName?.toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return fullName.contains(searchQuery) ||
          firstName.contains(searchQuery) ||
          lastName.contains(searchQuery);
    }).toList();
  }

  /// Filtrar pacientes por enfermedad crónica
  List<PatientProfileDto> filterPatientsByChronicDisease(String? chronicDisease) {
    if (chronicDisease == null || chronicDisease.isEmpty || chronicDisease == 'all') {
      return _patients;
    }

    return _patients.where((patient) {
      return patient.chronicDisease?.toLowerCase() == chronicDisease.toLowerCase();
    }).toList();
  }

  /// Obtener estadísticas rápidas
  Map<String, dynamic> getQuickStats() {
    return {
      'totalPatients': _patients.length,
      'patientsWithChronicDisease': _patients.where((p) =>
      p.hasMedicalCondition == true).length,
      'averageAge': _patients.isNotEmpty
          ? _patients.map((p) => p.age ?? 0).reduce((a, b) => a + b) / _patients.length
          : 0,
      'genderDistribution': {
        'male': _patients.where((p) => p.gender?.toLowerCase() == 'male').length,
        'female': _patients.where((p) => p.gender?.toLowerCase() == 'female').length,
      },
    };
  }
}