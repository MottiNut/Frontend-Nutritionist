import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../../../configuration/themes/app_colors.dart';
import 'categorys_patogys/diabetes/diabetes_screen.dart';
import 'categorys_patogys/hipertension/hipertencion_screen.dart';
import 'categorys_patogys/news/DiabetesPatientsScreen.dart';
import 'categorys_patogys/news/HypertensionPatientsScreen.dart';
import 'categorys_patogys/news/ObecityPatientsScreen.dart';
import 'categorys_patogys/obecidad/obecidad_screen.dart';

class PatientScreen extends StatefulWidget {
  const PatientScreen({super.key});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  // Lista de categorías profesionales
  final List<CategoryItem> categories = [
    CategoryItem(
      title: 'Diabetes\nTipo 1 - 2',
      icon: SvgPicture.asset('assets/images/iconEnf/diabe_icon_c.svg'),
      linearImage:
          SvgPicture.asset('assets/images/categorys/linear_diabetes_icon.svg'),
      color: AppColors.backgroundDiabetes.withOpacity(0.5),
      isVisible: true,
      routeName: '/diabetes',
    ),
    CategoryItem(
      title: 'Hipertensión\nArterial',
      icon: SvgPicture.asset('assets/images/iconEnf/hiper_icon_c.svg'),
      linearImage:
          SvgPicture.asset('assets/images/categorys/linear_hiper_icon.svg'),
      color: AppColors.backgroundHipertencion.withOpacity(0.5),
      isVisible: true,
      routeName: '/hipertension',
    ),
    CategoryItem(
      title: 'Obesidad y\nSobrepeso',
      icon: SvgPicture.asset('assets/images/iconEnf/obe_icon_c.svg'),
      linearImage:
          SvgPicture.asset('assets/images/categorys/linear_obes_icon.svg'),
      color: AppColors.backgroundObecidad.withOpacity(0.8),
      isVisible: true,
      routeName: '/obesidad',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light, // Para iOS
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Stack(
          children: [
            // GRADIENTE RADIAL DE FONDO
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.9, -0.9),
                    // Esquina superior izquierda
                    // Cambia a (0.9, -0.9) para esquina superior derecha
                    // Cambia a (0.0, -0.9) para centro superior
                    radius: 1,
                    colors: [
                      AppColors.primary.withOpacity(0.25),
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.08),
                      AppColors.primary.withOpacity(0.03),
                      AppColors.primary.withOpacity(0.01),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            // CONTENIDO PRINCIPAL
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header profesional sin AppBar
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // Acción del menú
                                },
                                child: Container(
                                  child: SvgPicture.asset(
                                    'assets/images/menu_icon.svg',
                                    width: 36,
                                    height: 36,
                                  ),
                                ),
                              ),
                              Text(
                                'Categorías',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTitleCateg,
                                  letterSpacing: 0.96,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Acción de notificaciones
                                },
                                child: Container(
                                  child: SvgPicture.asset(
                                    'assets/images/notification_icon.svg',
                                    width: 25.305,
                                    height: 30.278,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Grid de categorías con scroll
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = categories[index];
                          return CategoryCard(
                            category: category,
                            onTap: () {
                              if (category.isVisible) {
                                _navigateToCategory(context, category);
                              } else {
                                _showComingSoonDialog(context);
                              }
                            },
                          );
                        },
                        childCount: categories.length,
                      ),
                    ),
                  ),

                  // Espaciado inferior
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCategory(BuildContext context, CategoryItem category) {
    // Navegación a la pantalla específica de cada categoría
    switch (category.routeName) {
      case '/diabetes':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiabetesPatientsScreenn(),
          ),
        );
        break;
      case '/hipertension':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HypertensionPatientsScreen(),
          ),
        );
        break;
      case '/obesidad':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ObesityPatientsScreen(),
          ),
        );
        break;
      default:
        _showComingSoonDialog(context);
    }
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Próximamente',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Esta especialidad estará disponible pronto.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: Color(0xFF4ECDC4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItem {
  final String title;
  final Widget? icon;
  final Widget? linearImage;
  final Color color;
  final bool isVisible;
  final String routeName;

  CategoryItem({
    required this.title,
    this.icon,
    this.linearImage,
    required this.color,
    required this.isVisible,
    required this.routeName,
  });
}

class CategoryCard extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: category.color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              // Imagen linear en la parte superior derecha
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  child: Center(
                    child: category.linearImage ??
                        Icon(
                          Icons.medical_services_outlined,
                          color: category.isVisible
                              ? Colors.red
                              : Colors.grey[500],
                          size: 20,
                        ),
                  ),
                ),
              ),

              // Contenido principal en la parte inferior izquierda
              Positioned(
                left: 18,
                bottom: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono principal
                    Container(
                      child: category.icon ??
                          Icon(
                            Icons.medical_services,
                            color: category.isVisible
                                ? Colors.white
                                : Colors.grey[600],
                            size: 24,
                          ),
                    ),

                    const SizedBox(height: 8),

                    // Título
                    Text(
                      category.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: category.isVisible
                            ? Colors.white
                            : Colors.grey[600],
                        height: 1.3,
                        letterSpacing: 0.36,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


