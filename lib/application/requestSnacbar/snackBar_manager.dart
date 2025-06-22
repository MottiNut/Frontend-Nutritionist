import 'package:flutter/material.dart';

import '../../configuration/themes/app_colors.dart';

enum SnackBarType { success, error, warning, info }

class SnackBarManager {

  static const Color _backgroundUniform = Color(0xFF1F1F1F);

  /// Mostrar mensaje de éxito (verde)
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: _backgroundUniform,
      icon: Icons.check_circle_outline,
      iconColor: AppColors.checkValidation,
    );
  }
//save automatic
  static void showAutoSave(BuildContext context) {
    _showSnackBar(
      context: context,
      message: 'Guardado automáticamente',
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      iconColor: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }


  /// Mostrar mensaje de error (rojo suave)
  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: _backgroundUniform,
      icon: Icons.cancel_outlined,
      iconColor: AppColors.errorIcon,
    );
  }

  /// Mostrar mensaje de advertencia (amarillo/naranja)
  static void showWarning(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: _backgroundUniform,
      icon: Icons.warning_amber_outlined,
      iconColor: AppColors.secondary,
    );
  }

  /// Mostrar mensaje informativo (azul suave)
  static void showInfo(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: _backgroundUniform,
      icon: Icons.info_outline,
      iconColor: AppColors.backgroundDetail,
    );
  }

  /// Mostrar mensaje con acción personalizada
  static void showWithAction(
      BuildContext context, {
        required String message,
        required String actionText,
        required VoidCallback onAction,
        SnackBarType type = SnackBarType.info,
      }) {
    final config = _getTypeConfig(type);

    _showActionSnackBar(
      context: context,
      message: message,
      backgroundColor: _backgroundUniform,
      icon: config['icon']!,
      iconColor: config['iconColor']!,
      actionText: actionText,
      onAction: onAction,
    );
  }

  /// Configuración de colores e iconos por tipo
  static Map<String, dynamic> _getTypeConfig(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return {
          'icon': Icons.check_circle_outline,
          'iconColor': AppColors.backgroundSuccess,
        };
      case SnackBarType.error:
        return {
          'icon': Icons.cancel_outlined,
          'iconColor': AppColors.errorIcon,
        };
      case SnackBarType.warning:
        return {
          'icon': Icons.warning_outlined,
          'iconColor': AppColors.secondary,
        };
      case SnackBarType.info:
      default:
        return {
          'icon': Icons.info_outlined,
          'iconColor': AppColors.backgroundDetail,
        };
    }
  }

  /// SnackBar base sin acción
  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.transparent,
        duration: duration,
        content: Container(
          height: 47, // Altura más compacta
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white, // Texto blanco como solicitaste
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// SnackBar con acción
  static void _showActionSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    required String actionText,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.transparent,
        duration: duration,
        content: Container(
          height: 52, // Altura más compacta para acciones
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}