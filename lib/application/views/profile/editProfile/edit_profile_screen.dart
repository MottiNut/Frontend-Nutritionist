import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';

import '../../../../configuration/themes/app_colors.dart';
import '../../../../domain/auth/entities/user_profile.dart';
import '../../../../domain/auth/enums/specialty_type.dart';
import '../../../../domain/auth/value_objects/cnp_code.dart';
import '../../../../domain/auth/value_objects/email.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _cnpCodeController;
  late TextEditingController _masterDegreeController;
  late TextEditingController _otherSpecialtyController;
  late TextEditingController _locationController;
  late TextEditingController _addressController;

  late SpecialtyType _selectedSpecialty;
  String? _selectedPhotoUrl;
  File? _selectedImageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController =
        TextEditingController(text: widget.userProfile.firstName);
    _lastNameController =
        TextEditingController(text: widget.userProfile.lastName);
    _emailController =
        TextEditingController(text: widget.userProfile.email.toString());
    _cnpCodeController =
        TextEditingController(text: widget.userProfile.cnpCode.toString());
    _masterDegreeController =
        TextEditingController(text: widget.userProfile.masterDegree ?? '');
    _otherSpecialtyController =
        TextEditingController(text: widget.userProfile.otherSpecialty ?? '');
    _locationController =
        TextEditingController(text: widget.userProfile.location);
    _addressController =
        TextEditingController(text: widget.userProfile.address);

    _selectedSpecialty = widget.userProfile.specialty;
    _selectedPhotoUrl = widget.userProfile.photoUrl;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _cnpCodeController.dispose();
    _masterDegreeController.dispose();
    _otherSpecialtyController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _selectedPhotoUrl = null; // Limpiar la URL anterior
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error al tomar la foto: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _selectedPhotoUrl = null; // Limpiar la URL anterior
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar la imagen: $e');
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhotoUrl = null;
      _selectedImageFile = null;
    });
  }

  void _selectPhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
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
                'Cambiar foto de perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPhotoOption(
                    Icons.camera_alt,
                    'Cámara',
                    () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  _buildPhotoOption(
                    Icons.photo_library,
                    'Galería',
                    () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                  _buildPhotoOption(
                    Icons.delete,
                    'Eliminar',
                    () {
                      Navigator.pop(context);
                      _removePhoto();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      // Aquí implementarías la lógica para subir la imagen a tu servidor
      // Por ejemplo, usando http o dio

      // Simulación de subida
      await Future.delayed(const Duration(seconds: 2));

      // Retornar la URL de la imagen subida
      return 'https://example.com/uploaded-image.jpg';
    } catch (e) {
      throw Exception('Error al subir la imagen: $e');
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? finalPhotoUrl = _selectedPhotoUrl;

      // Si hay una nueva imagen seleccionada, subirla
      if (_selectedImageFile != null) {
        finalPhotoUrl = await _uploadImage(_selectedImageFile!);
      }

      // Crear el perfil actualizado
      final updatedProfile = UserProfile(
        id: widget.userProfile.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: widget.userProfile.email,
        // No cambiar el email
        photoUrl: finalPhotoUrl,
        cnpCode: widget.userProfile.cnpCode,
        // No cambiar el CNP
        cnpPhotoUrls: widget.userProfile.cnpPhotoUrls,
        specialty: _selectedSpecialty,
        masterDegree: _masterDegreeController.text.trim().isEmpty
            ? null
            : _masterDegreeController.text.trim(),
        otherSpecialty: _selectedSpecialty == SpecialtyType.other
            ? _otherSpecialtyController.text.trim()
            : null,
        location: _locationController.text.trim(),
        address: _addressController.text.trim(),
        verificationStatus: widget.userProfile.verificationStatus,
        createdAt: widget.userProfile.createdAt,
        updatedAt: DateTime.now(),
      );

      // Simular guardado (aquí harías la llamada a tu API)
      await Future.delayed(const Duration(seconds: 1));

      // Llamar al callback con el perfil actualizado
      widget.onProfileUpdated(updatedProfile);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Perfil actualizado correctamente'),
            backgroundColor: AppColors.checkValidation,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error al actualizar perfil: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLigth,
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Guardar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Lottie.asset('assets/loading/palta_saltarina.json',
                  width: 80, height: 80),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildPhotoSection(),
                    const SizedBox(height: 30),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 24),
                    _buildProfessionalInfoSection(),
                    const SizedBox(height: 24),
                    _buildContactInfoSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: _buildPhotoWidget(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _selectPhoto,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoWidget() {
    if (_selectedImageFile != null) {
      return Image.file(
        _selectedImageFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    } else if (_selectedPhotoUrl != null) {
      return Image.network(
        _selectedPhotoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    } else {
      return _buildDefaultAvatar();
    }
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
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Información Personal',
      icon: Icons.person_outline,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _firstNameController,
                label: 'Nombres',
                icon: Icons.badge_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo es requerido';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _lastNameController,
                label: 'Apellidos',
                icon: Icons.badge_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo es requerido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          enabled: false,
          // No editable
          validator: null, // No validar ya que no es editable
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoSection() {
    return _buildSection(
      title: 'Información Profesional',
      icon: Icons.work_outline,
      children: [
        _buildTextField(
          controller: _cnpCodeController,
          label: 'Código CNP',
          icon: Icons.badge_outlined,
          enabled: false,
          // No editable
          validator: null, // No validar ya que no es editable
        ),
        const SizedBox(height: 16),
        _buildSpecialtyDropdown(),
        if (_selectedSpecialty == SpecialtyType.other) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _otherSpecialtyController,
            label: 'Especificar especialidad',
            icon: Icons.medical_services_outlined,
            validator: (value) {
              if (_selectedSpecialty == SpecialtyType.other &&
                  (value == null || value.trim().isEmpty)) {
                return 'Este campo es requerido';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 16),
        _buildTextField(
          controller: _masterDegreeController,
          label: 'Título/Maestría (Opcional)',
          icon: Icons.school_outlined,
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return _buildSection(
      title: 'Contacto y Ubicación',
      icon: Icons.contact_mail_outlined,
      children: [
        _buildTextField(
          controller: _locationController,
          label: 'Ubicación',
          icon: Icons.location_on_outlined,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Este campo es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Dirección',
          icon: Icons.home_outlined,
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Este campo es requerido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
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
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      validator: validator,
      style: TextStyle(
        color: enabled ? Colors.black : Colors.grey[600],
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? AppColors.primary : Colors.grey[400],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: enabled
            ? Colors.grey.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: enabled ? null : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSpecialtyDropdown() {
    return DropdownButtonFormField<SpecialtyType>(
      value: _selectedSpecialty,
      decoration: InputDecoration(
        labelText: 'Especialidad',
        prefixIcon:
            Icon(Icons.medical_services_outlined, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: SpecialtyType.values.map((specialty) {
        return DropdownMenuItem(
          value: specialty,
          child: Text(specialty.displayName),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedSpecialty = value;
          });
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Selecciona una especialidad';
        }
        return null;
      },
    );
  }
}
