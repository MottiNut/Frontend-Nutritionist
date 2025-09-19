import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/about_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/backup_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/food_search_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/helper_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/language_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/location_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/payments_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/personal_information_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/privacy_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/rating_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/reminder_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/schedule_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/support_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/units_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/verification_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/utils/water_log_screen.dart';
import '../../../../configuration/providers/app_languaje_provider.dart';
import '../../../../configuration/themes/app_colors.dart';
import '../../../../domain/services/auth_provider.dart';
import '../../../auth/terms and conditions/politica_privacidad_screen.dart';
import '../../../auth/terms and conditions/terminos_condiciones_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  bool _biometricEnabled = false;
  bool _marketingEmails = false;

  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLigth,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_ios,
                    color: AppColors.iconDark, size: 22),
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
                        border: Border.all(width: 0.3, color: AppColors.primary),
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
                const SizedBox(height: 24),

                // Sección: Herramientas Nutricionales
                _buildSectionHeader('Herramientas', Icons.restaurant_outlined),
                const SizedBox(height: 4),
                _buildSettingsCard([
                  /*_buildSettingItem(
                  icon: Icons.flag_outlined,
                  title: 'Mis objetivos',
                  subtitle: 'Metas profesionales',
                  onTap: () => _navigateToGoals(),
                ),
                _buildDivider(),*/
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
                    value: false,
                    onChanged: (value) {},
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.language_outlined,
                    title: 'Idioma',
                    subtitle: context.watch<LanguageProvider>().languageName,
                    onTap: () => _navigateToLanguage(),
                  ),
                ]),
                const SizedBox(height: 24),

                // Sección: Seguridad
                _buildSectionHeader('Seguridad', Icons.security),
                const SizedBox(height: 4),
                _buildSettingsCard([
                  /*_buildSwitchItem(
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
                _buildDivider(),*/
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
                    onTap: () => showRatingDialog(context),
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
                _buildLogoutButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        if (_isLoggingOut)
          Material(
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Cerrando sesión...',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),

            child: Icon(
              icon,
              color: AppColors.iconPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width:6),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
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
        onTap: _isLoggingOut ? null : () => _showLogoutDialog(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.textInput.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          /*_isLoggingOut
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.iconDark),
            ),
          )
              : */
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
              color: _isLoggingOut ? Colors.grey : AppColors.textLDark,
              letterSpacing: 0.5
          ),
        ),
        subtitle: Text(
          _isLoggingOut ? 'Cerrando sesión...' : 'Salir de la aplicación',
          style: TextStyle(
            fontSize: 13,
            color: _isLoggingOut ? Colors.grey : AppColors.textInput,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.logout,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoggingOut ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _isLoggingOut ? Colors.grey : Colors.grey, // Borde gris
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: _isLoggingOut ? Colors.grey : Colors.grey[700],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoggingOut
                      ? null
                      : () {
                    Navigator.of(context).pop();
                    _performLogout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorIcon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: _isLoggingOut
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Cerrar sesión',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ],

      ),
    );
  }


  Future<void> _performLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();

      // 🔹 Pausa breve para que se vea el overlay antes de navegar
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
          arguments: {
            'message': 'Sesión cerrada. Por favor, inicia sesión nuevamente.',
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  // Métodos de navegación (implementar según necesidades)
  void _navigateToPersonalInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PersonalInfoScreenn()),
    );
  }
  void _navigateToPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
    );
  }
  void _navigateToVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerificationScreen()),
    );
  }
  void _navigateToSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleScreen()),
    );
  }

  void _navigateToPayments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentsScreen()),
    );
  }

  void _navigateToLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationInfoScreen()),
    );
  }

  void _navigateToGoals() {}
  void _navigateToWaterLog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WaterLogScreen()),
    );

  }
  void _navigateToUnits() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UnitsScreen()),
    );

  }
  void _navigateToFoodDatabase() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FoodDatabaseScreen()),
    );
  }
  void _navigateToReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RemindersScreen()),
    );

  }
  void _navigateToLanguage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LanguageScreen()),
    );
  }
  void _navigateToBackup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BackupScreen()),
    );
  }

  void _navigateToHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpScreen())
    );

  }
  void _navigateToSupport() {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SupportScreen())
    );

  }

  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );

  }
  void _navigateToTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TerminosCondicionesScreen()),
    );

  }
  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PoliticaPrivacidadScreen()),
    );
  }

}



