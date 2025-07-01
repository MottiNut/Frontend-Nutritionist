import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '/../../../../domain/patient/pruebaa.dart';
import 'dart:async';

class DatosNutricionalesSection extends StatefulWidget {
  final Patient patient;
  final bool isEditMode;
  final Function(Map<String, String>) onDataChanged;
  final Map<String, String>? initialData;

  const DatosNutricionalesSection({
    super.key,
    required this.patient,
    required this.isEditMode,
    required this.onDataChanged,
    this.initialData,
  });

  @override
  State<DatosNutricionalesSection> createState() => _DatosNutricionalesSectionState();
}

class _DatosNutricionalesSectionState extends State<DatosNutricionalesSection> {
  late SingleSelectController<String?> _vecesDiaComeController;
  late SingleSelectController<String?> _preferenciasController;
  late SingleSelectController<String?> _noAgradaController;
  late SingleSelectController<String?> _intoleranciasController;
  late SingleSelectController<String?> _lugarIngestaController;
  late SingleSelectController<String?> _habitosNocivosController;
  late SingleSelectController<String?> _tipoActividadController;

  // Variables para manejo de cambios
  Timer? _changeTimer;
  bool _hasLocalChanges = false;

  // Estados para los toggles
  bool? _consumoAgua;

  // Controladores para los campos de texto
  late TextEditingController _cantidadAguaController;
  late TextEditingController _otroVecesComidaController;
  late TextEditingController _otroPreferenciasController;
  late TextEditingController _otroNoAgradaController;
  late TextEditingController _otroIntoleranciasController;
  late TextEditingController _otroLugarIngestaController;
  late TextEditingController _otroHabitosController;
  late TextEditingController _otroActividadController;

  // Estados para mostrar campos "Otro"
  bool _showOtroVecesComida = false;
  bool _showOtroPreferencias = false;
  bool _showOtroNoAgrada = false;
  bool _showOtroIntolerancias = false;
  bool _showOtroLugarIngesta = false;
  bool _showOtroHabitos = false;
  bool _showOtroActividad = false;

  // Opciones ampliadas para los dropdowns
  final List<String> _vecesComidaOptions = [
    'Una vez al día',
    'Dos veces al día',
    'Tres veces al día (desayuno, almuerzo, cena)',
    'Cuatro veces al día (incluye merienda)',
    'Cinco veces al día (3 comidas + 2 colaciones)',
    'Seis veces al día (comidas pequeñas y frecuentes)',
    'Más de 6 veces al día',
    'Ayuno intermitente 16:8',
    'Ayuno intermitente 18:6',
    'Ayuno intermitente 20:4',
    'Una comida al día (OMAD)',
    'Alimentación intuitiva (sin horarios fijos)',
    'Picoteo constante durante el día',
    'Solo cuando tengo hambre',
    'Según mi horario de trabajo',
    'Otro',
  ];

  final List<String> _preferenciasOptions = [
    'Vegetales verdes (espinaca, brócoli, lechuga)',
    'Vegetales de colores (zanahoria, pimiento, tomate)',
    'Frutas dulces (mango, plátano, uva)',
    'Frutas cítricas (naranja, limón, toronja)',
    'Frutas del bosque (fresa, arándano, mora)',
    'Carnes blancas (pollo, pavo, pescado)',
    'Carnes rojas (res, cerdo, cordero)',
    'Mariscos y pescados',
    'Huevos y derivados',
    'Lácteos (leche, queso, yogurt)',
    'Cereales integrales (avena, quinoa, arroz integral)',
    'Cereales refinados (arroz blanco, pan blanco)',
    'Legumbres (frijoles, lentejas, garbanzos)',
    'Frutos secos (almendras, nueces, pistachos)',
    'Semillas (chía, linaza, girasol)',
    'Comida vegana',
    'Comida vegetariana',
    'Comida mediterránea',
    'Comida asiática',
    'Comida mexicana tradicional',
    'Comida peruana',
    'Platos típicos regionales',
    'Alimentos orgánicos',
    'Superalimentos (quinoa, chía, açaí)',
    'Comida casera tradicional',
    'Snacks saludables',
    'Bebidas naturales',
    'Otro',
  ];

  final List<String> _noAgradaOptions = [
    'Verduras amargas (rúcula, endivias)',
    'Verduras crucíferas (brócoli, coliflor, repollo)',
    'Tomate y derivados',
    'Cebolla en cualquier preparación',
    'Ajo en exceso',
    'Apio y hierbas aromáticas',
    'Pescados grasos (salmón, atún)',
    'Pescados blancos',
    'Mariscos en general',
    'Lácteos enteros',
    'Lácteos descremados',
    'Quesos fuertes',
    'Huevos (clara y/o yema)',
    'Legumbres (por gases o digestión)',
    'Frutos secos por textura',
    'Alimentos muy condimentados',
    'Comida muy picante',
    'Alimentos muy dulces',
    'Alimentos muy salados',
    'Comida muy grasosa',
    'Texturas gelatinosas',
    'Alimentos calientes',
    'Alimentos muy fríos',
    'Bebidas carbonatadas',
    'Café o té',
    'Alcohol en general',
    'Vísceras (hígado, riñón)',
    'Embutidos',
    'Comida procesada',
    'Otro',
  ];

  final List<String> _intoleranciasOAlergiasOptions = [
    'Lactosa (productos lácteos)',
    'Gluten (celiaquía o sensibilidad)',
    'Caseína (proteína de la leche)',
    'Fructosa (azúcar de frutas)',
    'Histamina (alimentos fermentados)',
    'Maní (cacahuate)',
    'Nueces de árbol (almendras, nueces)',
    'Mariscos y crustáceos',
    'Pescados en general',
    'Huevos (clara y/o yema)',
    'Soja y derivados',
    'Semillas de sésamo',
    'Mostaza',
    'Sulfitos (conservantes)',
    'Colorantes artificiales',
    'Conservantes (BHA, BHT)',
    'Edulcorantes artificiales',
    'Glutamato monosódico (MSG)',
    'Levadura',
    'Trigo (sin ser celiaquía)',
    'Avena',
    'Cebada y centeno',
    'Frutas con alta acidez',
    'Nightshades (tomate, papa, pimiento)',
    'FODMAP (varios alimentos)',
    'Cafeína',
    'Alcohol etílico',
    'Aditivos alimentarios',
    'Otro',
  ];

  final List<String> _lugarIngestaOptions = [
    'Casa - comedor familiar',
    'Casa - cocina',
    'Casa - sala viendo TV',
    'Casa - habitación',
    'Trabajo - oficina en escritorio',
    'Trabajo - comedor empresarial',
    'Trabajo - cafetería cercana',
    'Universidad - comedor estudiantil',
    'Universidad - cafetería del campus',
    'Colegio - comedor escolar',
    'Restaurantes de comida rápida',
    'Restaurantes casuales',
    'Restaurantes elegantes',
    'Food trucks',
    'Delivery en casa',
    'Delivery en trabajo',
    'Parques o espacios abiertos',
    'Auto (mientras conduzco)',
    'Transporte público',
    'Gimnasio o centro deportivo',
    'Eventos sociales',
    'Casa de familiares',
    'Casa de amigos',
    'Viajes (hoteles, aeropuertos)',
    'Otro',
  ];

  final List<String> _habitosNocivosOptions = [
    'Café (1-2 tazas diarias)',
    'Café (3-5 tazas diarias)',
    'Café (más de 5 tazas diarias)',
    'Té verde o negro (moderado)',
    'Té en exceso (más de 4 tazas)',
    'Bebidas energéticas ocasionales',
    'Bebidas energéticas frecuentes',
    'Alcohol social (fines de semana)',
    'Alcohol moderado (2-3 veces/semana)',
    'Alcohol frecuente (diario)',
    'Tabaco (menos de 10 cigarrillos/día)',
    'Tabaco (10-20 cigarrillos/día)',
    'Tabaco (más de 20 cigarrillos/día)',
    'Vapeo ocasional',
    'Vapeo frecuente',
    'Azúcar añadido en bebidas',
    'Consumo alto de dulces/postres',
    'Snacks procesados frecuentes',
    'Comida chatarra 2-3 veces/semana',
    'Comida chatarra diaria',
    'Comer frente a pantallas siempre',
    'Comer muy rápido',
    'Saltarse el desayuno',
    'Saltarse el almuerzo',
    'Saltarse la cena',
    'Comer muy tarde en la noche',
    'Picar entre comidas',
    'Comer por estrés/emociones',
    'No masticar bien los alimentos',
    'Beber poco agua',
    'Comer de pie',
    'Otro',
  ];

  final List<String> _tipoActividadOptions = [
    'Sedentaria (menos de 30 min/semana)',
    'Muy ligera (caminar ocasionalmente)',
    'Ligera (caminar 30 min, 2-3 veces/semana)',
    'Ligera a moderada (tareas domésticas activas)',
    'Moderada (30-45 min, 3-4 veces/semana)',
    'Moderada (gimnasio 3-4 veces/semana)',
    'Moderada alta (ejercicio 45-60 min, 4-5 veces)',
    'Intensa (ejercicio diario 60+ min)',
    'Muy intensa (entrenamiento deportivo)',
    'Deportista amateur (competencia ocasional)',
    'Deportista semi-profesional',
    'Deportista profesional',
    'Trabajo físico ligero (oficina de pie)',
    'Trabajo físico moderado (caminatas frecuentes)',
    'Trabajo físico pesado (construcción, carga)',
    'Trabajo físico muy exigente',
    'Actividades de fin de semana solamente',
    'Yoga/Pilates regular',
    'Natación regular',
    'Ciclismo recreativo',
    'Ciclismo intenso',
    'Running/Trote ocasional',
    'Running/Trote regular',
    'Deportes de equipo',
    'Artes marciales',
    'Baile/Danza',
    'Montañismo/Hiking',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupChangeListeners();
  }

  void _initializeControllers() {
    final vecesComida = widget.initialData?['vecesComidaDia'] ??
        widget.patient.nutritionalProfile?.vecesDiaCome;
    final preferenciasPor = widget.initialData?['preferencias'] ??
        widget.patient.nutritionalProfile?.preferencias;
    final desagrados = widget.initialData?['noLeAgrada'] ??
        widget.patient.nutritionalProfile?.noLeAgrada;
    final intoleranciasAlergias = widget.initialData?['intolerancias'] ??
        widget.patient.nutritionalProfile?.intolerancias;
    final lugarIngesta = widget.initialData?['lugarDeIngesta'] ??
        widget.patient.nutritionalProfile?.lugarIngesta;
    final habitos = widget.initialData?['habitosNocivos'] ??
        widget.patient.nutritionalProfile?.habitosNocivos;
    final actividad = widget.initialData?['tipoActividad'] ??
        widget.patient.nutritionalProfile?.tipoActividad;

    _vecesDiaComeController = SingleSelectController<String?>(
        _vecesComidaOptions.contains(vecesComida) ? vecesComida : null);
    _preferenciasController = SingleSelectController<String?>(
        _preferenciasOptions.contains(preferenciasPor) ? preferenciasPor : null);
    _noAgradaController = SingleSelectController<String?>(
        _noAgradaOptions.contains(desagrados) ? desagrados : null);
    _intoleranciasController = SingleSelectController<String?>(
        _intoleranciasOAlergiasOptions.contains(intoleranciasAlergias) ? intoleranciasAlergias : null);
    _lugarIngestaController = SingleSelectController<String?>(
        _lugarIngestaOptions.contains(lugarIngesta) ? lugarIngesta : null);
    _habitosNocivosController = SingleSelectController<String?>(
        _habitosNocivosOptions.contains(habitos) ? habitos : null);
    _tipoActividadController = SingleSelectController<String?>(
        _tipoActividadOptions.contains(actividad) ? actividad : null);

    // Inicializar controlador de texto
    _consumoAgua = widget.initialData?['consumoAgua'] != null
        ? widget.initialData!['consumoAgua'].toString().toLowerCase() == 'sí'.toLowerCase()
        : widget.patient.nutritionalProfile?.consumeAgua;

    _cantidadAguaController = TextEditingController(
        text: widget.initialData?['consumoAguaDetail'] ??
            widget.patient.nutritionalProfile?.consumoAguaDetalle ?? '');
  }

  void _setupChangeListeners() {
    _cantidadAguaController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasLocalChanges) {
      setState(() {
        _hasLocalChanges = true;
      });
    }

    // Cancelar timer anterior y crear uno nuevo para debounce
    _changeTimer?.cancel();
    _changeTimer = Timer(const Duration(milliseconds: 500), () {
      _notifyParentOfChanges();
    });
  }

  void _onDropdownChanged() {
    _onFieldChanged();
  }

  void _notifyParentOfChanges() {
    final data = {
      'vecesComidaDia': _vecesDiaComeController.value ?? '',
      'preferencias': _preferenciasController.value ?? '',
      'noLeAgrada': _noAgradaController.value ?? '',
      'intolerancias': _intoleranciasController.value ?? '',
      'lugarDeIngesta': _lugarIngestaController.value ?? '',
      'habitosNocivos': _habitosNocivosController.value ?? '',
      'tipoActividad': _tipoActividadController.value ?? '',
      'consumoAgua': _consumoAgua == true ? 'Sí' : 'No',
      'consumoAguaDetail': _consumoAgua == true ? _cantidadAguaController.text : '',
    };

    widget.onDataChanged(data);

    setState(() {
      _hasLocalChanges = false;
    });
  }

  @override
  void didUpdateWidget(DatosNutricionalesSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si cambió a modo edición, configurar listeners
    if (widget.isEditMode != oldWidget.isEditMode) {
      if (widget.isEditMode) {
        _setupChangeListeners();
      }
    }
  }

  @override
  void dispose() {
    _changeTimer?.cancel();

    _vecesDiaComeController.dispose();
    _preferenciasController.dispose();
    _noAgradaController.dispose();
    _intoleranciasController.dispose();
    _lugarIngestaController.dispose();
    _habitosNocivosController.dispose();
    _tipoActividadController.dispose();
    _cantidadAguaController.dispose();
    super.dispose();
  }

  Widget _buildSearchDropdownField(
      String label,
      String fallbackValue,
      SingleSelectController<String?> controller,
      List<String> options,
      VoidCallback onChanged,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          widget.isEditMode
              ? Container(
            constraints: const BoxConstraints(
              minWidth: 200,
              maxWidth: 280,
            ),
            child: CustomDropdown<String>.searchRequest(
              controller: controller,
              hintText: 'Selecciona una opción',
              items: options,
              noResultFoundText: 'No se encontraron resultados',
              searchHintText: 'Buscar...',
              futureRequest: (String filter) async {
                await Future.delayed(const Duration(milliseconds: 100));
                return options
                    .where((item) => item.toLowerCase().contains(filter.toLowerCase()))
                    .toList();
              },
              onChanged: (value) {
                onChanged();
              },
              decoration: CustomDropdownDecoration(
                closedFillColor: controller.value?.isNotEmpty == true
                    ? AppColors.primary
                    : Colors.white,
                expandedFillColor: Colors.white,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
                headerStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: controller.value?.isNotEmpty == true
                        ? FontWeight.normal
                        : FontWeight.normal,
                    color: controller.value?.isNotEmpty == true
                        ? Colors.white
                        : Colors.black87,
                    letterSpacing: 0.5),
                listItemStyle: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
                noResultFoundStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                searchFieldDecoration: SearchFieldDecoration(
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                listItemDecoration: ListItemDecoration(
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  highlightColor: AppColors.primary.withOpacity(0.08),
                  splashColor: AppColors.primary.withOpacity(0.1),
                ),
                closedSuffixIcon: Icon(
                  Icons.keyboard_arrow_down,
                  color: controller.value?.isNotEmpty == true
                      ? Colors.white
                      : Colors.grey[600],
                  size: 22,
                ),
                expandedSuffixIcon: Icon(
                  Icons.keyboard_arrow_up,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              closedHeaderPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              listItemPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              searchRequestLoadingIndicator: Center(
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: Lottie.asset(
                    'assets/loading/palta_saltarina.json',
                    width: 50,
                    height: 50,
                  ),
                ),
              ),
            ),
          )
              : Container(
            constraints: const BoxConstraints(
              minWidth: 200,
              maxWidth: 280,
            ),
            child: controller.value?.isNotEmpty == true
                ? // Mostrar como chip cuando hay valor seleccionado
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.primary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      controller.value!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
                : // Mostrar placeholder cuando no hay valor seleccionado
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        fallbackValue,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldField(
      String label,
      String fallbackValue,
      TextEditingController controller, {
        bool enabled = true,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          widget.isEditMode
              ? Container(
            constraints: const BoxConstraints(
              minWidth: 200,
              maxWidth: 280,
            ),
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
              color: Colors.white,
            ),
            child: TextField(
              controller: controller,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: 'Escribe...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          )
              : Container(
            constraints: const BoxConstraints(
              minWidth: 200,
              maxWidth: 280,
            ),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                controller.text.isNotEmpty
                    ? controller.text
                    : fallbackValue,
                style: TextStyle(
                  fontSize: 13,
                  color: controller.text.isNotEmpty
                      ? Colors.black87
                      : Colors.grey[500],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterConsumptionField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consumo diario de agua',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          widget.isEditMode
              ? Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _consumoAgua = true;
                    _onFieldChanged();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 8),
                  decoration: BoxDecoration(
                    color: _consumoAgua == true
                        ? AppColors.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _consumoAgua == true
                          ? AppColors.primary
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    'Sí',
                    style: TextStyle(
                      color: _consumoAgua == true
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 14,
                      fontWeight:  _consumoAgua == true
                          ? FontWeight.w600 : FontWeight.normal
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _consumoAgua = false;
                    _cantidadAguaController.clear();
                    _onFieldChanged();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 8),
                  decoration: BoxDecoration(
                    color: _consumoAgua == false
                        ? AppColors.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _consumoAgua == false
                          ? AppColors.primary
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    'No',
                    style: TextStyle(
                      color: _consumoAgua == false
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 14,
                      fontWeight: _consumoAgua == false
                        ? FontWeight.w600
                        : FontWeight.w500
                    ),
                  ),
                ),
              ),
            ],
          )
              : Container(
            constraints: const BoxConstraints(
              minWidth: 200,
              maxWidth: 280,
            ),
            child: _consumoAgua == true
                ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Sí',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_cantidadAguaController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      _cantidadAguaController.text,
                      style: const TextStyle(
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            )
                : Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey[300]!,
                ),
              ),
              child: const Text(
                'No',
                style: TextStyle(
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          if (widget.isEditMode && _consumoAgua == true) ...[
            const SizedBox(height: 10),
            _buildTextFieldField(
              'Cantidad de agua (litros)',
              'Escribe la cantidad',
              _cantidadAguaController,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchDropdownField(
            '¿Cuántas veces al día come?',
            'Selecciona',
            _vecesDiaComeController,
            _vecesComidaOptions,
            _onDropdownChanged,
          ),
          _buildSearchDropdownField(
            'Preferencia por...',
            'Selecciona',
            _preferenciasController,
            _preferenciasOptions,
            _onDropdownChanged,
          ),
          _buildSearchDropdownField(
            'No le agrada...',
            'Selecciona',
            _noAgradaController,
            _noAgradaOptions,
            _onDropdownChanged,
          ),
          _buildSearchDropdownField(
            'Intolerancia o alergia por...',
            'Selecciona',
            _intoleranciasController,
            _intoleranciasOAlergiasOptions,
            _onDropdownChanged,
          ),
          _buildSearchDropdownField(
            'Lugar regular de ingesta',
            'Selecciona',
            _lugarIngestaController,
            _lugarIngestaOptions,
            _onDropdownChanged,
          ),
          _buildSearchDropdownField(
            'Hábitos nocivos',
            'Selecciona',
            _habitosNocivosController,
            _habitosNocivosOptions,
            _onDropdownChanged,
          ),
          _buildSearchDropdownField(
            'Tipo de actividad',
            'Selecciona',
            _tipoActividadController,
            _tipoActividadOptions,
            _onDropdownChanged,
          ),
          _buildWaterConsumptionField(),
        ],
      ),
    );
  }

  // Método público para obtener los datos actuales
  Map<String, String> getCurrentData() {
    return {
      'vecesComidaDia': _vecesDiaComeController.value ?? '',
      'preferencias': _preferenciasController.value ?? '',
      'noLeAgrada': _noAgradaController.value ?? '',
      'intolerancias': _intoleranciasController.value ?? '',
      'lugarDeIngesta': _lugarIngestaController.value ?? '',
      'habitosNocivos': _habitosNocivosController.value ?? '',
      'tipoActividad': _tipoActividadController.value ?? '',
      'consumoAgua': _consumoAgua == true ? 'Sí' : 'No',
      'consumoAguaDetail': _consumoAgua == true ? _cantidadAguaController.text : '',
    };
  }

  // Método público para actualizar datos externamente
  void updateData(Map<String, String> newData) {
    if (_vecesComidaOptions.contains(newData['vecesComidaDia'])) {
      _vecesDiaComeController.value = newData['vecesComidaDia'];
    }
    if (_preferenciasOptions.contains(newData['preferencias'])) {
      _preferenciasController.value = newData['preferencias'];
    }
    if (_noAgradaOptions.contains(newData['noLeAgrada'])) {
      _noAgradaController.value = newData['noLeAgrada'];
    }
    if (_intoleranciasOAlergiasOptions.contains(newData['intolerancias'])) {
      _intoleranciasController.value = newData['intolerancias'];
    }
    if (_lugarIngestaOptions.contains(newData['lugarDeIngesta'])) {
      _lugarIngestaController.value = newData['lugarDeIngesta'];
    }
    if (_habitosNocivosOptions.contains(newData['habitosNocivos'])) {
      _habitosNocivosController.value = newData['habitosNocivos'];
    }
    if (_tipoActividadOptions.contains(newData['tipoActividad'])) {
      _tipoActividadController.value = newData['tipoActividad'];
    }

    _consumoAgua = newData['consumoAgua']?.toLowerCase() == 'sí'.toLowerCase();
    if (_consumoAgua == true) {
      _cantidadAguaController.text = newData['consumoAguaDetail'] ?? '';
    }
  }

  // Método para limpiar cambios no guardados
  void resetToOriginal() {
    final vecesComidaOriginal = widget.patient.nutritionalProfile?.vecesDiaCome;
    final preferenciasOriginal = widget.patient.nutritionalProfile?.preferencias;
    final noAgradaOriginal = widget.patient.nutritionalProfile?.noLeAgrada;
    final intoleranciasOriginal = widget.patient.nutritionalProfile?.intolerancias;
    final lugarIngestaOriginal = widget.patient.nutritionalProfile?.lugarIngesta;
    final habitosOriginal = widget.patient.nutritionalProfile?.habitosNocivos;
    final actividadOriginal = widget.patient.nutritionalProfile?.tipoActividad;

    _vecesDiaComeController.value =
    _vecesComidaOptions.contains(vecesComidaOriginal) ? vecesComidaOriginal : null;
    _preferenciasController.value =
    _preferenciasOptions.contains(preferenciasOriginal) ? preferenciasOriginal : null;
    _noAgradaController.value =
    _noAgradaOptions.contains(noAgradaOriginal) ? noAgradaOriginal : null;
    _intoleranciasController.value =
    _intoleranciasOAlergiasOptions.contains(intoleranciasOriginal)
        ? intoleranciasOriginal
        : null;
    _lugarIngestaController.value =
    _lugarIngestaOptions.contains(lugarIngestaOriginal) ? lugarIngestaOriginal : null;
    _habitosNocivosController.value =
    _habitosNocivosOptions.contains(habitosOriginal) ? habitosOriginal : null;
    _tipoActividadController.value =
    _tipoActividadOptions.contains(actividadOriginal) ? actividadOriginal : null;

    _consumoAgua = widget.patient.nutritionalProfile?.consumeAgua;
    _cantidadAguaController.text =
        widget.patient.nutritionalProfile?.consumoAguaDetalle ?? '';

    setState(() {
      _hasLocalChanges = false;
    });
  }
}