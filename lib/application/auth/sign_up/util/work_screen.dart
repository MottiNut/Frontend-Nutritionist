import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/services.dart';
import '../../../../configuration/themes/app_colors.dart';

class LocationSelectorScreen extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String email;
  final String contrasena;
  final String codeCNP;
  final String photoCNP;
  final String especialidad;
  final String maestria;
  final String other;
  final String initialUbicacion;
  final String initialDireccion;
  final Function(String ubicacion, String direccion)? onDataChanged;

  const LocationSelectorScreen({
    Key? key,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.contrasena,
    required this.codeCNP,
    required this.photoCNP,
    required this.especialidad,
    required this.maestria,
    required this.other,
    this.initialUbicacion = '',
    this.initialDireccion = '',
    this.onDataChanged,
  }) : super(key: key);

  @override
  LocationSelectorScreenState createState() => LocationSelectorScreenState();
}

class LocationSelectorScreenState extends State<LocationSelectorScreen> {
  final SingleSelectController<String> _controller = SingleSelectController<String>(null);
  final TextEditingController _direccionController = TextEditingController();
  String? selectedLocation;
  bool termsAccepted = false;
  bool privacyAccepted = false;

  final List<String> limaDistricts = [
    'Ate',
    'Barranco',
    'Breña',
    'Carabayllo',
    'Chaclacayo',
    'Chorrillos',
    'Cieneguilla',
    'Comas',
    'El Agustino',
    'Independencia',
    'Jesús María',
    'La Molina',
    'La Victoria',
    'Lima',
    'Lince',
    'Los Olivos',
    'Lurigancho',
    'Lurín',
    'Magdalena del Mar',
    'Miraflores',
    'Pachacámac',
    'Pucusana',
    'Pueblo Libre',
    'Puente Piedra',
    'Punta Hermosa',
    'Punta Negra',
    'Rímac',
    'San Bartolo',
    'San Borja',
    'San Isidro',
    'San Juan de Lurigancho',
    'San Juan de Miraflores',
    'San Luis',
    'San Martín de Porres',
    'San Miguel',
    'Santa Anita',
    'Santa María del Mar',
    'Santa Rosa',
    'Santiago de Surco',
    'Surquillo',
    'Villa El Salvador',
    'Villa María del Triunfo',
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar con valores previos si existen
    if (widget.initialUbicacion.isNotEmpty) {
      selectedLocation = widget.initialUbicacion;
      _controller.value = widget.initialUbicacion;
    }
    if (widget.initialDireccion.isNotEmpty) {
      _direccionController.text = widget.initialDireccion;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  // Método para validar si el formulario está completo
  bool isValid() {
    return selectedLocation != null &&
        _direccionController.text.trim().isNotEmpty &&
        termsAccepted &&
        privacyAccepted;
  }

  void _openTermsOfService() {
    print("Abrir Términos de Servicio");
  }

  void _openPrivacyPolicy() {
    print("Abrir Política de Privacidad");
  }

  void _notifyParent() {
    if (widget.onDataChanged != null) {
      widget.onDataChanged!(
        selectedLocation ?? '',
        _direccionController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '¿Dónde trabajas?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Los pacientes podrán encontrarte más fácilmente',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),

                    // Dropdown mejorado
                    CustomDropdown<String>.search(
                      controller: _controller,
                      hintText: 'Seleccionar distrito',
                      searchHintText: 'Buscar distrito...',
                      items: limaDistricts,
                      onChanged: (value) {
                        setState(() {
                          selectedLocation = value;
                        });
                        HapticFeedback.lightImpact();
                        _notifyParent();
                      },
                      decoration: CustomDropdownDecoration(
                        closedShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            spreadRadius: 0,
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                        expandedShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                        closedBorder: Border.all(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                        closedBorderRadius: BorderRadius.circular(16),
                        expandedBorder: Border.all(
                          color: AppColors.primary,
                          width: 2,
                        ),
                        expandedBorderRadius: BorderRadius.circular(16),
                        closedFillColor: Colors.white,
                        expandedFillColor: Colors.white,
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        headerStyle: TextStyle(
                          color: Colors.grey[900],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        listItemStyle: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        noResultFoundStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        searchFieldDecoration: SearchFieldDecoration(
                          fillColor: Colors.grey[50]!,
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.search_rounded,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Campo de dirección específica
                    TextFormField(
                      controller: _direccionController,
                      onChanged: (value) {
                        _notifyParent();
                      },
                      decoration: InputDecoration(
                        labelText: 'Dirección específica',
                        hintText: 'Ej: Av. Javier Prado 123, San Isidro',
                        prefixIcon: Icon(
                          Icons.place_rounded,
                          color: AppColors.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                    ),

                    // Selected location display
                    if (selectedLocation != null) ...[
                      SizedBox(height: 24),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 0,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ubicación seleccionada',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    selectedLocation!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[900],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedLocation = null;
                                  _controller.clear();
                                });
                                HapticFeedback.lightImpact();
                                _notifyParent();
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey[600],
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Terms and conditions section at the bottom
            Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Términos de servicio checkbox
                  _buildCheckboxRow(
                    value: termsAccepted,
                    onChanged: (value) {
                      setState(() {
                        termsAccepted = value ?? false;
                      });
                      _notifyParent();
                    },
                    text: 'Acepto los ',
                    linkText: 'Términos del servicio',
                    onLinkTap: _openTermsOfService,
                  ),
                  SizedBox(height: 16),

                  // Política de privacidad checkbox
                  _buildCheckboxRow(
                    value: privacyAccepted,
                    onChanged: (value) {
                      setState(() {
                        privacyAccepted = value ?? false;
                      });
                      _notifyParent();
                    },
                    text: 'Acepto la ',
                    linkText: 'Política de privacidad',
                    onLinkTap: _openPrivacyPolicy,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
    required String linkText,
    required VoidCallback onLinkTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: BorderSide(
              color: value ? AppColors.primary : Colors.grey[400]!,
              width: 2,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: RichText(
              text: TextSpan(
                text: text,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
                children: [
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: onLinkTap,
                      child: Text(
                        linkText,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}