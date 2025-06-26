import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../configuration/themes/app_colors.dart';

class EmailPasswordScreen extends StatefulWidget {
  final String initialEmail;
  final String initialPassword;
  final String initialConfirmPassword;
  final String initialPhone;
  final Function(String email, String password, String confirmPassword, String phone) onDataChanged;

  const EmailPasswordScreen({
    Key? key,
    required this.initialEmail,
    required this.initialPassword,
    required this.initialConfirmPassword,
    required this.initialPhone,
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
  late String phone;

  // Password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Error states
  String emailError = '';
  String passwordError = '';
  String confirmPasswordError = '';
  String phoneError = '';

  // Password validation states
  bool hasMinLength = false;
  bool hasUppercase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;

  // Focus nodes
  late FocusNode emailFocus;
  late FocusNode passwordFocus;
  late FocusNode confirmPasswordFocus;
  late FocusNode phoneFocus;

  // Controllers
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();

    // Inicializar variables con los valores recibidos
    email = widget.initialEmail;
    password = widget.initialPassword;
    confirmPassword = widget.initialConfirmPassword;
    phone = widget.initialPhone;

    // Inicializar controllers
    emailController = TextEditingController(text: email);
    passwordController = TextEditingController(text: password);
    confirmPasswordController = TextEditingController(text: confirmPassword);
    phoneController = TextEditingController(text: phone);

    // Inicializar focus nodes
    emailFocus = FocusNode();
    passwordFocus = FocusNode();
    confirmPasswordFocus = FocusNode();
    phoneFocus = FocusNode();

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

    phoneFocus.addListener(() {
      if (!phoneFocus.hasFocus) {
        _validatePhone();
      }
    });

    // Validar password inicial si existe
    if (password.isNotEmpty) {
      _validatePasswordRequirements(password);
    }
  }

  @override
  void dispose() {
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    phoneFocus.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
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

    final domain = email.split('@').last.toLowerCase();

    if (!domain.contains('.') || domain.startsWith('.') || domain.endsWith('.')) {
      return false;
    }

    if (domain.contains('..')) {
      return false;
    }

    return commonDomains.contains(domain);
  }

  void _validatePhone() {
    setState(() {
      if (phone.isEmpty) {
        phoneError = 'El número de celular es requerido';
      } else if (!_isValidPeruvianPhone(phone)) {
        phoneError = 'Ingrese un número de celular válido (9 dígitos)';
      } else {
        phoneError = '';
      }
    });
    _notifyParent();
  }

  bool _isValidPeruvianPhone(String phone) {
    // Remover espacios y caracteres especiales
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Verificar que tenga exactamente 9 dígitos y comience con 9
    return cleanPhone.length == 9 && cleanPhone.startsWith('9');
  }

  void _validatePasswordRequirements(String password) {
    setState(() {
      hasMinLength = password.length >= 6;
      hasUppercase = password.contains(RegExp(r'[A-Z]'));
      hasNumber = password.contains(RegExp(r'[0-9]'));
      hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  void _validatePassword() {
    setState(() {
      if (password.isEmpty) {
        passwordError = 'La contraseña es requerida';
      } else if (!hasMinLength || !hasUppercase || !hasNumber || !hasSpecialChar) {
        passwordError = 'La contraseña no cumple con los requisitos';
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
    widget.onDataChanged(email, password, confirmPassword, phone);
  }

  // Método público para validar desde el padre
  bool isValid() {
    _validateEmail();
    _validatePassword();
    _validateConfirmPassword();
    _validatePhone();

    return email.trim().isNotEmpty &&
        password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        phone.isNotEmpty &&
        emailError.isEmpty &&
        passwordError.isEmpty &&
        confirmPasswordError.isEmpty &&
        phoneError.isEmpty;
  }

  Widget _buildPasswordRequirement(String text, bool isValid) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isValid ? AppColors.checkValidation : Colors.grey[400],
          ),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? AppColors.checkValidation : Colors.grey[400],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
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
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                    fontWeight: FontWeight.w500,
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
                    hintStyle: TextStyle(color: AppColors.textInput, fontSize: 16),
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
                  style: TextStyle(fontSize: 16),
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

                // Número de celular
                Text(
                  'Número de celular',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  focusNode: phoneFocus,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  onChanged: (value) {
                    setState(() {
                      phone = value;
                      if (value.isNotEmpty && phoneError.isNotEmpty) {
                        phoneError = '';
                      }
                    });
                    _notifyParent();
                  },
                  decoration: InputDecoration(
                    hintText: '999 999 999',
                    hintStyle: TextStyle(color: AppColors.textInput, fontSize: 16),
                    prefixIcon: Container(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '+51',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        width: 1.4,
                        color: phoneError.isNotEmpty
                            ? AppColors.errorText
                            : AppColors.textInput,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        width: 1.4,
                        color: phoneError.isNotEmpty
                            ? AppColors.errorText
                            : AppColors.textInput,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        width: 1.4,
                        color: phoneError.isNotEmpty
                            ? AppColors.errorText
                            : AppColors.primary,
                      ),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(fontSize: 16),
                ),
                if (phoneError.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4, left: 16),
                    child: Text(
                      phoneError,
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
                    fontWeight: FontWeight.w500,
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
                      _validatePasswordRequirements(value);
                      if (value.isNotEmpty && passwordError.isNotEmpty) {
                        passwordError = '';
                      }
                    });
                    _notifyParent();
                  },
                  decoration: InputDecoration(
                    hintText: 'Ingrese su contraseña',
                    hintStyle: TextStyle(color: AppColors.textInput, fontSize: 16),
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
                  style: TextStyle(fontSize: 16),
                ),

                if (passwordFocus.hasFocus && password.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8, left: 16, right: 16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requisitos de contraseña:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildPasswordRequirement('Al menos 6 caracteres', hasMinLength),
                        _buildPasswordRequirement('Al menos una letra mayúscula', hasUppercase),
                        _buildPasswordRequirement('Al menos un número', hasNumber),
                        _buildPasswordRequirement('Al menos un carácter especial (!@#%^&*)', hasSpecialChar),
                      ],
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
                    fontWeight: FontWeight.w500,
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
                    hintStyle: TextStyle(color: AppColors.textInput, fontSize: 16),
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
                  style: TextStyle(fontSize: 16),
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