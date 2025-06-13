import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

import '../../../configuration/providers/color_dar_light_app.dart';
import '../../../configuration/themes/app_colors.dart';
import '../../../domain/services/auth_provider.dart';


class CodeVerificationScreen extends StatefulWidget {
  final String email;
  CodeVerificationScreen({required this.email});

  @override
  _CodeVerificationScreenState createState() => _CodeVerificationScreenState();
}

class _CodeVerificationScreenState extends State<CodeVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeControllers = List.generate(6, (index) => TextEditingController());
  List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  int failedAttempts = 0;
  final int maxAttempts = 5;
  bool _isVerifying = false;
  bool _isValidating = false; // Nueva variable para validación en tiempo real

  // Timer variables
  Timer? _timer;
  Timer? _validationTimer; // Timer para validación retardada
  int _remainingTime = 60;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        _showTimeoutDialog();
      }
    });
  }

  String get _timeDisplay {
    int minutes = _remainingTime ~/ 60;
    int seconds = _remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Método para verificar si un campo puede ser editado
  bool _canEditField(int index) {
    // Todos los campos se pueden editar mientras no esté validando
    if (_isValidating || _isVerifying) return false;

    // El primer campo siempre se puede editar
    if (index == 0) return true;

    // Los demás campos se pueden editar si el anterior tiene contenido
    if (index > 0 && _codeControllers[index - 1].text.isNotEmpty) {
      return true;
    }

    // O si el campo actual ya tiene contenido
    return _codeControllers[index].text.isNotEmpty;
  }

  // Método para obtener el siguiente campo disponible para editar
  int _getNextAvailableField() {
    for (int i = 0; i < 6; i++) {
      if (_canEditField(i) && _codeControllers[i].text.isEmpty) {
        return i;
      }
    }
    return -1; // No hay campos disponibles
  }

  // Validación automática con retraso
  void _scheduleValidation() {
    _validationTimer?.cancel();
    _validationTimer = Timer(Duration(milliseconds: 500), () {
      String completeCode = _codeControllers
          .map((controller) => controller.text)
          .join();

      if (completeCode.length == 6 && !_isVerifying) {
        _validateCodeRealTime(completeCode);
      }
    });
  }

  // Validación en tiempo real usando el AuthProvider real
  void _validateCodeRealTime(String code) async {
    if (_isValidating || _isVerifying) return;

    setState(() {
      _isValidating = true;
    });

    try {
      // Usamos el AuthProvider real para validar el código
      await Provider.of<AuthProvider>(context, listen: false)
          .verifyCode(widget.email, code);

      // Si llegamos aquí, la validación fue exitosa
      _handleSuccessfulValidation();

    } catch (e) {
      // Si hay error, manejamos la validación fallida
      _handleFailedValidation();
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  void _handleSuccessfulValidation() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    _showSuccessDialog();
  }

  void _handleFailedValidation() {
    HapticFeedback.heavyImpact();
    failedAttempts++;

    if (failedAttempts >= maxAttempts) {
      _showMaxAttemptsError();
    } else {
      _showValidationError();
      _clearFieldsWithAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkModeProvider = Provider.of<DarkModeProvider>(context, listen: false);
    final isDarkMode = darkModeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDarkMode),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    _buildSecurityIcon(isDarkMode),
                    SizedBox(height: 32),
                    _buildTitle(isDarkMode),
                    SizedBox(height: 12),
                    _buildSubtitle(),
                    SizedBox(height: 48),
                    _buildInputFields(isDarkMode),
                    SizedBox(height: 32),
                    _buildTimerWithLoader(isDarkMode),
                    SizedBox(height: 48),
                    _buildResendOptions(isDarkMode),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDarkMode) {
    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.iconPrimary,
              size: 24,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showHelpDialog(),
            icon: const Icon(
              Icons.help_outline,
              color: AppColors.iconPrimary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityIcon(bool isDarkMode) {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      ),
      child: Image.asset(
        'assets/image/security.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildTitle(bool isDarkMode) {
    final darkModeProvider = Provider.of<DarkModeProvider>(context, listen: false);
    final textColor = darkModeProvider.textColor;

    return Text(
      'Introduce el código de 6 dígitos',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    final darkModeProvider = Provider.of<DarkModeProvider>(context, listen: false);
    final textColor = darkModeProvider.textColor;

    return Column(
      children: [
        Text(
          'Tu código se envió a',
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          _maskEmailImproved(widget.email),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _maskEmailImproved(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final localPart = parts[0];
    final domainPart = parts[1];

    if (localPart.length <= 2) {
      return '${localPart}******@${domainPart}';
    }

    final visibleLocal = localPart.substring(0, 2);
    return '${visibleLocal}******@${domainPart}';
  }

  Widget _buildInputFields(bool isDarkMode) {
    return Form(
      key: _formKey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) {
          bool canEdit = _canEditField(index);
          bool hasContent = _codeControllers[index].text.isNotEmpty;
          bool isDisabled = _isVerifying || _isValidating;

          return GestureDetector(
            onTap: () {
              if (isDisabled) return;

              if (canEdit || hasContent) {
                _focusNodes[index].requestFocus();
              } else {
                // Si no puede editar, buscar el próximo campo disponible
                int nextAvailable = _getNextAvailableField();
                if (nextAvailable != -1) {
                  _focusNodes[nextAvailable].requestFocus();
                }
                HapticFeedback.lightImpact();
                _showFieldLockedFeedback();
              }
            },
            child: Container(
              width: 45,
              height: 55,
              child: TextFormField(
                controller: _codeControllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(1),
                  UpperCaseTextFormatter(),
                ],
                textAlign: TextAlign.center,
                enabled: !isDisabled && (canEdit || hasContent),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? Colors.white38
                      : (canEdit || hasContent)
                      ? Colors.white
                      : Colors.white24,
                  letterSpacing: 0,
                ),
                cursorWidth: 0,
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Colors.transparent,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: hasContent
                          ? AppColors.primary.withOpacity(0.5)
                          : (canEdit ? Colors.white24 : Colors.white12),
                      width: hasContent ? 2.5 : 2,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: _isValidating
                          ? Colors.orange
                          : AppColors.primary,
                      width: 3,
                    ),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.errorText,
                      width: 2,
                    ),
                  ),
                  disabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white12,
                      width: 1,
                    ),
                  ),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white24,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (isDisabled) return;

                  setState(() {}); // Actualizar UI para reflejar cambios

                  // Avanzar automáticamente al siguiente campo cuando se ingresa un carácter
                  if (value.length == 1) {
                    _animationController.forward(from: 0.0);

                    // Buscar el siguiente campo vacío disponible
                    for (int i = index + 1; i < 6; i++) {
                      if (_codeControllers[i].text.isEmpty) {
                        Future.delayed(Duration(milliseconds: 100), () {
                          if (mounted) {
                            _focusNodes[i].requestFocus();
                          }
                        });
                        break;
                      }
                    }
                  }
                  // Retroceder cuando se borra un carácter
                  else if (value.isEmpty && index > 0) {
                    // Buscar el campo anterior que tenga contenido o sea editable
                    for (int i = index - 1; i >= 0; i--) {
                      if (_canEditField(i)) {
                        Future.delayed(Duration(milliseconds: 50), () {
                          if (mounted) {
                            _focusNodes[i].requestFocus();
                          }
                        });
                        break;
                      }
                    }
                  }

                  // Programar validación automática cuando se complete el código
                  Future.delayed(Duration(milliseconds: 200), () {
                    if (mounted && _getCompleteCodeLength() == 6) {
                      FocusScope.of(context).unfocus();
                      _scheduleValidation();
                    }
                  });
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  int _getCompleteCodeLength() {
    return _codeControllers
        .map((controller) => controller.text)
        .join()
        .length;
  }

  void _showFieldLockedFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Completa los campos anteriores primero',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange.withOpacity(0.8),
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  // Widget mejorado del timer con indicador de carga
  Widget _buildTimerWithLoader(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: _remainingTime < 30
            ? AppColors.errorText.withOpacity(0.1)
            : AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _remainingTime < 30
              ? AppColors.errorText.withOpacity(0.3)
              : AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mostrar loader o icono de tiempo
          if (_isValidating)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.secondary,
                ),
              ),
            )
          else
            Icon(
              Icons.access_time,
              size: 18,
              color: _remainingTime < 30 ? AppColors.errorText : AppColors.primary,
            ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              _isValidating
                  ? 'Validando código...'
                  : 'Volver a enviar código ${_timeDisplay}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _isValidating
                    ? AppColors.secondary
                    : _remainingTime < 30
                    ? AppColors.errorText
                    : AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendOptions(bool isDarkMode) {
    bool canResend = _remainingTime == 0 && !_isVerifying && !_isValidating;

    return Column(
      children: [
        // Texto principal y botón de reenvío
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿No recibiste el código? ',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white70,
              ),
            ),
            GestureDetector(
              onTap: canResend ? _resendCode : null,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: canResend
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'Reenviar código',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: canResend
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 30),

        const Row(
          children: [
            Expanded(
              child: Divider(
                color: AppColors.textSecondary,
                thickness: 1,
                height: 0.5,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'o',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: AppColors.textSecondary,
                thickness: 1,
                height: 0.5,
              ),
            ),
          ],
        ),

        SizedBox(height: 30),
        // Botón de llamada telefónica
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canResend ? _requestPhoneCall : null,
            icon: Icon(
              Icons.phone_callback_rounded,
              size: 20,
              color: canResend ? AppColors.textLight : AppColors.textPrimary,
            ),
            label: Text(
              'Solicitar llamada telefónica',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: canResend ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: canResend
                  ? AppColors.primary.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.2),
              padding: EdgeInsets.symmetric(vertical: 16),
              elevation: canResend ? 8 : 0,
              shadowColor: canResend
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: canResend
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.textPrimary,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _requestPhoneCall() {
    HapticFeedback.mediumImpact();

    Fluttertoast.showToast(
      msg: "📞 Solicitando llamada telefónica...",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    // Aquí implementarías la lógica para solicitar llamada telefónica
    // Por ejemplo: Provider.of<AuthProvider>(context, listen: false).requestPhoneCall(widget.email);
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Ayuda', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• El código tiene 6 caracteres alfanuméricos',
                style: TextStyle(color: AppColors.textInput), maxLines: 1, overflow: TextOverflow.ellipsis,),
            SizedBox(height: 8),
            Text('• El código se valida automáticamente',
                style: TextStyle(color: AppColors.textInput), maxLines: 1, overflow: TextOverflow.ellipsis,),
            SizedBox(height: 8),
            Text('• Completa los campos en orden secuencial',
                style: TextStyle(color: AppColors.textInput), maxLines: 1, overflow: TextOverflow.ellipsis,),
            SizedBox(height: 8),
            Text('• Revisa tu bandeja de entrada y spam',
                style: TextStyle(color: AppColors.textInput), maxLines: 1, overflow: TextOverflow.ellipsis,),
            SizedBox(height: 8),
            Text('• El código expira en 1 minuto',
                style: TextStyle(color: AppColors.textInput), maxLines: 1, overflow: TextOverflow.ellipsis,),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _clearFieldsWithAnimation() {
    _animationController.repeat(reverse: true);

    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) {
        _animationController.stop();
        _animationController.reset();
        _codeControllers.forEach((controller) => controller.clear());
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _showMaxAttemptsError() {
    final darkModeProvider = Provider.of<DarkModeProvider>(context, listen: false);
    final isDarkMode = darkModeProvider.isDarkMode;
    final iconColor = darkModeProvider.iconColor;
    final textColor = darkModeProvider.textColor;
    final backgroundColor = darkModeProvider.backgroundColor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(Icons.error_outline, size: 48, color: iconColor),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Demasiados intentos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            const Text(
              'Por favor, intenta más tarde',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textInput),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
            style: ElevatedButton.styleFrom(backgroundColor: backgroundColor),
            child: Text('Entendido', style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }

  void _showValidationError() {
    Fluttertoast.showToast(
      msg: "Código incorrecto. Intentos restantes: ${maxAttempts - failedAttempts}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: AppColors.secondary,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  void _showSuccessDialog() {
    _timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.backgroundSuccess,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/succes/success.json',
                width: 100,
                height: 100,
                repeat: false,
              ),
              SizedBox(height: 16),
              const Text(
                '¡Verificación Exitosa!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 24),
              const Text(
                'Redirigiendo...',
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(Icons.timer_off_outlined, size: 48, color: Colors.orange),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tiempo expirado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'El código ha expirado. ¿Deseas solicitar uno nuevo?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resendCode();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Reenviar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resendCode() {
    setState(() {
      _remainingTime = 60;
      failedAttempts = 0;
      _isVerifying = false;
      _isValidating = false;
    });

    _validationTimer?.cancel();
    _codeControllers.forEach((controller) => controller.clear());
    _focusNodes[0].requestFocus();
    _startTimer();

    Fluttertoast.showToast(
      msg: "Nuevo código enviado",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _validationTimer?.cancel();
    _animationController.dispose();
    _codeControllers.forEach((controller) => controller.dispose());
    _focusNodes.forEach((node) => node.dispose());
    super.dispose();
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}