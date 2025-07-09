import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mottinutnutriotinist/application/auth/sign_up/util/impInf/photo_validator_service_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../../../configuration/themes/app_colors.dart';

class PhotoTutorialScreen extends StatefulWidget {
  const PhotoTutorialScreen({Key? key}) : super(key: key);

  @override
  _PhotoTutorialScreenState createState() => _PhotoTutorialScreenState();
}

class _PhotoTutorialScreenState extends State<PhotoTutorialScreen> {
  bool _isProcessing = false;

  void _showImageSourceDialog(BuildContext context) {
    if (_isProcessing) return; // Prevenir múltiples llamadas

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Container(
          padding: EdgeInsets.all(20),
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
              SizedBox(height: 16),
              Text(
                'Seleccionar imagen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceOptionMinimal(
                      bottomSheetContext,
                      icon: Icons.camera_alt,
                      label: 'Cámara',
                      source: ImageSource.camera,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildSourceOptionMinimal(
                      bottomSheetContext,
                      icon: Icons.photo_library,
                      label: 'Galería',
                      source: ImageSource.gallery,
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(bottomSheetContext).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOptionMinimal(
      BuildContext context, {
        required IconData icon,
        required String label,
        required ImageSource source,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Cerrar el bottom sheet
        _pickImageSafely(source);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: AppColors.primary,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickImageSafely(ImageSource source) async {
    if (_isProcessing) {
      print('⚠️ Ya hay un proceso de selección de imagen en curso');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    print('🔍 Iniciando _pickImageSafely con source: $source');

    try {
      // ✅ AQUÍ ES DONDE AGREGAS LA VERIFICACIÓN DE PERMISOS
      bool hasPermission = false;

      if (source == ImageSource.camera) {
        // Solicitar permiso de cámara
        PermissionStatus cameraStatus = await Permission.camera.request();
        hasPermission = cameraStatus == PermissionStatus.granted;

        if (!hasPermission) {
          _showPermissionDeniedDialog('cámara');
          return;
        }
      } else {

        PermissionStatus storageStatus;


        if (Platform.isAndroid) {
          storageStatus = await Permission.photos.request();
          // Si photos no está disponible, intenta con storage
          if (storageStatus == PermissionStatus.denied) {
            storageStatus = await Permission.storage.request();
          }
        } else {
          // Para iOS usa photos
          storageStatus = await Permission.photos.request();
        }

        hasPermission = storageStatus == PermissionStatus.granted;

        if (!hasPermission) {
          _showPermissionDeniedDialog('galería');
          return;
        }
      }

      print('✅ Permisos concedidos, procediendo con ImagePicker...');

      final ImagePicker picker = ImagePicker();

      // Agregar un pequeño delay antes de abrir el picker
      await Future.delayed(Duration(milliseconds: 300));

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
        requestFullMetadata: false,
      );

      print('📷 Imagen seleccionada: ${image?.path}');

      if (image != null) {
        print('✅ Imagen no es null, verificando archivo...');

        final File imageFile = File(image.path);

        // Verificar que el archivo existe y es válido
        if (await imageFile.exists()) {
          final int fileSize = await imageFile.length();
          print('📁 Tamaño del archivo: $fileSize bytes');

          if (fileSize > 0) {
            print('🚀 Navegando a PhotoValidationScreen...');

            if (mounted) {
              // CAMBIADO: Usar push en lugar de pushReplacement
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhotoValidationScreen(
                    imagePath: image.path,
                  ),
                ),
              );

              print('🔄 Regresó de PhotoValidationScreen con resultado: $result');

              // Si el resultado es válido, regresar al PersonalInfoScreen
              if (result != null && result is File) {
                if (mounted) {
                  Navigator.pop(context, result);
                }
              }
            } else {
              print('❌ Widget desmontado durante la navegación');
            }
          } else {
            throw Exception('El archivo de imagen está vacío');
          }
        } else {
          throw Exception('El archivo de imagen no existe');
        }
      } else {
        print('❌ No se seleccionó ninguna imagen');
      }
    } catch (e) {
      print('💥 Error en _pickImageSafely: $e');

      if (mounted) {
        _showErrorSnackBar('Error al seleccionar la imagen: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showPermissionDeniedDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permiso requerido'),
          content: Text(
            'Para usar la $permissionType necesitamos tu permiso. '
                'Puedes habilitarlo en la configuración de la aplicación.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings(); // Abre la configuración de la app
              },
              child: Text('Configuración'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header con botón de cerrar
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 20,
              right: 20,
              bottom: 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (!_isProcessing) {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 0.5)
                    ),
                    child: IconButton(
                      icon: SvgPicture.asset(
                        'assets/images/anterior_icon.svg',
                        color: AppColors.primary,
                        width: 40,
                        height: 40,
                      ),
                      onPressed: () {
                        if (!_isProcessing) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showHelpDialog(),
                  child: Container(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.help_outline,
                      color: AppColors.iconPrimary.withOpacity(0.5),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido scrolleable
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Imagen de perfil más compacta
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/placeholder_nutri.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // Texto principal más compacto
                  Text(
                    'Tómate una selfie como se \nmuestra en el ejemplo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    'Esta imagen aparecerá en tu perfil y será lo primero que vean tus clientes. Una buena foto genera más confianza.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.2,
                    ),
                  ),

                  SizedBox(height: 15),

                  // Recomendaciones más compactas
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          '¿Cómo debe ser tu foto?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLDark,
                            letterSpacing: 0.4
                          ),
                        ),
                        SizedBox(height: 10),

                        _buildCompactTip('Encuadre desde los hombros'),
                        _buildCompactTip('Rostro centrado en la pantalla'),
                        _buildCompactTip('Sin lentes de sol o gorras'),
                        _buildCompactTip('Elija un fondo simple, preferible blanco'),
                        _buildCompactTip('Buena iluminación natural', isLast: true),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Evita estos errores',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLDark,
                            letterSpacing: 0.4
                          ),
                        ),
                        SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildBadExample(
                                icon: FontAwesomeIcons.glasses,
                                text: 'Lentes de sol\no gorras',
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildBadExample(
                                icon: FontAwesomeIcons.userSlash,
                                text: 'Solo media\ncara visible',
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildBadExample(
                                icon: FontAwesomeIcons.magnifyingGlassMinus,
                                text: 'Muy lejos\no borroso',
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botón fijo en la parte inferior
          Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Container(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _showImageSourceDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProcessing ? Colors.grey[400] : AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Procesando...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                    : const Text(
                  'Seleccionar foto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Consejos para una buena foto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Use luz natural cuando sea posible'),
              Text('• Mantenga el teléfono estable'),
              Text('• Mire directamente a la cámara'),
              Text('• Use un fondo neutro'),
              Text('• Mantenga una expresión neutral'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactTip(String text, {bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadExample({required IconData icon, required String text}) {
    return Container(
      height: 160, // Altura fija para todos los contenedores
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.errorIcon.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Círculo de fondo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.errorIcon.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.errorIcon.withOpacity(0.8),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: AppColors.errorIcon.withOpacity(0.7),
                ),
              ),
              // Línea diagonal tachada
              Transform.rotate(
                angle: -0.785398,
                child: Container(
                  width: 56,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.errorIcon.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.errorText,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
