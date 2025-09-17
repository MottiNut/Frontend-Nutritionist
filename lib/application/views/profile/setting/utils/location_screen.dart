import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/services/auth_provider.dart';

// Modelo para la ubicación del consultorio
class ConsultorioLocation {
  final String district;
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;

  ConsultorioLocation({
    required this.district,
    required this.address,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  factory ConsultorioLocation.fromJson(Map<String, dynamic> json) {
    return ConsultorioLocation(
      district: json['district'] ?? json['location'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'district': district,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  bool _gpsEnabled = false;
  bool _hasExistingLocation = false;
  String _errorMessage = '';
  String _successMessage = '';
  Position? _currentPosition;
  Placemark? _currentPlacemark;
  ConsultorioLocation? _existingLocation;

  // URLs del backend
  static const String baseUrl = 'https://mottinut-backend-2025-djf0f5c0hjckhpgp.centralus-01.azurewebsites.net/api/bff/auth/profile';
  static const String locationEndpoint = '$baseUrl/nutritionist/location';

  @override
  void initState() {
    super.initState();
    _checkGpsStatus();
    _loadExistingLocation();
  }

  Future<void> _checkGpsStatus() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _gpsEnabled = isEnabled;
    });
  }

  // Cargar ubicación existente del backend
  Future<void> _loadExistingLocation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(locationEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Load Location Response Status: ${response.statusCode}');
      debugPrint('Load Location Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Intentar diferentes estructuras de respuesta
        Map<String, dynamic>? locationData;
        if (responseData['data'] != null) {
          locationData = responseData['data'];
        } else if (responseData['location'] != null) {
          locationData = responseData['location'];
        } else if (responseData is Map<String, dynamic>) {
          locationData = responseData;
        }

        if (locationData != null &&
            (locationData['district'] != null || locationData['location'] != null)) {
          _existingLocation = ConsultorioLocation.fromJson(locationData);

          setState(() {
            _hasExistingLocation = true;
            _districtController.text = _existingLocation!.district;
            _addressController.text = _existingLocation!.address;
          });
        }
      } else if (response.statusCode == 404) {
        // No hay ubicación guardada aún
        setState(() {
          _hasExistingLocation = false;
        });
      } else {
        final responseData = json.decode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? 'Error cargando ubicación';
        });
      }
    } catch (e) {
      debugPrint('Error loading location: $e');
      setState(() {
        _errorMessage = 'Error de conexión al cargar ubicación';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final status = await Permission.location.request();

      if (status.isGranted) {
        _getCurrentLocation();
      } else if (status.isDenied) {
        setState(() {
          _errorMessage = 'Permiso de ubicación denegado. Por favor, activa los permisos de ubicación en la configuración de tu dispositivo.';
          _isLoading = false;
        });
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _errorMessage = 'Permiso de ubicación denegado permanentemente. Ve a configuración de la aplicación para habilitarlo manualmente.';
          _isLoading = false;
        });
        // Abrir configuración de la app
        openAppSettings();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al solicitar permisos de ubicación';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      // Verificar si el GPS está activado
      final isGpsEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        setState(() {
          _gpsEnabled = false;
          _errorMessage = 'Por favor activa tu GPS para obtener tu ubicación';
          _isLoading = false;
        });

        // Mostrar diálogo para activar GPS
        _showEnableGpsDialog();
        return;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Permiso de ubicación denegado';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Permiso de ubicación denegado permanentemente. Ve a configuración para habilitarlo.';
          _isLoading = false;
        });

        // Mostrar diálogo para abrir configuración
        _showOpenSettingsDialog();
        return;
      }

      // Obtener la ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Obtener la dirección a partir de las coordenadas
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _currentPosition = position;
          _currentPlacemark = placemark;

          // Actualizar campos con la nueva ubicación
          String district = _getDistrictFromPlacemark(placemark);
          String address = _formatAddress(placemark);

          _districtController.text = district;
          _addressController.text = address;
          _gpsEnabled = true;
          _successMessage = 'Ubicación actualizada correctamente';
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
          _errorMessage = 'Tiempo de espera agotado. Verifica que tengas buena señal GPS.';
        } else if (e.toString().contains('PERMISSION_DENIED')) {
          _errorMessage = 'Permiso de ubicación denegado';
        } else {
          _errorMessage = 'Error al obtener la ubicación. Verifica tu GPS y conexión.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showEnableGpsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.gps_off, color: Colors.orange),
              SizedBox(width: 10),
              Text('GPS Desactivado'),
            ],
          ),
          content: const Text(
            'Para obtener tu ubicación precisa, necesitamos que actives el GPS de tu dispositivo. ¿Deseas activarlo ahora?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Activar GPS'),
            ),
          ],
        );
      },
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.red),
              SizedBox(width: 10),
              Text('Permisos de Ubicación'),
            ],
          ),
          content: const Text(
            'Los permisos de ubicación están desactivados permanentemente. Debes habilitarlos manualmente en la configuración de la aplicación para poder usar esta función.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Abrir Configuración'),
            ),
          ],
        );
      },
    );
  }

  String _getDistrictFromPlacemark(Placemark placemark) {
    // Priorizar locality (distrito) sobre subAdministrativeArea
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      return placemark.locality!;
    }
    if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
      return placemark.subAdministrativeArea!;
    }
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      return placemark.administrativeArea!;
    }
    return 'Lima'; // Fallback para Lima
  }

  String _formatAddress(Placemark placemark) {
    final List<String> addressParts = [];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }
    if (placemark.subThoroughfare != null && placemark.subThoroughfare!.isNotEmpty) {
      addressParts.add(placemark.subThoroughfare!);
    }
    if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty &&
        placemark.thoroughfare != placemark.street) {
      addressParts.add(placemark.thoroughfare!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      addressParts.add(placemark.subLocality!);
    }

    return addressParts.join(', ');
  }

  Future<void> _saveLocation() async {
    if (_districtController.text.trim().isEmpty || _addressController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor completa todos los campos';
        _successMessage = '';
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _errorMessage = 'Usuario no autenticado';
        _successMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final locationData = {
        'district': _districtController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
      };

      final response = await http.put(
        Uri.parse(locationEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(locationData),
      );

      debugPrint('Save Location Response Status: ${response.statusCode}');
      debugPrint('Save Location Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        setState(() {
          _hasExistingLocation = true;
          _successMessage = responseData['message'] ?? 'Ubicación guardada correctamente';
        });

        // Actualizar el estado del proveedor si es necesario
        await authProvider.loadUserProfile();

        // Mostrar SnackBar de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ubicación ${_hasExistingLocation ? "actualizada" : "guardada"} correctamente',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.checkValidation,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        final responseData = json.decode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? 'Error guardando ubicación';
        });
      }
    } catch (e) {
      debugPrint('Error saving location: $e');
      setState(() {
        _errorMessage = 'Error de conexión al guardar ubicación';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildLocationStatus() {
    if (_hasExistingLocation && _existingLocation != null) {
      return Card(
        color: AppColors.backgroundSuccess,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_city,
                    color: AppColors.checkValidation,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ubicación registrada',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Distrito: ${_existingLocation!.district}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dirección: ${_existingLocation!.address}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (_existingLocation!.updatedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Actualizada: ${_formatDate(_existingLocation!.updatedAt!)}',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicación del Consultorio'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        actions: [
          if (_hasExistingLocation)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadExistingLocation,
              tooltip: 'Recargar datos',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado de ubicación existente
            _buildLocationStatus(),

            if (_hasExistingLocation) const SizedBox(height: 16),

            // Estado del GPS
            Card(
              color: _gpsEnabled ? AppColors.backgroundSuccess : AppColors.errorIcon.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      _gpsEnabled ? Icons.gps_fixed : Icons.gps_off,
                      color: _gpsEnabled ? AppColors.checkValidation : AppColors.errorIcon,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _gpsEnabled
                                ? 'GPS activado - Listo para obtener ubicación'
                                : 'GPS desactivado - Actívalo para continuar',
                            style: TextStyle(
                              color: _gpsEnabled ? AppColors.textSecondary : AppColors.errorText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!_gpsEnabled)
                            Text(
                              'Puedes ingresar la dirección manualmente',
                              style: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botón para activar GPS con mensaje bonito
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _requestLocationPermission,
                icon: _isLoading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.gps_fixed),
                label: const Text('Activar GPS y Obtener Ubicación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Formulario de ubicación
            Text(
              _hasExistingLocation ? 'Actualizar dirección del consultorio' : 'Dirección del consultorio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _districtController,
              decoration: InputDecoration(
                labelText: 'Distrito *',
                hintText: 'Ej: Miraflores, San Isidro, Surco...',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.backgroundtInput.withOpacity(0.1),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Dirección completa *',
                hintText: 'Ej: Av. Larco 123, Oficina 456',
                prefixIcon: const Icon(Icons.home),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.backgroundtInput.withOpacity(0.1),
              ),
              maxLines: 2,
            ),

            // Mensajes de estado
            if (_successMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.checkValidation.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.checkValidation.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.checkValidation),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage,
                        style: TextStyle(color: AppColors.checkValidation),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorIcon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorIcon.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: AppColors.errorIcon),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: AppColors.errorText),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Botón para guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveLocation,
                icon: _isLoading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(_hasExistingLocation ? Icons.update : Icons.save),
                label: Text(_isLoading
                    ? 'Guardando...'
                    : _hasExistingLocation
                    ? 'Actualizar Ubicación'
                    : 'Guardar Ubicación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Nota informativa
            const SizedBox(height: 12),
            Text(
              '* Los campos marcados son obligatorios. Esta información será visible para tus pacientes.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _districtController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}