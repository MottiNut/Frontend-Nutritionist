import 'package:flutter/material.dart';

import '../../../../configuration/themes/app_colors.dart';

class EmailPasswordScreen extends StatefulWidget {
  final String initialEmail;
  final String initialPassword;
  final String initialConfirmPassword;
  final Function(String email, String password, String confirmPassword) onDataChanged;

  const EmailPasswordScreen({
    Key? key,
    required this.initialEmail,
    required this.initialPassword,
    required this.initialConfirmPassword,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  EmailPasswordScreenState createState() => EmailPasswordScreenState();
}

class EmailPasswordScreenState extends State<EmailPasswordScreen> {
  // Variables locales
  late String email;
  late String password;
  late String confirmPassword;

  // Password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Error states
  String emailError = '';
  String passwordError = '';
  String confirmPasswordError = '';

  // Focus nodes
  late FocusNode emailFocus;
  late FocusNode passwordFocus;
  late FocusNode confirmPasswordFocus;

  // Controllers
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  @override
  void initState() {
    super.initState();

    // Inicializar variables con los valores recibidos
    email = widget.initialEmail;
    password = widget.initialPassword;
    confirmPassword = widget.initialConfirmPassword;

    // Inicializar controllers
    emailController = TextEditingController(text: email);
    passwordController = TextEditingController(text: password);
    confirmPasswordController = TextEditingController(text: confirmPassword);

    // Inicializar focus nodes
    emailFocus = FocusNode();
    passwordFocus = FocusNode();
    confirmPasswordFocus = FocusNode();

    // Agregar listeners para detectar cuando se pierde el foco
    emailFocus.addListener(() {
      if (!emailFocus.hasFocus) {
        _validateEmail();
      }
    });

    passwordFocus.addListener(() {
      if (!passwordFocus.hasFocus) {
        _validatePassword();
      }
    });

    confirmPasswordFocus.addListener(() {
      if (!confirmPasswordFocus.hasFocus) {
        _validateConfirmPassword();
      }
    });
  }

  @override
  void dispose() {
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Validaciones
  void _validateEmail() {
    setState(() {
      if (email.trim().isEmpty) {
        emailError = 'El correo electrónico es requerido';
      } else if (!_isValidEmail(email.trim())) {
        emailError = 'Ingrese un correo electrónico válido';
      } else {
        emailError = '';
      }
    });
    _notifyParent();
  }

  bool _isValidEmail(String email) {

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );

    if (!emailRegex.hasMatch(email)) {
      return false;
    }

    final commonDomains = [
      'gmail.com', 'outlook.com', 'hotmail.com', 'yahoo.com', 'yahoo.es',
      'icloud.com', 'aol.com', 'protonmail.com', 'zoho.com', 'live.com',
      'msn.com', 'yandex.com', 'mail.com', 'gmx.com', 'tutanota.com',

    ];

    // Extraer el dominio del email
    final domain = email.split('@').last.toLowerCase();

    // Validar que el dominio tenga al menos un punto y caracteres válidos
    if (!domain.contains('.') || domain.startsWith('.') || domain.endsWith('.')) {
      return false;
    }

    // Validar que no tenga puntos consecutivos
    if (domain.contains('..')) {
      return false;
    }

    return commonDomains.contains(domain);
  }

  void _validatePassword() {
    setState(() {
      if (password.isEmpty) {
        passwordError = 'La contraseña es requerida';
      } else if (password.length < 6) {
        passwordError = 'La contraseña debe tener al menos 6 caracteres';
      } else {
        passwordError = '';
      }
    });
    _notifyParent();
  }

  void _validateConfirmPassword() {
    setState(() {
      if (confirmPassword.isEmpty) {
        confirmPasswordError = 'Confirme su contraseña';
      } else if (confirmPassword != password) {
        confirmPasswordError = 'Las contraseñas no coinciden';
      } else {
        confirmPasswordError = '';
      }
    });
    _notifyParent();
  }

  // Notificar al padre sobre los cambios
  void _notifyParent() {
    widget.onDataChanged(email, password, confirmPassword);
  }

  // Método público para validar desde el padre
  bool isValid() {
    _validateEmail();
    _validatePassword();
    _validateConfirmPassword();

    return email.trim().isNotEmpty &&
        password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        emailError.isEmpty &&
        passwordError.isEmpty &&
        confirmPasswordError.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 32),
// Título
                const Center(
                    child: Text(
                      'Crear Cuenta',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    )),
                SizedBox(height: 3),
                Center(
                  child: Text(
                    'Configura tus credenciales de acceso',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.36
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
                // Correo electrónico
                Text(
                  'Correo electrónico',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  focusNode: emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setState(() {
                      email = value;
                      if (value.isNotEmpty && emailError.isNotEmpty) {
                        emailError = '';
                      }
                    });
                    _notifyParent();
                  },
                  decoration: InputDecoration(
                    hintText: 'ejemplo@gmail.com',
                    hintStyle: TextStyle(color: AppColors.textInput, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        width: 1.4,
                        color: emailError.isNotEmpty
                            ? AppColors.errorText
                            : AppColors.textInput,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        width: 1.4,
                        color: emailError.isNotEmpty
                            ? AppColors.errorText
                            : AppColors.textInput,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        width: 1.4,
                        color: emailError.isNotEmpty
                            ? AppColors.errorText
                            : AppColors.primary,
                      ),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                if (emailError.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: 16),
                    child: Text(
                      emailError,
                      style: TextStyle(
                        color: AppColors.errorText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                SizedBox(height: 24),

                // Contraseña
                Text(
                  'Contraseña',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  focusNode: passwordFocus,
                  obscureText: _obscurePassword,
                  onChanged: (value) {
                    setState(() {
                      password = value;
                      if (value.isNotEmpty && passwordError.isNotEmpty) {
                        passwordError = '';
                      }
                    });
                    _notifyParent();
                  },
                  decoration: InputDecoration(
                    hintText: 'Ingrese su contraseña',
                    hintStyle: TextStyle(color: AppColors.textInput, fontSize: 13),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.primary.withOpacity(0.7),
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        width: 1.4,
                        color: passwordError.isNotEmpty
                            ? AppColors.errorText
                            : AppColors.textInput,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        width: 1.4,
                        color: passwordError.isNotEmpty
                            ? AppColors.errorText
                            : AppColors.textInput,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        width: 1.4,
                        color: passwordError.isNotEmpty
                            ? AppColors.errorText
                            : AppColors.primary,
                      ),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                if (passwordError.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: 16),
                    child: Text(
                      passwordError,
                      style: TextStyle(
                        color: AppColors.errorText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                SizedBox(height: 24),

                // Confirmar Contraseña
                Text(
                  'Confirmar contraseña',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: confirmPasswordController,
                  focusNode: confirmPasswordFocus,
                  obscureText: _obscureConfirmPassword,
                  onChanged: (value) {
                    setState(() {
                      confirmPassword = value;
                      if (value.isNotEmpty && confirmPasswordError.isNotEmpty) {
                        confirmPasswordError = '';
                      }
                    });
                    _notifyParent();
                  },
                  decoration: InputDecoration(
                    hintText: 'Confirme su contraseña',
                    hintStyle: TextStyle(color: AppColors.textInput, fontSize: 13),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.primary.withOpacity(0.7),
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        width: 1.4,
                        color: confirmPasswordError.isNotEmpty
                            ? AppColors.errorText
                            : AppColors.textInput,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        width: 1.4,
                        color: confirmPasswordError.isNotEmpty
                            ? AppColors.errorText
                            : AppColors.textInput,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        width: 1.4,
                        color: confirmPasswordError.isNotEmpty
                            ? AppColors.errorText
                            : AppColors.primary,
                      ),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                if (confirmPasswordError.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: 16),
                    child: Text(
                      confirmPasswordError,
                      style: TextStyle(
                        color: AppColors.errorText,
                        fontSize: 13,
                      ),
                    ),
                  ),

                SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}