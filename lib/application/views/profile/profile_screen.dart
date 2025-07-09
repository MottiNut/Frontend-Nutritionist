import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:mottinutnutriotinist/application/views/profile/setting/setting_screen.dart';
import 'package:share_plus/share_plus.dart';
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
  UserProfile? _profile;
  bool _isInitializing = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  int _totalPatients = 0;
  int _totalConsultations = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
    _loadStats(); // Cargar stats en paralelo
  }

  Future<void> _initializeProfile() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      // Si ya tenemos el perfil del widget, úsalo inmediatamente
      if (widget.userProfile != null) {
        _profile = widget.userProfile;
        setState(() {
          _isInitializing = false;
        });
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Primero intenta crear el perfil con los datos que ya tenemos en memoria
      if (authProvider.user != null) {
        _profile = _createProfileFromUserData(authProvider.user!);
        setState(() {
          _isInitializing = false;
        });
      }

      // Luego carga los datos frescos del backend en segundo plano
      _loadFreshProfileData();

    } catch (e) {
      _handleProfileError(e);
    }
  }

  Future<void> _loadFreshProfileData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Cargar datos frescos del backend
      final success = await authProvider.loadUserProfile();

      if (success && authProvider.user != null) {
        final freshProfile = _createProfileFromUserData(authProvider.user!);

        // Solo actualizar si hay cambios significativos
        if (mounted && _profile != freshProfile) {
          setState(() {
            _profile = freshProfile;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading fresh profile data: $e');
      // No mostrar error si ya tenemos datos básicos
    }
  }

  Future<void> _loadStats() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        final nutritionistService = NutritionistService();

        // Cargar pacientes
        final patients = await nutritionistService.getAllPatients(token: token);

        if (mounted) {
          setState(() {
            _totalPatients = patients.length;
            _isLoadingStats = false;
          });
        }

        // Cargar consultas en segundo plano
        _loadConsultationsCount(nutritionistService, token, patients);
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadConsultationsCount(
      NutritionistService nutritionistService,
      String token,
      List<dynamic> patients) async {
    try {
      int totalConsultations = 0;

      // Cargar consultas por lotes para mejor rendimiento
      for (int i = 0; i < patients.length; i += 5) {
        final batch = patients.skip(i).take(5).toList();

        final futures = batch.map((patient) async {
          try {
            final histories = await nutritionistService.getPatientHistory(
                patient.patientId, token);
            return histories.length;
          } catch (e) {
            debugPrint('Error loading history for patient ${patient.patientId}: $e');
            return 0;
          }
        });

        final batchResults = await Future.wait(futures);
        totalConsultations += batchResults.fold(0, (sum, count) => sum + count);

        // Actualizar UI cada lote
        if (mounted) {
          setState(() {
            _totalConsultations = totalConsultations;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading consultations count: $e');
    }
  }

  void _handleProfileError(dynamic e) {
    debugPrint('Error in profile: $e');

    if (mounted) {
      setState(() {
        _errorMessage = 'Error cargando perfil: ${e.toString()}';
        _isInitializing = false;

      });
    }
  }

  UserProfile _createProfileFromUserData(Map<String, dynamic> userData) {
    try {
      return UserProfile(
        id: userData['id']?.toString() ?? userData['userId']?.toString() ?? '1',
        firstName: userData['firstName'] ?? userData['first_name'] ?? 'Usuario',
        lastName: userData['lastName'] ?? userData['last_name'] ?? 'Sin apellido',
        email: Email(userData['email'] ?? 'usuario@ejemplo.com'),
        photoUrl: userData['profileImageUrl'] ??
            userData['profileImage'] ??
            userData['profile_image'] ??
            userData['avatar'] ??
            userData['photo'] ??
            userData['imageUrl'] ??
            userData['image_url'],
        cnpCode: CNPCode(userData['cnpCode'] ?? userData['cnp_code'] ?? '0000'),
        cnpPhotoUrls: _extractCnpPhotoUrls(userData),
        specialty: _mapSpecialtyFromString(userData['specialty']),
        masterDegree: userData['masterDegree'] ?? userData['master_degree'] ?? userData['title'],
        otherSpecialty: userData['otherSpecialty'] ?? userData['other_specialty'],
        location: userData['location'] ?? userData['city'] ?? 'No especificado',
        address: userData['address'] ?? userData['full_address'] ?? 'No especificado',
        createdAt: _parseDateTime(userData['createdAt'] ?? userData['created_at']) ?? DateTime.now(),
        verificationStatus: _mapVerificationStatus(userData),
        updatedAt: _parseDateTime(userData['updatedAt'] ?? userData['updated_at']) ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error creating profile from user data: $e');
      // Retornar un perfil por defecto en caso de error
      return UserProfile(
        id: '1',
        firstName: 'Usuario',
        lastName: 'Sin apellido',
        email: Email('usuario@ejemplo.com'),
        photoUrl: null,
        cnpCode: CNPCode('0000'),
        cnpPhotoUrls: [],
        specialty: SpecialtyType.nutricionista,
        masterDegree: null,
        otherSpecialty: null,
        location: 'No especificado',
        address: 'No especificado',
        createdAt: DateTime.now(),
        verificationStatus: VerificationStatus.pending,
        updatedAt: DateTime.now(),
      );
    }
  }

  List<String> _extractCnpPhotoUrls(Map<String, dynamic> userData) {
    List<String> urls = [];

    final frontImage = userData['licenseFrontImageUrl'] ??
        userData['licenseFrontImage'] ??
        userData['license_front_image'] ??
        userData['cnpFrontImage'];

    final backImage = userData['licenseBackImageUrl'] ??
        userData['licenseBackImage'] ??
        userData['license_back_image'] ??
        userData['cnpBackImage'];

    if (frontImage != null && frontImage.isNotEmpty) {
      urls.add(frontImage);
    }
    if (backImage != null && backImage.isNotEmpty) {
      urls.add(backImage);
    }

    final cnpPhotoUrls = userData['cnpPhotoUrls'] ?? userData['cnp_photo_urls'];
    if (cnpPhotoUrls is List) {
      urls.addAll(cnpPhotoUrls.map((url) => url.toString()));
    }

    return urls;
  }

  SpecialtyType _mapSpecialtyFromString(String? specialty) {
    if (specialty == null) return SpecialtyType.nutricionista;

    switch (specialty.toLowerCase()) {
      case 'nutricion_clinica':
      case 'nutricionClinica':
      case 'clinical_nutrition':
        return SpecialtyType.nutricionClinica;
      case 'dietista':
      case 'dietitian':
        return SpecialtyType.dietista;
      case 'nutricion_deportiva':
      case 'nutricionDeportiva':
      case 'sports_nutrition':
        return SpecialtyType.nutricionDeportiva;
      case 'nutricionista':
      case 'nutritionist':
        return SpecialtyType.nutricionista;
      case 'other':
      case 'otra':
        return SpecialtyType.other;
      default:
        return SpecialtyType.nutricionista;
    }
  }

  VerificationStatus _mapVerificationStatus(Map<String, dynamic> userData) {
    final status = userData['verificationStatus'] ??
        userData['verification_status'] ??
        userData['emailVerified'] ??
        userData['email_verified'] ??
        userData['isVerified'] ??
        userData['verified'];

    if (status == null) return VerificationStatus.pending;

    if (status is bool) {
      return status ? VerificationStatus.verified : VerificationStatus.pending;
    }

    if (status is String) {
      switch (status.toLowerCase()) {
        case 'verified':
        case 'verificado':
        case 'true':
          return VerificationStatus.verified;
        case 'rejected':
        case 'rechazado':
        case 'false':
          return VerificationStatus.rejected;
        case 'pending':
        case 'pendiente':
        default:
          return VerificationStatus.pending;
      }
    }

    return VerificationStatus.pending;
  }

  DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;

    try {
      if (dateTime is String) {
        return DateTime.parse(dateTime);
      } else if (dateTime is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateTime);
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }

    return null;
  }

  void _updateProfile(UserProfile updatedProfile) {
    setState(() {
      _profile = updatedProfile;
    });
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isRefreshing = true;
    });

    await Future.wait([
      _loadFreshProfileData(),
      _loadStats(),
    ]);

    setState(() {
      _isRefreshing = false;
    });
  }

  String _getDisplayName() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user != null) {
      final userData = authProvider.user!;

      String? firstName = userData['firstName'] ?? userData['first_name'];
      String? lastName = userData['lastName'] ?? userData['last_name'];
      String? fullName = userData['name'] ?? userData['fullName'] ?? userData['full_name'];

      if (firstName != null && firstName.isNotEmpty) {
        if (lastName != null && lastName.isNotEmpty) {
          return '$firstName $lastName';
        }
        return firstName;
      }

      if (fullName != null && fullName.isNotEmpty) {
        return fullName.trim();
      }
    }

    if (widget.username != null && widget.username!.isNotEmpty) {
      return widget.username!;
    }

    return _profile?.fullName ?? 'Usuario';
  }

  String _getSpecialtyText() {
    if (_profile == null) return 'Nutricionista';

    switch (_profile!.specialty) {
      case SpecialtyType.nutricionClinica:
        return 'Nutrición Clínica';
      case SpecialtyType.dietista:
        return 'Dietista';
      case SpecialtyType.nutricionDeportiva:
        return 'Nutrición Deportiva';
      case SpecialtyType.nutricionista:
        return 'Nutricionista';
      case SpecialtyType.other:
        return _profile!.otherSpecialty ?? 'Otra especialidad';
      default:
        return 'Nutricionista';
    }
  }

  bool _isVerified() {
    return _profile?.verificationStatus == VerificationStatus.verified;
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading solo en la primera carga
    if (_isInitializing && _profile == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLigth,
        body: Center(
          child: Lottie.asset('assets/loading/palta_saltarina.json',
              width: 80,
              height: 80
          ),
        ),
      );
    }

    // Mostrar error solo si no tenemos perfil
    if (_errorMessage != null && _profile == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLigth,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Error cargando perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _refreshProfile,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final displayName = _getDisplayName();
    final specialtyText = _getSpecialtyText();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: AppColors.primary,
        backgroundColor: AppColors.backgroundLigth,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 310,
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
                    letterSpacing: 1
                ),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  onPressed: () {
                    _shareProfile();
                  },
                ),

                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
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
                const SizedBox(width: 5),
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

                      // FOTO DE PERFIL OPTIMIZADA
                      Stack(
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),

                            ),
                            child: ClipOval(
                              child: _buildProfileImage(),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                if (_profile != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => EditProfileScreen(
                                        userProfile: _profile!,
                                        onProfileUpdated: _updateProfile,
                                      ),
                                    ),
                                  );
                                }
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

                      const SizedBox(height: 5),

                      // Nombre y verificación
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          String displayName = _getDisplayName();

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
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
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),

                      Text(
                        specialtyText,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // CONTENIDO DEL PERFIL
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: 12),
                    _buildInfoSection(),
                    const SizedBox(height: 12),
                    _buildContactSection(),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareProfile() async {
    final displayName = _getDisplayName();
    final profileLink = 'www.mottinut.com/${displayName.toLowerCase().replaceAll(' ', '')}';

    final String shareText = 'Mira mi perfil: $profileLink';

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final imageUrl = authProvider.getProfileImageUrl() ?? _profile?.photoUrl;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        final response = await http.get(
          Uri.parse(imageUrl),
          headers: {
            if (authProvider.token != null) 'Authorization': 'Bearer ${authProvider.token}',
            'Accept': 'image/*',
          },
        );

        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final tempDir = await getTemporaryDirectory();
          final file = await File('${tempDir.path}/profile_image.jpg').create();
          await file.writeAsBytes(bytes);

          await Share.shareXFiles(
            [XFile(file.path)],
            text: shareText,
            subject: 'Perfil de $displayName',
          );
          return;
        }
      }

      // Si no hay imagen o falla
      await Share.share(
        shareText,
        subject: 'Perfil de $displayName',
      );

    } catch (e) {
      debugPrint('Error sharing profile: $e');
      await Share.share(
        shareText,
        subject: 'Perfil de $displayName',
      );
    }
  }

  // IMAGEN DE PERFIL OPTIMIZADA
  Widget _buildProfileImage() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final imageUrl = authProvider.getProfileImageUrl() ?? _profile?.photoUrl;
        final token = authProvider.token;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
              'Accept': 'image/*',
            },
            // Configuración para carga rápida
            cacheWidth: 260, // 2x el tamaño del widget para retina
            cacheHeight: 260,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.primary.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading profile image: $error');
              debugPrint('URL intentada: $imageUrl');
              return _buildDefaultAvatar();
            },
          );
        }

        return _buildDefaultAvatar();
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.7),
            AppColors.primary,
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 65,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatsRow() {
    final nutritionistService = NutritionistService();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(width: 0.1, color: Colors.grey)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildStatItem(
            'Consultas',
            _isLoadingStats ? '...' : _totalConsultations.toString(),
            Icons.medical_services_outlined,
          ),
          buildVerticalDivider(),
          buildStatItem(
            'Pacientes',
            _isLoadingStats ? '...' : _totalPatients.toString(),
            Icons.people_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivePatientsScreen(
                    nutritionistService: nutritionistService,
                  ),
                ),
              );
            },
          ),
          buildVerticalDivider(),
          buildStatItem('Rating', '0', Icons.star_outline),
        ],
      ),
    );
  }

  Widget buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget buildStatItem(
      String label,
      String value,
      IconData icon, {
        VoidCallback? onTap,
      }) {
    Widget content = Column(
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

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
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

          _buildInfoRow(Icons.badge_outlined, 'CNP', _profile?.cnpCode.toString() ?? 'No especificado'),
          const SizedBox(height: 16),

          if (_profile?.masterDegree != null && _profile!.masterDegree!.isNotEmpty)
            _buildInfoRow(Icons.school_outlined, 'Título', _profile!.masterDegree!),

          if (_profile?.masterDegree != null && _profile!.masterDegree!.isNotEmpty)
            const SizedBox(height: 16),

          _buildInfoRow(Icons.schedule_outlined, 'Experiencia', _calculateExperience()),

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

  String _calculateExperience() {
    if (_profile?.createdAt == null) return '0 años';

    final now = DateTime.now();
    final createdAt = _profile!.createdAt;
    final difference = now.difference(createdAt);
    final years = (difference.inDays / 365).floor();

    if (years == 0) {
      final months = (difference.inDays / 30).floor();
      return months <= 1 ? 'Nuevo' : '$months meses';
    }

    return '$years año${years == 1 ? '' : 's'}';
  }

  String _getVerificationStatusText() {
    if (_profile == null) return 'Sin verificar';

    switch (_profile!.verificationStatus) {
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

          _buildInfoRow(Icons.email_outlined, 'Email', _profile?.email.toString() ?? 'No especificado'),
          const SizedBox(height: 16),

          _buildInfoRow(Icons.location_on_outlined, 'Ubicación', _profile?.location ?? 'No especificado'),
          const SizedBox(height: 16),

          _buildInfoRow(Icons.home_outlined, 'Dirección', _profile?.address ?? 'No especificado'),
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
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor ?? Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

}