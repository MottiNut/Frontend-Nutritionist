import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';

import '../../../configuration/themes/app_colors.dart';

class SubscriptionPlansPage extends StatefulWidget {
  @override
  _SubscriptionPlansPageState createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentIndex = 2;

  // Contador de tiempo (23h 59m 59s)
  Timer? _timer;
  int _hours = 23;
  int _minutes = 59;
  int _seconds = 59;

  final List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'free',
      title: 'Gratuito',
      subtitle: 'Perfecto para empezar',
      price: 'S/ 0',
      period: 'Siempre gratis',
      maxPatients: 15,
      features: [
        'Máximo 15 pacientes/mes',
        'Planes nutricionales básicos',
        'Historial de consultas',
        'Soporte por email',
      ],
      gradient: AppColors.softPrimaryGradient,
      iconColor: AppColors.primary,
      isPopular: false,
      description: 'Ideal para nutricionistas que están comenzando su práctica profesional. Incluye funciones básicas para gestionar pacientes.',
      icon: Icons.favorite_outline,
      validUntil: '31 Dic 2025',
    ),
    SubscriptionPlan(
      id: 'monthly',
      title: 'Mensual Pro',
      subtitle: 'Flexibilidad total',
      price: 'S/ 20',
      period: 'por mes',
      maxPatients: -1,
      features: [
        'Pacientes ilimitados',
        'IA para planes nutricionales',
        'Análisis avanzado',
        'Reportes detallados',
        'Soporte prioritario',
        'Recordatorios automáticos',
      ],
      gradient: AppColors.primarySecondaryGradient,
      iconColor: AppColors.secondary,
      isPopular: true,
      description: 'La opción más flexible para profesionales que buscan todas las funciones premium sin limitaciones.',
      icon: Icons.star_outline,
      validUntil: '31 Dic 2025',
    ),
    SubscriptionPlan(
      id: 'yearly',
      title: 'Anual Pro',
      subtitle: 'Ahorra 37%',
      price: 'S/ 150',
      period: 'por año',
      maxPatients: -1,
      originalPrice: 'S/ 240',
      features: [
        'Todo del plan mensual',
        'Ahorra S/ 90 al año',
        'Consultoría personalizada',
        'Acceso anticipado a funciones',
        'Soporte 24/7',
        'Backup automático',
        'Análisis predictivo con IA',
      ],
      gradient: AppColors.successGradient,
      iconColor: AppColors.progress,
      isPopular: false,
      description: 'Máximo valor para tu práctica profesional. Incluye todo del plan mensual más beneficios exclusivos y IA predictiva.',
      icon: Icons.diamond_outlined,
      validUntil: '31 Dic 2025',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _seconds = 59;
          if (_minutes > 0) {
            _minutes--;
          } else {
            _minutes = 59;
            if (_hours > 0) {
              _hours--;
            } else {
              _hours = 23;
              _minutes = 59;
              _seconds = 59;
            }
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundDark,
              AppColors.backgroundSecondary,
              AppColors.backgroundPrimary,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildAppBar(),
                _buildOfferCountdown(),
                Expanded(
                  child: _buildCarousel(),
                ),

                SizedBox(height: 7),
                _buildDots(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppColors.textLight),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Planes de Suscripción',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildOfferCountdown() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.errorGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🔥 OFERTA LIMITADA 🔥',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeCard(_hours.toString().padLeft(2, '0')),
              Text(' : ', style: TextStyle(color: AppColors.textLight, fontSize: 18)),
              _buildTimeCard(_minutes.toString().padLeft(2, '0')),
              Text(' : ', style: TextStyle(color: AppColors.textLight, fontSize: 18)),
              _buildTimeCard(_seconds.toString().padLeft(2, '0')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String time) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textLight.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        time,
        style: TextStyle(
          color: AppColors.textLight,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: 500, // Aumentado para más contenido
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemCount: plans.length,
          itemBuilder: (context, index) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              child: _buildPlanCard(plans[index], index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, int index) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: plan.gradient,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.textLight.withOpacity(0.3)
                        : AppColors.textLight.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isSelected ? 0.4 : 0.2),
                      blurRadius: isSelected ? 25 : 15,
                      offset: Offset(0, isSelected ? 15 : 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.black.withOpacity(0.2),
                  ),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icono arriba
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.textLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: plan.iconColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          plan.icon,
                          color: plan.iconColor,
                          size: 36,
                        ),
                      ),

                      // Fecha pequeña arriba
                      Text(
                        'Válido hasta: ${plan.validUntil}',
                        style: TextStyle(
                          color: AppColors.textLight.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),

                      SizedBox(height: 8),

                      // Título y precio
                      Text(
                        plan.title,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        plan.subtitle,
                        style: TextStyle(
                          color: AppColors.textLight.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),

                      SizedBox(height: 12),

                      if (plan.originalPrice != null)
                        Text(
                          plan.originalPrice!,
                          style: TextStyle(
                            color: AppColors.textLight.withOpacity(0.6),
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),

                      Text(
                        plan.price,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        plan.period,
                        style: TextStyle(
                          color: AppColors.textLight.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),

                      SizedBox(height: 16),

                      // Descripción abajo
                      Expanded(
                        child: Text(
                          plan.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textLight.withOpacity(0.9),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),


                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _selectPlan(plan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.textLight,
                            foregroundColor: AppColors.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: AppColors.textLight.withOpacity(0.3),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                plan.id == 'free' ? 'Empezar Gratis' : 'Suscribirse',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Badge de popular
          if (plan.isPopular)
            Positioned(
              top: -8,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '⭐ POPULAR',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(plans.length, (index) {
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: 6),
            width: _currentIndex == index ? 24 : 10,
            height: 7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: _currentIndex == index
                  ? AppColors.progress
                  : AppColors.textLight.withOpacity(0.3),
            ),
          ),
        );
      }),
    );
  }

  void _selectPlan(SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLigth,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Plan Seleccionado',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Has seleccionado el ${plan.title}. ¿Deseas continuar?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textCuatary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPurchase(plan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Continuar', style: TextStyle(color: AppColors.textLight)),
          ),
        ],
      ),
    );
  }

  void _processPurchase(SubscriptionPlan plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Procesando suscripción a ${plan.title}...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class SubscriptionPlan {
  final String id;
  final String title;
  final String subtitle;
  final String price;
  final String period;
  final int maxPatients;
  final String? originalPrice;
  final List<String> features;
  final LinearGradient gradient;
  final Color iconColor;
  final bool isPopular;
  final String description;
  final IconData icon;
  final String validUntil;

  SubscriptionPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.period,
    required this.maxPatients,
    this.originalPrice,
    required this.features,
    required this.gradient,
    required this.iconColor,
    this.isPopular = false,
    required this.description,
    required this.icon,
    required this.validUntil,
  });
}