import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'notification_screen.dart';

class AnimatedNotificationIcon extends StatefulWidget {
  final List<NotificationItem> notifications;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  const AnimatedNotificationIcon({
    super.key,
    required this.notifications,
    required this.onTap,
    this.width = 25.305,
    this.height = 30.278,
  });

  @override
  State<AnimatedNotificationIcon> createState() => _AnimatedNotificationIconState();
}

class _AnimatedNotificationIconState extends State<AnimatedNotificationIcon>
    with TickerProviderStateMixin {
  late AnimationController _bellShakeController;
  late AnimationController _badgeController;
  late AnimationController _rippleController;
  late AnimationController _glowController;

  late Animation<double> _bellShakeAnimation;
  late Animation<double> _badgeScaleAnimation;
  late Animation<double> _badgeBounceAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Offset> _bellTranslateAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador para el shake/vibración de la campana
    _bellShakeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Controlador para el badge (escala y bounce)
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Controlador para el efecto ripple
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Controlador para el glow effect
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animación de shake para la campana (rotación sutil)
    _bellShakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bellShakeController,
      curve: Curves.elasticOut,
    ));

    // Animación de traslación para el shake
    _bellTranslateAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: const Offset(0.05, 0))
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0.05, 0), end: const Offset(-0.05, 0))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(-0.05, 0), end: const Offset(0.02, 0))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_bellShakeController);

    // Animación de escala para el badge
    _badgeScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Animación de bounce continuo para el badge
    _badgeBounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
    ));

    // Animación de ripple (círculo expansivo)
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    // Animación de glow
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animaciones si hay notificaciones no leídas
    if (unreadCount > 0) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _bellShakeController.forward();
    _badgeController.forward().then((_) {
      if (unreadCount > 0) {
        _badgeController.repeat(reverse: true, period: const Duration(milliseconds: 2000));
      }
    });
    _rippleController.repeat();
    _glowController.repeat(reverse: true);
  }

  void _stopAnimations() {
    _bellShakeController.stop();
    _badgeController.stop();
    _rippleController.stop();
    _glowController.stop();
  }

  void _triggerNewNotificationAnimation() {
    _bellShakeController.reset();
    _badgeController.reset();
    _bellShakeController.forward();
    _badgeController.forward().then((_) {
      if (unreadCount > 0) {
        _badgeController.repeat(reverse: true, period: const Duration(milliseconds: 2000));
      }
    });
  }

  int get unreadCount => widget.notifications.where((n) => !n.isRead).length;

  @override
  void didUpdateWidget(AnimatedNotificationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    int oldUnreadCount = oldWidget.notifications.where((n) => !n.isRead).length;
    int newUnreadCount = unreadCount;

    if (newUnreadCount > oldUnreadCount && newUnreadCount > 0) {
      _triggerNewNotificationAnimation();
    } else if (newUnreadCount == 0) {
      _stopAnimations();
    } else if (oldUnreadCount == 0 && newUnreadCount > 0) {
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _bellShakeController.dispose();
    _badgeController.dispose();
    _rippleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.width! + 20,
        height: widget.height! + 20,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Ripple effect de fondo
            if (unreadCount > 0)
              AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return Container(
                    width: (widget.width! + 30) * _rippleAnimation.value,
                    height: (widget.height! + 30) * _rippleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6C63FF).withOpacity(
                        0.1 * (1 - _rippleAnimation.value),
                      ),
                    ),
                  );
                },
              ),

            // Glow effect para el icono
            if (unreadCount > 0)
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: widget.width! + 10,
                    height: widget.height! + 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(
                            0.3 * _glowAnimation.value,
                          ),
                          blurRadius: 15 * _glowAnimation.value,
                          spreadRadius: 2 * _glowAnimation.value,
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Icono principal con animaciones
            AnimatedBuilder(
              animation: Listenable.merge([_bellShakeAnimation, _bellTranslateAnimation]),
              builder: (context, child) {
                return Transform.translate(
                  offset: _bellTranslateAnimation.value * 20,
                  child: Transform.rotate(
                    angle: _bellShakeAnimation.value * 0.1 *
                        (1 - _bellShakeAnimation.value).clamp(0.0, 1.0),
                    child: SvgPicture.asset(
                      'assets/images/notification_icon.svg',
                      width: widget.width,
                      height: widget.height,

                    ),
                  ),
                );
              },
            ),

            // Badge moderno con gradiente y efectos
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_badgeScaleAnimation, _badgeBounceAnimation]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _badgeScaleAnimation.value * _badgeBounceAnimation.value,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: unreadCount > 99 ? 6 : 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF4757),
                              Color(0xFFFF6B6B),
                              Color(0xFFFF8E8E),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),

                        ),
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),

          ],
        ),
      ),
    );
  }
}