import 'package:flutter/material.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/pages/location_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/pages/payments_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/pages/personal_info_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/pages/privacy_security_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/pages/professional_verification_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/pages/schedule_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../configuration/themes/app_colors.dart';
import '../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import '../../../../domain/services/auth_provider.dart';
import '../../../auth/terms and conditions/politica_privacidad_screen.dart';
import '../../../auth/terms and conditions/terminos_condiciones_screen.dart';
import '../../../requestSnacbar/snackBar_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  bool _marketingEmails = false;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(
              Icons.arrow_back_ios,
              color: AppColors.iconDark,
              size: 22,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Configuración',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección: Mi Cuenta
            _buildSectionHeader('Mi Cuenta', Icons.person),
            const SizedBox(height: 4),
            _buildSettingsCard([
              _buildSettingItem(
                icon: Icons.account_circle_outlined,
                title: 'Información personal',
                subtitle: 'Nombre, email, teléfono',
                onTap: () => _navigateToPersonalInfo(),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.lock_outline,
                title: 'Privacidad y seguridad',
                subtitle: 'Contraseña, autenticación',
                onTap: () => _navigateToPrivacy(),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.verified_user_outlined,
                title: 'Verificación profesional',
                subtitle: 'Estado de verificación CNP',
                onTap: () => _navigateToVerification(),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(width: 0.3, color: AppColors.primary)
                  ),
                  child: Text(
                    'Verificado',
                    style: TextStyle(
                      color: AppColors.checkValidation,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // Sección: Práctica Profesional
            _buildSectionHeader('Práctica Profesional', Icons.medical_services),
            const SizedBox(height: 4),
            _buildSettingsCard([
              _buildSettingItem(
                icon: Icons.calendar_today_outlined,
                title: 'Horarios de consulta',
                subtitle: 'Disponibilidad y citas',
                onTap: () => _navigateToSchedule(),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.monetization_on_outlined,
                title: 'Tarifas y pagos',
                subtitle: 'Precios de consultas',
                onTap: () => _navigateToPayments(),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.location_on_outlined,
                title: 'Ubicación del consultorio',
                subtitle: 'Dirección y contacto',
                onTap: () => _navigateToLocation(),
              ),
            ]),

            const SizedBox(height: 6),

            // Sección: Herramientas Nutricionales
            _buildSectionHeader('Herramientas', Icons.restaurant_outlined),
            const SizedBox(height: 4),
            _buildSettingsCard([
              _buildSettingItem(
                icon: Icons.flag_outlined,
                title: 'Mis objetivos',
                subtitle: 'Metas profesionales',
                onTap: () => _navigateToGoals(),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.water_drop_outlined,
                title: 'Diario y registro de agua',
                subtitle: 'Seguimiento diario',
                onTap: () => _navigateToWaterLog(),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.scale_outlined,
                title: 'Unidades de medida',
                subtitle: 'Sistema métrico, imperial',
                onTap: () => _navigateToUnits(),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.restaurant_menu_outlined,
                title: 'Base de datos de alimentos',
                subtitle: 'Personalizar alimentos',
                onTap: () => _navigateToFoodDatabase(),
              ),
            ]),

            const SizedBox(height: 24),

            // Sección: Notificaciones
            _buildSectionHeader('Notificaciones', Icons.notifications),
            const SizedBox(height: 4),
            _buildSettingsCard([
              _buildSwitchItem(
                icon: Icons.notifications_active_outlined,
                title: 'Notificaciones push',
                subtitle: 'Recordatorios y alertas',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.alarm_outlined,
                title: 'Recordatorios',
                subtitle: 'Personalizar alarmas',
                onTap: () => _navigateToReminders(),
              ),
              _buildDivider(),
              _buildSwitchItem(
                icon: Icons.email_outlined,
                title: 'Emails promocionales',
                subtitle: 'Noticias y actualizaciones',
                value: _marketingEmails,
                onChanged: (value) {
                  setState(() {
                    _marketingEmails = value;
                  });
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Sección: Apariencia
            _buildSectionHeader('Apariencia', Icons.palette),
            const SizedBox(height: 4),
            _buildSettingsCard([
              _buildSwitchItem(
                icon: Icons.dark_mode_outlined,
                title: 'Modo oscuro',
                subtitle: 'Tema de la aplicación',
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled = value;
                  });
                },
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.language_outlined,
                title: 'Idioma',
                subtitle: 'Español',
                onTap: () => _navigateToLanguage(),
              ),
            ]),

            const SizedBox(height: 24),

            // Sección: Seguridad
            _buildSectionHeader('Seguridad', Icons.security),
            const SizedBox(height: 4),
            _buildSettingsCard([
              _buildSwitchItem(
                icon: Icons.fingerprint_outlined,
                title: 'Autenticación biométrica',
                subtitle: 'Huella dactilar o Face ID',
                value: _biometricEnabled,
                onChanged: (value) {
                  setState(() {
                    _biometricEnabled = value;
                  });
                },
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.backup_outlined,
                title: 'Copia de seguridad',
                subtitle: 'Respaldo de datos',
                onTap: () => _navigateToBackup(),
              ),
            ]),

            const SizedBox(height: 24),

            // Sección: Soporte
            _buildSectionHeader('Soporte', Icons.help_outline),
            const SizedBox(height: 4),
            _buildSettingsCard([
              _buildSettingItem(
                icon: Icons.quiz_outlined,
                title: 'Ayuda y preguntas frecuentes',
                subtitle: 'Centro de ayuda',
                onTap: () => _navigateToHelp(),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.contact_support_outlined,
                title: 'Contactar soporte',
                subtitle: 'Asistencia técnica',
                onTap: () => _navigateToSupport(),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.star_outline,
                title: 'Calificar MottiNut',
                subtitle: 'Valorar en la tienda',
                onTap: () => _navigateToRating(),
              ),
            ]),

            const SizedBox(height: 24),

            // Sección: Acerca de
            _buildSectionHeader('Acerca de', Icons.info),
            const SizedBox(height: 4),
            _buildSettingsCard([
              _buildSettingItem(
                icon: Icons.info_outlined,
                title: 'Sobre MottiNut',
                subtitle: 'Versión 2.1.0',
                onTap: () => _navigateToAbout(),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.description_outlined,
                title: 'Términos y condiciones',
                subtitle: 'Política de uso',
                onTap: () => _navigateToTerms(),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Política de privacidad',
                subtitle: 'Protección de datos',
                onTap: () => _navigateToPrivacyPolicy(),
              ),
            ]),

            const SizedBox(height: 20),

            // Botón de Cerrar Sesión
            _buildLogoutButton(),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          /*Container(
            padding: const EdgeInsets.all(6),

            child: Icon(
              icon,
              color: AppColors.iconPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width:6),*/
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.iconPrimary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppColors.iconPrimary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.iconPrimary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppColors.iconPrimary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary,
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: AppColors.iconPrimary.withOpacity(0.3),
        ),
      ),
    );
  }


  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.withOpacity(0.1),
      indent: 60,
      endIndent: 20,
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _showLogoutDialog(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.textInput.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.logout,
            color: AppColors.iconDark,
            size: 20,
          ),
        ),
        title: Text(
          'Cerrar sesión',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textLDark,
            letterSpacing: 0.5
          ),
        ),
        subtitle: const Text(
          'Salir de la aplicación',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textInput,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implementar logout
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  // Métodos de navegación (implementar según necesidades)
  void _navigateToPersonalInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PersonalProfileScreen()),
    );
  }

  void _navigateToPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacySecurityScreen()),
    );
  }

  void _navigateToVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfessionalVerificationScreen()),
    );
  }

  void _navigateToSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScheduleScreen()),
    );
  }

  void _navigateToLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationScreen()),
    );
  }

  // Métodos de navegación
  void _navigateToPayments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentsScreen(), // You'll need to create this screen
      ),
    );
  }

  void _navigateToGoals() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GoalsScreen(), // You'll need to create this screen
      ),
    );
  }

  void _navigateToWaterLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WaterLogScreen(), // You'll need to create this screen
      ),
    );
  }

  void _navigateToUnits() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UnitsScreen(), // You'll need to create this screen
      ),
    );
  }

  void _navigateToFoodDatabase() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FoodDatabaseScreen(), // You'll need to create this screen
      ),
    );
  }

  void _navigateToReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RemindersScreen(), // You'll need to create this screen
      ),
    );
  }

  void _navigateToLanguage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LanguageScreen(), // You'll need to create this screen
      ),
    );
  }

  void _navigateToBackup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BackupScreen(), // You'll need to create this screen
      ),
    );
  }

  void _navigateToHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpScreen(), // You'll need to create this screen
      ),
    );
  }

  void _navigateToSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SupportScreen(), // You'll need to create this screen
      ),
    );
  }

  void _navigateToRating() async {
    const url = 'https://play.google.com/store/apps/details?id=your.package.name'; // Replace with your app's URL
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la tienda de aplicaciones')),
      );
    }
  }

  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutScreen(),
      ),
    );
  }

  void _navigateToTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TerminosCondicionesScreen()),
    );
  }

  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PoliticaPrivacidadScreen()),
    );
  }

  void _performLogout() async {
    try {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      // Limpiar caché de imágenes
      NutritionistService.clearImageCache();

      // Navegar al login y limpiar el stack de navegación
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarManager.showError(context, 'Error al cerrar sesión: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

}