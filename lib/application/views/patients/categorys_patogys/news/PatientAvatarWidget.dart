import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';

class PatientAvatarWidget extends StatefulWidget {
  final PatientProfile patient;
  final Color statusColor;
  final String token;
  final double? size;
  final bool isCircular;
  final double borderRadius;
  final BorderRadius? customBorderRadius;
  final BoxFit fit;

  const PatientAvatarWidget({
    Key? key,
    required this.patient,
    required this.statusColor,
    required this.token,
    this.size,
    this.isCircular = true,
    this.borderRadius = 12.0,
    this.customBorderRadius,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<PatientAvatarWidget> createState() => _PatientAvatarWidgetState();
}

class _PatientAvatarWidgetState extends State<PatientAvatarWidget> {
  Uint8List? _profileImage;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final nutritionistService = NutritionistService();
      final imageData = await nutritionistService.getPatientProfileImage(
        widget.patient.patientId,
        widget.token,
      );

      if (mounted) {
        setState(() {
          _profileImage = imageData;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileImage = null;
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // Método helper para obtener el BorderRadius correcto
  BorderRadius _getBorderRadius() {
    if (widget.customBorderRadius != null) {
      return widget.customBorderRadius!;
    }
    return BorderRadius.circular(widget.borderRadius);
  }

  Widget _buildPlaceholderAvatar() {
    final isFemale = widget.patient.gender?.toLowerCase() == 'femenino' ||
        widget.patient.gender?.toLowerCase() == 'female';

    Widget content = isFemale
        ? SvgPicture.asset(
      'assets/images/user_placeholder_esmer.svg',
      fit: BoxFit.scaleDown,
    )
        : FittedBox(
      fit: BoxFit.contain,
      child: Icon(
        Icons.person,
        color: widget.statusColor,
        size: widget.isCircular && widget.size != null
            ? widget.size! * 0.6
            : 40,
      ),
    );

    if (widget.isCircular && widget.size != null) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(4),
        child: content,
      );
    } else {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: _getBorderRadius(),
        ),
        padding: const EdgeInsets.all(8),
        child: content,
      );
    }
  }

  Widget _buildProfileImage() {
    if (widget.isCircular && widget.size != null) {
      // Versión circular
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.statusColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: Image.memory(
            _profileImage!,
            width: widget.size,
            height: widget.size,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderAvatar();
            },
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: _getBorderRadius(),
          border: Border.all(
            color: widget.statusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: _getBorderRadius(),
          child: Image.memory(
            _profileImage!,
            width: double.infinity,
            height: double.infinity,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderAvatar();
            },
          ),
        ),
      );
    }
  }

  Widget _buildLoadingWidget() {
    if (widget.isCircular && widget.size != null) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.statusColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox(
            width: widget.size! * 0.4,
            height: widget.size! * 0.4,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(widget.statusColor),
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: widget.statusColor.withOpacity(0.1),
          borderRadius: _getBorderRadius(),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Para versión circular con tamaño específico
    if (widget.isCircular && widget.size != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: _isLoading
            ? _buildLoadingWidget()
            : _profileImage != null
            ? _buildProfileImage()
            : _buildPlaceholderAvatar(),
      );
    }
    // Para versión que se adapta al contenedor padre
    else {
      return _isLoading
          ? _buildLoadingWidget()
          : _profileImage != null
          ? _buildProfileImage()
          : _buildPlaceholderAvatar();
    }
  }
}