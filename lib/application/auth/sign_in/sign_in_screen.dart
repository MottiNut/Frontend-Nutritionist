import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:mottinutnutriotinist/application/auth/sign_in/recover_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../configuration/providers/color_dar_light_app.dart';
import '../../../configuration/themes/app_colors.dart';
import '../../../domain/services/auth_provider.dart';
import '../../requestSnacbar/snackBar_manager.dart';
import '../terms and conditions/politica_privacidad_screen.dart';
import '../terms and conditions/terminos_condiciones_screen.dart';

class SignInScreen extends StatefulWidget {
  final String? message;
  final String? email;

  const SignInScreen({Key? key, this.message, this.email}) : super(key: key);

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
  bool _rememberMe = false; // AGREGADO

  late FocusNode _passwordFocusNode;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // AGREGADO: Almacenamiento seguro
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _loadSavedCredentials(); // AGREGADO
  }

  void _initializeScreen() {
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }

    // Mostrar mensaje de éxito si viene de verificación usando SnackBarManager
    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackBarManager.showSuccess(context, widget.message!);
      });
    }

    // Inicializar animaciones
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

    // Inicializar FocusNode
    _passwordFocusNode = FocusNode();
    _passwordFocusNode.addListener(() {
      setState(() {
        _showPasswordToggle =
            _passwordFocusNode.hasFocus || _passwordController.text.isNotEmpty;
      });
    });
  }

  // AGREGADO: Cargar credenciales guardadas
  Future<void> _loadSavedCredentials() async {
    try {
      final savedEmail = await _secureStorage.read(key: 'saved_email');
      final savedPassword = await _secureStorage.read(key: 'saved_password');
      final rememberMe = await _secureStorage.read(key: 'remember_me');

      if (savedEmail != null && savedPassword != null && rememberMe == 'true') {
        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _rememberMe = true;
          _showPasswordToggle = savedPassword.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error cargando credenciales: $e');
    }
  }

  // AGREGADO: Guardar credenciales de forma segura
  Future<void> _saveCredentials() async {
    try {
      if (_rememberMe) {
        await _secureStorage.write(
            key: 'saved_email', value: _emailController.text.trim());
        await _secureStorage.write(
            key: 'saved_password', value: _passwordController.text.trim());
        await _secureStorage.write(key: 'remember_me', value: 'true');
      } else {
        await _clearSavedCredentials();
      }
    } catch (e) {
      print('Error guardando credenciales: $e');
    }
  }

  // AGREGADO: Limpiar credenciales guardadas
  Future<void> _clearSavedCredentials() async {
    try {
      await _secureStorage.delete(key: 'saved_email');
      await _secureStorage.delete(key: 'saved_password');
      await _secureStorage.delete(key: 'remember_me');
    } catch (e) {
      print('Error limpiando credenciales: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkModeProvider = Provider.of<DarkModeProvider>(context);
    final isDarkMode = darkModeProvider.isDarkMode;

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
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoginModal() {
    final screenHeight = MediaQuery.of(context).size.height;
    final topSectionHeight = screenHeight * 0.30;

    return Column(
      children: [
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
        _buildTabButtons(),
        SizedBox(height: 5),
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
                        _buildInputFields(),
                        SizedBox(height: 1),
                        _buildRememberMeCheckbox(),
                        SizedBox(height: 15),
                        _buildLoginButton(),
                        _buildRecoverPasswordButton(context),
                        const SizedBox(height: 4),
                        _buildDividerSection(),
                        SizedBox(height: 8),
                        _buildSocialButtonsRow(),
                        Spacer(),
                        _buildTermsAndConditions(context),
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

  // AGREGADO: Checkbox para recordar credenciales
  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        Transform.scale(
          scale: 0.8,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (value) {
              setState(() {
                _rememberMe = value ?? false;
              });
            },
            activeColor: Colors.white,
            checkColor: AppColors.primary,
            side: BorderSide(color: Colors.white70, width: 1.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            visualDensity: VisualDensity.compact,
          ),
        ),
      
        Text(
          'Recordar mis datos',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // Métodos de UI existentes (mantener los originales)...
  Widget _buildLogoSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 110,
            child: SvgPicture.asset(
              'assets/images/logos/mottinut.svg',
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  FontAwesomeIcons.nutritionix,
                  size: 80,
                  color: AppColors.primary,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 35),
      child: Row(
        children: [
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
                  fontWeight: FontWeight.w300),
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
                    width: 0.75),
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

  // PASSWORD FIELD (mantener el original)
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
            focusNode: _passwordFocusNode,
            obscureText: _obscureText,
            onChanged: (value) {
              setState(() {
                if (value.isNotEmpty) {
                  _showPasswordError = false;
                }
                _isPasswordEmpty = value.isEmpty;
                _showPasswordToggle =
                    value.isNotEmpty || _passwordFocusNode.hasFocus;
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
                            : Colors.white54,
                      )
                    : Icon(
                        Icons.visibility_off,
                        color: _showPasswordToggle
                            ? AppColors.iconSecondary.withOpacity(0.8)
                            : Colors.grey.withOpacity(0.5),
                        size: 25,
                      ),
                onPressed: _showPasswordToggle
                    ? () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      }
                    : null,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color:
                      _showPasswordError ? AppColors.errorText : Colors.white,
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
  return Align(
    alignment: Alignment.centerRight,  
    child: TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecoverPasswordScreen()),
        );
      },
      child: Text(
        '¿Olvidaste tu contraseña?',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
}


  Widget _buildDividerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
             Expanded(
              child: Divider(
                color: Colors.white.withOpacity(0.15),
                thickness: 0.7,
                indent: 8,
                endIndent: 8,
              ),
            ),
            Text(
              'o con',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
             Expanded(
              child: Divider(
                color: Colors.white.withOpacity(0.15),
                thickness: 0.7,
                indent: 8,
                endIndent: 8,
              ),
            ),
          ],
        ),
      ],
    );
  }

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

  Widget _buildTermsAndConditions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: 'Al continuar, aceptas los \n',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w300,
            fontSize: 11,
            letterSpacing: 0.5,
            height: 1.3,
          ),
          children: [
            TextSpan(
              text: 'Términos y Condiciones',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                letterSpacing: 0.5,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TerminosCondicionesScreen(),
                    ),
                  );
                },
            ),
            TextSpan(
              text: ' y ',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
                fontSize: 11,
              ),
            ),
            TextSpan(
              text: 'Política de privacidad',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PoliticaPrivacidadScreen(),
                    ),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
      String assetPath, String provider, VoidCallback onPressed) {
    return Container(
      width: 43,
      height: 43,
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

  // MÉTODOS DE FUNCIONALIDAD MEJORADOS

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

      // USANDO SNACKBARMANAGER
      if (_isEmailEmpty && _isPasswordEmpty) {
        SnackBarManager.showWarning(
            context, 'Por favor completa todos los campos');
      } else if (_isEmailEmpty) {
        SnackBarManager.showWarning(
            context, 'Por favor ingresa tu correo electrónico');
      } else {
        SnackBarManager.showWarning(context, 'Por favor ingresa tu contraseña');
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

      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Guardar credenciales si el usuario lo desea
        await _saveCredentials();

        // USANDO SNACKBARMANAGER
        SnackBarManager.showSuccess(context, 'Inicio de sesión exitoso');

        // Navegar al home después de un pequeño delay para mostrar el snackbar
        Future.delayed(Duration(milliseconds: 1500), () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (Route<dynamic> route) => false,
            arguments: {'initialIndex': 0},
          );
        });
      } else {
        final errorMessage = authProvider.errorMessage ?? 'Error desconocido';
        print('🔍 Error del AuthProvider: $errorMessage');
        _handleLoginErrorFromProvider(errorMessage);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('💥 Exception en _handleLogin: $e');
      _handleLoginError(e, isDarkMode);
    }
  }

  void _handleLoginErrorFromProvider(String errorMessage) {
    print('🔍 Error del AuthProvider: $errorMessage');

    // Normalizar mensaje para comparación
    final normalizedError = errorMessage.toLowerCase();

    // ✅ Manejo específico de errores de verificación
    if (_isVerificationError(normalizedError)) {
      _handleVerificationError();
      return;
    }

    // ✅ Manejo de errores de credenciales
    if (_isCredentialError(normalizedError)) {
      _handleCredentialError();
      return;
    }

    // ✅ Manejo de cuenta bloqueada
    if (_isAccountBlockedError(normalizedError)) {
      _handleAccountBlockedError();
      return;
    }

    // ✅ Manejo de errores de servidor
    if (_isServerError(normalizedError)) {
      SnackBarManager.showError(
          context, 'Problema del servidor. Intenta más tarde');
      return;
    }

    // ✅ Error genérico con mensaje personalizado
    SnackBarManager.showError(context, _getFriendlyErrorMessage(errorMessage));
  }

// ✅ NUEVO: Verificar si es error de verificación
  bool _isVerificationError(String error) {
    return error.contains('verificar') ||
        error.contains('verify') ||
        error.contains('verification') ||
        error.contains('confirm') ||
        error.contains('activate');
  }

// ✅ NUEVO: Verificar si es error de credenciales
  bool _isCredentialError(String error) {
    return error.contains('credenciales') ||
        error.contains('password') ||
        error.contains('email') ||
        error.contains('usuario') ||
        error.contains('contraseña') ||
        error.contains('invalid') ||
        error.contains('incorrect');
  }

// ✅ NUEVO: Verificar si es cuenta bloqueada
  bool _isAccountBlockedError(String error) {
    return error.contains('blocked') ||
        error.contains('bloqueado') ||
        error.contains('suspended') ||
        error.contains('locked');
  }

// ✅ NUEVO: Verificar si es error de servidor
  bool _isServerError(String error) {
    return error.contains('500') ||
        error.contains('502') ||
        error.contains('503') ||
        error.contains('server') ||
        error.contains('timeout');
  }

// ✅ NUEVO: Manejar error de verificación
  void _handleVerificationError() {
    SnackBarManager.showWithAction(
      context,
      message: 'Tu cuenta necesita verificación',
      actionText: 'Reenviar correo',
      onAction: () => _resendVerificationEmail(),
      type: SnackBarType.warning,
      duration: Duration(seconds: 3),
    );
  }

// ✅ NUEVO: Manejar error de credenciales
  void _handleCredentialError() {
    setState(() {
      _showEmailError = true;
      _showPasswordError = true;
    });

    _loginAttempts++;

    if (_loginAttempts >= 3) {
      _handleAccountLock();
    } else {
      final remaining = 3 - _loginAttempts;
      SnackBarManager.showError(
          context, 'Credenciales incorrectas. Te quedan $remaining intentos');
    }
  }

// ✅ NUEVO: Manejar cuenta bloqueada
  void _handleAccountBlockedError() {
    SnackBarManager.showError(context, 'Cuenta bloqueada temporalmente');
    _handleAccountLock();
  }

// ✅ NUEVO: Obtener mensaje amigable
  String _getFriendlyErrorMessage(String originalError) {
    final errorMap = {
      'network': 'Error de conexión',
      'timeout': 'Tiempo de espera agotado',
      'unauthorized': 'No autorizado',
      'forbidden': 'Acceso denegado',
      'not found': 'Recurso no encontrado',
      'internal server error': 'Error interno del servidor',
    };

    final normalizedError = originalError.toLowerCase();

    for (final key in errorMap.keys) {
      if (normalizedError.contains(key)) {
        return errorMap[key]!;
      }
    }

    // Si no encuentra una coincidencia, devuelve un mensaje genérico
    return 'Credenciales incorrectas. Intenta nuevamente';
  }

  // AGREGAR este método
  Future<void> _resendVerificationEmail() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      //final success = await authProvider.resendVerificationEmail(_emailController.text.trim());

      setState(() {
        _isLoading = false;
      });

      /*if (success) {
        SnackBarManager.showSuccess(context, 'Correo de verificación enviado');
      } else {
        SnackBarManager.showError(context, 'Error al enviar correo de verificación');
      }*/
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackBarManager.showError(context, 'Error de conexión');
    }
  }

  void _handleLoginError(dynamic error, bool isDarkMode) {
    String message = "Error de conexión";

    if (error.toString().contains('SocketException') ||
        error.toString().contains('HandshakeException') ||
        error.toString().contains('TimeoutException')) {
      message = "Error de conexión. Verifica tu internet.";
    } else if (error.toString().contains('FormatException')) {
      message = "Error en la respuesta del servidor";
    } else if (error.toString().contains('HttpException')) {
      message = "Error del servidor";
    }

    SnackBarManager.showError(context, message);
  }

  void _handleAccountLock() {
    _lockoutEndTime = DateTime.now().add(Duration(minutes: 10));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.lock, color: AppColors.errorText, size: 24),
              SizedBox(width: 8),
              Text('Cuenta Bloqueada', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Text(
            'Debido a múltiples intentos fallidos, tu cuenta ha sido bloqueada temporalmente por 10 minutos.\n\n¿Olvidaste tu contraseña?',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RecoverPasswordScreen()),
                );
              },
              child: Text('Recuperar Contraseña'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Entendido', style: TextStyle(color: Colors.white)),
            ),
          ],
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

      SnackBarManager.showError(context,
          'Se produjo un error al iniciar sesión con Google. Inténtalo nuevamente.');
    }
  }

  void _loginWithApple() async {
    try {
      SnackBarManager.showError(
          context, 'Login con Apple próximamente disponible');
    } catch (error) {
      print(error);

      SnackBarManager.showError(context,
          'Se produjo un error al iniciar sesión con Apple. Inténtalo nuevamente.');
    }
  }
}
