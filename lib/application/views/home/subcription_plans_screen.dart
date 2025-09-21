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

  // Contador de tiempo (23h 59m 59s)
  Timer? _timer;
  int _hours = 23;
  int _minutes = 59;
  int _seconds = 59;

  final List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'free',
      title: 'Plan Gratuito',
      subtitle: 'Perfecto para empezar',
      price: 'S/ 0',
      period: 'Siempre gratis',
      maxPatients: 15,
      features: [
        'Máximo 15 pacientes por mes',
        'Planes nutricionales básicos',
        'Historial de consultas',
        'Soporte por email',
      ],
      gradient: AppColors.softPrimaryGradient,
      iconColor: AppColors.primary,
      isPopular: false,
    ),
    SubscriptionPlan(
      id: 'monthly',
      title: 'Plan Mensual',
      subtitle: 'Flexibilidad total',
      price: 'S/ 20',
      period: 'por mes',
      maxPatients: -1, // Ilimitado
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
    ),
    SubscriptionPlan(
      id: 'yearly',
      title: 'Plan Anual',
      subtitle: 'Mejor valor - Ahorra 37%',
      price: 'S/ 150',
      period: 'por año',
      maxPatients: -1, // Ilimitado
      originalPrice: 'S/ 240',
      features: [
        'Todo del plan mensual',
        'Ahorra S/ 90 al año',
        'Consultoría personalizada',
        'Acceso a nuevas funciones',
        'Soporte 24/7',
        'Backup automático en la nube',
        'Análisis predictivo con IA',
      ],
      gradient: AppColors.successGradient,
      iconColor: AppColors.progress,
      isPopular: false,
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
              // Reiniciar contador
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
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  _buildOfferCountdown(),
                  _buildPlansGrid(),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: AppColors.textLight),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Planes de Suscripción',
          style: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildOfferCountdown() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Obtén descuentos especiales',
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeCard(_hours.toString().padLeft(2, '0'), 'Horas'),
                Text(' : ', style: TextStyle(color: AppColors.textLight, fontSize: 20)),
                _buildTimeCard(_minutes.toString().padLeft(2, '0'), 'Min'),
                Text(' : ', style: TextStyle(color: AppColors.textLight, fontSize: 20)),
                _buildTimeCard(_seconds.toString().padLeft(2, '0'), 'Seg'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(String time, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.textLight.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.textLight.withOpacity(0.3)),
          ),
          child: Text(
            time,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textLight.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildPlansGrid() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return _buildPlanCard(plans[index], index);
          },
          childCount: plans.length,
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          // Fondo con blur
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: plan.gradient,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.textLight.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlanHeader(plan),
                      SizedBox(height: 20),
                      _buildPlanFeatures(plan),
                      SizedBox(height: 24),
                      _buildActionButton(plan),
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
              right: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
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
                  '⭐ MÁS POPULAR',
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

  Widget _buildPlanHeader(SubscriptionPlan plan) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.textLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: plan.iconColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            _getPlanIcon(plan.id),
            color: plan.iconColor,
            size: 24,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.title,
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 20,
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
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (plan.originalPrice != null)
              Text(
                plan.originalPrice!,
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.6),
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            Text(
              plan.price,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              plan.period,
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanFeatures(SubscriptionPlan plan) {
    return Column(
      children: plan.features.map((feature) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.progress,
                size: 18,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature,
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(SubscriptionPlan plan) {
    return Container(
      width: double.infinity,
      height: 50,
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
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              plan.id == 'free' ? 'Empezar Gratis' : 'Suscribirse Ahora',
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
    );
  }

  IconData _getPlanIcon(String planId) {
    switch (planId) {
      case 'free':
        return Icons.favorite_outline;
      case 'monthly':
        return Icons.star_outline;
      case 'yearly':
        return Icons.diamond_outlined;
      default:
        return Icons.workspace_premium_outlined;
    }
  }

  void _selectPlan(SubscriptionPlan plan) {
    // Aquí integras la lógica de suscripción
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
              // Aquí integrar Google Play Billing o el sistema de pagos
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
    // Implementar lógica de compra
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
  final int maxPatients; // -1 para ilimitado
  final String? originalPrice;
  final List<String> features;
  final LinearGradient gradient;
  final Color iconColor;
  final bool isPopular;

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
  });
}