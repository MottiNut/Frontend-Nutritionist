import '/../../../domain/patient/pruebaa.dart';

class NutritionalCalculator {
  final Patient patient;
  final Map<String, dynamic> savedData;

  NutritionalCalculator({
    required this.patient,
    required this.savedData,
  });

  /// Obtiene la edad del paciente (datos guardados tienen prioridad)
  int get age {
    return int.tryParse(savedData['age']?.toString() ?? '') ??
        patient.age ?? 0;
  }

  /// Obtiene el peso del paciente (datos guardados tienen prioridad)
  double get weight {
    return double.tryParse(savedData['weight']?.toString() ?? '') ??
        patient.weight ?? 0.0;
  }

  /// Obtiene la altura del paciente (datos guardados tienen prioridad)
  double get height {
    return double.tryParse(savedData['height']?.toString() ?? '') ??
        patient.height ?? 0.0;
  }

  /// Calcula la Tasa Metabólica Basal usando la fórmula Harris-Benedict
  double calculateTMB() {
    if (weight <= 0 || height <= 0 || age <= 0) return 0;

    // Convertir altura a cm si está en metros
    double heightInCm = height;
    if (height > 0 && height < 3) {
      heightInCm = height * 100;
    }

    double tmb = 0;
    if (patient.gender.displayName.toLowerCase() == 'masculino') {
      // Fórmula Harris-Benedict para hombres
      tmb = 66.4730 + (13.7516 * weight) + (5.0033 * heightInCm) - (6.7550 * age);
    } else {
      // Fórmula Harris-Benedict para mujeres
      tmb = 655.0955 + (9.5634 * weight) + (1.8449 * heightInCm) - (4.6756 * age);
    }

    return tmb;
  }

  /// Obtiene el factor de actividad física basado en el tipo de actividad
  double getActivityFactor() {
    String tipoActividad = savedData['tipoActividad']?.toString().toLowerCase() ?? '';

    // Sedentario/Muy ligero: 1.2
    if (tipoActividad.contains('sedentaria') ||
        tipoActividad.contains('menos de 30 min/semana') ||
        tipoActividad.contains('muy ligera') ||
        tipoActividad.contains('caminar ocasionalmente')) {
      return 1.2;
    }

    // Ligero: 1.375
    else if (tipoActividad.contains('ligera (caminar 30 min') ||
        tipoActividad.contains('ligera a moderada') ||
        tipoActividad.contains('tareas domésticas activas') ||
        tipoActividad.contains('trabajo físico ligero') ||
        tipoActividad.contains('oficina de pie') ||
        tipoActividad.contains('actividades de fin de semana') ||
        tipoActividad.contains('yoga/pilates regular')) {
      return 1.375;
    }

    // Moderado: 1.55
    else if (tipoActividad.contains('moderada (30-45 min') ||
        tipoActividad.contains('moderada (gimnasio 3-4') ||
        tipoActividad.contains('trabajo físico moderado') ||
        tipoActividad.contains('caminatas frecuentes') ||
        tipoActividad.contains('natación regular') ||
        tipoActividad.contains('ciclismo recreativo') ||
        tipoActividad.contains('running/trote ocasional') ||
        tipoActividad.contains('baile/danza')) {
      return 1.55;
    }

    // Moderado Alto: 1.725
    else if (tipoActividad.contains('moderada alta') ||
        tipoActividad.contains('ejercicio 45-60 min') ||
        tipoActividad.contains('running/trote regular') ||
        tipoActividad.contains('deportes de equipo') ||
        tipoActividad.contains('artes marciales') ||
        tipoActividad.contains('montañismo/hiking') ||
        tipoActividad.contains('ciclismo intenso')) {
      return 1.725;
    }

    // Intenso: 1.9
    else if (tipoActividad.contains('intensa (ejercicio diario') ||
        tipoActividad.contains('muy intensa') ||
        tipoActividad.contains('entrenamiento deportivo') ||
        tipoActividad.contains('deportista amateur') ||
        tipoActividad.contains('trabajo físico pesado') ||
        tipoActividad.contains('construcción, carga')) {
      return 1.9;
    }

    // Muy Intenso: 2.2
    else if (tipoActividad.contains('deportista semi-profesional') ||
        tipoActividad.contains('deportista profesional') ||
        tipoActividad.contains('trabajo físico muy exigente')) {
      return 2.2;
    }

    // Valor por defecto
    return 1.375; // Actividad ligera como promedio
  }

  /// Obtiene el factor de estrés basado en comorbilidades y diagnósticos
  double getStressFactor() {
    List<String> comorbilidades = [];

    // Obtener comorbilidades del savedData
    if (savedData['comorbilidades'] != null) {
      String comorbString = savedData['comorbilidades'].toString().toLowerCase();
      comorbilidades = comorbString.split(',').map((e) => e.trim()).toList();
    }

    String diagnostico = savedData['diagnosticoMedicoReciente']?.toString().toLowerCase() ?? '';

    // Factor de estrés alto (1.4-1.5) - Condiciones severas
    bool tieneEstresAlto = comorbilidades.any((c) =>
    c.contains('enfermedad renal') ||
        c.contains('enfermedad hepática') ||
        c.contains('crónica')) ||
        diagnostico.contains('cáncer') ||
        diagnostico.contains('diabetes descompensada') ||
        diagnostico.contains('insuficiencia') ||
        diagnostico.contains('sepsis');

    if (tieneEstresAlto) return 1.45;

    // Factor de estrés moderado (1.2-1.3) - Condiciones moderadas
    bool tieneEstresModerado = comorbilidades.any((c) =>
    c.contains('dislipidemia') ||
        c.contains('artritis') ||
        c.contains('artrosis') ||
        c.contains('trastornos de tiroides') ||
        c.contains('apnea del sueño')) ||
        diagnostico.contains('diabetes') ||
        diagnostico.contains('hipertensión') ||
        diagnostico.contains('obesidad');

    if (tieneEstresModerado) return 1.25;

    // Factor de estrés leve (1.1) - Condiciones menores
    bool tieneEstresLeve = comorbilidades.any((c) =>
    c.contains('asma') ||
        c.contains('reflujo gastroesofágico') ||
        c.contains('ansiedad') ||
        c.contains('depresión') ||
        c.contains('pie plano') ||
        c.contains('escoliosis'));

    if (tieneEstresLeve) return 1.1;

    // Sin comorbilidades significativas
    if (comorbilidades.isEmpty || comorbilidades.any((c) => c.contains('ninguna'))) {
      return 1.0;
    }

    // Por defecto, si hay alguna comorbilidad no identificada
    return 1.05;
  }

  /// Calcula el requerimiento energético total
  double calculateEnergyRequirement() {
    double tmb = calculateTMB();
    double activityFactor = getActivityFactor();
    double stressFactor = getStressFactor();

    return tmb * activityFactor * stressFactor;
  }

  /// Obtiene el diagnóstico nutricional basado en el IMC
  String getDiagnosticoNutricional() {
    double bmi = patient.bmi;
    if (bmi <= 0) return 'N/A';

    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  /// Verifica si hay datos válidos para el cálculo energético
  bool hasValidEnergyData() {
    return age > 0 && weight > 0 && height > 0 && calculateEnergyRequirement() > 0;
  }

  /// Método de debugging para verificar los cálculos
  void debugEnergyCalculation() {
    double tmb = calculateTMB();
    double activityFactor = getActivityFactor();
    double stressFactor = getStressFactor();
    double totalRequirement = calculateEnergyRequirement();

    print('=== DEBUG CÁLCULO ENERGÉTICO DETALLADO ===');
    print('📊 DATOS DEL PACIENTE:');
    print('   Edad: $age años');
    print('   Peso: $weight kg');
    print('   Altura: $height m');
    print('   Género: ${patient.gender.displayName}');
    print('');
    print('🔥 CÁLCULOS:');
    print('   TMB: ${tmb.toStringAsFixed(2)} kcal');
    print('   Factor Actividad: $activityFactor');
    print('   Factor Estrés: $stressFactor');
    print('   Requerimiento Total: ${totalRequirement.toStringAsFixed(2)} kcal');
    print('');
    print('📝 DATOS GUARDADOS:');
    print('   Tipo Actividad: "${savedData['tipoActividad']}"');
    print('   Comorbilidades: "${savedData['comorbilidades']}"');
    print('   Diagnóstico Reciente: "${savedData['diagnosticoMedicoReciente']}"');
    print('');
    print('✅ FÓRMULA: TMB × FA × FE');
    print('   ${tmb.toStringAsFixed(0)} × ${activityFactor} × ${stressFactor} = ${totalRequirement.toStringAsFixed(0)} kcal');
    print('==========================================');
  }
}