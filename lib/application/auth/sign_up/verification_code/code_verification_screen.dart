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
  bool _showMaskedContact = false;

  // Timer para reenvío
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

  // Timer para mostrar contacto oculto
  Timer? _contactDisplayTimer;

  // Animaciones
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _initializeAnimations();
    _startContactDisplayTimer();
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

  void _startContactDisplayTimer() {
    // Mostrar el contacto completo por 3 segundos, luego ocultarlo
    _contactDisplayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showMaskedContact = true;
        });
      }
    });
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
    _contactDisplayTimer?.cancel();
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

  String _maskContact(String contact) {
    if (widget.verificationMethod == VerificationMethod.email) {
      // Ocultar email: ejemplo@gmail.com -> e****@gmail.com
      final parts = contact.split('@');
      if (parts.length == 2) {
        final username = parts[0];
        final domain = parts[1];
        if (username.length > 2) {
          return '${username[0]}${'*' * (username.length - 1)}@$domain';
        }
      }
    } else {
      // Ocultar teléfono: +51987654321 -> +51***654321
      if (contact.length > 6) {
        final start = contact.substring(0, 3);
        final end = contact.substring(contact.length - 3);
        return '$start${'*' * (contact.length - 6)}$end';
      }
    }
    return contact;
  }

  Future<void> _verifyCode() async {
    if (!_isCodeComplete) {
      SnackBarManager.showWarning(context, 'Por favor, ingresa el código completo de 6 dígitos');
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

      // Verificación adicional por mensaje si success es false
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

        // Esperar para mostrar el mensaje
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
                  (route) => false,
              arguments: {
                'message': 'Tu cuenta ha sido verificada exitosamente. ¡Ya puedes iniciar sesión!',
                'email': widget.email,
              }
          );
        }
      } else {
        String errorMessage = _getErrorMessage(message);
        SnackBarManager.showError(context, errorMessage);
        _shakeFields();
        _clearCode();
      }
    } catch (e) {
      SnackBarManager.showError(context, 'Error de conexión. Por favor, verifica tu internet e inténtalo nuevamente');
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
        return '¡Excelente! Tu cuenta ha sido verificada completamente';
      } else if (emailVerified) {
        return '¡Perfecto! Tu dirección de correo ha sido verificada exitosamente';
      } else if (phoneVerified) {
        return '¡Genial! Tu número de teléfono ha sido verificado exitosamente';
      }
    }
    return '¡Verificación completada! Tu cuenta está lista para usar';
  }

  String _getErrorMessage(String? message) {
    if (message == null) return 'Código de verificación incorrecto. Por favor, verifica los dígitos e inténtalo nuevamente';

    String lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('expired') || lowerMessage.contains('expirado') || lowerMessage.contains('caducado')) {
      return 'El código de verificación ha expirado. Por favor, solicita un nuevo código';
    } else if (lowerMessage.contains('invalid') || lowerMessage.contains('inválido') || lowerMessage.contains('incorrecto')) {
      return 'Código de verificación inválido. Por favor, revisa los dígitos ingresados';
    } else if (lowerMessage.contains('attempts') || lowerMessage.contains('intentos') || lowerMessage.contains('bloqueado')) {
      return 'Has excedido el límite de intentos. Por favor, espera unos minutos antes de intentar nuevamente';
    } else if (lowerMessage.contains('network') || lowerMessage.contains('conexión') || lowerMessage.contains('internet')) {
      return 'Error de conexión. Por favor, verifica tu conexión a internet';
    } else if (lowerMessage.contains('server') || lowerMessage.contains('servidor') || lowerMessage.contains('servicio')) {
      return 'Servicio temporalmente no disponible. Por favor, inténtalo más tarde';
    }

    return 'Código de verificación incorrecto. Por favor, verifica los dígitos e inténtalo nuevamente';
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
        SnackBarManager.showSuccess(context, 'Nuevo código de verificación enviado exitosamente');
        _clearCode();
        _startResendTimer();
        // Reiniciar el timer del contacto cuando se reenvía
        setState(() {
          _showMaskedContact = false;
        });
        _startContactDisplayTimer();
      } else {
        String errorMsg = authProvider.errorMessage ?? 'No se pudo enviar el código de verificación. Por favor, inténtalo más tarde';
        SnackBarManager.showError(context, errorMsg);
      }
    } catch (e) {
      SnackBarManager.showError(context, 'Error al enviar el código. Por favor, verifica tu conexión e inténtalo más tarde');
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
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Descripción con contacto que se oculta
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _getVerificationMessage(),
                  key: ValueKey(_showMaskedContact),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
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
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
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
        return 'correo electrónico';
      case VerificationMethod.sms:
        return 'número de teléfono';
      case VerificationMethod.whatsapp:
        return 'WhatsApp';
    }
  }

  String _getVerificationMessage() {
    final contact = widget.verificationMethod == VerificationMethod.email
        ? widget.email
        : widget.phone;

    final displayContact = _showMaskedContact ? _maskContact(contact) : contact;

    switch (widget.verificationMethod) {
      case VerificationMethod.email:
        return 'Hemos enviado un código de verificación de 6 dígitos a:\n\n$displayContact\n\nPor favor, revisa tu bandeja de entrada y carpeta de spam';
      case VerificationMethod.sms:
        return 'Hemos enviado un código de verificación de 6 dígitos por SMS al número:\n\n$displayContact\n\nEl mensaje puede tardar unos minutos en llegar';
      case VerificationMethod.whatsapp:
        return 'Hemos enviado un código de verificación de 6 dígitos por WhatsApp al número:\n\n$displayContact\n\nRevisa tus mensajes de WhatsApp';
    }
  }

  String _getHelpMessage() {
    switch (widget.verificationMethod) {
      case VerificationMethod.email:
        return '• Verifica tu carpeta de spam o correo no deseado\n• El código tiene una validez de 10 minutos\n• Asegúrate de tener una conexión estable a internet\n• Si no lo encuentras, solicita un nuevo código';
      case VerificationMethod.sms:
        return '• Verifica que tu dispositivo tenga buena señal de red\n• El código tiene una validez de 10 minutos\n• Los mensajes pueden tardar hasta 5 minutos en llegar\n• Reinicia tu teléfono si no llega el mensaje';
      case VerificationMethod.whatsapp:
        return '• Asegúrate de tener WhatsApp instalado y actualizado\n• El código tiene una validez de 10 minutos\n• Revisa los mensajes de WhatsApp Business\n• Verifica tu conexión a internet';
    }
  }
}