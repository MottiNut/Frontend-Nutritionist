import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../configuration/themes/app_colors.dart';
import '../../../domain/patient/new/rutadirectaaa/muestraaa.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class PatientUrgencyScreen extends StatefulWidget {
  final String token;

  const PatientUrgencyScreen({Key? key, required this.token}) : super(key: key);

  @override
  _PatientUrgencyScreenState createState() => _PatientUrgencyScreenState();
}

class _PatientUrgencyScreenState extends State<PatientUrgencyScreen>
    with SingleTickerProviderStateMixin {
  final NutritionistService _service = NutritionistService();

  List<PatientUrgency> _urgencies = [];
  List<PatientUrgency> _filteredUrgencies = [];
  Map<String, int> _stats = {};
  int _totalMonitoredPatients = 0;

  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _searchQuery = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;

  late SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';

  late AudioPlayer _audioPlayer;
  bool _canVibrate = false;

  late final NutritionistService nutritionistService;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initSpeech();
    _initializeAudioAndVibration();
    nutritionistService = NutritionistService();
    _loadUrgencies();
    _startAutoRefresh();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _applyFilters();
    });
  }

  void _initializeAudioAndVibration() async {
    // Verificar si el dispositivo puede vibrar
    bool canVibrate = await Vibrate.canVibrate;
    setState(() {
      _canVibrate = canVibrate;
    });

    print(
        '🔊 Audio del sistema y vibración inicializados. Puede vibrar: $canVibrate');
  }

  void _initSpeech() async {
    print('🎤 Inicializando Speech to Text...');

    try {
      _speech = SpeechToText();

      // Verificar si el dispositivo tiene capacidad de reconocimiento
      bool available = await _speech.initialize(
        onError: (errorNotification) {
          print('❌ Error en Speech: ${errorNotification.errorMsg}');
          setState(() {
            _speechEnabled = false;
            _isListening = false;
          });
        },
        onStatus: (status) {
          print('📊 Status Speech: $status');
          setState(() {
            _isListening = status == 'listening';
          });
        },
        debugLogging: true, // Habilitar logs para debugging
      );

      if (available) {
        // Verificar permisos específicamente
        bool hasPermission = await _speech.hasPermission;
        print('🔐 Permisos: $hasPermission');

        setState(() {
          _speechEnabled = available && hasPermission;
        });

        print('✅ Speech inicializado correctamente: $_speechEnabled');
      } else {
        print('❌ Speech no disponible en este dispositivo');
        setState(() {
          _speechEnabled = false;
        });
      }
    } catch (e) {
      print('💥 Error crítico en _initSpeech: $e');
      setState(() {
        _speechEnabled = false;
      });
    }
  }

  Future<bool> _checkMicrophonePermission() async {
    try {
      bool hasPermission = await _speech.hasPermission;
      print('🔍 Verificando permisos: $hasPermission');

      if (!hasPermission) {
        // Mostrar diálogo explicativo
        bool shouldRequestPermission = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.mic, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Permiso de Micrófono'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Para usar la búsqueda por voz, necesitamos acceso al micrófono.'),
                    SizedBox(height: 8),
                    Text(
                      'Esta función te permite buscar pacientes hablando en lugar de escribir.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Permitir'),
                  ),
                ],
              ),
            ) ??
            false;

        if (shouldRequestPermission) {
          // Reintentar inicialización para solicitar permisos
          try {
            bool reinitialized = await _speech.initialize(
              onError: (error) =>
                  print('Error reinicializando: ${error.errorMsg}'),
              onStatus: (status) => print('Status reinicialización: $status'),
            );

            if (reinitialized) {
              bool newPermission = await _speech.hasPermission;
              print('🔄 Nuevo estado de permisos: $newPermission');
              return newPermission;
            }
          } catch (e) {
            print('Error en reinicialización: $e');
          }
        }
        return false;
      }

      return true;
    } catch (e) {
      print('Error verificando permisos: $e');
      return false;
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();

      // FEEDBACK DE PARADA
      _vibrateStop();
      _playStopSound();

      print('🛑 Grabación detenida');
    } catch (e) {
      print('Error deteniendo grabación: $e');
    } finally {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _playStartSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      print('🔊 Sonido de inicio reproducido');
    } catch (e) {
      print('❌ Error reproduciendo sonido de inicio: $e');
    }
  }

  void _playStopSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      print('🔊 Sonido de parada reproducido');
    } catch (e) {
      print('❌ Error reproduciendo sonido de parada: $e');
    }
  }

  void _vibrateStart() async {
    if (_canVibrate) {
      try {
        await HapticFeedback.mediumImpact();
        print('📳 Vibración de inicio');
      } catch (e) {
        print('❌ Error en vibración: $e');
      }
    }
  }

  void _vibrateStop() async {
    if (_canVibrate) {
      try {
        await HapticFeedback.heavyImpact();
        print('📳 Vibración de parada');
      } catch (e) {
        print('❌ Error en vibración: $e');
      }
    }
  }

  Future<void> _startListening() async {
    print('🎙️ Intentando iniciar grabación...');

    if (!_speechEnabled) {
      print('❌ Speech no está habilitado');
      _showSpeechErrorDialog(
          'El reconocimiento de voz no está disponible en este dispositivo.');
      return;
    }

    // Verificar permisos
    bool hasPermission = await _checkMicrophonePermission();
    if (!hasPermission) {
      print('❌ Sin permisos de micrófono');
      return;
    }

    try {
      // Si ya está escuchando, detener
      if (_isListening) {
        await _stopListening();
        return;
      }

      // FEEDBACK DE INICIO
      _vibrateStart();
      _playStartSound();

      // Limpiar texto anterior
      _lastWords = '';

      // Iniciar grabación
      await _speech.listen(
        onResult: (result) {
          print('🗣️ Resultado: ${result.recognizedWords}');
          setState(() {
            _lastWords = result.recognizedWords;
            _searchController.text = result.recognizedWords;
            _searchQuery = result.recognizedWords;
          });
          _applyFilters();

          // Si el resultado es final, detener
          if (result.finalResult) {
            _stopListening();
          }
        },
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 5),
        partialResults: true,
        localeId: 'es_ES',
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      print('✅ Grabación iniciada exitosamente');
    } catch (e) {
      print('💥 Error iniciando grabación: $e');
      setState(() {
        _isListening = false;
      });
      _showSpeechErrorDialog('Error al iniciar el reconocimiento de voz: $e');
    }
  }

  void _showSpeechErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error de Voz'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  void _startAutoRefresh() {
    // Refrescar cada 30 segundos
    Stream.periodic(const Duration(seconds: 30)).listen((_) {
      if (mounted) {
        _loadUrgencies();
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _lastWords = '';
      if (_isListening) {
        _stopListening();
      }
    });
    _applyFilters();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _speech.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadUrgencies() async {
    try {
      // Ejecutar ambas llamadas en paralelo
      final results = await Future.wait([
        _service.getPatientsWithUrgency(token: widget.token),
        _service.getUrgencyStats(widget.token),
      ]);

      final urgencies = results[0] as List<PatientUrgency>;
      final stats = results[1] as Map<String, int>;

      if (mounted) {
        setState(() {
          _urgencies = urgencies;
          _stats = stats;
          // CAMBIO: Calcular el total correcto
          _totalMonitoredPatients =
              urgencies.length; // O usar stats['total'] si viene del backend
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      print('Error cargando urgencias: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error al cargar urgencias: $e');
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUrgencies = _urgencies.where((urgency) {
        bool matchesFilter = _selectedFilter == 'all' ||
            urgency.urgencyLevel.toString().split('.').last == _selectedFilter;

        bool matchesSearch = _searchQuery.isEmpty ||
            urgency.patientName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            urgency.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  UrgencyConfig _getUrgencyConfig(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.critical:
        return UrgencyConfig(
          color: AppColors.errorIcon,
          icon: Icons.emergency,
          text: 'CRÍTICO',
          pulse: true,
        );
      case UrgencyLevel.high:
        return UrgencyConfig(
          color: AppColors.secondary,
          icon: Icons.warning,
          text: 'ALTA',
          pulse: false,
        );
      case UrgencyLevel.medium:
        return UrgencyConfig(
          color: Colors.amber,
          icon: Icons.priority_high,
          text: 'MEDIA',
          pulse: false,
        );
      case UrgencyLevel.low:
        return UrgencyConfig(
          color: AppColors.checkValidation,
          icon: Icons.check_circle,
          text: 'BAJA',
          pulse: false,
        );
    }
  }

  Future<void> _contactPatient(
      PatientUrgency urgency, ContactMethod method) async {
    try {
      switch (method) {
        case ContactMethod.phone:
          await launchUrl(Uri.parse('tel:${urgency.patient?.phone ?? ''}'));
          break;
        case ContactMethod.whatsapp:
          final message = Uri.encodeComponent(
              'Hola ${urgency.patientName}, necesitamos agendar una consulta urgente. '
              'Motivo: ${urgency.description}. Por favor, contáctanos.');
          final phone =
              urgency.patient?.phone?.replaceAll(RegExp(r'\D'), '') ?? '';
          await launchUrl(Uri.parse('https://wa.me/$phone?text=$message'));
          break;
      }
    } catch (e) {
      _showErrorDialog('Error al contactar paciente: $e');
    }
  }

  void _showPatientDetails(PatientUrgency urgency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PatientUrgencyDetails(
        urgency: urgency,
        onContact: (method) => _contactPatient(urgency, method),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        // Botón de retroceso personalizado
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/images/anterior_icon.svg',
            height: 22,
            width: 22,
            color: AppColors.errorText,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        // Título centrado
        title: Text(
          'Pacientes con Urgencias',
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.errorText,
              fontSize: 20),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/loading/palta_saltarina.json',
            width: 100,
            height: 100,
          ),
          SizedBox(height: 16),
          Text('Analizando urgencias...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: Colors.white,
      onRefresh: _loadUrgencies,
      child: CustomScrollView(
        slivers: [
          // Filters Section - FIJO
          SliverPersistentHeader(
            pinned: true,
            delegate: _FiltersSectionDelegate(
              child: Container(
                color: Colors.grey[50],
                child: _buildFiltersSection(),
              ),
            ),
          ),

          // Stats Section
          SliverToBoxAdapter(
            child: _buildStatsSection(),
          ),

          // Urgencies List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildUrgencyCard(_filteredUrgencies[index]),
              childCount: _filteredUrgencies.length,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 60),
          ),

          // Empty State
          if (_filteredUrgencies.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 80, 20, 0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 70,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No hay urgencias en este momento',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.withOpacity(0.5),
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Todos los pacientes están bajo control',
                        style: TextStyle(color: AppColors.textPrimary1),
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

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de Urgencias',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Críticos', _stats['critical'] ?? 0,
                      AppColors.errorIcon)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildStatCard(
                      'Alta', _stats['high'] ?? 0, AppColors.secondary)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildStatCard(
                      'Media', _stats['medium'] ?? 0, Colors.amber)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildStatCard(
                      'Baja', _stats['low'] ?? 0, AppColors.checkValidation)),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Icon(Icons.people, color: AppColors.errorText.withOpacity(0.6)),
                const SizedBox(width: 12),
                Text(
                  'Total de pacientes monitoreados: ',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.errorText.withOpacity(0.6),
                      fontSize: 12),
                ),
                const SizedBox(width: 2),
                Text(
                  '$_totalMonitoredPatients',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.errorText,
                      fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(3, 0, 3, 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          _buildSearchField(),
          _buildRecordingIndicator(),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildFilterChip('Todos', 'all'),
                buildFilterChip('Críticos', 'critical'),
                buildFilterChip('Alta', 'high'),
                buildFilterChip('Media', 'medium'),
                buildFilterChip('Baja', 'low'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    if (!_isListening) return SizedBox.shrink();

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.15),
            Colors.red.withOpacity(0.08),
            Colors.red.withOpacity(0.15),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.red.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animación de ondas mejorada
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Row(
                children: List.generate(4, (index) {
                  final delay = index * 0.25;
                  final animValue = ((_pulseAnimation.value + delay) % 1.0);
                  return Container(
                    width: 3,
                    height: 8 + (12 * animValue),
                    margin: EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  );
                }),
              );
            },
          ),

          SizedBox(width: 12),

          // Icono de micrófono activo
          Icon(
            Icons.mic,
            color: Colors.red.shade700,
            size: 16,
          ),

          SizedBox(width: 8),

          // Texto indicador mejorado
          Text(
            _lastWords.isEmpty ? 'Escuchando...' : 'Procesando...',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(width: 12),

          // Botón para parar mejorado
          GestureDetector(
            onTap: _stopListening,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
              ),
              child: Icon(
                Icons.stop_rounded,
                color: Colors.red.shade700,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuffixIcon() {
    if (_searchController.text.isEmpty) {
      return Container(
        width: 45,
        height: 45,
        margin: EdgeInsets.all(2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: _speechEnabled ? _startListening : null,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              decoration: BoxDecoration(
                // Solo mostrar fondo cuando está grabando
                color: _isListening
                    ? Colors.red.withOpacity(0.1)
                    : Colors.transparent, // Sin fondo cuando no está grabando
                borderRadius: BorderRadius.circular(25),
                // Solo mostrar borde cuando está grabando
                border: _isListening
                    ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
                    : null,
                // Sombra solo cuando está grabando
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animación de ondas cuando está grabando
                  if (_isListening)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 35 * _pulseAnimation.value,
                          height: 35 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(
                                0.15 * (1 - _pulseAnimation.value + 0.5)),
                          ),
                        );
                      },
                    ),

                  // Icono del micrófono - estilo TikTok
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      // Icono relleno cuando está grabando, outline cuando no
                      _isListening ? Icons.mic : Icons.mic_none_outlined,
                      color: _isListening
                          ? Colors.red.shade600 // Rojo cuando está grabando
                          : (_speechEnabled
                              ? Colors.grey
                                  .shade600 // Gris normal cuando está habilitado
                              : Colors.grey.shade400),
                      // Gris claro cuando está deshabilitado
                      size: _isListening ? 26 : 24,
                    ),
                  ),

                  // Punto indicador solo cuando está grabando
                  if (_isListening)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.clear, color: Colors.grey.shade500, size: 20),
      onPressed: _clearSearch,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _isListening
              ? Colors.red.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: _isListening ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: _isListening ? 'Escuchando...' : 'Buscar paciente...',
          hintStyle: TextStyle(
            color: _isListening ? Colors.red.shade400 : Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: (_searchController.text.isEmpty && !_isListening)
              ? Icon(Icons.search, color: Colors.grey.shade400)
              : null,
          suffixIcon: _buildSuffixIcon(),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        style: TextStyle(
          color: _isListening ? Colors.red.shade700 : Colors.black87,
          fontWeight: _isListening ? FontWeight.w500 : FontWeight.normal,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade500,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
          _applyFilters();
        },
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 1 : 0.5,
        ),
        checkmarkColor: Colors.white,
        elevation: isSelected ? 2 : 0,
        shadowColor: Colors.grey.shade300,
      ),
    );
  }

  Widget _buildUrgencyCard(PatientUrgency urgency) {
    final config = _getUrgencyConfig(urgency.urgencyLevel);
    final patientId = urgency.patientId;
    final hasPhone = urgency.patient?.phone != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Card(
        elevation: 3,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.5),
            width: 0.3,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPatientDetails(urgency),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 110,
                  child: Stack(
                    children: [
                      FutureBuilder<Uint8List?>(
                        future: patientId > 0
                            ? nutritionistService.getPatientProfileImage(
                                patientId,
                                widget.token,
                              )
                            : Future.value(null),
                        builder: (context, snapshot) {
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(14),
                                bottomLeft: Radius.circular(14),
                              ),
                              child: snapshot.hasData && snapshot.data != null
                                  ? Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: AppColors.primary.withOpacity(0.2),
                                      child: Center(
                                        child: SvgPicture.asset(
                                          'assets/images/user_placeholder_esmer.svg',
                                          width: 70,
                                          height: 70,

                                          fit: BoxFit.contain,
                                          placeholderBuilder:
                                              (BuildContext context) =>
                                                  Container(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            child: Center(
                                              child: Text(
                                                urgency.patientName
                                                    .split(' ')
                                                    .map((e) => e.isNotEmpty
                                                        ? e[0]
                                                        : '')
                                                    .take(2)
                                                    .join()
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 30,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                      if (urgency.urgencyLevel == UrgencyLevel.critical)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.priority_high,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ETIQUETA DE URGENCIA ARRIBA A LA DERECHA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: config.color,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    config.icon,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    config.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 1
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // CONTENIDO PRINCIPAL
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    urgency.patientName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Hace ${urgency.daysSinceLastConsultation} días',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    urgency.description,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // Indicador de acción inmediata
                                      if (urgency.requiresImmediateAction)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red[100],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: Colors.red[300]!),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.warning,
                                                color: Colors.red[700],
                                                size: 10,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                'URGENTE',
                                                style: TextStyle(
                                                  color: Colors.red[700],
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      const SizedBox(width: 6),

                                      // Indicador de contacto disponible
                                      if (hasPhone)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.phone,
                                                color: Colors.green[700],
                                                size: 8,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                'Tel',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // BOTONES DEBAJO QUE SE EXPANDEN
                        if (hasPhone)
                          Row(
                            children: [
                              // Botón llamar
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _contactPatient(
                                      urgency, ContactMethod.phone),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: 1,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.phone, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Llamar',
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 6),

                              // Botón WhatsApp
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _contactPatient(
                                      urgency, ContactMethod.whatsapp),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.checkValidation,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: 1,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.message, size: 14),
                                      const SizedBox(width: 4),
                                      Text('WhatsApp',
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 6),

                              // Botón ver
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _showPatientDetails(urgency),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey[600],
                                    side: BorderSide(color: Colors.grey[400]!),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.visibility, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Ver',
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showPatientDetails(urgency),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 1,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ver detalles',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FiltersSectionDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FiltersSectionDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 130.0;

  @override
  double get minExtent => 130.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class PatientUrgencyDetails extends StatelessWidget {
  final PatientUrgency urgency;
  final Function(ContactMethod) onContact;

  const PatientUrgencyDetails({
    Key? key,
    required this.urgency,
    required this.onContact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header

                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        urgency.patientName.substring(0, 2).toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            urgency.patientName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (urgency.patient?.phone != null) ...[
                            Text(
                              ' ${urgency.patient?.phone}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ] else ...[
                            Container(
                              child: Row(
                                children: [
                                  Text(
                                    'Teléfono no disponible',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Urgency Level
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emergency, color: AppColors.errorIcon),
                          const SizedBox(width: 8),
                          Text(
                            'Nivel de Urgencia: ${urgency.urgencyLevel.toString().split('.').last.toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        urgency.description,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Details
                _buildDetailRow('Días sin consulta',
                    '${urgency.daysSinceLastConsultation} días'),
                if (urgency.lastConsultationDate != null)
                  _buildDetailRow(
                    'Última consulta',
                    _formatDate(urgency.lastConsultationDate!),
                  ),
                _buildDetailRow('Detectado', _formatDate(urgency.detectedAt)),
                if (urgency.requiresImmediateAction)
                  _buildDetailRow(
                    'Acción requerida',
                    'INMEDIATA',
                    isImportant: true,
                  ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onContact(ContactMethod.phone),
                        icon: const Icon(Icons.phone),
                        label: const Text('Llamar',
                            style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onContact(ContactMethod.whatsapp),
                        icon: const Icon(Icons.message),
                        label: Text(
                          'WhatsApp',
                          style: TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.checkValidation,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
                color: isImportant ? Colors.red[600] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
