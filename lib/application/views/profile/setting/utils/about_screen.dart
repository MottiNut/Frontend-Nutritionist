import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../configuration/themes/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLigth,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Acerca de MottiNut',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(

        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            // Header Card con logo y version
            _buildHeaderCard(theme),

            const SizedBox(height: 16),

            // Features Card
            _buildFeaturesCard(theme),

            const SizedBox(height: 16),

            // Team & Contact Card
            _buildTeamCard(theme),

            const SizedBox(height: 6),

            // Version Info
            _buildVersionCard(theme),
          ],
        ),
      ),
    );
  }

  /// Header principal con logo y descripción
  Widget _buildHeaderCard(ThemeData theme) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SvgPicture.asset("assets/images/logos/mottinut.svg"),

            const SizedBox(height: 8),

            // Slogan mejorado
            Text(
              'Nutrición inteligente para mejorar vidas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Descripción principal
            Text(
              'Aplicación móvil desarrollada por estudiantes de la UPC para transformar '
              'la atención nutricional mediante inteligencia artificial y planes personalizados.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Card con características principales
  Widget _buildFeaturesCard(ThemeData theme) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Características principales',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              icon: Icons.psychology,
              title: 'Inteligencia Artificial',
              description:
                  'Planes nutricionales generados con IA según tu perfil médico',
              color: Colors.purple,
            ),
            _buildFeatureItem(
              icon: Icons.favorite_border,
              title: 'Personalización Total',
              description:
                  'Adaptado a tu peso, edad, alergias y enfermedades crónicas',
              color: Colors.red,
            ),
            _buildFeatureItem(
              icon: Icons.people_alt_outlined,
              title: 'Apoyo Profesional',
              description: 'Herramientas especializadas para nutricionistas',
              color: Colors.blue,
            ),
            _buildFeatureItem(
              icon: Icons.trending_up,
              title: 'Seguimiento Continuo',
              description: 'Monitoreo de progreso y ajustes automáticos',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(ThemeData theme) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Desarrollado en UPC',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Proyecto académico desarrollado por estudiantes comprometidos con la '
              'innovación en salud y tecnología. Nuestro objetivo es democratizar '
              'el acceso a una nutrición personalizada y de calidad.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // Impacto social
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.public, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tecnología que cuida, alimenta y transforma vidas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionCard(ThemeData theme) {
    return Card(
      elevation: 2,
      color: Colors.grey[50],
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Versión', '2.1.0'),
                _buildInfoItem('Build', '202500233423'),
                _buildInfoItem('Año', '2025'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '© 2025 MottiNut -  Todos los Derechos Reservados',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
