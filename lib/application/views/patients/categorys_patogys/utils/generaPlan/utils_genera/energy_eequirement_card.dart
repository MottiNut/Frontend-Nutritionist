import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../../../../configuration/themes/app_colors.dart';

class EnergyRequirementCard extends StatelessWidget {
  final double? energyRequirement;
  final bool hasValidData;
  final double? Function() calculateTMB;
  final double? Function() getActivityFactor;
  final double? Function() getStressFactor;

  final String? gender;
  final int? age;
  final double? weight;
  final double? height;
  final String? patientName;
  final bool isLoading;

  const EnergyRequirementCard({
    Key? key,
    required this.energyRequirement,
    required this.hasValidData,
    required this.calculateTMB,
    required this.getActivityFactor,
    required this.getStressFactor,
    this.gender,
    this.age,
    this.weight,
    this.height,
    this.patientName,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasValidData ? () => _showEnergyCalculationDetails(context) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValidData
                ? const Color(0xFFE8F2FF)
                : const Color(0xFFF5F5F7),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con imagen y título
              Row(
                children: [
                  // Imagen o icono
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: hasValidData
                          ? const Color(0xFFF0F7FF)
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: hasValidData
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/plan/dx.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackIcon(true),
                      ),
                    )
                        : _buildFallbackIcon(false),
                  ),

                  const SizedBox(width: 16),

                  // Título y subtítulo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoading ? 'Calculando...' : (hasValidData ? 'Energía diaria' : 'Cálculo energético'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLDark,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isLoading
                              ? 'Procesando datos'
                              : (hasValidData
                              ? 'Cálculo completado'
                              : 'Completa tu perfil para obtener el cálculo'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isLoading
                                ? AppColors.primary
                                : (hasValidData
                                ? AppColors.primary
                                : Color(0xFF6B7280)),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Valor principal
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 20),
          decoration: hasValidData
              ? BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE8F2FF),
              width: 1,
            ),
          )
              : null, // Sin fondo ni borde si no hay datos
          child: Column(
            children: [
              if (isLoading) ...[
                SizedBox(
                  height: 40,
                  child: Center(
                    child: Lottie.asset(
                      'assets/loading/palta_saltarina.json',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ] else if (hasValidData) ...[
                // Mostrar calorías
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(energyRequirement ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1D29),
                        letterSpacing: 0.7,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'kcal/día',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Sin datos: imagen más pequeña sin fondo
                Column(
                  children: [
                    Image.asset(
                      'assets/plan/no_found.png',
                      width: 45,
                      height: 45,
                      fit: BoxFit.contain,

                    ),

                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(
                height: 4,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hasValidData && !isLoading
                          ? 'Ver detalles'
                          : '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary1,
                      ),
                    ),
                    if (hasValidData && !isLoading) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.touch_app_outlined,
                        size: 16,
                        color: AppColors.textPrimary1,
                      ),
                    ],
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(bool hasData) {
    return Icon(
      hasData
          ? Icons.local_fire_department_outlined
          : Icons.help_outline_rounded,
      size: 24,
      color: hasData ? const Color(0xFF6B9DFF) : const Color(0xFF9CA3AF),
    );
  }

  // NUEVO: Método para obtener el icono según el género
  Widget _getGenderIcon() {
    if (gender == null) return const SizedBox.shrink();

    bool isMale = gender!.toLowerCase().startsWith('m') || gender!.toLowerCase() == 'masculino';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMale ? AppColors.backgroundHipertencion.withOpacity(0.2) : AppColors.errorText.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMale ? AppColors.backgroundHipertencion: AppColors.errorText,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMale ? Icons.male : Icons.female,
            size: 16,
            color: isMale ? AppColors.backgroundHipertencion: AppColors.errorText,
          ),
          const SizedBox(width: 4),
          Text(
            isMale ? 'Masculino' : 'Femenino',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isMale ? AppColors.primary: AppColors.errorText,
            ),
          ),
        ],
      ),
    );
  }

  void _showEnergyCalculationDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            children: [
              Container(color: Colors.transparent),
              GestureDetector(
                onTap: () {},
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 0.9,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: _buildDetailedEnergyCalculation(
                            context, scrollController),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailedEnergyCalculation(
      BuildContext context, ScrollController scrollController) {
    double tmb = calculateTMB() ?? 0;
    double activityFactor = getActivityFactor() ?? 1.0;
    double stressFactor = getStressFactor() ?? 1.0;
    double totalRequirement = tmb * activityFactor * stressFactor;

    return Column(
      children: [
        // Handle minimalista
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header mejorado con información del paciente
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                         'Resumen Energético',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                            letterSpacing: -0.2,
                          ),
                        ),
                         Text(
                          'Paciente: $patientName',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),

              // NUEVO: Información del paciente
              if (hasValidData && (gender != null || age != null || weight != null || height != null))
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      // Género
                      if (gender != null) ...[
                        _getGenderIcon(),
                        const SizedBox(width: 12),
                      ],

                      // Datos básicos
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (age != null)
                              _buildPatientInfo('Edad', '$age años', Icons.cake_outlined),
                            if (weight != null)
                              _buildPatientInfo('Peso', '${weight!.toStringAsFixed(1)} kg', Icons.monitor_weight_outlined),
                            if (height != null)
                              _buildPatientInfo('Talla', '${height!.toStringAsFixed(0)} cm', Icons.height_outlined),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Contenido principal
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Resultado principal
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(width: 1.2, color: AppColors.primary.withOpacity(0.2),),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Requerimiento Total',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${totalRequirement.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: AppColors.backgroundIconNav,
                              letterSpacing: 0.4,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              'kcal/día',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Componentes del cálculo mejorados
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      // NUEVO: Header con fórmula usada
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.functions,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Fórmula Harris-Benedict ${_getGenderText()}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      _buildCalculationComponent(
                        'TMB',
                        'Tasa Metabólica Basal',
                        '${tmb.toStringAsFixed(0)} kcal',
                        Icons.favorite_border,
                        AppColors.backgroundHipertencion,
                        isFirst: true,
                      ),
                      _buildCalculationComponent(
                        'Factor Actividad',
                        'Nivel de actividad física',
                        '× ${activityFactor.toStringAsFixed(2)}',
                        Icons.directions_run,
                        AppColors.backgroundHipertencion,
                      ),
                      _buildCalculationComponent(
                        'Factor Estrés',
                        'Condición clínica actual',
                        '× ${stressFactor.toStringAsFixed(2)}',
                        Icons.healing,
                        AppColors.backgroundHipertencion,
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Fórmula final
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calculate,
                            color: const Color(0xFF6B7280),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Cálculo Final',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'RET = TMB × FA × FE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${tmb.toStringAsFixed(0)} × ${activityFactor.toStringAsFixed(2)} × ${stressFactor.toStringAsFixed(2)} = ${totalRequirement.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // NUEVO: Widget para mostrar información del paciente
  Widget _buildPatientInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // NUEVO: Método para obtener texto del género
  String _getGenderText() {
    if (gender == null) return '';
    bool isMale = gender!.toLowerCase().startsWith('m') || gender!.toLowerCase() == 'masculino';
    return isMale ? '(Masculino)' : '(Femenino)';
  }

  Widget _buildCalculationComponent(
      String title,
      String subtitle,
      String value,
      IconData icon,
      Color iconColor, {
        bool isFirst = false,
        bool isLast = false,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.backgroundHipertencion.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.backgroundHipertencion.withOpacity(0.4)),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary1,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textInput,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}