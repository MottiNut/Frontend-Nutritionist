import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/setting_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../configuration/themes/app_colors.dart';
import '../../../domain/auth/entities/user_profile.dart';
import '../../../domain/auth/enums/specialty_type.dart';
import '../../../domain/auth/enums/verification_status.dart';
import '../../../domain/auth/value_objects/cnp_code.dart';
import '../../../domain/auth/value_objects/email.dart';
import '../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import '../../../domain/services/auth_provider.dart';
import '../home/active_patients_screen.dart';
import 'editProfile/edit_profile_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;

class ProfileScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final String? username;

  const ProfileScreen({
    super.key,
    this.userProfile,
    this.username,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  UserProfile? profile;
  String? _errorMessage;
  bool _isLoading = true;
  bool _hasAttemptedLoad = false;

  bool _usingCachedData = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeProfile();
    _precacheUserAvatar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  void _initializeProfile() async {
    final authProvider = context.read<AuthProvider>();
    if (widget.userProfile != null) {
      profile = widget.userProfile;
      _isLoading = false;
      if (mounted) setState(() {});
      return;
    }

    if (authProvider.isAuthenticated) {
      await _loadProfileData(authProvider);
    } else {
      _isLoading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadProfileData(AuthProvider authProvider) async {
    if (_hasAttemptedLoad) return;

    if (authProvider.user != null) {
      setState(() {
        profile = _createProfileFromAuthProvider(authProvider);
        _usingCachedData = true;
        _isLoading = false;
      });
    }

    setState(() {
      _hasAttemptedLoad = true;
    });

    try {
      final success = await authProvider.loadUserProfile();

      if (success && authProvider.user != null && mounted) {
        final newProfile = _createProfileFromAuthProvider(authProvider);

        if (profile == null ||
            newProfile.updatedAt != profile!.updatedAt ||
            !_areProfilesEqual(profile!, newProfile)) {
          setState(() {
            profile = newProfile;
            _usingCachedData = false;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Profile background refresh error: $e');
    }
  }

  bool _areProfilesEqual(UserProfile a, UserProfile b) {
    return a.id == b.id &&
        a.firstName == b.firstName &&
        a.lastName == b.lastName &&
        a.email.value == b.email.value &&
        a.photoUrl == b.photoUrl;
  }

  void _precacheUserAvatar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _preloadAvatarImage(authProvider);
    });
  }

  void _preloadAvatarImage(AuthProvider authProvider) async {
    if (authProvider.user != null) {
      final userData = authProvider.user!;
      final userId = userData['id'] ?? userData['userId'];

      String? profileImageUrl = userData['profileImageUrl'] ??
          userData['profileImage'] ??
          userData['profile_image'] ??
          userData['avatar'] ??
          userData['photo'] ??
          userData['imageUrl'] ??
          userData['image_url'];

      if ((profileImageUrl == null || profileImageUrl.isEmpty) &&
          userId != null) {
        profileImageUrl = AuthService.buildProfileImageUrl(userId.toString());
      }

      if (profileImageUrl != null &&
          profileImageUrl.isNotEmpty &&
          userId != null) {
        unawaited(AuthService.preloadAvatarImage(
          imageUrl: profileImageUrl,
          token: authProvider.token,
          userId: userId.toString(),
        ));
      }
    }
  }

  UserProfile _createProfileFromAuthProvider(AuthProvider authProvider) {
    final userData = authProvider.user!;
    final emailStr = authProvider.email;

    return UserProfile(
      id: userData['id']?.toString() ??
          userData['userId']?.toString() ??
          userData['_id']?.toString() ??
          '1',
      firstName: userData['firstName']?.toString() ??
          _extractFirstName(userData['fullName']?.toString() ?? 'Usuario'),
      lastName: userData['lastName']?.toString() ??
          _extractLastName(userData['fullName']?.toString() ?? 'Desconocido'),
      email: Email(
          emailStr ?? userData['email']?.toString() ?? 'usuario@ejemplo.com'),
      photoUrl: _extractProfileImageUrl(userData, authProvider),
      cnpCode: CNPCode(userData['cnpCode']?.toString() ??
          userData['cnp']?.toString() ??
          userData['licenseNumber']?.toString() ??
          '0000'),
      specialty: _parseSpecialty(userData['specialty']?.toString()),
      masterDegree: userData['masterDegree']?.toString() ??
          userData['education']?.toString() ??
          userData['degree']?.toString(),
      otherSpecialty: userData['otherSpecialty']?.toString(),
      location: userData['location']?.toString() ??
          userData['city']?.toString() ??
          userData['ubication']?.toString() ??
          'No especificada',
      address: userData['address']?.toString() ??
          userData['fullAddress']?.toString() ??
          userData['direction']?.toString() ??
          'No especificada',
      phone: userData['phone']?.toString() ??
          userData['phoneNumber']?.toString() ??
          userData['telephone']?.toString(),
      experience: userData['experience']?.toString() ??
          userData['yearsExperience']?.toString() ??
          userData['expYears']?.toString(),
      createdAt: _parseDateTime(userData['createdAt']) ?? DateTime.now(),
      verificationStatus: _parseVerificationStatus(userData),
      updatedAt: _parseDateTime(userData['updatedAt']) ?? DateTime.now(),
    );
  }

  String? _extractProfileImageUrl(
      Map<String, dynamic> userData, AuthProvider authProvider) {
    // Intentar múltiples campos para la imagen
    String? imageUrl = userData['profileImageUrl']?.toString() ??
        userData['profileImage']?.toString() ??
        userData['photoUrl']?.toString() ??
        userData['photoURL']?.toString() ??
        userData['avatar']?.toString() ??
        userData['image']?.toString() ??
        userData['picture']?.toString();

    if ((imageUrl == null || imageUrl.isEmpty) && userData['id'] != null) {
      final userId = userData['id'].toString();
      imageUrl =
      'https://mottinut-backend-2025-djf0f5c0hjckhpgp.centralus-01.azurewebsites.net/api/bff/auth/profile/nutritionist/$userId/image';
    }

    if (imageUrl != null && authProvider.token != null) {
      // Verificar si la URL ya tiene parámetros de consulta
      final separator = imageUrl.contains('?') ? '&' : '?';
      imageUrl = '$imageUrl${separator}token=${authProvider.token}';
    }

    return imageUrl;
  }


  // Métodos auxiliares sin cambios
  String _extractFirstName(String fullName) {
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts.first : 'Usuario';
  }

  String _extractLastName(String fullName) {
    final parts = fullName.split(' ');
    return parts.length > 1 ? parts.skip(1).join(' ') : 'Desconocido';
  }

  SpecialtyType _parseSpecialty(String? specialty) {
    if (specialty == null) return SpecialtyType.nutricionClinica;

    switch (specialty.toLowerCase()) {
      case 'nutricion_clinica':
      case 'nutricionclinica':
      case 'clinical_nutrition':
      case 'clinical nutrition':
        return SpecialtyType.nutricionClinica;
      case 'dietista':
      case 'dietitian':
        return SpecialtyType.dietista;
      case 'nutricionista':
      case 'nutritionist':
        return SpecialtyType.nutricionista;
      case 'nutricion_deportiva':
      case 'nutriciondeportiva':
      case 'sports_nutrition':
      case 'sports nutrition':
        return SpecialtyType.nutricionDeportiva;
      case 'other':
      case 'otra':
      case 'otro':
        return SpecialtyType.other;
      default:
        return SpecialtyType.nutricionClinica;
    }
  }

  VerificationStatus _parseVerificationStatus(Map<String, dynamic> userData) {
    final emailVerified = userData['emailVerified'] ?? false;
    final phoneVerified = userData['phoneVerified'] ?? false;
    final fullyVerified = userData['fullyVerified'] ?? false;
    final isVerified = userData['isVerified'] ?? false;
    final verificationStatus = userData['verificationStatus']?.toString();

    if (verificationStatus != null) {
      switch (verificationStatus.toLowerCase()) {
        case 'verified':
        case 'verificado':
        case 'approved':
          return VerificationStatus.verified;
        case 'pending':
        case 'pendiente':
        case 'in_review':
        case 'in review':
          return VerificationStatus.pending;
        case 'rejected':
        case 'rechazado':
        case 'denied':
          return VerificationStatus.rejected;
      }
    }

    if (fullyVerified || isVerified || (emailVerified && phoneVerified)) {
      return VerificationStatus.verified;
    } else if (emailVerified || phoneVerified) {
      return VerificationStatus.pending;
    }

    return VerificationStatus.pending;
  }

  DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void _updateProfile(UserProfile updatedProfile) {
    setState(() {
      profile = updatedProfile;
    });
  }

  Future<void> _refreshProfile() async {
    final authProvider = context.read<AuthProvider>();

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await authProvider.loadUserProfile(forceRefresh: true);

      if (authProvider.user != null && mounted) {
        setState(() {
          profile = _createProfileFromAuthProvider(authProvider);
          _usingCachedData = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error actualizando perfil: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getDisplayName() {
    if (widget.username != null && widget.username!.isNotEmpty) {
      return widget.username!;
    }
    return profile?.fullName ?? 'Usuario';
  }

  String _getSpecialtyText() {
    if (profile == null) return 'Nutricionista';

    switch (profile!.specialty) {
      case SpecialtyType.nutricionClinica:
        return 'Nutrición Clínica';
      case SpecialtyType.dietista:
        return 'Dietista';
      case SpecialtyType.nutricionista:
        return 'Nutricionista';
      case SpecialtyType.nutricionDeportiva:
        return 'Nutrición Deportiva';
      case SpecialtyType.other:
        return profile!.otherSpecialty ?? 'Otra especialidad';
      default:
        return 'Nutricionista';
    }
  }

  bool _isVerified() {
    return profile?.verificationStatus == VerificationStatus.verified;
  }

  // Reemplazar el método build() completo
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLigth,
      body: _isLoading ? _buildLoading() : _buildProfileContent(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            "assets/loading/palta_saltarina.json",
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }


  Widget _buildProfileContent() {
    if (profile == null) {
      return _buildErrorState();
    }

    final displayName = _getDisplayName();
    final specialtyText = _getSpecialtyText();

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return RefreshIndicator(
          backgroundColor: AppColors.iconSecondary,
          color: AppColors.primary,
          onRefresh: _refreshProfile,
          child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.3,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  title: const Text(
                    'Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                  centerTitle: false,
                  actions: [
                    IconButton(
                      icon: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                            child: const Icon(
                              Icons.reply,
                              color: Colors.white,
                              size: 26,
                            ),
                          )
                      ),
                      onPressed: _shareProfile,
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                            AppColors.backgroundDetail,
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 45),
                          // FOTO DE PERFIL
                          Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _buildProfileImage(authProvider),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => EditProfileScreen(
                                          userProfile: profile!,
                                          onProfileUpdated: _updateProfile,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Nombre
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            specialtyText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                        child: Column(
                          children: [
                            if (_errorMessage != null) ...[
                              _buildErrorMessage(),
                            ],
                            _buildStatsRow(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      _buildTabBar(),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildTipsGrid(),
                _buildRecipesGrid(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Material(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2.5,
          ),
          insets: EdgeInsets.symmetric(horizontal: 60),
        ),
        indicatorPadding: EdgeInsets.zero,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey[500],
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        splashFactory: NoSplash.splashFactory,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        dividerColor: Colors.grey[200],
        tabs: [
          Tab(
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_on, size: 20),
                const SizedBox(height: 2),
                Text('Tips'),
              ],
            ),
          ),
          Tab(
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 20),
                const SizedBox(height: 2),
                Text('Recetas'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsGrid() {
    // Para demostración, agrega algunas imágenes de ejemplo
    final List<String> tips = [

      // 'tip1', 'tip2', 'tip3', 'tip4', 'tip5', 'tip6',
    ];

    if (tips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.lightbulb_outline,
        title: '¡Comparte tus mejores consejos!',
        subtitle: 'Ayuda a tus pacientes con tips valiosos',
        //actionText: '',//Crear primer tip
        onAction: () {
          // Aquí iría la navegación para crear contenido
          print('Crear tip');
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Aquí irían las imágenes reales
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.primary.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.lightbulb,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              // Overlay para simular contenido tipo TikTok/Instagram
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${10 + index}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecipesGrid() {
    final List<String> recipes = [
      // Descomenta para probar
      // 'recipe1', 'recipe2', 'recipe3',
    ];

    if (recipes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant_menu_outlined,
        title: 'No hay recetas aún',
        subtitle: 'Comparte recetas saludables con tus pacientes',
        //actionText: '', //Crear primera receta
        onAction: () {
          print('Crear receta');
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.withOpacity(0.3),
                      Colors.orange.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${5 + index}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionText != null && onAction != null) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Reemplaza el método _shareProfile() en tu ProfileScreen

  Future<void> _shareProfile() async {
    final authProvider = context.read<AuthProvider>();

    try {
      // Generar URL del perfil web
      final profileUrl = _generateProfileWebUrl(authProvider);

      if (profileUrl == null) {
        throw Exception('No se pudo generar la URL del perfil');
      }

      // Intentar compartir usando Share Plus
      final result = await Share.shareWithResult(
        'Mira mi perfil profesional: $profileUrl',
        subject: 'Perfil de ${_getDisplayName()}',
      );

      // Manejar diferentes resultados del share
      if (result.status == ShareResultStatus.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil compartido exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (result.status == ShareResultStatus.dismissed) {
        // Usuario canceló el share - no mostrar error
        return;
      } else {
        // Error o no hay apps disponibles - abrir en navegador
        await _openProfileInBrowser(profileUrl);
      }
    } catch (e) {
      // Fallback: intentar abrir en navegador o copiar enlace
      try {
        final profileUrl = _generateProfileWebUrl(authProvider);
        if (profileUrl != null) {
          await _openProfileInBrowser(profileUrl);
        } else {
          throw e;
        }
      } catch (fallbackError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error compartiendo perfil: $fallbackError'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  String? _generateProfileWebUrl(AuthProvider authProvider) {
    try {
      final userData = authProvider.user;
      if (userData == null) return null;

      final userId = userData['id'] ?? userData['userId'];
      if (userId == null) return null;

      // Para desarrollo local
      if (kDebugMode) {
        return 'http://192.168.0.8:5000/profile/$userId';
      }

      // Para producción
      return 'https://mottinut-backend-2025-djf0f5c0hjckhpgp.centralus-01.azurewebsites.net/api/bff/profile/$userId';
    } catch (e) {
      debugPrint('Error generando URL del perfil: $e');
      return null;
    }
  }

  Future<void> _openProfileInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil abierto en el navegador'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Si no puede abrir, copiar al clipboard
        await _copyToClipboard(url);
      }
    } catch (e) {
      // Fallback final: copiar al clipboard
      await _copyToClipboard(url);
    }
  }

  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enlace del perfil copiado al portapapeles'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

// También actualiza el método _showShareMenu() para incluir más opciones
  void _showShareMenu() {
    final authProvider = context.read<AuthProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Compartir Perfil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Compartir usando apps
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.share,
                  color: AppColors.primary,
                ),
              ),
              title: const Text('Compartir enlace'),
              subtitle: const Text('Usar apps instaladas o abrir en navegador'),
              onTap: () {
                Navigator.pop(context);
                _shareProfile();
              },
            ),

            // Abrir en navegador directamente
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.open_in_browser,
                  color: Colors.blue,
                ),
              ),
              title: const Text('Abrir en navegador'),
              subtitle: const Text('Ver perfil directamente en el navegador'),
              onTap: () async {
                Navigator.pop(context);
                final profileUrl = _generateProfileWebUrl(authProvider);
                if (profileUrl != null) {
                  await _openProfileInBrowser(profileUrl);
                }
              },
            ),

            // Copiar enlace
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.link,
                  color: Colors.orange,
                ),
              ),
              title: const Text('Copiar enlace'),
              subtitle: const Text('Copiar enlace al portapapeles'),
              onTap: () async {
                Navigator.pop(context);
                final profileUrl = _generateProfileWebUrl(authProvider);
                if (profileUrl != null) {
                  await _copyToClipboard(profileUrl);
                }
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  Future<void> _copyProfileLink(AuthProvider authProvider) async {
    try {
      await authProvider.copyShareLinkToClipboard();

      if (authProvider.errorMessage == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enlace copiado al portapapeles'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copiando enlace: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildProfileImage(AuthProvider authProvider) {
    String? profileImageUrl;
    int? userId;

    if (authProvider.user != null) {
      final userData = authProvider.user!;
      userId = userData['id'] ?? userData['userId'];

      // Buscar URL directa de imagen
      profileImageUrl = userData['profileImageUrl'] ??
          userData['profileImage'] ??
          userData['profile_image'] ??
          userData['avatar'] ??
          userData['photo'] ??
          userData['imageUrl'] ??
          userData['image_url'];

      // Usar el método del servicio para construir la URL si no hay una directa
      if ((profileImageUrl == null || profileImageUrl.isEmpty) &&
          userId != null) {
        profileImageUrl = AuthService.buildProfileImageUrl(userId.toString());
      }
    }

    // Mostrar la imagen con caché del servicio
    if (profileImageUrl != null &&
        profileImageUrl.isNotEmpty &&
        userId != null) {
      return FutureBuilder<File?>(
        future: AuthService.getLocalAvatarImage(userId.toString()),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(
              snapshot.data!,
              fit: BoxFit.cover,
            );
          }

          return CachedNetworkImage(
            imageUrl: profileImageUrl!,
            httpHeaders: {
              if (authProvider.token != null)
                'Authorization': 'Bearer ${authProvider.token}',
            },
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              debugPrint('Error cargando imagen de perfil: $error');
              return Image.asset(
                'assets/images/placeholder_nutri.jpg',
                fit: BoxFit.cover,
              );
            },
            cacheManager: AuthService.avatarCacheManager,
          );
        },
      );
    } else {
      return Image.asset(
        'assets/images/placeholder_nutri.jpg',
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error cargando perfil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshProfile,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.orange[800]),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: Colors.orange[600]),
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return DynamicStatsRow(
      token: authProvider.token!,
      nutritionistService: NutritionistService(),
    );
  }

  String _getVerificationStatusText() {
    if (profile == null) return 'Sin verificar';

    switch (profile!.verificationStatus) {
      case VerificationStatus.verified:
        return 'Verificado';
      case VerificationStatus.pending:
        return 'Pendiente';
      case VerificationStatus.rejected:
        return 'Rechazado';
      default:
        return 'Sin verificar';
    }
  }
}

class NutritionistStats {
  final int consultationCount;
  final int patientCount;
  final double rating;

  NutritionistStats({
    required this.consultationCount,
    required this.patientCount,
    required this.rating,
  });

  factory NutritionistStats.fromJson(Map<String, dynamic> json) {
    return NutritionistStats(
      consultationCount: json['consultationCount'] ?? 0,
      patientCount: json['patientCount'] ?? 0,
      rating: json['rating']?.toDouble() ?? 0.0,
    );
  }
}

class DynamicStatsRow extends StatefulWidget {
  final String token;
  final NutritionistService nutritionistService;

  const DynamicStatsRow({
    Key? key,
    required this.token,
    required this.nutritionistService,
  }) : super(key: key);

  @override
  _DynamicStatsRowState createState() => _DynamicStatsRowState();
}

class _DynamicStatsRowState extends State<DynamicStatsRow> {
  late Future<NutritionistStats> _statsFuture;
  late StatsService _statsService;

  @override
  void initState() {
    super.initState();
    _statsService = StatsService(widget.nutritionistService);
    _statsFuture = _statsService.getNutritionistStats(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NutritionistStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingStats();
        } else if (snapshot.hasError) {
          return _buildErrorStats(snapshot.error.toString());
        } else if (snapshot.hasData) {
          final stats = snapshot.data!;
          return _buildStatsRow(
            consultationCount: stats.consultationCount,
            patientCount: stats.patientCount,
            rating: stats.rating,
          );
        } else {
          return _buildPlaceholderStats();
        }
      },
    );
  }

  Widget _buildLoadingStats() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 5, 14, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLoadingStatItem(Icons.medical_services_outlined),
          _buildVerticalDivider(),
          _buildLoadingStatItem(Icons.people_outline),
          _buildVerticalDivider(),
          _buildLoadingStatItem(Icons.star_outline),
        ],
      ),
    );
  }

  Widget _buildLoadingStatItem(IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 60,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorStats(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Error cargando estadísticas',
          style: TextStyle(
            color: Colors.red[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderStats() {
    return _buildStatsRow(
      consultationCount: 0,
      patientCount: 0,
      rating: 0.0,
    );
  }

  Widget _buildStatsRow({
    required int consultationCount,
    required int patientCount,
    required double rating,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 0.3, color: Colors.grey.shade200),

      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Consultas',
            _formatNumber(consultationCount),
            Icons.medical_services_outlined,
          ),
          _buildVerticalDivider(),

          // 👇 Pacientes con tap
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActivePatientsScreen(
                    nutritionistService: widget.nutritionistService,
                  ),
                ),
              );
            },
            child: _buildStatItem(
              'Pacientes',
              _formatNumber(patientCount),
              Icons.people_outline,
            ),
          ),

          _buildVerticalDivider(),
          _buildStatItem(
            'Rating',
            '${rating.toStringAsFixed(1)}',
            Icons.star_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 0.5,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      double result = number / 1000000;
      return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}M';
    } else if (number >= 1000) {
      double result = number / 1000;
      return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}K';
    }
    return number.toString();
  }
}

class StatsCache {
  static NutritionistStats? _cachedStats;
  static DateTime? _lastUpdate;

  static void cacheStats(NutritionistStats stats) {
    _cachedStats = stats;
    _lastUpdate = DateTime.now();
  }

  static NutritionistStats? getCachedStats() {
    if (_lastUpdate == null) return null;
    // Invalidar cache después de 5 minutos
    if (DateTime.now().difference(_lastUpdate!) > Duration(minutes: 5)) {
      _cachedStats = null;
      return null;
    }
    return _cachedStats;
  }

  static void clearCache() {
    _cachedStats = null;
    _lastUpdate = null;
  }
}

class StatsService {
  final NutritionistService _nutritionistService;

  StatsService(this._nutritionistService);

  Future<NutritionistStats> getNutritionistStats(String token) async {
    final cachedStats = StatsCache.getCachedStats();
    if (cachedStats != null) {
      return cachedStats;
    }

    try {
      // Obtener todos los pacientes para contar
      final patients = await _nutritionistService.getAllPatients(token: token);
      final patientCount = patients.length;

      // Calcular consultas sumando historiales médicos
      int consultationCount = 0;
      for (var patient in patients) {
        try {
          final history = await _nutritionistService.getPatientHistory(
              patient.patientId, token);
          consultationCount += history.length;
        } catch (e) {
          print(
              'Error obteniendo historial para paciente ${patient.patientId}: $e');
          // Continuar con el siguiente paciente
        }
      }

      // Obtener rating (en una implementación real, esto vendría de la API)
      double rating = await _getNutritionistRating(token);

      final stats = NutritionistStats(
        consultationCount: consultationCount,
        patientCount: patientCount,
        rating: rating,
      );

      // Guardar en cache
      StatsCache.cacheStats(stats);

      return stats;
    } catch (e) {
      if (cachedStats != null) {
        return cachedStats;
      }
      rethrow;
    }
  }

  Future<double> _getNutritionistRating(String token) async {
    // Esta es una implementación de ejemplo
    // En una app real, tendrías un endpoint específico para ratings
    try {
      // Simular obtención de rating - reemplazar con llamada real a tu API
      return 0; // Valor por defecto
    } catch (e) {
      print('Error obteniendo rating: $e');
      return 0; // Valor por defecto en caso de error
    }
  }
}