import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../../../../configuration/themes/app_colors.dart';
import '../../../../requestSnacbar/snackBar_manager.dart';

class RatingConfig {
  static const String appName = 'MottiNut';
  static const String playStoreId = 'com.tuempresa.mottinut';
  static const int minimumRatingForStore = 4;
  static const Duration animationDuration = Duration(milliseconds: 300);
}

Future<void> showRatingDialog(BuildContext context) async {
  double rating = 0;
  bool isSubmitting = false;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final maxWidth = MediaQuery.of(context).size.width * 0.90;
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              '¿Califica a ${RatingConfig.appName}?',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.close, color: Colors.black54),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          final isSelected = rating >= starIndex;
                          return GestureDetector(
                            onTap: isSubmitting
                                ? null
                                : () => setState(
                                    () => rating = starIndex.toDouble()),
                            child: AnimatedContainer(
                              duration: RatingConfig.animationDuration,
                              padding: const EdgeInsets.all(4),
                              child: AnimatedScale(
                                scale: isSelected ? 1.1 : 1.0,
                                duration: RatingConfig.animationDuration,
                                child: Icon(
                                  isSelected
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 42,
                                  color: isSelected
                                      ? Colors.amber
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: RatingConfig.animationDuration,
                        child: _buildRatingMessage(context, rating),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: rating == 0 || isSubmitting
                                  ? null
                                  : () async {
                                      setState(() => isSubmitting = true);
                                      try {
                                        await _handleRatingSubmission(
                                            context, rating);
                                        Navigator.pop(ctx);
                                      } catch (_) {
                                        setState(() => isSubmitting = false);
                                        _showErrorMessage(context);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black87,
                                elevation: 2,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                disabledBackgroundColor: Colors.grey.shade300,
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  :  Text(
                                      'Enviar calificación',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildRatingMessage(BuildContext context, double rating) {
  String message;
  IconData icon;
  Color color;

  if (rating == 0) {
    return const SizedBox(key: ValueKey('empty'));
  } else if (rating <= 2) {
    message = 'Lamentamos que no tengas una buena experiencia';
    icon = Icons.sentiment_dissatisfied_rounded;
    color = Colors.red.shade400;
  } else if (rating == 3) {
    message = 'Gracias, trabajamos para mejorar';
    icon = Icons.sentiment_neutral_rounded;
    color = Colors.orange.shade400;
  } else if (rating == 4) {
    message = '¡Genial! ¿Nos calificas en la tienda?';
    icon = Icons.sentiment_satisfied_rounded;
    color = Colors.green.shade400;
  } else {
    message = '¡Excelente! Comparte tu experiencia en Play Store';
    icon = Icons.sentiment_very_satisfied_rounded;
    color = Colors.green.shade400;
  }

  return Container(
    key: ValueKey(rating),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.1)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _handleRatingSubmission(
    BuildContext context, double rating) async {
  await Future.delayed(const Duration(milliseconds: 500));
  if (rating >= RatingConfig.minimumRatingForStore) {
    await _openPlayStore(context);
  } else {
    _showThankYouMessage(context, rating);
  }
}

Future<void> _openPlayStore(BuildContext context) async {
  final inAppReview = InAppReview.instance;
  try {
    if (await inAppReview.isAvailable()) {
      // Muestra el pop-up nativo de reseña
      await inAppReview.requestReview();
    } else {
      // Como fallback, abre la ficha de la app en la store
      await inAppReview.openStoreListing(
        appStoreId: '644XXXXXXX', // <-- SOLO en iOS, si la publicas allí
        // microsoftStoreId: 'XXXXXXXX' // si lo necesitaras
      );
    }
  } catch (_) {
    _showErrorMessage(context);
  }
}


void _showThankYouMessage(BuildContext context, double rating) {
  final msg = rating <= 2
      ? '¡Gracias por tu honestidad! Trabajaremos para mejorar.'
      : '¡Gracias por tu calificación!';

  SnackBarManager.showSuccess(context, msg);
}

void _showErrorMessage(BuildContext context) {
  SnackBarManager.showError(context, 'Ocurrió un error. Intenta de nuevo.');
}

