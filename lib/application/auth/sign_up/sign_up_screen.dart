import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mottinutnutriotinist/application/auth/registration/registration_bloc.dart';
import 'package:mottinutnutriotinist/application/auth/registration/registration_event.dart';
import 'package:mottinutnutriotinist/application/auth/registration/registration_state.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/colegiatura_verification_screen.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/email_password_screen.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/personal_info_screen.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/specialty_screen.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/work_screen.dart';
import '../../../configuration/themes/app_colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late PageController _pageController;
  static const int totalPages = 5;

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
    context.read<RegistrationBloc>().add(
      PersonalInfoSubmitted(
        firstName: nombre,
        lastName: apellido,
        photo: photo,
      ),
    );
  }

  void _onEmailPasswordChanged(String email, String password, String confirmPassword) {
    context.read<RegistrationBloc>().add(
      EmailPasswordSubmitted(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      ),
    );
  }

  void _onColegiaturaValidated(String codeCNP, List<File> photoCNP, bool termsAccepted) {
    context.read<RegistrationBloc>().add(
      ColegiaturaSubmitted(
        cnpCode: codeCNP,
        cnpPhotos: photoCNP,
        termsAccepted: termsAccepted,
      ),
    );

    debugPrint('Datos de colegiatura guardados:');
    debugPrint('Código CNP: $codeCNP');
    debugPrint('Fotos CNP: ${photoCNP.length}');
    debugPrint('Términos aceptados: $termsAccepted');
  }

  void _onSpecialtyChanged(String especialidad, String maestria, String other) {
    context.read<RegistrationBloc>().add(
      SpecialtySubmitted(
        specialty: especialidad,
        masterDegree: maestria,
        otherSpecialty: other,
      ),
    );
  }

  void _onLocationChanged(String ubicacion, String direccion) {
    context.read<RegistrationBloc>().add(
      LocationSubmitted(
        location: ubicacion,
        address: direccion,
      ),
    );
  }

  // ========== CALLBACKS DE VERIFICACIÓN ==========

  void _onVerificationStart() {
    // El loading se maneja a través del BLoC state
    debugPrint('Iniciando verificación...');
  }

  void _onVerificationSuccess() {
    // El success se maneja a través del BLoC state
    debugPrint('Verificación exitosa');
  }

  void _nextPage(RegistrationState state) {
    final currentStep = state.currentStep;

    switch (currentStep) {
      case 0:
        _validateAndProceed(
            state.isPersonalInfoValid,
            'Por favor, completa la información personal'
        );
        break;
      case 1:
        _validateAndProceed(
            state.isEmailPasswordValid && !state.emailExists,
            state.emailExists
                ? 'Este email ya está registrado'
                : 'Por favor, completa el email y contraseña'
        );
        break;
      case 2:
      // DEBUGGING: Agrega estos logs para ver el estado
        debugPrint('=== DEBUG COLEGIATURA ===');
        debugPrint('isColegiaturaValid: ${state.isColegiaturaValid}');
        debugPrint('cnpIsValid: ${state.cnpIsValid}');
        debugPrint('cnpVerificationInProgress: ${state.cnpVerificationInProgress}');
        debugPrint('cnpCode: ${state.cnpCode}');
        debugPrint('cnpPhotos length: ${state.cnpPhotos.length}');
        debugPrint('termsAccepted: ${state.termsAccepted}');
        debugPrint('========================');

        // Verificar si está en progreso la verificación
        if (state.cnpVerificationInProgress) {
          _showValidationError('Verificando código CNP, por favor espera...');
          return;
        }

        // Verificar validación completa
        if (state.isColegiaturaValid && state.cnpIsValid) {
          _animateToNextPage(currentStep);
        } else {
          _showValidationError(_getColegiaturaValidationMessage(state));
        }
        break;
      case 3:
        _validateAndProceed(
            state.isSpecialtyValid,
            'Por favor, completa la información de especialidad'
        );
        break;
      case 4:
        _handleRegistration();
        break;
      default:
        _animateToNextPage(currentStep);
    }
  }

  void _validateAndProceed(bool isValid, String errorMessage) {
    if (isValid) {
      final currentStep = context.read<RegistrationBloc>().state.currentStep;
      _animateToNextPage(currentStep);
    } else {
      _showValidationError(errorMessage);
    }
  }

  void _animateToNextPage(int currentStep) {
    if (currentStep < totalPages - 1) {
      final nextStep = currentStep + 1;
      context.read<RegistrationBloc>().add(StepChanged(nextStep));

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage(int currentStep) {
    if (currentStep > 0) {
      final previousStep = currentStep - 1;
      context.read<RegistrationBloc>().add(StepChanged(previousStep));

      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // CORREGIDO: Manejo del botón de retroceso del sistema
  Future<bool> _onWillPop() async {
    final currentStep = context.read<RegistrationBloc>().state.currentStep;

    // Si estamos en el primer paso, ir al login en lugar de cerrar la app
    if (currentStep == 0) {
      Navigator.of(context).pushReplacementNamed('/login');
      return false; // No permitir el pop normal
    }

    // Si no estamos en el primer paso, retroceder al paso anterior
    _previousPage(currentStep);
    return false; // No permitir el pop normal, manejamos la navegación nosotros
  }

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  String _getColegiaturaValidationMessage(RegistrationState state) {
    if (state.cnpVerificationInProgress) {
      return 'Verificando código CNP...';
    }

    if (!state.isColegiaturaValid) {
      // Verificar qué específicamente falta
      if (state.cnpCode.trim().isEmpty) {
        return 'Por favor, ingresa el código CNP';
      }
      if (state.cnpPhotos.isEmpty) {
        return 'Por favor, adjunta las fotos del CNP';
      }
      if (!state.termsAccepted) {
        return 'Por favor, acepta los términos y condiciones';
      }
      return 'Por favor, completa la información de colegiatura';
    }

    if (!state.cnpIsValid) {
      return 'El código CNP ingresado no es válido';
    }

    return 'Error en la validación de colegiatura';
  }

  // ========== REGISTRO FINAL ==========

  void _handleRegistration() {
    context.read<RegistrationBloc>().add(const FinalRegistrationSubmitted());
  }

  void _handleRegistrationSuccess(RegistrationState state) {
    _showSuccessMessage(state.successMessage ?? '¡Registro completado exitosamente!');

    // Navegar al login o dashboard después de un breve delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  void _handleRegistrationError(RegistrationState state) {
    _showValidationError(state.errorMessage ?? 'Error en el registro');
  }

  // ========== UI WIDGETS ==========

  Widget _buildNavigationBar(RegistrationState state) {
    final currentStep = state.currentStep;
    final canProceed = state.canProceedToNext;
    final isLoading = state.isLoading;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
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
              '${currentStep + 1} de $totalPages',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
                  widthFactor: (currentStep + 1) / totalPages,
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
            if (currentStep > 0) ...[
              GestureDetector(
                onTap: isLoading ? null : () => _previousPage(currentStep),
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

            // Botón siguiente/registrar
            GestureDetector(
              onTap: (canProceed && !isLoading) ? () => _nextPage(state) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: (canProceed && !isLoading)
                      ? AppColors.primary
                      : AppColors.textInput.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: (canProceed && !isLoading)
                      ? [BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )]
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _getButtonText(currentStep, isLoading),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isLoading) ...[
                      const SizedBox(width: 8),
                      Icon(
                        currentStep == totalPages - 1
                            ? Icons.check
                            : Icons.arrow_forward_ios,
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

  String _getButtonText(int currentStep, bool isLoading) {
    if (isLoading) {
      return currentStep == totalPages - 1 ? 'Registrando...' : 'Cargando...';
    }
    return currentStep == totalPages - 1 ? 'Registrarme' : 'Siguiente';
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Procesando registro...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegistrationBloc, RegistrationState>(
      listener: (context, state) {
        if (state.isSuccess) {
          _handleRegistrationSuccess(state);
        } else if (state.isFailure) {
          _handleRegistrationError(state);
        }
      },
      builder: (context, state) {
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            // CORREGIDO: Usar SafeArea para evitar que el contenido se esconda
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
                              initialPhoto: state.photo,
                              initialNombre: state.firstName,
                              initialApellido: state.lastName,
                              onDataChanged: _onPersonalInfoChanged,
                            ),
                            EmailPasswordScreen(
                              key: _emailPasswordKey,
                              initialEmail: state.email,
                              initialPassword: state.password,
                              initialConfirmPassword: state.confirmPassword,
                              onDataChanged: _onEmailPasswordChanged,
                            ),
                            ColegiaturaVerificationScreen(
                              key: _colegiaturaKey,
                              nombre: state.firstName,
                              apellido: state.lastName,
                              email: state.email,
                              contrasena: state.password,
                              onValidationComplete: _onColegiaturaValidated,
                              onVerificationStart: _onVerificationStart,
                              onVerificationSuccess: _onVerificationSuccess,
                            ),
                            SpecialtyScreen(
                              key: _specialtyKey,
                              nombre: state.firstName,
                              apellido: state.lastName,
                              email: state.email,
                              contrasena: state.password,
                              codeCNP: state.cnpCode,
                              photoCNP: state.cnpPhotos.isNotEmpty
                                  ? state.cnpPhotos.first.path
                                  : '',
                              initialEspecialidad: state.specialty,
                              initialMaestria: state.masterDegree ?? '',
                              initialOther: state.otherSpecialty ?? '',
                              onDataChanged: _onSpecialtyChanged,
                            ),
                            LocationSelectorScreen(
                              key: _locationKey,
                              nombre: state.firstName,
                              apellido: state.lastName,
                              email: state.email,
                              contrasena: state.password,
                              codeCNP: state.cnpCode,
                              photoCNP: state.cnpPhotos.isNotEmpty
                                  ? state.cnpPhotos.first.path
                                  : '',
                              especialidad: state.specialty,
                              maestria: state.masterDegree ?? '',
                              other: state.otherSpecialty ?? '',
                              initialUbicacion: state.location,
                              initialDireccion: state.address,
                              onDataChanged: _onLocationChanged,
                            ),
                          ],
                        ),
                      ),
                      _buildNavigationBar(state),
                    ],
                  ),

                  // Loading overlay durante el registro
                  if (state.isLoading) _buildLoadingOverlay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}