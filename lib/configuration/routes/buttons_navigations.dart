import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mottinutnutriotinist/application/views/patients/patient_screen.dart';
import 'package:mottinutnutriotinist/application/views/profile/profile_screen.dart';
import 'package:mottinutnutriotinist/application/views/recipes/recipes_screen.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../application/views/home/home_screen.dart';
import '../providers/color_dar_light_app.dart';
import '../themes/app_colors.dart';

class ButtonsNavigations extends StatefulWidget {
  final int? initialIndex;

  const ButtonsNavigations({super.key, this.initialIndex});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ButtonsNavigations> with TickerProviderStateMixin {
  late int _selectedIndex;
  DateTime? _lastPressedAt;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Siempre inicializar en 0 (Inicio) para navegación profesional
    _selectedIndex = widget.initialIndex ?? 0;

    // Configurar animaciones para transiciones suaves
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    const PatientScreen(),
    const RecipesScreen(),
    const ProfileScreen()
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Evitar navegación innecesaria

    // Animación de tap
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Vibración sutil para feedback táctil
    _provideTactileFeedback();

    setState(() {
      _selectedIndex = index;
      // Removido: _isVideoCaptureScreen = (index == 2);
    });
  }

  void _provideTactileFeedback() async {
    if ((await Vibration.hasVibrator()) == true) {
      Vibration.vibrate(duration: 50, amplitude: 128);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  Future<bool> _onWillPop() async {
    DateTime now = DateTime.now();

    // Si no está en Inicio, regresar a Inicio
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }

    // Doble tap para salir solo cuando esté en Inicio
    if (_selectedIndex == 0) {
      if (_lastPressedAt == null ||
          now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
        _lastPressedAt = now;
        _showExitToast();
        return false;
      }

      //await _provideTactileFeedback();
      return true;
    }

    return false;
  }

  void _showExitToast() {
    Fluttertoast.showToast(
      msg: "Presiona nuevamente para salir",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: AppColors.textSecondary,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  // Método para crear iconos SVG con fallback
  Widget _buildSvgIcon({
    required String svgPath,
    required IconData fallbackIcon,
    required Color color,
    double size = 23.48,
    double sizeh = 24.50,
  }) {
    try {
      return SvgPicture.asset(
        svgPath,
        color: color,
        width: size,
        height: sizeh,
        placeholderBuilder: (BuildContext context) => FaIcon(
          fallbackIcon,
          color: color,
          size: size,
        ),
      );
    } catch (e) {
      // Si hay error cargando el SVG, usar el icono alternativo
      return FaIcon(
        fallbackIcon,
        color: color,
        size: size,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkModeProvider = Provider.of<DarkModeProvider>(context);
    final isDarkMode = darkModeProvider.isDarkMode;
    final isIndex0 = _selectedIndex == 0;
    final isIndex2 = _selectedIndex == 2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _getSystemUIOverlayStyle(isIndex0, isIndex2, isDarkMode),
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: AppColors.backgroundIconNav,
          body: SafeArea(
            bottom: false, // Permitir que la navegación se extienda
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _widgetOptions.elementAt(_selectedIndex),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(isIndex0, isDarkMode),
        ),
      ),
    );
  }

  SystemUiOverlayStyle _getSystemUIOverlayStyle(bool isIndex0, bool isIndex2, bool isDarkMode) {

    return SystemUiOverlayStyle.light.copyWith(
      systemNavigationBarColor: Colors.black,
      statusBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    );
  }

  Widget _buildBottomNavigationBar(bool isIndex0, bool isDarkMode) {
    // Removido: if (_isVideoCaptureScreen) return const SizedBox.shrink();
    // Ahora los botones siempre estarán visibles

    return SafeArea(
      top: false, // Solo aplicar SafeArea en la parte inferior
      child: IntrinsicHeight( // Usar IntrinsicHeight para dimensionamiento automático
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 0.5,
              color: isIndex0 || isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
            ),
            Flexible( // Usar Flexible en lugar de Container con altura fija
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: SizedBox(
                  height: 45,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            icon: _buildSvgIcon(
                              svgPath: 'assets/icons/home_grey.svg',
                              fallbackIcon: FontAwesomeIcons.house,
                              color: AppColors.iconPrimary,
                            ),
                            selectedIcon: _buildSvgIcon(
                              svgPath: 'assets/icons/home.svg',
                              fallbackIcon: FontAwesomeIcons.house,
                              color: AppColors.iconSecondary,
                            ),
                            label: "Inicio",
                            index: 0,
                            currentIndex: _selectedIndex,
                            onTap: () => _onItemTapped(0),
                          ),

                          _buildNavItem(
                            icon: _buildSvgIcon(
                              svgPath: 'assets/icons/patient_grey.svg',
                              fallbackIcon: FontAwesomeIcons.userInjured,
                              color: AppColors.iconPrimary,
                            ),
                            selectedIcon: _buildSvgIcon(
                              svgPath: 'assets/icons/patient.svg',
                              fallbackIcon: FontAwesomeIcons.userInjured,
                              color: AppColors.iconSecondary,
                            ),
                            label: "Pacientes",
                            index: 1,
                            currentIndex: _selectedIndex,
                            onTap: () => _onItemTapped(1),
                          ),

                          _buildNavItem(
                            icon: _buildSvgIcon(
                              svgPath: 'assets/icons/recetas_icon_grey.svg',
                              fallbackIcon: FontAwesomeIcons.utensils,
                              color: AppColors.iconPrimary,
                            ),
                            selectedIcon: _buildSvgIcon(
                              svgPath: 'assets/icons/recetas_icon.svg',
                              fallbackIcon: FontAwesomeIcons.utensils,
                              color: AppColors.iconSecondary,
                            ),
                            label: "Recetas",
                            index: 2,
                            currentIndex: _selectedIndex,
                            onTap: () => _onItemTapped(2),
                          ),

                          _buildNavItem(
                            icon: _buildSvgIcon(
                              svgPath: 'assets/icons/profile_icon_grey.svg',
                              fallbackIcon: FontAwesomeIcons.userDoctor,
                              color: AppColors.iconPrimary,
                            ),
                            selectedIcon: _buildSvgIcon(
                              svgPath: 'assets/icons/profile_icon.svg',
                              fallbackIcon: FontAwesomeIcons.userDoctor,
                              color: AppColors.iconSecondary,
                            ),
                            label: "Perfil",
                            index: 3,
                            currentIndex: _selectedIndex,
                            onTap: () => _onItemTapped(3),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required Widget icon,
    required Widget selectedIcon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isSelected ? selectedIcon : icon,
          Text(
            label,
            style: TextStyle(
                color: isSelected ? AppColors.textLight : AppColors.textInput,
                fontSize: 12
            ),
          ),
        ],
      ),
    );
  }
}