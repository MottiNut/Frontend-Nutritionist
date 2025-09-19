import 'package:flutter/material.dart';
import 'package:mottinutnutriotinist/configuration/themes/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../../domain/services/auth_provider.dart';
import 'dart:async';
import '../../../requestSnacbar/snackBar_manager.dart';

class CodeVerificationScreen extends StatefulWidget {
  final String email;
  final String phone;
  final VerificationMethod verificationMethod;

  const CodeVerificationScreen({
    Key? key,
    required this.email,
    required this.phone,
    required this.verificationMethod,
  }) : super(key: key);

  @override
  State<CodeVerificationScreen> createState() => _CodeVerificationScreenState();
}

class _CodeVerificationScreenState extends State<CodeVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;

  // Timer para reenvío
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

  // Animaciones
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  int _attempts = 0;
  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _shakeController.dispose();

    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _verificationCode {
    return _controllers.map((controller) => controller.text).join();
  }

  bool get _isCodeComplete {
    return _verificationCode.length == 6;
  }

  Future<void> _verifyCode() async {
    if (!_isCodeComplete) {
      SnackBarManager.showWarning(context, 'Completa todos los dígitos del código');
      _shakeFields();
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final verificationResult = await authProvider.verifyCode(_verificationCode);

      bool isSuccess = verificationResult['success'] == true;
      String? message = verificationResult['message'];

      if (!isSuccess && message != null) {
        String lowerMessage = message.toLowerCase();
        if (lowerMessage.contains('verificado exitosamente') ||
            lowerMessage.contains('email verificado') ||
            lowerMessage.contains('verificado correctamente') ||
            lowerMessage.contains('verification successful')) {
          isSuccess = true;
        }
      }

      if (isSuccess) {
        final verificationStatus = verificationResult['verificationStatus'];
        String successMessage = _getSuccessMessage(verificationStatus);

        SnackBarManager.showSuccess(context, successMessage);

        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
                  (route) => false,
              arguments: {
                'message': 'Tu cuenta ha sido verificada. ¡Ya puedes iniciar sesión!',
                'email': widget.email,
              }
          );
        }
      } else {
        _attempts++; // incremento de intentos
        if (_attempts >= 3) {
          SnackBarManager.showError(context, 'Has excedido 3 intentos. La pantalla se cerrará.');
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) Navigator.of(context).pop(); // cierra la pantalla
          });
        } else {
          String errorMessage = _getErrorMessage(message);
          SnackBarManager.showError(context, '$errorMessage\nIntento $_attempts de 3');
          _shakeFields();
          _clearCode();
        }
      }
    } catch (e) {
      SnackBarManager.showError(context, 'Algo salió mal. Inténtalo de nuevo');
      _shakeFields();
      _clearCode();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getSuccessMessage(Map<String, dynamic>? verificationStatus) {
    if (verificationStatus != null) {
      final emailVerified = verificationStatus['emailVerified'] ?? false;
      final phoneVerified = verificationStatus['phoneVerified'] ?? false;

      if (emailVerified && phoneVerified) {
        return '¡Perfecto! Tu cuenta está completamente verificada';
      } else if (emailVerified) {
        return '¡Excelente! Tu email ha sido verificado';
      } else if (phoneVerified) {
        return '¡Genial! Tu teléfono ha sido verificado';
      }
    }
    return '¡Verificación exitosa! Ya puedes continuar';
  }

  String _getErrorMessage(String? message) {
    if (message == null) return 'Código incorrecto. Inténtalo de nuevo';

    String lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('expired') || lowerMessage.contains('expirado')) {
      return 'El código ha expirado. Solicita uno nuevo';
    } else if (lowerMessage.contains('invalid') || lowerMessage.contains('inválido')) {
      return 'El código no es válido. Revisa los dígitos';
    } else if (lowerMessage.contains('attempts') || lowerMessage.contains('intentos')) {
      return 'Demasiados intentos. Espera un momento';
    }

    return 'Código incorrecto. Inténtalo de nuevo';
  }

  void _shakeFields() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  Future<void> _resendCode() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.sendVerificationCode(
        method: widget.verificationMethod,
        phoneNumber: widget.verificationMethod != VerificationMethod.email ? widget.phone : null,
      );

      if (success) {
        SnackBarManager.showSuccess(context, 'Nuevo código enviado correctamente');
        _clearCode();
        _startResendTimer();
      } else {
        String errorMsg = authProvider.errorMessage ?? 'No pudimos enviar el código';
        SnackBarManager.showError(context, errorMsg);
      }
    } catch (e) {
      SnackBarManager.showError(context, 'Error al enviar el código. Inténtalo más tarde');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _clearCode() {
    for (var controller in _controllers) {
      controller.clear();
    }
    if (mounted && _focusNodes[0].canRequestFocus) {
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Icono animado
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,

                      ),
                      child: Icon(
                        _getVerificationIcon(),
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 6),

              // Título
              Text(
                'Verifica tu ${_getVerificationTypeText()}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Descripción
              Text(
                _getVerificationMessage(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Campos de código con animación
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 50,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _controllers[index].text.isNotEmpty
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            color: _controllers[index].text.isNotEmpty
                                ? Theme.of(context).primaryColor.withOpacity(0.05)
                                : Colors.white,
                          ),
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500, // Cambiado de bold a w500
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8), // Padding interno
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                if (index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                } else {
                                  _focusNodes[index].unfocus();
                                  if (_isCodeComplete && !_isLoading) {
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      _verifyCode();
                                    });
                                  }
                                }
                              } else if (value.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Botón verificar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || !_isCodeComplete ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Verificar código',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Contador y botón reenviar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No recibiste el código? ',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (_canResend)
                    GestureDetector(
                      onTap: _isResending ? null : _resendCode,
                      child: Text(
                        _isResending ? 'Enviando...' : 'Reenviar',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Reenviar en ${_resendCountdown}s',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 40),

              // Consejos
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Consejos útiles',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getHelpMessage(),
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.8),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getVerificationIcon() {
    switch (widget.verificationMethod) {
      case VerificationMethod.email:
        return Icons.email_outlined;
      case VerificationMethod.sms:
        return Icons.sms_outlined;
      case VerificationMethod.whatsapp:
        return Icons.chat_outlined;
    }
  }

  String _getVerificationTypeText() {
    switch (widget.verificationMethod) {
      case VerificationMethod.email:
        return 'email';
      case VerificationMethod.sms:
        return 'teléfono';
      case VerificationMethod.whatsapp:
        return 'WhatsApp';
    }
  }

  String _getVerificationMessage() {
    final contact = widget.verificationMethod == VerificationMethod.email
        ? _getMaskedEmail(widget.email)
        : widget.phone;

    switch (widget.verificationMethod) {
      case VerificationMethod.email:
        return 'Te enviamos un código de 6 dígitos a\n$contact\n\nRevisa tu bandeja de entrada';
      case VerificationMethod.sms:
        return 'Te enviamos un código de 6 dígitos por SMS a\n$contact';
      case VerificationMethod.whatsapp:
        return 'Te enviamos un código de 6 dígitos por WhatsApp a\n$contact';
    }
  }

  String _getHelpMessage() {
    switch (widget.verificationMethod) {
      case VerificationMethod.email:
        return '• Revisa tu carpeta de spam o correo no deseado\n• El código es válido por 10 minutos\n• Asegúrate de tener conexión a internet';
      case VerificationMethod.sms:
        return '• Verifica que tu teléfono tenga señal\n• El código es válido por 10 minutos\n• Puede tardar unos minutos en llegar';
      case VerificationMethod.whatsapp:
        return '• Asegúrate de tener WhatsApp instalado\n• El código es válido por 10 minutos\n• Revisa los mensajes de WhatsApp Business';
    }
  }

  String _getMaskedEmail(String email) {
    if (email.isEmpty) return '';
    int visibleChars = 3;
    int atIndex = email.indexOf('@');
    if (atIndex <= visibleChars) {
      visibleChars = atIndex;
    }
    String masked = email.substring(0, visibleChars) + '*******';
    String domain = email.substring(atIndex);
    return masked + domain;
  }

}