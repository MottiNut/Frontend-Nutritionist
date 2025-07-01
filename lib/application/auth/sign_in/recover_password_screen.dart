import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../configuration/themes/app_colors.dart';
import '../../../domain/services/auth_provider.dart';
import '../../requestSnacbar/snackBar_manager.dart';

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({Key? key}) : super(key: key);

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen>
    with TickerProviderStateMixin {

  final _emailController = TextEditingController();
  bool _showEmailError = false;
  bool _isEmailEmpty = false;
  bool _isLoading = false;
  bool _emailSent = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 1.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SlideTransition(
            position: _slideAnimation,
            child: _buildRecoverPasswordContent(),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildRecoverPasswordContent() {
    final screenHeight = MediaQuery.of(context).size.height;
    final topSectionHeight = screenHeight * 0.35;

    return Column(
      children: [
        // Sección superior con logo y título
        Container(
          height: topSectionHeight,
          color: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                // Botón de retroceso
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20, top: 10),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Logo y título
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 80,
                        child: SvgPicture.asset(
                          'assets/images/logos/mottinut.svg',
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              FontAwesomeIcons.nutritionix,
                              size: 60,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        _emailSent ? '¡Correo Enviado!' : 'Recuperar Contraseña',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sección inferior con formulario
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              color: AppColors.primary,
            ),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(25, 40, 25, 30),
                child: _emailSent ? _buildSuccessContent() : _buildFormContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Descripción
        Text(
          'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 40),

        // Campo de email
        _buildEmailField(),

        SizedBox(height: 30),

        // Botón de enviar
        _buildSendButton(),

        SizedBox(height: 20),

        // Botón de volver al login
        _buildBackToLoginButton(),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      children: [
        // Icono de éxito
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            Icons.mark_email_read,
            color: AppColors.primary,
            size: 40,
          ),
        ),

        SizedBox(height: 30),

        // Mensaje de éxito
        Text(
          'Hemos enviado un enlace de recuperación a:',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 10),

        Text(
          _emailController.text.trim(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 30),

        Text(
          'Revisa tu bandeja de entrada y sigue las instrucciones del correo.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 40),

        // Botón para reenviar
        _buildResendButton(),

        SizedBox(height: 15),

        // Botón de volver al login
        _buildBackToLoginButton(),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _emailController,
            onChanged: (value) {
              setState(() {
                if (value.isNotEmpty) {
                  _showEmailError = false;
                }
                _isEmailEmpty = value.isEmpty;
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface.withOpacity(0.3),
              labelText: 'Correo electrónico',
              labelStyle: TextStyle(
                color: AppColors.textLight,
                fontSize: 18,
                letterSpacing: -0.4,
                fontWeight: FontWeight.w300,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SvgPicture.asset(
                  'assets/images/user_icon.svg',
                  width: 20,
                  height: 20,
                  color: AppColors.iconSecondary.withOpacity(0.8),
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.email_outlined,
                      color: AppColors.iconSecondary.withOpacity(0.8),
                      size: 20,
                    );
                  },
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: _showEmailError ? AppColors.errorText : Colors.white,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: _showEmailError || _isEmailEmpty
                      ? AppColors.errorText
                      : Colors.transparent,
                  width: _showEmailError || _isEmailEmpty ? 1.6 : 0,
                ),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
            ),
          ),
          if (_showEmailError)
            Padding(
              padding: EdgeInsets.only(left: 12, top: 4),
              child: Text(
                'Por favor ingresa un correo válido',
                style: TextStyle(
                  color: AppColors.errorText,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleSendRecoveryEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          'Enviar Enlace',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildResendButton() {
    return Container(
      width: double.infinity,
      height: 46,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton(
        onPressed: _handleSendRecoveryEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          'Reenviar Correo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return TextButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: Text(
        'Volver al inicio de sesión',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.none,
          decorationColor: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.all(20),
        width: 180,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              child: Lottie.asset(
                'assets/loading/loading_infinity.json',
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Enviando...",
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos de funcionalidad
  Future<void> _handleSendRecoveryEmail() async {
    // Validar email
    setState(() {
      _isEmailEmpty = _emailController.text.trim().isEmpty;
      _showEmailError = _isEmailEmpty || !_isValidEmail(_emailController.text.trim());
    });

    if (_showEmailError) {
      if (_isEmailEmpty) {
        SnackBarManager.showWarning(context, 'Por favor ingresa tu correo electrónico');
      } else {
        SnackBarManager.showWarning(context, 'Por favor ingresa un correo válido');
      }
      return;
    }

    // Verificar conectividad
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      SnackBarManager.showError(context, 'No hay conexión a Internet');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Aquí llamarías al método de recuperación de contraseña de tu AuthProvider
      // final success = await authProvider.sendPasswordResetEmail(_emailController.text.trim());

      // Simulación temporal - reemplaza con tu lógica real
      await Future.delayed(Duration(seconds: 2));
      final success = true; // Cambiar por la respuesta real del servidor

      setState(() {
        _isLoading = false;
      });

      if (success) {
        setState(() {
          _emailSent = true;
        });
        SnackBarManager.showSuccess(context, 'Correo de recuperación enviado exitosamente');
      } else {
        SnackBarManager.showError(context, 'Error al enviar el correo. Intenta nuevamente');
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('Error enviando correo de recuperación: $e');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        SnackBarManager.showError(context, 'Error de conexión. Verifica tu internet');
      } else {
        SnackBarManager.showError(context, 'Error inesperado. Intenta más tarde');
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}