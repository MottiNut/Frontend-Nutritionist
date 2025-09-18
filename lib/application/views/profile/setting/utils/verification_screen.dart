import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/services/auth_provider.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isRefreshing = false;
  Timer? _refreshTimer;

  bool _showInfoMessage = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshVerificationStatus();
      }
    });
  }

  Future<void> _refreshVerificationStatus() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      //await auth.refreshUserData();
    } catch (e) {
      _showMessage('Error al actualizar el estado', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final user = auth.user ?? {};
        final bool emailVerified = user['emailVerified'] ?? false;
        final bool phoneVerified = user['phoneVerified'] ?? false;
        final bool isFullyVerified = emailVerified && phoneVerified;

        final double progress = _calculateProgress(emailVerified, phoneVerified);

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            backgroundColor: Colors.grey.shade100,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.black87),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Verificación de cuenta',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _refreshVerificationStatus,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header con progreso
                    _buildProgressHeader(context, progress, isFullyVerified),

                    const SizedBox(height: 12),

                    // Tooltip debajo
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      child: _showInfoMessage
                          ? _buildInfoMessage(context, isFullyVerified)
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 15),
                    // Lista de verificaciones
                    _buildVerificationList(context, user, emailVerified, phoneVerified),

                    const SizedBox(height: 32),

                    // Botones de acción
                    _buildActionButtons(context, isFullyVerified, auth),

                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressHeader(BuildContext context, double progress, bool isComplete) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showInfoMessage = true;
        });

        // Se oculta solo después de 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _showInfoMessage = false);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 0.5,
            color: isComplete ? Colors.green.shade200 : Colors.blue.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isComplete ? Icons.verified_user : Icons.security,
              size: 48,
              color: isComplete ? Colors.green.shade600 : AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              isComplete ? '¡Cuenta verificada!' : 'Verificación de cuenta',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isComplete ? Colors.green.shade800 : AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Barra de progreso
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.backgroundHipertencion,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? AppColors.checkValidation : AppColors.backgroundHipertencion,
                  ),
                  minHeight: 6,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoMessage(BuildContext context, bool isFullyVerified) {
    final Color bgColor = isFullyVerified ? Colors.green.shade50 : Colors.orange.shade50;
    final Color borderColor = isFullyVerified ? Colors.green.shade200 : Colors.orange.shade200;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(20, 10),
          painter: _TrianglePainter(color: AppColors.secondary, borderColor: AppColors.secondary),
        ),

        // Caja principal (mensaje)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.secondary),
          ),
          child: Row(
            children: [
              Icon(
                isFullyVerified ? Icons.check_circle : Icons.info_outline,
                color: isFullyVerified ? AppColors.checkValidation : Colors.orange.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isFullyVerified
                      ? 'Tu cuenta está completamente verificada y protegida.'
                      : 'Verifica tu email y teléfono para completar la seguridad de tu cuenta.',
                  style: TextStyle(
                    color: isFullyVerified ? AppColors.checkValidation : Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationList(BuildContext context, Map<String, dynamic> user,
      bool emailVerified, bool phoneVerified) {
    return Column(
      children: [
        // Email
        _buildVerificationItem(
          context,
          icon: Icons.email_outlined,
          label: 'Correo electrónico',
          value: user['email'] != null && user['email'].toString().isNotEmpty
              ? _maskEmail(user['email'].toString())
              : 'No configurado',
          isVerified: emailVerified,
          onVerify: () => _handleEmailVerification(context, user),
        ),
        const SizedBox(height: 16),

        _buildVerificationItem(
          context,
          icon: Icons.phone_outlined,
          label: 'Teléfono',
          value: user['phone'] != null && user['phone'].toString().isNotEmpty
              ? _maskPhone(user['phone'].toString())
              : 'No configurado',
          isVerified: phoneVerified,
          onVerify: () => _handlePhoneVerification(context, user),
        ),
      ],
    );
  }

  Widget _buildVerificationItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        required bool isVerified,
        required VoidCallback onVerify,
      }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.fromLTRB(13, 10, 4, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? Colors.green.shade300 : Colors.grey.shade300,
          width: isVerified ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? AppColors.checkValidation.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isVerified
                          ? AppColors.checkValidation
                          : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          value,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isVerified && value != 'No configurado') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: onVerify,
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Enviar código'),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          Positioned(
            top: 0,
            right: 0,
            child: _buildVerificationStatus(isVerified),
          ),
        ],
      ),
    );
  }


  Widget _buildVerificationStatus(bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified ? AppColors.checkValidation.withOpacity(0.1) : AppColors.secondary.withOpacity(0.1) ,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.pending,
            size: 16,
            color: isVerified ? AppColors.checkValidation : AppColors.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verificado' : 'Pendiente',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isVerified ? AppColors.checkValidation : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isFullyVerified, AuthProvider auth) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isFullyVerified ? AppColors.checkValidation : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isFullyVerified ? 2 : 0,
            ),
            onPressed: isFullyVerified
                ? () => Navigator.pop(context, true)
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isFullyVerified) ...[
                  const Icon(Icons.check_circle, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  isFullyVerified ? 'Continuar' : 'Complete la verificación',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isFullyVerified) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Continuar más tarde',
              style: TextStyle(color: Colors.grey.shade600),),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorIcon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppColors.errorIcon, size: 20),
              const SizedBox(width: 8),
              Text(
                '¿Por qué verificar?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.errorIcon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Mayor seguridad para tu cuenta\n'
                '• Recuperación rápida de contraseña\n'
                '• Notificaciones de seguridad\n'
                '• Acceso completo a todas las funciones',
            style: TextStyle(
              color: Color(0xFFF8574F),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProgress(bool emailVerified, bool phoneVerified) {
    int completed = 0;
    if (emailVerified) completed++;
    if (phoneVerified) completed++;
    return completed / 2;
  }

  Future<void> _handleEmailVerification(BuildContext context, Map<String, dynamic> user) async {
    final email = user['email']?.toString();
    if (email == null || email.isEmpty) {
      _showMessage('No hay un email configurado', isError: true);
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('El formato del email no es válido', isError: true);
      return;
    }

    await _sendVerificationCode(
      context,
      VerificationMethod.email,
      'Código de verificación enviado a $email',
    );
  }

  Future<void> _handlePhoneVerification(BuildContext context, Map<String, dynamic> user) async {
    final phone = user['phone']?.toString();
    if (phone == null || phone.isEmpty) {
      _showMessage('No hay un teléfono configurado', isError: true);
      return;
    }

    await _sendVerificationCode(
      context,
      VerificationMethod.sms,
      'Código de verificación enviado al teléfono',
    );
  }

  Future<void> _sendVerificationCode(
      BuildContext context,
      VerificationMethod method,
      String successMessage,
      ) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // Mostrar indicador de carga
      _showMessage('Enviando código...', showProgress: true);

      await auth.sendVerificationCode(method: method);

      _showMessage(successMessage);

      // Opcional: Navegar a pantalla de ingreso de código
      // Navigator.of(context).push(
      //   MaterialPageRoute(
      //     builder: (context) => CodeVerificationScreen(method: method),
      //   ),
      // );

    } catch (e) {
      _showMessage('Error al enviar el código: ${e.toString()}', isError: true);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showMessage(String message, {bool isError = false, bool showProgress = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (showProgress) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
            ] else if (isError) ...[
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ] else ...[
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: showProgress ? 1 : 3),
      ),
    );
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 2) return '${name[0]}*****@$domain';
    return '${name[0]}*******${name[name.length - 1]}@$domain';
  }

  String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'No configurado';

    final last3 = digits.length >= 3 ? digits.substring(digits.length - 3) : digits;
    return '+51 ******$last3';
  }

}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _TrianglePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);

    // Borde opcional
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}