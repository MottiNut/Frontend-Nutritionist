import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../../../../configuration/themes/app_colors.dart';
import '../../terms and conditions/politica_privacidad_screen.dart';
import '../../terms and conditions/terminos_condiciones_screen.dart';

class LocationSelectorScreen extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String email;
  final String contrasena;
  final String codeCNP;
  final File? licenseFrontImage;
  final File? licenseBackImage;
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
    this.licenseFrontImage,
    this.licenseBackImage,
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
  final FocusNode _direccionFocusNode = FocusNode();
  String? selectedLocation;
  bool termsAccepted = false;
  bool _showFields = true;

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

    // Verificar si debe mostrar campos o resumen
    _showFields = selectedLocation == null || _direccionController.text.trim().isEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    _direccionController.dispose();
    _direccionFocusNode.dispose();
    super.dispose();
  }

  // Método para validar si el formulario está completo
  bool isValid() {
    return selectedLocation != null &&
        _direccionController.text.trim().isNotEmpty &&
        termsAccepted;
  }

  void _openTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TerminosCondicionesScreen()),
    );
  }

  void _openPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PoliticaPrivacidadScreen()),
    );
  }


  void _notifyParent() {
    if (widget.onDataChanged != null) {
      widget.onDataChanged!(
        selectedLocation ?? '',
        _direccionController.text.trim(),
      );
    }
  }

  // Método para desactivar el foco del campo de dirección
  void _unfocusAddressField() {
    if (_direccionFocusNode.hasFocus) {
      _direccionFocusNode.unfocus();
      _checkToShowSummary();
    }
  }

  void _checkToShowSummary() {
    if (selectedLocation != null && _direccionController.text.trim().isNotEmpty) {
      setState(() {
        _showFields = false;
      });
    }
  }

  void _editLocation() {
    setState(() {
      _showFields = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocusAddressField,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              // Header fijo
              Container(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Ubicación de tu consulta',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ayuda a tus pacientes a encontrarte fácilmente\nespecificando dónde brindas tus servicios',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        child: Lottie.asset(
                          'assets/lottie/locations_animations.json',
                          width: 150,
                          height: 150,

                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Contenido scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showFields) ...[
                        _buildLocationFields(),
                      ] else ...[
                        _buildLocationSummary(),
                      ],
                      const SizedBox(height: 30),
                      _buildTermsAndConditions(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildLocationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección Distrito
        _buildSectionLabel('Distrito de atención', Icons.location_city_rounded),
        SizedBox(height: 6),

        CustomDropdown<String>.search(
          controller: _controller,
          hintText: 'Selecciona el distrito donde atiendes',
          searchHintText: 'Buscar distrito...',
          noResultFoundText: 'Sin resultados encontrados',
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
                color: Colors.black.withOpacity(0.04),
                spreadRadius: 0,
                blurRadius: 10,
                offset: Offset(0, 3),
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
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(14),
            expandedBorder: Border.all(
              color: AppColors.primary,
              width: 2,
            ),
            expandedBorderRadius: BorderRadius.circular(14),
            closedFillColor: Colors.white,
            expandedFillColor: Colors.white,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            headerStyle: TextStyle(
              color: Colors.grey[900],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            listItemStyle: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
            noResultFoundStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
                  size: 18,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        SizedBox(height: 20),

        // Sección Dirección específica
        _buildSectionLabel('Dirección específica', Icons.place_rounded),
        SizedBox(height: 6),

        AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),

          ),
          child: TextFormField(
            controller: _direccionController,
            focusNode: _direccionFocusNode,
            onChanged: (value) {
              _notifyParent();
            },
            decoration: InputDecoration(
              hintText: 'Ej: Av. Javier Prado 456, Of. 302\nCentro Médico San Juan',

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              fillColor: Colors.white,
              filled: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                height: 1.4,
              ),
            ),
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.done,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ),

        // Información adicional sobre la dirección
        if (_direccionController.text.trim().isNotEmpty) ...[
          SizedBox(height: 6),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary.withOpacity(0.7),
                  size: 20,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Esta dirección aparecerá en tu perfil profesional y será visible para tus pacientes.',
                    style: TextStyle(
                      color: AppColors.primary ,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSummary() {
    return Container(
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Ubicación configurada',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _editLocation,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: Colors.grey[600],
                size: 18,
              ),
              SizedBox(width: 4),
              Text(
                'Distrito: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                selectedLocation!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (_direccionController.text.trim().isNotEmpty) ...[
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.place_rounded,
                  color: Colors.grey[600],
                  size: 18,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        color: Colors.grey[900],
                      ),
                      children: [
                        TextSpan(
                          text: 'Dirección: ',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        TextSpan(
                          text: _direccionController.text.trim(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // clave
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2), // ajuste fino opcional
            child: SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: termsAccepted,
                onChanged: (value) {
                  setState(() {
                    termsAccepted = value ?? false;
                  });
                  _notifyParent();
                },
                activeColor: AppColors.primary,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: termsAccepted ? AppColors.primary : Colors.grey[400]!,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  termsAccepted = !termsAccepted;
                });
                _notifyParent();
              },
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'Al continuar, aceptas los ',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w300,
                    fontSize: 12,
                  ),
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: _openTermsOfService,
                        child: Text(
                          'Términos y Condiciones',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: ' y ',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: _openPrivacyPolicy,
                        child: Text(
                          'Política de privacidad',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }

}