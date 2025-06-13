import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../../configuration/themes/app_colors.dart';
import '../../domain/data/onboarding_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showPageCounter = false;
  Timer? _hideTimer;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Gestiona\nPacientes",
      description: "Administra y da seguimiento a todos tus pacientes desde una sola plataforma profesional",
      svgPath: "assets/nutrition_illustration.png",
      backgroundColor: AppColors.backgroundLigth,
      gradientColors: [AppColors.primary, AppColors.secondary],
    ),
    OnboardingData(
      title: "Planes\n Inteligentes",
      description: "Crea planes nutricionales únicos con herramientas avanzadas e IA especializada",
      svgPath: "assets/nutrition_illustration.png",
      backgroundColor: AppColors.backgroundLigth,
      gradientColors: [AppColors.primary, AppColors.secondary],
    ),
    OnboardingData(
      title: "Red\nProfesional",
      description: "Conecta con otros nutricionistas y accede a recursos especializados de la comunidad",
      svgPath: "assets/nutrition_illustration.png",
      backgroundColor: AppColors.backgroundLigth,
      gradientColors: [AppColors.primary, AppColors.secondary],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (_currentPage == 2) {
      setState(() {
        _showPageCounter = true;
      });

      // Ocultar el contador después de 3 segundos
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showPageCounter = false;
          });
        }
      });
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      // Ocultar el contador si cambiamos de página
      if (page != 2) {
        _showPageCounter = false;
        _hideTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding;

    return Scaffold(
      body: GestureDetector(
        onTap: _handleTap,
        child: Stack(
          children: [
            // PageView principal
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _buildPage(_pages[index]);
              },
            ),

            if (_currentPage < 2)
              Positioned(
                top: 20,
                right: 20,
                child: SafeArea(
                  child: TextButton(
                    onPressed: () {
                      _pageController.animateToPage(
                        _pages.length - 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text(
                      "Saltar",
                      style: TextStyle(
                        color: AppColors.textInput,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // Contador de página "3/3" - solo aparece en la página 3 cuando se hace tap
            if (_currentPage == 2)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: _showPageCounter ? safePadding.top + 1 : -50,
                right: 20,
                child: SafeArea(
                  child: AnimatedOpacity(
                    opacity: _showPageCounter ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "${_currentPage + 1}/${_pages.length}",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Contenido de texto en la parte superior izquierda
            Positioned(
              top: 141.14,
              left: 30.67,
              right: 95.08,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pages[_currentPage].title,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _pages[_currentPage].description,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.black.withOpacity(0.7),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Indicadores de página - se ocultan en la página 3
            if (_currentPage != 2)
              Positioned(
                bottom: 100 + safePadding.bottom,
                left: 0,
                right: 0,
                child: _buildPageIndicator(),
              ),

            // Botón "Comenzar" - aparece solo en la tercera página
            if (_currentPage == 2)
              Positioned(
                bottom: safePadding.bottom + 24,
                left: 24,
                right: 24,
                child: _buildBottomButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // Imagen en la parte inferior
          Positioned(
            bottom: 110,
            left: 24,
            right: 24,
            height: MediaQuery.of(context).size.height * 0.35,
            child: Image.asset(
              data.svgPath,
              fit: BoxFit.contain,
            ),
          ),

          // Efecto blur con colores primary, secondary y centro
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: _buildGradientBackground(),
          ),

          // Imagen en la parte inferior sobre el degradado
          Positioned(
            bottom: 110,
            left: 24,
            right: 24,
            height: MediaQuery.of(context).size.height * 0.35,
            child: Image.asset(
              data.svgPath,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Capa de color primary (esmeralda - izquierda)
        Positioned(
          bottom: 0,
          left: 0,
          width: screenWidth * 0.4,
          height: screenHeight * 0.55,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.5, 0.8, 1.0],
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Capa de color secondary (naranja - derecha)
        Positioned(
          bottom: 0,
          right: 0,
          width: screenWidth * 0.4,
          height: screenHeight * 0.55,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.5, 0.8, 1.0],
                colors: [
                  AppColors.secondary.withOpacity(0.3),
                  AppColors.secondary.withOpacity(0.2),
                  AppColors.secondary.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Capa central con color FFF8F2
        Positioned(
          bottom: 0,
          left: screenWidth * 0.25,
          right: screenWidth * 0.25,
          height: screenHeight * 0.55,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.4, 0.7, 1.0],
                colors: [
                  const Color(0xFFFFF8F2).withOpacity(0.3),
                  const Color(0xFFFFF8F2).withOpacity(0.2),
                  const Color(0xFFFFF8F2).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Efecto blur aplicado sobre todos los colores
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: screenHeight * 0.55,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.6),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.primary
                : Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: _currentPage == index
                ? Border.all(width: 1, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 2,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Comenzar",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}