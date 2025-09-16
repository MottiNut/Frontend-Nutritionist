import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/setting_screen.dart';
import '../../../configuration/themes/app_colors.dart';
import '../../../domain/auth/entities/user_profile.dart';
import '../../../domain/auth/enums/specialty_type.dart';
import '../../../domain/auth/enums/verification_status.dart';
import '../../../domain/auth/value_objects/cnp_code.dart';
import '../../../domain/auth/value_objects/email.dart';
import 'editProfile/edit_profile_screen.dart';
import '../../../domain/services/auth_provider.dart';
import '../../../domain/services/auth_service.dart';

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

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile profile;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    profile = widget.userProfile ?? _createDemoProfile();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user != null) {
      _buildProfileFromAuthData(authProvider);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final success = await authProvider.loadUserProfile();

      if (success && authProvider.user != null) {
        _buildProfileFromAuthData(authProvider);
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'No se pudieron cargar los datos del perfil';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error al cargar el perfil: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _buildProfileFromAuthData(AuthProvider authProvider) {
    final userData = authProvider.user!;

    // DEBUG: Mostrar la estructura completa de los datos
    debugPrint('=== DATOS DEL USUARIO RECIBIDOS ===');
    userData.forEach((key, value) {
      debugPrint('$key: $value');
    });
    debugPrint('==================================');

    profile = UserProfile(
      id: userData['id']?.toString() ??
          userData['userId']?.toString() ??
          userData['_id']?.toString() ?? '1',

      firstName: userData['firstName'] ??
          userData['first_name'] ??
          userData['name']?.split(' ').first ??
          '',

      lastName: userData['lastName'] ??
          userData['last_name'] ??
          userData['name']?.split(' ').last ??
          '',

      email: Email(userData['email'] ?? 'usuario@ejemplo.com'),

      // Múltiples posibles campos para la foto
      photoUrl: _extractProfileImageUrl(userData),

      // Múltiples posibles campos para el CNP
      cnpCode: CNPCode(userData['cnpCode']?.toString() ??
          userData['cnp_code']?.toString() ??
          userData['cnp']?.toString() ??
          userData['licenseNumber']?.toString() ??
          ' '),

      cnpPhotoUrls: [],

      // Múltiples posibles campos para la especialidad
      specialty: _parseSpecialty(userData['specialty'] ??
          userData['speciality'] ??
          userData['especialidad']),

      masterDegree: userData['masterDegree'] ??
          userData['master_degree'] ??
          userData['degree'] ??
          userData['titulo'],

      otherSpecialty: userData['otherSpecialty'] ??
          userData['other_specialty'] ??
          userData['especialidad_alternativa'],

      location: userData['location'] ??
          userData['ubicacion'] ??
          userData['city'] ??
          'Lima, Perú',

      address: userData['address'] ??
          userData['direccion'] ??
          userData['street'] ??
          'Av. Principal 123',

      createdAt: DateTime.now(),
      verificationStatus: _parseVerificationStatus(userData),
      updatedAt: DateTime.now(),
    );


  }

  String? _extractProfileImageUrl(Map<String, dynamic> userData) {
    // Prueba múltiples campos posibles para la imagen
    return userData['profileImageUrl'] ??
        userData['profileImage'] ??
        userData['profile_image'] ??
        userData['avatar'] ??
        userData['photo'] ??
        userData['imageUrl'] ??
        userData['image_url'] ??
        userData['foto'] ??
        userData['imagen'];
  }

  SpecialtyType _parseSpecialty(dynamic specialty) {
    if (specialty == null) return SpecialtyType.nutricionClinica;

    final String specialtyStr = specialty.toString().toLowerCase();

    if (specialtyStr.contains('clinic') || specialtyStr.contains('clínica'))
      return SpecialtyType.nutricionClinica;
    if (specialtyStr.contains('sport') || specialtyStr.contains('deport'))
      return SpecialtyType.nutricionDeportiva;
    if (specialtyStr.contains('pediatr') || specialtyStr.contains('niño'))
      return SpecialtyType.nutricionista;
    if (specialtyStr.contains('geriatr') || specialtyStr.contains('anciano'))
      return SpecialtyType.dietista;

    return SpecialtyType.nutricionClinica;
  }

  VerificationStatus _parseVerificationStatus(Map<String, dynamic> userData) {
    // Múltiples campos posibles para verificación
    final emailVerified = userData['emailVerified'] ??
        userData['email_verified'] ??
        userData['verified'] ??
        false;

    final phoneVerified = userData['phoneVerified'] ??
        userData['phone_verified'] ??
        false;

    final fullyVerified = userData['fullyVerified'] ??
        userData['fully_verified'] ??
        userData['isVerified'] ??
        false;

    if (fullyVerified == true) return VerificationStatus.verified;
    if (emailVerified == true || phoneVerified == true) return VerificationStatus.pending;
    return VerificationStatus.rejected;
  }

  UserProfile _createDemoProfile() {
    return UserProfile(
      id: '1',
      firstName: 'Ana María',
      lastName: 'González',
      email: Email('usuario@ejemplo.com'),
      photoUrl: null,
      cnpCode: CNPCode('4945'),
      cnpPhotoUrls: [],
      specialty: SpecialtyType.nutricionClinica,
      masterDegree: 'Magíster en Nutrición Clínica',
      otherSpecialty: null,
      location: 'Lima, Perú',
      address: 'Av. Principal 123',
      createdAt: DateTime.now(),
      verificationStatus: VerificationStatus.verified,
      updatedAt: DateTime.now(),
    );
  }

  void _updateProfile(UserProfile updatedProfile) {
    setState(() {
      profile = updatedProfile;
    });
  }

  String _getDisplayName() {
    if (widget.username != null && widget.username!.isNotEmpty) {
      return widget.username!;
    }
    return profile.fullName;
  }

  String _getSpecialtyText() {
    switch (profile.specialty) {
      case SpecialtyType.nutricionClinica:
        return 'Nutrición Clínica';
      case SpecialtyType.dietista:
        return 'Nutrición Deportiva';
      case SpecialtyType.nutricionista:
        return 'Nutrición Pediátrica';
      case SpecialtyType.nutricionDeportiva:
        return 'Nutrición Geriátrica';
      case SpecialtyType.other:
        return profile.otherSpecialty ?? 'Otra especialidad';
      default:
        return 'Nutricionista';
    }
  }

  bool _isVerified() {
    return profile.verificationStatus == VerificationStatus.verified;
  }

  Widget _buildProfileAvatar(AuthProvider authProvider) {
    final String? profileImageUrl = profile.photoUrl;
    final String? userId = profile.id;

    if (profileImageUrl != null && profileImageUrl.isNotEmpty && userId != null) {
      return FutureBuilder<File?>(
        future: AuthService.getLocalAvatarImage(userId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return ClipOval(
              child: Image.file(
                snapshot.data!,
                width: 130,
                height: 130,
                fit: BoxFit.cover,
              ),
            );
          }

          return ClipOval(
            child: CachedNetworkImage(
              imageUrl: profileImageUrl,
              width: 130,
              height: 130,
              fit: BoxFit.cover,
              httpHeaders: {
                if (authProvider.token != null)
                  'Authorization': 'Bearer ${authProvider.token}',
              },
              placeholder: (context, url) => _buildDefaultAvatar(),
              errorWidget: (context, url, error) {
                debugPrint('Error loading profile image: $error');
                return _buildDefaultAvatar();
              },
              cacheManager: AuthService.avatarCacheManager,
            ),
          );
        },
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.7),
            AppColors.primary,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        size: 50,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundLigth,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Cargando perfil...',
              style: TextStyle(
                color: AppColors.textPrimary1,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundLigth,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorText,
            ),
            const SizedBox(height: 20),
            Text(
              'Error al cargar',
              style: TextStyle(
                color: AppColors.errorText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _errorMessage ?? 'Ocurrió un error inesperado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textLDark,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loadUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_hasError) {
      return _buildErrorScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final displayName = _getDisplayName();
        final specialtyText = _getSpecialtyText();

        return Scaffold(
          backgroundColor: AppColors.backgroundLigth,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings,
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
                  const SizedBox(width: 16),
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
                        const SizedBox(height: 80),
                        Stack(
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: _buildProfileAvatar(authProvider),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => EditProfileScreen(
                                        userProfile: profile,
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
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isVerified()) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.checkValidation,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          specialtyText,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Mostrar el CNP code debajo de la especialidad
                        Text(
                          'CNP: ${profile.cnpCode.value}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      _buildInfoSection(),
                      const SizedBox(height: 24),
                      _buildContactSection(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 40),
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

  // Los métodos _buildStatsRow, _buildInfoSection, etc. se mantienen igual que en tu código original
  Widget _buildStatsRow() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Consultas', '1,250', Icons.medical_services_outlined),
          _buildVerticalDivider(),
          _buildStatItem('Pacientes', '5.8K', Icons.people_outline),
          _buildVerticalDivider(),
          _buildStatItem('Rating', '4.9⭐', Icons.star_outline),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
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

  Widget _buildInfoSection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.work_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información Profesional',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.badge_outlined, 'CNP', profile.cnpCode.toString()),
          const SizedBox(height: 16),
          if (profile.masterDegree != null && profile.masterDegree!.isNotEmpty)
            _buildInfoRow(Icons.school_outlined, 'Título', profile.masterDegree!),
          if (profile.masterDegree != null && profile.masterDegree!.isNotEmpty)
            const SizedBox(height: 16),
          _buildInfoRow(Icons.schedule_outlined, 'Experiencia', '8 años'),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.verified_user_outlined,
            'Estado',
            _getVerificationStatusText(),
            textColor: _isVerified() ? AppColors.checkValidation : AppColors.secondary,
          ),
        ],
      ),
    );
  }

  String _getVerificationStatusText() {
    switch (profile.verificationStatus) {
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

  Widget _buildContactSection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.contact_mail_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Contacto y Ubicación',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.email_outlined, 'Email', profile.email.toString()),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on_outlined, 'Ubicación', profile.location),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.home_outlined, 'Dirección', profile.address),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? textColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              // Agendar cita
            },
            icon: const Icon(Icons.calendar_today, size: 20),
            label: const Text(
              'Agendar Consulta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Enviar mensaje
                  },
                  icon: const Icon(Icons.message_outlined, size: 18),
                  label: const Text(
                    'Mensaje',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: Colors.transparent,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.secondary, width: 1.5),
                ),
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Compartir perfil
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text(
                    'Compartir',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    backgroundColor: Colors.transparent,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}