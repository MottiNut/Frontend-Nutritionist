import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mottinutnutriotinist/domain/services/auth_provider.dart';

class ProfessionalVerificationScreen extends StatelessWidget {
  const ProfessionalVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final isEmailVerified = user?['emailVerified'] ?? false;
    final isPhoneVerified = user?['phoneVerified'] ?? false;
    final isCnpVerified = user?['cnpVerified'] ?? false;
    final isFullyVerified = user?['fullyVerified'] ?? false;

    // Get CNP information if available
    final cnpCode = user?['cnpCode'];
    final licenseFront = user?['licenseFrontImage'];
    final licenseBack = user?['licenseBackImage'];
    final specialty = user?['specialty'];
    final hasCnpInfo = cnpCode != null || licenseFront != null || licenseBack != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Verificación Profesional'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVerificationStatus(isFullyVerified),
            const SizedBox(height: 24),

            // Show CNP information card if available
            if (hasCnpInfo) ...[
              _buildCnpInfoCard(
                context: context, // Pass context here
                cnpCode: cnpCode,
                specialty: specialty,
                licenseFront: licenseFront,
                licenseBack: licenseBack,
              ),
              const SizedBox(height: 16),
            ],

            _buildVerificationSection(
              title: 'Verificación de Email',
              isVerified: isEmailVerified,
              verifiedDate: user?['emailVerifiedAt'],
              onVerify: !isEmailVerified ? () => _verifyEmail(context) : null,
            ),
            const SizedBox(height: 16),
            _buildVerificationSection(
              title: 'Verificación de Teléfono',
              isVerified: isPhoneVerified,
              verifiedDate: user?['phoneVerifiedAt'],
              onVerify: !isPhoneVerified ? () => _verifyPhone(context) : null,
            ),
            const SizedBox(height: 16),
            _buildVerificationSection(
              title: 'Verificación CNP',
              isVerified: isCnpVerified,
              verifiedDate: user?['cnpVerifiedAt'],
              onVerify: !isCnpVerified ? () => _verifyCnp(context) : null,
              isProfessional: true,
            ),
            const SizedBox(height: 32),

            // Show license images section if available
            if (licenseFront != null || licenseBack != null)
              _buildLicenseImagesSection(context, licenseFront, licenseBack),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseImagesSection(BuildContext context, String? frontImage, String? backImage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentos de Licencia CNP',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (frontImage != null && frontImage.isNotEmpty)
          _buildLicenseImageCard(context, 'Licencia CNP (Frente)', frontImage),
        if (backImage != null && backImage.isNotEmpty)
          _buildLicenseImageCard(context, 'Licencia CNP (Reverso)', backImage),
      ],
    );
  }

  Widget _buildLicenseImageCard(BuildContext context, String title, String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showFullScreenImage(context, imageUrl, title),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: _buildNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget mejorado para manejar imágenes de red con fallback
  Widget _buildNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    if (imageUrl.isEmpty) {
      return _buildImagePlaceholder(width, height);
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder(width, height, hasError: true);
      },
    );
  }

  Widget _buildImagePlaceholder(double? width, double? height, {bool hasError = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasError ? Icons.error_outline : Icons.image_outlined,
            size: 48,
            color: hasError ? Colors.red.shade400 : Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            hasError ? 'Error al cargar' : 'Imagen no disponible',
            style: TextStyle(
              color: hasError ? Colors.red.shade600 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Fixed method - now accepts BuildContext as parameter
  void _showFullScreenImage(BuildContext context, String imageUrl, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          imageUrl: imageUrl,
          title: title,
        ),
      ),
    );
  }

  Widget _buildCnpInfoCard({
    required BuildContext context, // Add context parameter
    String? cnpCode,
    String? specialty,
    String? licenseFront,
    String? licenseBack,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información CNP',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (cnpCode != null && cnpCode.isNotEmpty) ...[
              _buildInfoRow('Código CNP:', cnpCode),
              const SizedBox(height: 8),
            ],
            if (specialty != null && specialty.isNotEmpty) ...[
              _buildInfoRow('Especialidad:', specialty),
              const SizedBox(height: 8),
            ],
            if ((licenseFront != null && licenseFront.isNotEmpty) ||
                (licenseBack != null && licenseBack.isNotEmpty)) ...[
              const Text(
                'Documentos:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (licenseFront != null && licenseFront.isNotEmpty)
                    _buildDocumentThumbnail(context, 'Frente', licenseFront),
                  if (licenseBack != null && licenseBack.isNotEmpty) ...[
                    if (licenseFront != null && licenseFront.isNotEmpty)
                      const SizedBox(width: 8),
                    _buildDocumentThumbnail(context, 'Reverso', licenseBack),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentThumbnail(BuildContext context, String label, String imageUrl) {
    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(context, imageUrl, 'Licencia CNP ($label)'),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus(bool isFullyVerified) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isFullyVerified ? Icons.verified : Icons.pending_actions,
            color: isFullyVerified ? Colors.green : Colors.orange,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFullyVerified
                      ? 'Verificación completa'
                      : 'Verificación pendiente',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  isFullyVerified
                      ? 'Tu cuenta está completamente verificada y activa.'
                      : 'Completa los pasos de verificación para acceder a todas las funciones.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection({
    required String title,
    required bool isVerified,
    String? verifiedDate,
    VoidCallback? onVerify,
    bool isProfessional = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isVerified ? Colors.green : Colors.orange,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  isVerified ? 'Verificado' : 'Pendiente',
                  style: TextStyle(
                    color: isVerified ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (isVerified && verifiedDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Verificado el ${_formatDate(verifiedDate)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          if (!isVerified && onVerify != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isProfessional
                      ? Colors.blue.shade50
                      : Colors.grey.shade100,
                  foregroundColor: isProfessional
                      ? Colors.blue
                      : Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  isProfessional
                      ? 'Subir documentos CNP'
                      : 'Verificar ahora',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _verifyEmail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verificar Email'),
        content: const Text('Se enviará un código de verificación a tu dirección de email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendVerificationCode(context, VerificationMethod.email);
            },
            child: const Text('Enviar código'),
          ),
        ],
      ),
    );
  }

  void _verifyPhone(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verificar Teléfono'),
        content: const Text('Se enviará un código SMS a tu número de teléfono.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendVerificationCode(context, VerificationMethod.sms);
            },
            child: const Text('Enviar código'),
          ),
        ],
      ),
    );
  }

  void _verifyCnp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UploadDocumentsScreen(),
      ),
    );
  }

  Future<void> _sendVerificationCode(BuildContext context, VerificationMethod method) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.sendVerificationCode(
      method: method,
      phoneNumber: method == VerificationMethod.sms && authProvider.user?['phone'] != null
          ? authProvider.user!['phone']
          : null,
    );

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VerificationCodeScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Error al enviar código'),
        ),
      );
    }
  }
}

// Pantalla para mostrar imagen en pantalla completa
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: imageUrl,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Error al cargar la imagen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class VerificationCodeScreen extends StatefulWidget {
  const VerificationCodeScreen({super.key});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresar Código'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa el código de verificación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hemos enviado un código a tu email/teléfono. Por favor ingrésalo a continuación.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código de verificación',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Verificar Código'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resendCode,
              child: const Text('No recibí el código. Reenviar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.verifyCode(_codeController.text.trim());

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verificación exitosa')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Error al verificar')),
      );
    }
  }

  Future<void> _resendCode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resendVerificationCode();

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Error al reenviar')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código reenviado exitosamente')),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  // Implementar lógica para subir documentos CNP
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Documentos CNP'),
      ),
      body: const Center(
        child: Text('Pantalla para subir documentos CNP'),
      ),
    );
  }
}


