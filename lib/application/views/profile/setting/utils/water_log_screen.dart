import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/patient/entity/patient.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import '../../../../../domain/services/auth_provider.dart';
import 'package:dropdown_flutter/custom_dropdown.dart';

import '../../../../requestSnacbar/snackBar_manager.dart';

class WaterLogScreen extends StatefulWidget {
  const WaterLogScreen({super.key});

  @override
  State<WaterLogScreen> createState() => _WaterLogScreenState();
}

class _WaterLogScreenState extends State<WaterLogScreen> {
  // Servicios
  final NutritionistService _nutritionistService = NutritionistService();

  // Lista de pacientes
  List<PatientProfile> patients = [];
  PatientProfile? selectedPatient;

  bool isLoadingPatients = false;

  double weight = 0;
  int age = 0;
  String? gender;
  String? activityLevel;
  String? climate;
  bool hasKidneyProblems = false;
  bool isPregnant = false;
  bool isBreastfeeding = false;

  // Unidad de medida
  String unit = 'L';
  double unitFactor = 0.001;

  TextEditingController _weightController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: weight.toString());
    _ageController = TextEditingController(text: age.toString());
    _loadPatients();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => isLoadingPatients = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        final loadedPatients =
            await _nutritionistService.getAllPatients(token: token);
        if (mounted) {
          setState(() {
            patients = loadedPatients;
          });
        }
      }
    } on SocketException catch (_) {
      // 🔌 Sin conexión a Internet
      if (mounted) {
        SnackBarManager.showError(
          context,
          'No hay conexión a Internet. Verifica tu red e inténtalo de nuevo.',
        );
      }
    } on HttpException catch (_) {
      // 🌐 Problema en el servidor
      if (mounted) {
        SnackBarManager.showError(
          context,
          'El servidor no responde en este momento. Intenta nuevamente en unos minutos.',
        );
      }
    } on FormatException catch (_) {
      // 📦 Respuesta inesperada
      if (mounted) {
        SnackBarManager.showError(
          context,
          'Se recibió información no válida del servidor. Intenta más tarde.',
        );
      }
    } catch (_) {
      // ❗ Error genérico
      if (mounted) {
        SnackBarManager.showError(
          context,
          'No se pudieron cargar los pacientes. Por favor, inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => isLoadingPatients = false);
    }
  }

  void _onPatientSelected(PatientProfile? patient) {
    setState(() {
      selectedPatient = patient;
      if (patient != null) {
        weight = patient.weight ?? 0;
        age = patient.age ?? 0;
        gender = (patient.gender == 'male' || patient.gender == 'Masculino')
            ? 'Masculino'
            : 'Femenino';

        _weightController.text = weight.toString();
        _ageController.text = age.toString();

        hasKidneyProblems = false;
        isPregnant = false;
        isBreastfeeding = false;

        if (age < 18) {
          activityLevel = 'Moderada';
        } else if (age > 65) {
          activityLevel = 'Ligera';
        } else {
          activityLevel = 'Moderada';
        }
        climate = 'Templado';
      }
    });
  }

  double _calculateRecommendedWater() {
    double baseMl = 0;

    if (gender == 'Masculino') {
      baseMl = weight * 35;
    } else {
      baseMl = weight * 31;
    }

    // Ajuste por edad
    if (age > 65) {
      baseMl *= 1.1;
    } else if (age < 18) {
      baseMl *= 1.15;
    }

    // Ajuste por actividad física
    switch (activityLevel) {
      case 'Sedentaria':
        baseMl *= 1.0;
        break;
      case 'Ligera':
        baseMl *= 1.1;
        break;
      case 'Moderada':
        baseMl *= 1.25;
        break;
      case 'Intensa':
        baseMl *= 1.4;
        break;
      case 'Muy Intensa':
        baseMl *= 1.6;
        break;
    }

    // Ajuste por clima
    switch (climate) {
      case 'Frío':
        baseMl *= 1.0;
        break;
      case 'Templado':
        baseMl *= 1.1;
        break;
      case 'Cálido':
        baseMl *= 1.2;
        break;
      case 'Muy Cálido':
        baseMl *= 1.35;
        break;
    }

    if (isPregnant) {
      baseMl *= 1.3;
    }

    if (isBreastfeeding) {
      baseMl *= 1.6;
    }

    if (hasKidneyProblems) {
      baseMl *= 0.8;
    }

    return baseMl;
  }

  void _changeUnit(String newUnit) {
    setState(() {
      unit = newUnit;
      switch (newUnit) {
        case 'ml':
          unitFactor = 1;
          break;
        case 'L':
          unitFactor = 0.001;
          break;
        case 'oz':
          unitFactor = 0.033814;
          break;
      }
    });
  }

  void _showUnitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fila del título con botón cerrar
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Seleccionar unidad",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade300,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...['ml', 'L', 'oz'].map((unit) {
                  final bool isSelected = unit == this.unit;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _changeUnit(unit);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade100,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            color:
                                isSelected ? Colors.white : AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _clearForm() {
    setState(() {
      selectedPatient = null;
      weight = 0;
      age = 0;
      gender = 'Masculino';
      activityLevel = 'Moderada';
      climate = 'Templado';
      hasKidneyProblems = false;
      isPregnant = false;
      isBreastfeeding = false;

      // Actualizar controladores
      _weightController.text = weight.toString();
      _ageController.text = age.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double recommendedMl = _calculateRecommendedWater();
    final int glassSize = 250; // ml por vaso
    final int dailyGlasses = (recommendedMl / glassSize).round();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Calculadora de Hidratación',
          style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              letterSpacing: -0.1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Limpiar formulario',
            onPressed: _clearForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              color: Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Seleccionar Paciente",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        if (isLoadingPatients)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // DROPDOWN
                    patients.isEmpty
                        ? const Text(
                            'No hay pacientes disponibles',
                            style: TextStyle(color: Colors.grey),
                          )
                        : DropdownFlutter<PatientProfile>.search(
                            hintText: 'Selecciona un paciente',
                            items: patients,
                            excludeSelected: false,
                            initialItem: selectedPatient,
                            onChanged: _onPatientSelected,
                          ),

                    // MOSTRAR PACIENTE SELECCIONADO (solo una vez)
                    if (selectedPatient != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Paciente: ${selectedPatient!.firstName} ${selectedPatient!.lastName}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              color: Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header clicable
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Parámetros de Cálculo",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            enabled: selectedPatient == null,
                            onChanged: selectedPatient == null
                                ? (value) {
                                    setState(() {
                                      weight = double.tryParse(value) ?? 70;
                                    });
                                  }
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Peso (kg)',
                              prefixIcon: const Icon(Icons.monitor_weight),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade400),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            enabled: selectedPatient == null,
                            onChanged: selectedPatient == null
                                ? (value) {
                                    setState(() {
                                      age = int.tryParse(value) ?? 30;
                                    });
                                  }
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Edad (años)',
                              prefixIcon: const Icon(Icons.cake),
                              filled: true,
                              fillColor: Colors.white,
                              // fondo blanco
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    16), // bordes redondeados
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade400),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Contenido expandible
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      // nada cuando está colapsado
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // Dropdown de Género
                          patients.isEmpty
                              ? const SizedBox()
                              : DropdownFlutter<String>.search(
                                  hintText: 'Selecciona el género',
                                  items: ['Masculino', 'Femenino'],
                                  initialItem: gender,
                                  onChanged: selectedPatient == null
                                      ? (value) {
                                          setState(() {
                                            gender = value!;
                                          });
                                        }
                                      : null,
                                ),
                          const SizedBox(height: 10),
                          DropdownFlutter<String>.search(
                            hintText: 'Selecciona nivel de actividad',
                            items: [
                              'Sedentaria',
                              'Ligera',
                              'Moderada',
                              'Intensa',
                              'Muy Intensa'
                            ],
                            initialItem: activityLevel,
                            onChanged: (value) {
                              setState(() {
                                activityLevel = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownFlutter<String>.search(
                            hintText: 'Selecciona clima',
                            items: ['Frío', 'Templado', 'Cálido', 'Muy Cálido'],
                            initialItem: climate,
                            onChanged: (value) {
                              setState(() {
                                climate = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // Condiciones especiales
                          const Text(
                            "Condiciones especiales:",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              _buildStyledCheckbox(
                                label: "Embarazo",
                                value: isPregnant,
                                onChanged: (val) {
                                  setState(() {
                                    isPregnant = val;
                                    if (isPregnant && gender == 'Masculino')
                                      gender = 'Femenino';
                                  });
                                },
                              ),
                              _buildStyledCheckbox(
                                label: "Lactancia",
                                value: isBreastfeeding,
                                onChanged: (val) {
                                  setState(() {
                                    isBreastfeeding = val;
                                    if (isBreastfeeding &&
                                        gender == 'Masculino')
                                      gender = 'Femenino';
                                  });
                                },
                              ),
                              _buildStyledCheckbox(
                                label: "Problemas renales",
                                value: hasKidneyProblems,
                                onChanged: (val) {
                                  setState(() {
                                    hasKidneyProblems = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.green.shade50, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(15, 13, 16, 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Recomendación Diaria",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: _showUnitDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  unit,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down,
                                    color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Resultado principal
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (selectedPatient != null)
                            Text(
                              "Para: ${selectedPatient!.firstName} ${selectedPatient!.lastName}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            "${(recommendedMl * unitFactor).toStringAsFixed(1)} $unit",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            "por día",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Equivale a $dailyGlasses vasos de 250ml",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Distribución sugerida:",
                            style: TextStyle(fontWeight: FontWeight.bold,  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              "- Al despertar: ${(dailyGlasses * 0.15).round()} vasos"),
                          Text(
                              "- Durante comidas: ${(dailyGlasses * 0.3).round()} vasos"),
                          Text(
                              "- Entre comidas: ${(dailyGlasses * 0.4).round()} vasos"),
                          Text(
                              "- Antes de dormir: ${(dailyGlasses * 0.15).round()} vasos"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: Colors.orange.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          "Notas Importantes",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getProfessionalNotes(),
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledCheckbox({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: value ? AppColors.primary : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProfessionalNotes() {
    String notes =
        "• Esta calculadora utiliza fórmulas científicas actualizadas\n";
    notes +=
        "• Los valores son aproximados y pueden variar según condiciones individuales\n";

    if (hasKidneyProblems) {
      notes +=
          "⚠️ IMPORTANTE: Paciente con problemas renales - consultar con médico antes de aplicar\n";
    }

    if (isPregnant) {
      notes += "🤱 Requerimiento aumentado por embarazo (+30%)\n";
    }

    if (isBreastfeeding) {
      notes += "🍼 Requerimiento aumentado por lactancia (+60%)\n";
    }

    if (activityLevel == 'Intensa' || activityLevel == 'Muy Intensa') {
      notes +=
          "🏃‍♂️ Considerar hidratación adicional durante y después del ejercicio\n";
    }

    if (climate == 'Cálido' || climate == 'Muy Cálido') {
      notes += "☀️ Ambiente cálido: considerar bebidas con electrolitos\n";
    }

    notes += "• Ajustar según respuesta individual del paciente";

    return notes;
  }
}
