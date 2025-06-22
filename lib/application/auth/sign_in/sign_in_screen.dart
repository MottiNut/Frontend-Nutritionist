import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
//import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:mottinutnutriotinist/application/auth/sign_in/recover_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../configuration/providers/color_dar_light_app.dart';
import '../../../configuration/themes/app_colors.dart';
import '../../../domain/services/auth_provider.dart';


class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _showEmailError = false;
  bool _showPasswordError = false;
  bool _isEmailEmpty = false;
  bool _isPasswordEmpty = false;
  int _loginAttempts = 0;
  DateTime? _lockoutEndTime;
  bool _isLoading = false;
  bool _isLoginSelected = true;

  bool _showWelcomeScreen = false;

  bool _showPasswordToggle = false;
  late FocusNode _passwordFocusNode;

  // Controlador de animación
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador de animación
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Configurar la animación de deslizamiento
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 1.0), // Comienza desde abajo
      end: Offset(0.0, 0.0), // Termina en su posición normal
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // Inicializar el FocusNode
    _passwordFocusNode = FocusNode();

    // Listener para detectar cambios en el focus
    _passwordFocusNode.addListener(() {
      setState(() {
        _showPasswordToggle = _passwordFocusNode.hasFocus || _passwordController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _showLoginModal() {
    setState(() {
      _showWelcomeScreen = false;
    });
    _animationController.forward();
  }

  void _backToWelcome() {
    _animationController.reverse().then((_) {
      setState(() {
        _showWelcomeScreen = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkModeProvider = Provider.of<DarkModeProvider>(context);
    final isDarkMode = darkModeProvider.isDarkMode;

    // CORREGIDO: Personalización de la barra de estado - hacer opaca
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SlideTransition(
            position: _slideAnimation,
            child: _buildLoginModal(),
          ),
          // Indicador de carga
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // CORREGIDO: Modal de login con SingleChildScrollView para evitar desborde
  Widget _buildLoginModal() {
    final screenHeight = MediaQuery.of(context).size.height;
    final topSectionHeight = screenHeight * 0.33;

    return Column(
      children: [
        // SECCIÓN SUPERIOR - Logo (altura fija)
        Container(
          height: topSectionHeight,
          color: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 20),
                Expanded(child: _buildLogoSection()),
              ],
            ),
          ),
        ),

        // BOTONES DE TABS
        _buildTabButtons(),
        SizedBox(height: 5),

        // SECCIÓN INFERIOR - Con scroll para evitar desborde
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
              // AGREGADO: SingleChildScrollView para manejar el desborde
              physics: BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 2, 20, 30),
                    child: Column(
                      children: [
                        SizedBox(height: 15),
                        // Campos de entrada
                        _buildInputFields(),
                        SizedBox(height: 30),
                        _buildLoginButton(),
                        _buildRecoverPasswordButton(context),
                        const SizedBox(height: 8),
                        _buildDividerSection(),
                        SizedBox(height: 12),
                        _buildSocialButtonsRow(),
                        // CORREGIDO: Usar Spacer flexible
                        Spacer(),
                        _buildTermsAndConditions(),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // CORREGIDO: Sección del logo más compacta
  Widget _buildLogoSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 110,
            child: SvgPicture.asset(
              'assets/icons/mottinut_logo.svg',
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  FontAwesomeIcons.nutritionix,
                  size: 80,
                  color: AppColors.primary,
                );
              },
            ),
          ),
          Text(
            'MottiNut',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
             ),
          ),
        ],
      ),
    );
  }

  // CORREGIDO: Botones de tabs más pegados al modal
  Widget _buildTabButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 35),
      child: Row(
        children: [
          // Botón Login
          Expanded(
            child: _buildTabButton(
              text: 'Iniciar Sesión',
              isSelected: _isLoginSelected,
              onTap: () {
                setState(() {
                  _isLoginSelected = true;
                });
              },
            ),
          ),
          SizedBox(width: 6),
          // Botón Register
          Expanded(
            child: _buildTabButton(
              text: 'Registrar',
              isSelected: !_isLoginSelected,
              onTap: () {
                setState(() {
                  _isLoginSelected = false;
                });
                Navigator.pushReplacementNamed(context, '/register');
              },
            ),
          ),
        ],
      ),
    );
  }

  // Botón individual de tab
  Widget _buildTabButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 35,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.grey.shade200,
              border: Border(
                top: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey,
                  width: 0.4,
                ),
                left: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey,
                  width: 0.4,
                ),
                right: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey,
                  width: 0.4,
                ),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Medio círculo superior para botón seleccionado
          if (isSelected)
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 15,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Campos de entrada
  Widget _buildInputFields() {
    return Column(
      children: [
        SizedBox(height: 15),
        _buildEmailField(),
        SizedBox(height: 18),
        _buildPasswordField(),
      ],
    );
  }

  // Sección del divisor
  Widget _buildDividerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Divider(
                color: Colors.white38,
                thickness: 1,
                indent: 8,
                endIndent: 8,
              ),
            ),
            Text(
              'o con',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Expanded(
              child: Divider(
                color: Colors.white38,
                thickness: 1,
                indent: 8,
                endIndent: 8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Fila de botones sociales
  Widget _buildSocialButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          'assets/images/logo_google_login.png',
          'Google',
          _loginWithGoogle,
        ),
        SizedBox(width: 35),
        _buildSocialButton(
          'assets/image/apple_logo.png',
          'Apple',
          _loginWithApple,
        ),
      ],
    );
  }

  // Overlay de carga
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
                    valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Verificando",
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

  // EMAIL FIELD
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
                  fontSize: 20,
                  letterSpacing: -0.4,
                  fontWeight: FontWeight.w300
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SvgPicture.asset(
                  'assets/images/user_icon.svg',
                  width: 20,
                  height: 20,
                  color: AppColors.iconSecondary.withOpacity(0.8),
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
                    width: 0.75
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppColors.errorText, width: 1.6),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppColors.errorText, width: 1.6),
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
                'Correo inválido o no autenticado',
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

// PASSWORD FIELD
  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode, // Asignar el FocusNode
            obscureText: _obscureText,
            onChanged: (value) {
              setState(() {
                if (value.isNotEmpty) {
                  _showPasswordError = false;
                }
                _isPasswordEmpty = value.isEmpty;
                // Actualizar el estado del ícono del ojo basado en si hay texto
                _showPasswordToggle = value.isNotEmpty || _passwordFocusNode.hasFocus;
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface.withOpacity(0.3),
              labelText: 'Contraseña',
              labelStyle: TextStyle(
                color: AppColors.textLight,
                fontSize: 20,
                letterSpacing: -0.4,
                fontWeight: FontWeight.w300,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SvgPicture.asset(
                  'assets/images/candado_icon.svg',
                  height: 20,
                  width: 20,
                ),
              ),

              suffixIcon: IconButton(
                icon: _obscureText
                    ? SvgPicture.asset(
                  'assets/images/eye_icon.svg',
                  height: 18,
                  width: 18,

                  color: _showPasswordToggle
                      ? AppColors.iconSecondary
                      : Colors.white54 ,
                )
                    : Icon(
                  Icons.visibility_off,
                  // Mismo comportamiento de color para el ícono de ocultar
                  color: _showPasswordToggle
                      ? AppColors.iconSecondary.withOpacity(0.8)
                      : Colors.grey.withOpacity(0.5),
                  size: 25,
                ),
                // Solo es clickeable cuando está activo
                onPressed: _showPasswordToggle ? () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                } : null, // null = no clickeable cuando inactivo
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: _showPasswordError ? AppColors.errorText : Colors.white,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: _showPasswordError || _isPasswordEmpty
                      ? AppColors.errorText
                      : Colors.transparent,
                  width: _showPasswordError || _isPasswordEmpty ? 1.6 : 0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppColors.errorText, width: 1.6),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppColors.errorText, width: 1.6),
              ),
            ),
            style: TextStyle(
              color: AppColors.textLDark,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          if (_showPasswordError)
            Padding(
              padding: EdgeInsets.only(left: 12, top: 4),
              child: Text(
                'Contraseña incorrecta. Verifica e intenta nuevamente.',
                style: TextStyle(
                  color: AppColors.errorText,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
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
        onPressed: () => _handleLogin(false),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.zero,
          alignment: Alignment.center,
        ),
        child: const Center(  
          child: Text(
            'Iniciar sesión',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }


  Widget _buildRecoverPasswordButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecoverPasswordScreen()),
        );
      },
      child: const Text(
        '¿Olvidaste tu contraseña?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.none,
          decorationColor: Colors.white,
          letterSpacing: 0.5
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: 'Al continuar, aceptas los',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w300,
            fontSize: 12,
            letterSpacing: 0.5,
            height: 1.3,
          ),
          children: [
            TextSpan(
              text: '\nTérminos y Condiciones',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                letterSpacing: 0.5,
              ),
            ),
            TextSpan(
              text: ' y ',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: 'Política de privacidad',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
      String assetPath, String provider, VoidCallback onPressed) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Image.asset(
          assetPath,
          height: 27,
          width: 27,
          color: AppColors.primary,
          errorBuilder: (context, error, stackTrace) {
            if (provider == 'Google') {
              return Icon(Icons.login, color: AppColors.primary, size: 27);
            } else {
              return Icon(Icons.apple, color: AppColors.primary, size: 27);
            }
          },
        ),
      ),
    );
  }

  // Métodos de funcionalidad (mantienen la lógica original)
  Future<void> _handleLogin(bool isDarkMode) async {
    setState(() {
      _showEmailError = false;
      _showPasswordError = false;
      _isEmailEmpty = _emailController.text.trim().isEmpty;
      _isPasswordEmpty = _passwordController.text.trim().isEmpty;
    });

    if (_isEmailEmpty || _isPasswordEmpty) {
      setState(() {
        if (_isEmailEmpty) _showEmailError = true;
        if (_isPasswordEmpty) _showPasswordError = true;
      });
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    Duration delayDuration;

    if (connectivityResult == ConnectivityResult.mobile) {
      delayDuration = Duration(seconds: 2);
    } else if (connectivityResult == ConnectivityResult.wifi) {
      delayDuration = Duration(seconds: 2);
    } else {
      Fluttertoast.showToast(
          msg: "No hay conexión a Internet",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.grey.shade800,
          textColor: Colors.white,
          fontSize: 11);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      await Future.delayed(delayDuration);

      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Datos validados correctamente",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 11.0,
      );

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
            (Route<dynamic> route) => false,
        arguments: {'initialIndex': 0},
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _handleLoginError(e, isDarkMode);
    }
  }

  void _handleLoginError(Object e, bool isDarkMode) {
    String errorMessage;

    if (e is Exception) {
      if (e.toString().contains('Unauthorized')) {
        errorMessage =
        'Correo inválido o no autenticado. Por favor, revisa tu correo.';
      } else if (e.toString().contains('Invalid email format') ||
          e.toString().contains('Email not authenticated')) {
        errorMessage =
        'El formato del correo es inválido. Asegúrate de ingresarlo correctamente.';
      } else if (e.toString().contains('Invalid password')) {
        errorMessage =
        'Contraseña incorrecta. Verifica que has ingresado la contraseña correcta.';
      } else {
        errorMessage = 'Ocurrió un error inesperado. Intenta nuevamente.';
      }
    } else {
      errorMessage =
      'Error desconocido. Por favor, intenta de nuevo más tarde.';
    }

    Fluttertoast.showToast(
      msg: errorMessage,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: AppColors.backgroundSuccess,
      textColor: AppColors.textLight,
      fontSize: 11.0,
    );

    _loginAttempts += 1;
    if (_loginAttempts >= 3) {
      _handleAccountLock(isDarkMode);
    }
  }

  void _handleAccountLock(bool isDarkMode) {
    if (_lockoutEndTime == null) {
      _lockoutEndTime = DateTime.now().add(Duration(minutes: 10));
    } else {
      _lockoutEndTime = DateTime.now().add(Duration(days: 5));
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Material(
              borderRadius: BorderRadius.circular(15),
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cuenta bloqueada',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Icon(Icons.lock, size: 30, color: AppColors.errorText),
                    const SizedBox(height: 16),
                    Text(
                      'Debido a múltiples intentos fallidos, tu \ncuenta ha sido bloqueada temporalmente. \nVuelve a intentar en 10 minutos.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('OK',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _loginWithGoogle() async {
    try {
      await _googleSignIn.signIn();
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      print(error);
      Fluttertoast.showToast(
        msg:
        'Se produjo un error al iniciar sesión con Google. Inténtalo nuevamente.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.backgroundSuccess,
        textColor: AppColors.textLight,
        fontSize: 13.0,
      );
    }
  }

  void _loginWithApple() async {
    try {
      Fluttertoast.showToast(
        msg: 'Login con Apple próximamente disponible',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.backgroundSuccess,
        textColor: AppColors.textLight,
        fontSize: 13.0,
      );
    } catch (error) {
      print(error);
      Fluttertoast.showToast(
        msg:
        'Se produjo un error al iniciar sesión con Apple. Inténtalo nuevamente.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.backgroundSuccess,
        textColor: AppColors.textLight,
        fontSize: 13.0,
      );
    }
  }
}