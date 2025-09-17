import 'package:flutter/material.dart';
import '../../../../configuration/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
import '../../../../domain/services/auth_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLigth,
        elevation: 0,
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
          activeColor: Colors.white, // Círculo blanco cuando está activo
          activeTrackColor: AppColors.primary, // Fondo del switch cuando está activo
          inactiveThumbColor: Colors.grey, // Círculo blanco cuando está inactivo
          inactiveTrackColor: AppColors.iconPrimary.withOpacity(0.3), // Fondo cuando está apagado
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
      MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
    );
  }
  void _navigateToPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
    );
  }
  void _navigateToVerification() {}
  void _navigateToSchedule() {}
  void _navigateToPayments() {}
  void _navigateToLocation() {}
  void _navigateToGoals() {}
  void _navigateToWaterLog() {}
  void _navigateToUnits() {}
  void _navigateToFoodDatabase() {}
  void _navigateToReminders() {}
  void _navigateToLanguage() {}
  void _navigateToBackup() {}
  void _navigateToHelp() {}
  void _navigateToSupport() {}
  void _navigateToRating() {}
  void _navigateToAbout() {}
  void _navigateToTerms() {}
  void _navigateToPrivacyPolicy() {}
  void _performLogout() {}
}


////////////////////////

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user ?? {}; // Datos en Map<String, dynamic>

    // Datos básicos del usuario
    final String name = user['fullName'] ??
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final String email = user['email'] ?? 'No disponible';
    final String phone = user['phone'] ?? 'No disponible';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Información Personal', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Card(
          color: Colors.grey.shade100,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.person, 'Nombre', name),
                const Divider(height: 30, thickness: 0.3 ),
                _buildInfoRow(Icons.email, 'Email', email),
                const Divider(height: 30, thickness: 0.3,),
                _buildInfoRow(Icons.phone, 'Teléfono', phone),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget reutilizable para cada fila de información
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 26),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'No disponible',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

////2
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}
class _PrivacyScreenState extends State<PrivacyScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canCheck) {
        setState(() {
          _error = 'Tu dispositivo no soporta autenticación biométrica.';
          _loading = false;
        });
        return;
      }

      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Confirma tu identidad para acceder a Privacidad',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // permite PIN/patrón si no hay huella/face
        ),
      );

      setState(() {
        _isAuthenticated = didAuthenticate;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error en la autenticación: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidad y seguridad',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : !_isAuthenticated
          ? const Center(child: Text('Autenticación fallida'))
          : _buildPrivacyContent(authProvider),
    );
  }

  Widget _buildPrivacyContent(AuthProvider authProvider) {
    final user = authProvider.user ?? {};
    final String email = user['email'] ?? 'No disponible';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.grey.shade100,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cuenta',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('Correo: $email',
                  style: const TextStyle(fontSize: 16, color: Colors.black87)),
              const Divider(height: 40, thickness: 0.3),
              const Text('Contraseña',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('********', style: TextStyle(fontSize: 18)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text('Cambiar',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      // Aquí navegas a tu pantalla de cambio de contraseña
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar contraseña', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPasswordField('Contraseña actual', oldController),
            const SizedBox(height: 16),
            _buildPasswordField('Nueva contraseña', newController),
            const SizedBox(height: 16),
            _buildPasswordField('Confirmar nueva contraseña', confirmController),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                // TODO: llamar al servicio para actualizar la contraseña
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contraseña actualizada')),
                );
                Navigator.pop(context);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}


class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user ?? {};

    final bool emailVerified = user['emailVerified'] ?? false;
    final bool phoneVerified = user['phoneVerified'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de cuenta',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Estado de verificación',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Email
            _buildVerificationItem(
              context,
              label: 'Correo electrónico',
              isVerified: emailVerified,
              onVerify: () async {
                final email = user['email'];
                if (email != null && email.toString().isNotEmpty) {
                  await auth.sendVerificationCode(

                    method: VerificationMethod.email,
                  );
                  _showSnack(context, 'Código de verificación enviado a $email');
                }
              },
            ),
            const SizedBox(height: 24),

            // Teléfono
            _buildVerificationItem(
              context,
              label: 'Teléfono',
              isVerified: phoneVerified,
              onVerify: () async {
                final phone = user['phone'];
                if (phone != null && phone.toString().isNotEmpty) {
                  await auth.sendVerificationCode(
                    method: VerificationMethod.sms,
                  );
                  _showSnack(context, 'Código de verificación enviado al teléfono');
                }
              },
            ),
            const SizedBox(height: 40),

            // Botón continuar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: (emailVerified && phoneVerified)
                  ? () {
                Navigator.pop(context, true); // Vuelve a la app principal
              }
                  : null,
              child: const Text(
                'Continuar',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget reutilizable para cada item de verificación
  Widget _buildVerificationItem(
      BuildContext context, {
        required String label,
        required bool isVerified,
        required VoidCallback onVerify,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.error_outline,
            color: isVerified ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isVerified ? '$label verificado' : '$label pendiente',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isVerified ? Colors.green[800] : Colors.black87,
              ),
            ),
          ),
          if (!isVerified)
            TextButton(
              onPressed: onVerify,
              child: const Text('Verificar'),
            ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}


class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Horarios de consulta')),
    );
  }
}

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Tarifas y pagos')),
    );
  }
}

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Ubicación del consultorio')),
    );
  }
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Mis objetivos')),
    );
  }
}

class WaterLogScreen extends StatelessWidget {
  const WaterLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Diario y registro de agua')),
    );
  }
}

class UnitsScreen extends StatelessWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Unidades de medida')),
    );
  }
}

class FoodDatabaseScreen extends StatelessWidget {
  const FoodDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Base de datos de alimentos')),
    );
  }
}

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Recordatorios')),
    );
  }
}

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Idioma')),
    );
  }
}

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Copia de seguridad')),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Ayuda y preguntas frecuentes')),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Contactar soporte')),
    );
  }
}

class RatingScreen extends StatelessWidget {
  const RatingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Calificar MottiNut')),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Sobre MottiNut')),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Términos y condiciones')),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Política de privacidad')),
    );
  }
}
