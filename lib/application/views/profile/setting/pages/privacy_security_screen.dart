import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/services/auth_provider.dart';
import 'change_password_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  // Eliminar la inicialización aquí
  late AuthProvider _authProvider;
  bool _passwordExpired = false;

  @override
  void initState() {
    super.initState();
    // Inicializar el AuthProvider aquí donde context ya está disponible
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _checkPasswordStatus();
  }

  Future<void> _checkPasswordStatus() async {
    // Simular verificación de expiración de contraseña
    await Future.delayed(const Duration(milliseconds: 500));
    final lastChanged = _authProvider.user?['passwordLastChanged'];
    if (lastChanged != null) {
      final lastChangedDate = DateTime.parse(lastChanged);
      final now = DateTime.now();
      final difference = now.difference(lastChangedDate).inDays;
      setState(() {
        _passwordExpired = difference >= 30;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Privacidad y Seguridad'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPasswordCard(),
            const SizedBox(height: 20),
            _buildBiometricCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.iconPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.lock_outline,
                color: AppColors.iconPrimary,
              ),
            ),
            title: const Text(
              'Contraseña',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            subtitle: Text(
              _passwordExpired
                  ? 'Debes cambiar tu contraseña (caduca cada 30 días)'
                  : 'Contraseña actual: ********',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: _navigateToChangePassword,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricCard() {
    final isEnabled = _authProvider.user?['biometricEnabled'] ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.iconPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.fingerprint,
              color: AppColors.iconPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Autenticación biométrica',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),

                Text(
                  'Usar huella digital o Face ID',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isEnabled,
              onChanged: (value) => _toggleBiometric(value),
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: AppColors.iconPrimary.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      // Aquí iría la lógica para activar/desactivar biométricos
      // Por ahora solo actualizamos el estado local
      setState(() {
        _authProvider.user?['biometricEnabled'] = value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Autenticación biométrica activada'
                : 'Autenticación biométrica desactivada',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        _authProvider.user?['biometricEnabled'] = !value;
      });
    }
  }
}