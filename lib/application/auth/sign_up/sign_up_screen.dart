import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/verification_code/code_verification_screen.dart';
import 'package:provider/provider.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/colegiatura_verification_screen.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/email_password_screen.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/personal_info_screen.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/specialty_screen.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/work_screen.dart';
import '../../../configuration/themes/app_colors.dart';
import '../../../domain/services/auth_provider.dart';
import '../../requestSnacbar/snackBar_manager.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late PageController _pageController;
  static const int totalPages = 5;
  int _currentStep = 0;

  // Keys para acceder a los estados de las pantallas
  final GlobalKey<PersonalInfoScreenState> _personalInfoKey =
      GlobalKey<PersonalInfoScreenState>();
  final GlobalKey<EmailPasswordScreenState> _emailPasswordKey =
      GlobalKey<EmailPasswordScreenState>();
  final GlobalKey<ColegiaturaVerificationScreenState> _colegiaturaKey =
      GlobalKey<ColegiaturaVerificationScreenState>();
  final GlobalKey<SpecialtyScreenState> _specialtyKey =
      GlobalKey<SpecialtyScreenState>();
  final GlobalKey<LocationSelectorScreenState> _locationKey =
      GlobalKey<LocationSelectorScreenState>();

  // Datos del formulario
  String _firstName = '';
  String _lastName = '';
  File? _profilePhoto;
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _phone = '';
  String _cnpCode = '';

  bool _termsAccepted = false;
  String _specialty = '';
  String _masterDegree = '';
  String _otherSpecialty = '';
  String _location = '';
  String _address = '';

  // Variables para archivos
  File? _profileImage;
  File? _licenseFrontImage;
  File? _licenseBackImage;

  // Variables para el método de verificación
  VerificationMethod _verificationMethod = VerificationMethod.email;
  String _phoneNumber = '';
  String _whatsappNumber = '';

  // Estado de validación
  bool _cnpIsValid = false;
  bool _cnpVerificationInProgress = false;
  bool _emailExists = false;

  VerificationMethod _selectedVerificationMethod = VerificationMethod.email;

  bool _verificationMethodSelected = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ========== CALLBACKS DE DATOS ==========

  void _onPersonalInfoChanged(String nombre, String apellido, File? photo) {
    setState(() {
      _firstName = nombre;
      _lastName = apellido;
      _profilePhoto = photo;
    });
  }

  void _onEmailPasswordChanged(
      String email, String password, String confirmPassword, String phone) {
    setState(() {
      _email = email;
      _password = password;
      _confirmPassword = confirmPassword;
      _phone = phone;
      _emailExists = false; 
    });
  }

  void _onCnpValidated() {
    setState(() {
      _cnpIsValid = true;
      _cnpVerificationInProgress = false;
    });
  }

  void _onColegiaturaValidated(
      String codeCNP, File? licenseFront, File? licenseBack) {
    setState(() {
      _cnpCode = codeCNP;
      _licenseFrontImage = licenseFront;
      _licenseBackImage = licenseBack;

     
      if (codeCNP.length == 4 && licenseFront != null && licenseBack != null) {
        _cnpIsValid = true;
        _cnpVerificationInProgress = false;
      }
    });
  }

  void _onSpecialtyChanged(String especialidad, String maestria, String other) {
    setState(() {
      _specialty = especialidad;
      _masterDegree = maestria;
      _otherSpecialty = other;
    });
  }

  void _onLocationChanged(String ubicacion, String direccion) {
    setState(() {
      _location = ubicacion;
      _address = direccion;
    });
  }

  // ========== VALIDACIONES ==========

  bool get _isPersonalInfoValid =>
      _firstName.trim().isNotEmpty && _lastName.trim().isNotEmpty;

  bool get _isEmailPasswordValid =>
      _email.trim().isNotEmpty &&
      _password.isNotEmpty &&
      _confirmPassword.isNotEmpty &&
      _password == _confirmPassword &&
      _password.length >= 6 &&
      _email.contains('@');

  bool get _isColegiaturaValid =>
      _cnpCode.trim().isNotEmpty &&
      _licenseFrontImage != null &&
      _licenseBackImage != null;

  bool get _isSpecialtyValid => _specialty.trim().isNotEmpty;

  bool get _isLocationValid {
    bool termsAccepted = _locationKey.currentState?.termsAccepted ?? false;

    bool basicValid = _location.trim().isNotEmpty &&
        _address.trim().isNotEmpty &&
        termsAccepted;

    switch (_verificationMethod) {
      case VerificationMethod.sms:
        return basicValid && _phone.trim().isNotEmpty;
      case VerificationMethod.whatsapp:
        return basicValid && _whatsappNumber.trim().isNotEmpty;
      case VerificationMethod.email:
      default:
        return basicValid;
    }
  }

  bool get _isSmsAvailable => _phone.trim().isNotEmpty;

  // ========== NAVEGACIÓN ==========
  void _nextPage() {
    switch (_currentStep) {
      case 0:
        _validateAndProceed(_isPersonalInfoValid,
            'Por favor, completa la información personal');
        break;
      case 1:
        _validateAndProceed(
            _isEmailPasswordValid && !_emailExists,
            _emailExists
                ? 'Este email ya está registrado'
                : 'Por favor, completa el email y contraseña correctamente');
        break;
      case 2:
        debugPrint('=== DEBUG COLEGIATURA ===');
        debugPrint('isColegiaturaValid: $_isColegiaturaValid');
        debugPrint('cnpIsValid: $_cnpIsValid');
        debugPrint('cnpVerificationInProgress: $_cnpVerificationInProgress');
        debugPrint('cnpCode: $_cnpCode');
        debugPrint(
            'licenseFrontImage: ${_licenseFrontImage != null ? 'Sí' : 'No'}');
        debugPrint(
            'licenseBackImage: ${_licenseBackImage != null ? 'Sí' : 'No'}');

        debugPrint('========================');

        if (_cnpVerificationInProgress) {
          _showValidationError('Verificando código CNP, por favor espera...');
          return;
        }

        if (_isColegiaturaValid && _cnpIsValid) {
          _animateToNextPage();
        } else {
          _showValidationError(_getColegiaturaValidationMessage());
        }
        break;
      case 3:
        _validateAndProceed(_isSpecialtyValid,
            'Por favor, completa la información de especialidad');
        break;
      case 4:
        _handleRegistration();
        break;
      default:
        _animateToNextPage();
    }
  }

  void _validateAndProceed(bool isValid, String errorMessage) {
    if (isValid) {
      _animateToNextPage();
    } else {
      _showValidationError(errorMessage);
    }
  }

  void _animateToNextPage() {
    if (_currentStep < totalPages - 1) {
      setState(() {
        _currentStep++;
      });

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });

      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<bool> _onWillPop() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);


    if (authProvider.isLoading) {
      return false;
    }

    if (_currentStep == 0) {
      Navigator.of(context).pushReplacementNamed('/login');
      return false;
    }

    _previousPage();
    return false;
  }

  // ========== REGISTRO ==========

  // ========== VALIDACIÓN ESPECÍFICA ==========

  String _getColegiaturaValidationMessage() {
    if (_cnpVerificationInProgress) {
      return 'Verificando código CNP...';
    }

    if (!_isColegiaturaValid) {
      if (_cnpCode.trim().isEmpty) {
        return 'Por favor, ingresa el código CNP';
      }
      if (_licenseFrontImage == null || _licenseBackImage == null) {
        return 'Por favor, adjunta ambas fotos del CNP (frontal y trasera)';
      }
      return 'Por favor, completa la información de colegiatura';
    }

    if (!_cnpIsValid) {
      return 'El código CNP ingresado no es válido';
    }

    return 'Error en la validación de colegiatura';
  }

  String _getLocationValidationMessage() {
    if (_location.trim().isEmpty) {
      return 'Por favor, selecciona tu ubicación';
    }
    if (_address.trim().isEmpty) {
      return 'Por favor, ingresa tu dirección específica';
    }

    // ✅ CORRECCIÓN: Usar los valores reales del estado
    bool termsAccepted = _locationKey.currentState?.termsAccepted ?? false;

    if (!termsAccepted) {
      return 'Por favor, acepta los términos y condiciones del servicio';
    }

    switch (_verificationMethod) {
      case VerificationMethod.sms:
        if (_phone.trim().isEmpty) {
          return 'Por favor, ingresa tu número de teléfono para SMS';
        }
        break;
      case VerificationMethod.whatsapp:
        if (_whatsappNumber.trim().isEmpty) {
          return 'Por favor, ingresa tu número de WhatsApp';
        }
        break;
      case VerificationMethod.email:
        // No se requiere validación adicional para email
        break;
    }

    return 'Por favor, completa toda la información requerida';
  }

  bool get _canProceedToNext {
    switch (_currentStep) {
      case 0:
        return _isPersonalInfoValid && _profilePhoto != null;
      case 1:
        return _isEmailPasswordValid && !_emailExists;
      case 2:
        return _isColegiaturaValid &&
            _cnpIsValid &&
            !_cnpVerificationInProgress;
      case 3:
        return _isSpecialtyValid;
      case 4:
        return _isLocationValid;
      default:
        return false;
    }
  }

  // ========== CALLBACKS DE VERIFICACIÓN ==========

  void _onVerificationStart() {
    setState(() {
      _cnpVerificationInProgress = true;
    });
    debugPrint('Iniciando verificación...');
  }

  // ========== MENSAJES ==========

  void _showValidationError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorText,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    SnackBarManager.showSuccess(context, message);
  }

  // ========== UI WIDGETS ==========

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/loading/loading_infinity.json',
                  width: 40,
                  height: 40,
                ),
                SizedBox(height: 16),
                Text(
                  'Procesando registro...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /*Future<void> _handleRegistration() async {
    if (_profilePhoto == null) {
      _showValidationError('Por favor, selecciona una foto de perfil');
      return;
    }

    if (_licenseFrontImage == null || _licenseBackImage == null) {
      _showValidationError('Por favor, adjunta ambas fotos del CNP');
      return;
    }

    if (!_isLocationValid) {
      _showValidationError(_getLocationValidationMessage());
      return;
    }

    // ✅ Validaciones adicionales antes del registro
    if (_profilePhoto == null) {
      _showValidationError('Por favor, selecciona una foto de perfil');
      return;
    }

    if (_licenseFrontImage == null || _licenseBackImage == null) {
      _showValidationError('Por favor, adjunta ambas fotos del CNP');
      return;
    }

    // ✅ Validaciones adicionales importantes
    if (_firstName.trim().isEmpty || _lastName.trim().isEmpty) {
      _showValidationError('Por favor, completa tu nombre completo');
      return;
    }

    if (_email.trim().isEmpty || !_email.contains('@')) {
      _showValidationError('Por favor, ingresa un email válido');
      return;
    }

    if (_password.length < 6) {
      _showValidationError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (_cnpCode.trim().isEmpty) {
      _showValidationError('Por favor, ingresa tu código CNP');
      return;
    }

    if (_specialty.trim().isEmpty) {
      _showValidationError('Por favor, selecciona una especialidad');
      return;
    }

    if (_location.trim().isEmpty) {
      _showValidationError('Por favor, selecciona tu ubicación');
      return;
    }

    if (_address.trim().isEmpty) {
      _showValidationError('Por favor, ingresa tu dirección');
      return;
    }

    _showVerificationMethodModal();
  }*/

  Future<void> _handleRegistration() async {
    // Validaciones básicas
    if (_profilePhoto == null) {
      _showValidationError('Por favor, selecciona una foto de perfil');
      return;
    }

    if (_licenseFrontImage == null || _licenseBackImage == null) {
      _showValidationError('Por favor, adjunta ambas fotos del CNP');
      return;
    }

    if (!_isLocationValid) {
      _showValidationError(_getLocationValidationMessage());
      return;
    }

    // Validaciones adicionales
    if (_firstName.trim().isEmpty || _lastName.trim().isEmpty) {
      _showValidationError('Por favor, completa tu nombre completo');
      return;
    }

    if (_email.trim().isEmpty || !_email.contains('@')) {
      _showValidationError('Por favor, ingresa un email válido');
      return;
    }

    if (_password.length < 6) {
      _showValidationError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (_cnpCode.trim().isEmpty) {
      _showValidationError('Por favor, ingresa tu código CNP');
      return;
    }

    if (_specialty.trim().isEmpty) {
      _showValidationError('Por favor, selecciona una especialidad');
      return;
    }

    if (_location.trim().isEmpty) {
      _showValidationError('Por favor, selecciona tu ubicación');
      return;
    }

    if (_address.trim().isEmpty) {
      _showValidationError('Por favor, ingresa tu dirección');
      return;
    }

    await _proceedWithRegistrationDirectly();
  }

  void _showVerificationMethodModal() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // No mostrar modal si está cargando
    if (authProvider.isLoading) {
      return;
    }

    _selectedVerificationMethod = _verificationMethodSelected
        ? _verificationMethod
        : VerificationMethod.email;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => _buildVerificationMethodModal(),
    );
  }

  Widget _buildVerificationMethodModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      // Barra de agarre
                      Center(
                        child: Container(
                          width: 36,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Título
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Verificar cuenta',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Selecciona tu método preferido',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Opciones de verificación
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Opción Email
                        _buildVerificationOption(
                          context: context,
                          setModalState: setModalState,
                          method: VerificationMethod.email,
                          icon: Icons.mail_outline_rounded,
                          title: 'Email',
                          subtitle: _email,
                          description: 'Código de 6 dígitos',
                          isAvailable: true,
                          onTap: () {
                            _selectedVerificationMethod =
                                VerificationMethod.email;
                            _confirmVerificationMethod();
                          },
                        ),

                        const SizedBox(height: 12),

                        // Opción SMS
                        _buildVerificationOption(
                          context: context,
                          setModalState: setModalState,
                          method: VerificationMethod.sms,
                          icon: Icons.sms_outlined,
                          title: 'SMS',
                          subtitle: _isSmsAvailable ? _phone : 'No disponible',
                          description: _isSmsAvailable
                              ? 'Código de 6 dígitos'
                              : 'Agrega tu número',
                          isAvailable: _isSmsAvailable,
                          onTap: _isSmsAvailable
                              ? () {
                                  _selectedVerificationMethod =
                                      VerificationMethod.sms;
                                  _confirmVerificationMethod();
                                }
                              : null,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerificationOption({
    required BuildContext context,
    required StateSetter setModalState,
    required VerificationMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required bool isAvailable,
    required VoidCallback? onTap,
  }) {
    final isSelected = _selectedVerificationMethod == method;

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.6,
          child: Row(
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(width: 14),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (!isAvailable) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'No disponible',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isAvailable ? Colors.grey[500] : Colors.orange[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Check icon
              if (isSelected && isAvailable)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmVerificationMethod() {
    // ✅ CORRECCIÓN: Validar que la selección sea válida usando _phone
    if (_selectedVerificationMethod == VerificationMethod.sms &&
        _phone.trim().isEmpty) {
      _showValidationError(
          'No puedes seleccionar SMS sin un número de teléfono válido');
      return;
    }

    // Actualizar el estado del widget principal
    setState(() {
      _verificationMethodSelected = true;
      _verificationMethod = _selectedVerificationMethod;
    });

    // Cerrar el modal
    Navigator.of(context).pop();

    // Mostrar mensaje de confirmación
    String methodName = _selectedVerificationMethod == VerificationMethod.email
        ? 'Correo Electrónico'
        : 'SMS';
    String contact = _selectedVerificationMethod == VerificationMethod.email
        ? _email
        : _phone;

    debugPrint('=== MÉTODO DE VERIFICACIÓN CONFIRMADO ===');
    debugPrint('Método: ${_selectedVerificationMethod.name}');
    debugPrint('Contacto: $contact');
  }

  /*Future<void> _proceedWithRegistration() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Validación de archivos (tu código existente)
      if (_profilePhoto != null) {
        final profileSize = await _profilePhoto!.length();
        if (profileSize > 10 * 1024 * 1024) {
          _showValidationError('La foto de perfil es muy grande. Máximo 10MB.');
          return;
        }
      }

      // Validación de imágenes de licencia
      if (_licenseFrontImage != null) {
        final frontSize = await _licenseFrontImage!.length();
        if (frontSize > 10 * 1024 * 1024) {
          _showValidationError(
              'La foto frontal del CNP es muy grande. Máximo 10MB.');
          return;
        }
      }

      if (_licenseBackImage != null) {
        final backSize = await _licenseBackImage!.length();
        if (backSize > 10 * 1024 * 1024) {
          _showValidationError(
              'La foto trasera del CNP es muy grande. Máximo 10MB.');
          return;
        }
      }

      debugPrint('=== INICIANDO PETICIÓN DE REGISTRO ===');
      debugPrint(
          'Método de verificación seleccionado: ${_selectedVerificationMethod.name}');
      debugPrint('Email: ${_email.trim().toLowerCase()}');
      debugPrint('Teléfono: $_phone');

      // ✅ CORRECCIÓN: Obtener el valor real de términos aceptados
      bool termsAccepted = _locationKey.currentState?.termsAccepted ?? false;

      debugPrint('Términos aceptados: $termsAccepted');

      // Validar que los términos estén aceptados
      if (!termsAccepted) {
        _showValidationError('Debes aceptar los términos y condiciones');
        return;
      }

      // ✅ SOLUCIÓN PRINCIPAL: Registrar usuario
      final success = await authProvider.register(
        firstName: _firstName.trim(),
        lastName: _lastName.trim(),
        profileImage: _profilePhoto!,
        email: _email.trim().toLowerCase(),
        password: _password,
        phone: _phone,
        cnpCode: _cnpCode.trim(),
        licenseFrontImage: _licenseFrontImage!,
        licenseBackImage: _licenseBackImage!,
        specialty: _specialty.trim(),
        masterDegree:
            _masterDegree.trim().isNotEmpty ? _masterDegree.trim() : null,
        otherSpecialty:
            _otherSpecialty.trim().isNotEmpty ? _otherSpecialty.trim() : null,
        location: _location.trim(),
        address: _address.trim(),
        acceptTerms: termsAccepted,
      );

      debugPrint('=== RESULTADO DEL REGISTRO ===');
      debugPrint('Registro exitoso: $success');
      debugPrint('Usuario autenticado: ${authProvider.isAuthenticated}');
      debugPrint(
          'Verificación pendiente: ${authProvider.isVerificationPending}');
      debugPrint('Error del provider: ${authProvider.errorMessage}');

      if (!success) {
        // ❌ Error en el registro
        String errorMsg = authProvider.errorMessage ??
            'Error durante el registro. Por favor, intenta nuevamente.';
        debugPrint('❌ ERROR EN REGISTRO: $errorMsg');
        _showValidationError(errorMsg);
        return;
      }

      // ✅ Registro exitoso - ahora determinar el flujo
      debugPrint('✅ REGISTRO EXITOSO - Determinando flujo...');

      // CASO 1: Usuario ya está completamente autenticado (sin necesidad de verificación)
      if (authProvider.isAuthenticated && !authProvider.isVerificationPending) {
        debugPrint('🎉 USUARIO COMPLETAMENTE AUTENTICADO');
        _showSuccessMessage('¡Registro completado exitosamente!');

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
        return;
      }

      // CASO 2: Usuario registrado pero necesita verificación
      if (authProvider.isVerificationPending) {
        debugPrint('📧 USUARIO NECESITA VERIFICACIÓN');

        // Determinar destino para mostrar en el mensaje
        String destination;
        String methodText;

        if (_selectedVerificationMethod == VerificationMethod.sms) {
          destination = _phone;
          methodText = 'SMS';
          debugPrint('📱 Código enviado por SMS a: $destination');
        } else {
          destination = _email.trim().toLowerCase();
          methodText = 'correo electrónico';
          debugPrint('📧 Código enviado por email a: $destination');
        }

        // ✅ CAMBIO PRINCIPAL: NO llamar sendVerificationCode aquí
        // porque el backend ya envió el código durante el registro
        debugPrint('=== CÓDIGO YA ENVIADO POR EL BACKEND ===');

        // Mostrar mensaje de éxito
        _showSuccessMessage(
            '¡Registro exitoso! Te hemos enviado un código de verificación por $methodText a $destination');

        // ✅ NAVEGAR DIRECTAMENTE A PANTALLA DE VERIFICACIÓN
        if (mounted) {
          debugPrint('🚀 NAVEGANDO A CodeVerificationScreen');
          debugPrint('Email: ${_email.trim().toLowerCase()}');
          debugPrint('Phone: $_phone');
          debugPrint('Method: ${_selectedVerificationMethod.name}');

          // Usar pushReplacement para reemplazar toda la pila de navegación
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CodeVerificationScreen(
                email: _email.trim().toLowerCase(),
                phone: _phone,
                verificationMethod: _selectedVerificationMethod,
              ),
            ),
          );
        }
        return;
      }

      // CASO 3: Estado inesperado
      debugPrint('⚠️ ESTADO INESPERADO DESPUÉS DEL REGISTRO');
      debugPrint('isAuthenticated: ${authProvider.isAuthenticated}');
      debugPrint(
          'isVerificationPending: ${authProvider.isVerificationPending}');
      _showValidationError(
          'Estado inesperado después del registro. Por favor, contacta soporte.');
    } catch (e, stackTrace) {
      debugPrint('=== EXCEPCIÓN DURANTE EL REGISTRO ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      _showValidationError('Error durante el registro: ${e.toString()}');
    }
  }*/

  Future<void> _proceedWithRegistrationDirectly() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Validación de tamaño de archivos
      if (_profilePhoto != null) {
        final profileSize = await _profilePhoto!.length();
        if (profileSize > 10 * 1024 * 1024) {
          _showValidationError('La foto de perfil es muy grande. Máximo 10MB.');
          return;
        }
      }

      if (_licenseFrontImage != null) {
        final frontSize = await _licenseFrontImage!.length();
        if (frontSize > 10 * 1024 * 1024) {
          _showValidationError('La foto frontal del CNP es muy grande. Máximo 10MB.');
          return;
        }
      }

      if (_licenseBackImage != null) {
        final backSize = await _licenseBackImage!.length();
        if (backSize > 10 * 1024 * 1024) {
          _showValidationError('La foto trasera del CNP es muy grande. Máximo 10MB.');
          return;
        }
      }

      debugPrint('=== INICIANDO REGISTRO AUTOMÁTICO CON EMAIL ===');
      debugPrint('Email: ${_email.trim().toLowerCase()}');
      debugPrint('Teléfono: $_phone');

      // Obtener términos aceptados
      bool termsAccepted = _locationKey.currentState?.termsAccepted ?? false;
      debugPrint('Términos aceptados: $termsAccepted');

      if (!termsAccepted) {
        _showValidationError('Debes aceptar los términos y condiciones');
        return;
      }

      // Registrar usuario
      final success = await authProvider.register(
        firstName: _firstName.trim(),
        lastName: _lastName.trim(),
        profileImage: _profilePhoto!,
        email: _email.trim().toLowerCase(),
        password: _password,
        phone: _phone,
        cnpCode: _cnpCode.trim(),
        licenseFrontImage: _licenseFrontImage!,
        licenseBackImage: _licenseBackImage!,
        specialty: _specialty.trim(),
        masterDegree: _masterDegree.trim().isNotEmpty ? _masterDegree.trim() : null,
        otherSpecialty: _otherSpecialty.trim().isNotEmpty ? _otherSpecialty.trim() : null,
        location: _location.trim(),
        address: _address.trim(),
        acceptTerms: termsAccepted,
      );

      debugPrint('=== RESULTADO DEL REGISTRO ===');
      debugPrint('Registro exitoso: $success');

      if (!success) {
        String errorMsg = authProvider.errorMessage ?? 'Error durante el registro. Por favor, intenta nuevamente.';
        debugPrint('❌ ERROR EN REGISTRO: $errorMsg');
        _showValidationError(errorMsg);
        return;
      }

      // Registro exitoso
      debugPrint('✅ REGISTRO EXITOSO - Navegando a verificación por email');

      // Si el usuario ya está completamente autenticado
      if (authProvider.isAuthenticated && !authProvider.isVerificationPending) {
        debugPrint('🎉 USUARIO COMPLETAMENTE AUTENTICADO');
        _showSuccessMessage('¡Registro completado exitosamente!');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
        return;
      }

      // Si necesita verificación (caso más común)
      if (authProvider.isVerificationPending) {
        debugPrint('📧 ENVIANDO CÓDIGO DE VERIFICACIÓN POR EMAIL');

        _showSuccessMessage('¡Registro exitoso! Te hemos enviado un código de verificación a tu email: ${_email.trim().toLowerCase()}');

        // Navegar a pantalla de verificación con método email
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CodeVerificationScreen(
                email: _email.trim().toLowerCase(),
                phone: _phone,
                verificationMethod: VerificationMethod.email, // Siempre email
              ),
            ),
          );
        }
        return;
      }

      // Estado inesperado
      debugPrint('⚠️ ESTADO INESPERADO DESPUÉS DEL REGISTRO');
      _showValidationError('Estado inesperado después del registro. Por favor, contacta soporte.');

    } catch (e, stackTrace) {
      debugPrint('=== EXCEPCIÓN DURANTE EL REGISTRO ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      _showValidationError('Error durante el registro: ${e.toString()}');
    }
  }


  /*Widget _buildLastStepNavigationBar() {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_verificationMethodSelected) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _verificationMethod == VerificationMethod.email
                          ? Icons.email_rounded
                          : Icons.sms_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _verificationMethod == VerificationMethod.email
                                ? 'Verificación por Email'
                                : 'Verificación por SMS',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _verificationMethod == VerificationMethod.email
                                ? _email
                                : _phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () {
                              _showVerificationMethodModal();
                            },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Botón principal
            GestureDetector(
              onTap: (_canProceedToNext && !isLoading)
                  ? (_verificationMethodSelected
                      ? _proceedWithRegistration
                      : _showVerificationMethodModal)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 50,
                decoration: BoxDecoration(
                  gradient: (_canProceedToNext && !isLoading)
                      ? LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            Colors.grey[400]!,
                            Colors.grey[300]!,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading) ...[
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _verificationMethodSelected
                              ? Icons.person_add_rounded
                              : Icons.security_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      isLoading
                          ? 'Creando tu cuenta...'
                          : (_verificationMethodSelected
                              ? 'Crear mi cuenta'
                              : 'Seleccionar verificación'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }*/

  Widget _buildLastStepNavigationBar() {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Información de verificación por email (siempre visible)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verificación por Email',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _email.isNotEmpty ? _email : 'Tu email registrado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Botón crear cuenta
            GestureDetector(
              onTap: (_canProceedToNext && !isLoading) ? _handleRegistration : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 50,
                decoration: BoxDecoration(
                  gradient: (_canProceedToNext && !isLoading)
                      ? LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : LinearGradient(
                    colors: [
                      Colors.grey[400]!,
                      Colors.grey[300]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading) ...[
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      isLoading ? 'Creando tu cuenta...' : 'Crear mi cuenta',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.backgroundLigth,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Contador de páginas
            Text(
              '${_currentStep + 1} de $totalPages',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),

            // Barra de progreso
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.backgroundtInput.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_currentStep + 1) / totalPages,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Botón de retroceso
            if (_currentStep > 0) ...[
              GestureDetector(
                onTap: isLoading ? null : _previousPage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isLoading
                        ? AppColors.secondary.withOpacity(0.5)
                        : AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Botón siguiente
            GestureDetector(
              onTap: (_canProceedToNext && !isLoading) ? _nextPage : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: (_canProceedToNext && !isLoading)
                      ? AppColors.primary
                      : AppColors.textInput.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: (_canProceedToNext && !isLoading)
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isLoading ? 'Cargando...' : 'Siguiente',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isLoading) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            PersonalInfoScreen(
                              key: _personalInfoKey,
                              initialPhoto: _profilePhoto,
                              initialNombre: _firstName,
                              initialApellido: _lastName,
                              onDataChanged: _onPersonalInfoChanged,
                            ),
                            EmailPasswordScreen(
                              key: _emailPasswordKey,
                              initialEmail: _email,
                              initialPassword: _password,
                              initialConfirmPassword: _confirmPassword,
                              initialPhone: _phone,
                              onDataChanged: _onEmailPasswordChanged,
                            ),
                            ColegiaturaVerificationScreen(
                              key: _colegiaturaKey,
                              nombre: _firstName,
                              apellido: _lastName,
                              email: _email,
                              contrasena: _password,
                              onValidationComplete: _onColegiaturaValidated,
                              onVerificationStart: _onVerificationStart,
                              onCnpValidated: _onCnpValidated,
                            ),
                            SpecialtyScreen(
                              key: _specialtyKey,
                              nombre: _firstName,
                              apellido: _lastName,
                              email: _email,
                              contrasena: _password,
                              codeCNP: _cnpCode,
                              licenseFrontImage: _licenseFrontImage,
                              licenseBackImage: _licenseBackImage,
                              initialEspecialidad: _specialty,
                              initialMaestria: _masterDegree,
                              initialOther: _otherSpecialty,
                              onDataChanged: _onSpecialtyChanged,
                            ),
                            LocationSelectorScreen(
                              key: _locationKey,
                              nombre: _firstName,
                              apellido: _lastName,
                              email: _email,
                              contrasena: _password,
                              codeCNP: _cnpCode,
                              licenseFrontImage: _licenseFrontImage,
                              licenseBackImage: _licenseBackImage,
                              especialidad: _specialty,
                              maestria: _masterDegree,
                              other: _otherSpecialty,
                              initialUbicacion: _location,
                              initialDireccion: _address,
                              onDataChanged: _onLocationChanged,
                              //onVerificationMethodChanged: _onVerificationMethodChanged,
                            ),
                          ],
                        ),
                      ),
                      // Mostrar navegación diferente en la última pantalla
                      _currentStep == totalPages - 1
                          ? _buildLastStepNavigationBar()
                          : _buildNavigationBar(),
                    ],
                  ),

                  // Loading overlay durante el registro
                  if (authProvider.isLoading) _buildLoadingOverlay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
