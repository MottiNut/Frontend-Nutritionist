import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';

class PatientAvatarWidget extends StatefulWidget {
  final PatientProfile patient;
  final Color statusColor;
  final String token;
  final double size;

  const PatientAvatarWidget({
    Key? key,
    required this.patient,
    required this.statusColor,
    required this.token,
    this.size = 60,
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

  Widget _buildPlaceholderAvatar() {
    final isFemale = widget.patient.gender?.toLowerCase() == 'femenino' ||
        widget.patient.gender?.toLowerCase() == 'female';

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(4),
      child: isFemale
          ? SvgPicture.asset(
        'assets/images/user_placeholder_esmer.svg',
        fit: BoxFit.scaleDown,
      )
          : FittedBox(
        fit: BoxFit.contain,
        child: Icon(
          Icons.person,
          color: widget.statusColor,
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
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
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderAvatar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: _isLoading
          ? Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(widget.size / 2),
        ),
        child: Center(
          child: SizedBox(
            width: widget.size * 0.4,
            height: widget.size * 0.4,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(widget.statusColor),
            ),
          ),
        ),
      )
          : _profileImage != null
          ? _buildProfileImage()
          : _buildPlaceholderAvatar(),
    );
  }
}
