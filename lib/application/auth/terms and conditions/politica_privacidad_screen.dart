import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../configuration/themes/app_colors.dart';
import '../../requestSnacbar/snackBar_manager.dart';

class PoliticaPrivacidadScreen extends StatefulWidget {
  const PoliticaPrivacidadScreen({Key? key}) : super(key: key);

  @override
  State<PoliticaPrivacidadScreen> createState() =>
      _PoliticaPrivacidadScreenState();
}

class _PoliticaPrivacidadScreenState extends State<PoliticaPrivacidadScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentSection = 0;

  final List<String> _secciones = [
    'Información General',
    'Datos que Recopilamos',
    'Uso de Datos',
    'Compartir Datos',
    'Tus Derechos',
    'Seguridad',
    'Cookies',
    'Contacto'
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar personalizada
            SliverAppBar(
              expandedHeight:100,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.backgroundLigth,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Política de Privacidad',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Actualizado: 30 de Julio, 2025',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 6),

              ),
            ),

            // Contenido principal
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Introducción
                    _buildIntroduccion(),
                    const SizedBox(height: 32),

                    // Secciones principales
                    _buildSeccion(
                      'Información General',
                      Icons.info_outline,
                      _buildInformacionGeneral(),
                    ),

                    _buildSeccion(
                      'Datos que Recopilamos',
                      Icons.data_usage,
                      _buildDatosRecopilamos(),
                    ),

                    _buildSeccion(
                      'Cómo Usamos tus Datos',
                      Icons.psychology,
                      _buildUsosDatos(),
                    ),

                    _buildSeccion(
                      'Compartir Información',
                      Icons.share,
                      _buildCompartirDatos(),
                    ),

                    _buildSeccion(
                      'Tus Derechos ARCO',
                      Icons.verified_user,
                      _buildDerechos(),
                    ),

                    _buildSeccion(
                      'Seguridad de Datos',
                      Icons.security,
                      _buildSeguridad(),
                    ),

                    _buildSeccion(
                      'Cookies y Tecnologías',
                      Icons.cookie,
                      _buildCookies(),
                    ),

                    _buildSeccion(
                      'Contacto y Ejercicio de Derechos',
                      Icons.contact_support,
                      _buildContacto(),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }


  Widget _buildIntroduccion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu privacidad es nuestra prioridad',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cumplimos con las leyes peruanas de protección de datos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'En Mottinut, protegemos tu información de salud con los más altos estándares de seguridad y transparencia. Esta política explica cómo recopilamos, usamos y protegemos tus datos personales en cumplimiento con la legislación peruana.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion(
      String titulo, IconData icono, Widget contenido) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey, width: 0.26)

      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icono, color: AppColors.primary, size: 24),
          ),
          title: Text(
            titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          subtitle: const Text(
            'Toca para expandir',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: contenido,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformacionGeneral() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          'Responsable del Tratamiento',
          'MOTTINUT S.A.C.',
          Icons.business,

        ),
        _buildInfoCard(
          'RUC',
          '20**********',
          Icons.receipt_long,

        ),
        _buildInfoCard(
          'Domicilio Legal',
          'Av. Pio XII - Surco, Lima, Perú',
          Icons.location_on,

        ),
        _buildInfoCard(
          'Base Legal',
          'Ley N° 29733 - LGPD Perú\nD.S. 016-2024-JUS',
          Icons.gavel,

        ),

      ],
    );
  }

  Widget _buildDatosRecopilamos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDatoCategoria(
          'Datos de Salud (Sensibles)',
          [
            'Condiciones médicas crónicas',
            'Alergias alimentarias',
            'Medicamentos actuales',
            'Historial nutricional',
            'Medidas antropométricas',
          ],

          'Estos datos requieren tu consentimiento explícito',
        ),
        _buildDatoCategoria(
          'Datos Personales',
          [
            'Nombre completo',
            'Edad y fecha de nacimiento',
            'Correo electrónico',
            'Número de teléfono',
            'Género',
          ],

          'Para personalizar tu experiencia',
        ),
        _buildDatoCategoria(
          'Datos de Uso',
          [
            'Interacciones con la app',
            'Preferencias nutricionales',
            'Progreso y seguimiento',
            'Dispositivo y ubicación',
          ],

          'Para mejorar nuestros servicios',
        ),
      ],
    );
  }

  Widget _buildUsosDatos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUsoItem(
          'Servicios Principales',
          'Generar recomendaciones nutricionales personalizadas para tu condición de salud',
          Icons.restaurant_menu,
          AppColors.primary
        ),
        _buildUsoItem(
          'Conexión Profesional',
          'Conectarte con nutricionistas validados especializados en tu patología',
          Icons.medical_services,
            AppColors.primary
        ),
        _buildUsoItem(
          'Seguimiento',
          'Monitorear tu progreso nutricional y ajustar recomendaciones',
          Icons.trending_up,
            AppColors.primary
        ),
        _buildUsoItem(
          'Comunicación',
          'Enviarte notificaciones importantes sobre tu salud nutricional',
          Icons.notifications,
            AppColors.primary
        ),
        _buildUsoItem(
          'Mejora del Servicio',
          'Analizar datos agregados para mejorar nuestros algoritmos',
          Icons.analytics,
            AppColors.primary
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.amber[700]),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'NO vendemos ni alquilamos tus datos personales a terceros',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompartirDatos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompartirItem(
          'Nutricionistas Validados',
          'Solo la información necesaria para tu consulta nutricional',
          Icons.person,

          true,
        ),
        _buildCompartirItem(
          'Servicios en la Nube',
          'AWS/Google Cloud con cifrado para almacenamiento seguro',
          Icons.cloud,
          true,
        ),
        _buildCompartirItem(
          'Autoridades de Salud',
          'Solo si es requerido por ley (MINSA, DIGEMID)',
          Icons.account_balance,
          true,
        ),
        _buildCompartirItem(
          'Empresas de Marketing',
          'NUNCA compartimos datos con fines comerciales',
          Icons.block,

          false,
        ),
        _buildCompartirItem(
          'Redes Sociales',
          'No integramos con Facebook, Google Analytics, etc.',
          Icons.share,
          false,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.checkValidation ,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Todos nuestros socios firman acuerdos de confidencialidad',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDerechos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Según la Ley Peruana N° 29733, tienes los siguientes derechos:',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4,),
        _buildDerechoARCO(
          'Acceso',
          'A',
          'Conocer qué datos personales tenemos sobre ti',
          'Solicita un reporte completo de tus datos',
        ),
        _buildDerechoARCO(
          'Rectificación',
          'R',
          'Corregir datos inexactos o incompletos',
          'Actualiza tu información médica',

        ),
        _buildDerechoARCO(
          'Cancelación',
          'C',
          'Solicitar la eliminación de tus datos',
          'Eliminar tu cuenta y datos asociados',

        ),
        _buildDerechoARCO(
          'Oposición',
          'O',
          'Oponerte al tratamiento de tus datos',
          'Limitar el uso de cierta información',

        ),
        const SizedBox(height: 20),
        _buildTimelineDerechos(),
        const SizedBox(height: 16),
        _buildContactButton(
          'Ejercer mis Derechos',
          'mailto:mottinutsoporte@gmail.com',
          'Formulario de solicitud ARCO',
        ),
      ],
    );
  }

  Widget _buildSeguridad() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSeguridadItem(
          'Cifrado End-to-End',
          'Todos los datos de salud se cifran con AES-256',
          Icons.lock,

        ),
        _buildSeguridadItem(
          'Acceso Restringido',
          'Solo personal autorizado puede acceder a datos sensibles',
          Icons.admin_panel_settings,

        ),
        _buildSeguridadItem(
          'Auditorías Regulares',
          'Revisiones de seguridad cada 3 meses',
          Icons.fact_check,

        ),
        _buildSeguridadItem(
          'Backup Seguro',
          'Respaldos automáticos cifrados en múltiples ubicaciones',
          Icons.backup,

        ),
        _buildSeguridadItem(
          'Monitoreo 24/7',
          'Detección automática de accesos no autorizados',
          Icons.monitor,

        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.errorIcon.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.errorIcon.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, color:AppColors.errorIcon),
                  const SizedBox(width: 8),
                  Text(
                    'En caso de brecha de seguridad',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.errorIcon,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Te notificaremos dentro de 72 horas y tomaremos medidas inmediatas para proteger tus datos.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.errorIcon.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCookies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCookieItem(
          'Cookies Esenciales',
          'Necesarias para el funcionamiento básico de la app',
          true,
          ['Sesión de usuario', 'Configuraciones básicas', 'Seguridad'],
        ),
        _buildCookieItem(
          'Cookies de Rendimiento',
          'Para mejorar la velocidad y experiencia de uso',
          true,

          ['Caché de contenido', 'Optimización de carga'],
        ),
        _buildCookieItem(
          'Cookies Analíticas',
          'Para entender cómo usas la aplicación',
          false,

          ['Estadísticas de uso', 'Patrones de navegación'],
        ),
        _buildCookieItem(
          'Cookies de Marketing',
          'Para publicidad personalizada',
          false,

          ['NO utilizamos cookies de marketing'],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:  AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color:  AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.settings, color:  AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Control de Cookies',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color:  AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Puedes gestionar tus preferencias de cookies en Configuración > Privacidad',
                style: TextStyle(
                  fontSize: 14,
                  color:  AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContacto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContactCard(
          'Oficial de Protección de Datos (DPO)',
          'mottinutsoporte@gmail.com',
          '+51 902 411 155',
          'Lun-Vie: 9:00 AM - 6:00 PM',
          Icons.person,
        ),
        _buildContactCard(
          'Soporte General',
          'mottinutsoporte@gmail.com',
          '+51 902 411 155',
          '24/7 disponible',
          Icons.support_agent,

        ),
        _buildContactCard(
          'Emergencias de Privacidad',
          'mottinutsoporte@gmail.com',
          '+51 902 411 155',
          'Respuesta inmediata',
          Icons.emergency,

        ),
        const SizedBox(height: 20),
        const Text(
          'Autoridades de Control:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildContactButton(
          'Autoridad Nacional de Protección de Datos',
          'https://www.minjus.gob.pe',
          'Ministerio de Justicia - MINJUS',
        ),
        _buildContactButton(
          'Defensoría del Pueblo',
          'https://www.defensoria.gob.pe',
          'Para quejas sobre protección de datos',
        ),
      ],
    );
  }

  // Widgets de construcción auxiliares
  Widget _buildInfoCard(
      String titulo, String valor, IconData icono) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.backgroundLigth,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icono, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textInput.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatoCategoria(
      String categoria, List<String> datos, String descripcion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLigth,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary ,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                categoria,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descripcion,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          ...datos
              .map((dato) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: AppColors.primary,),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dato,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildUsoItem(
      String titulo, String descripcion, IconData icono, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),

      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icono, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompartirItem(String titulo, String descripcion, IconData icono, bool permitido) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            permitido ? AppColors.backgroundLigth : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              permitido ? AppColors.primary.withOpacity(0.3) : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: permitido
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icono,
              color: permitido ? AppColors.primary : AppColors.errorIcon ,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: permitido ? AppColors.primary  : AppColors.errorIcon ,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: permitido ? AppColors.checkValidation : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        permitido ? 'SÍ' : 'NO',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDerechoARCO(String derecho, String letra, String descripcion,
      String ejemplo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLigth,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary ,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                letra,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  derecho,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary ,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ejemplo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDerechos() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plazos de Respuesta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.secondary ,
            ),
          ),
          const SizedBox(height: 12),
          _buildTimelineItem('Solicitud recibida', '24 horas', AppColors.checkValidation ),
          _buildTimelineItem(
              'Respuesta inicial', '10 días hábiles', AppColors.secondary),
          _buildTimelineItem(
              'Resolución completa', '20 días hábiles', AppColors.primary ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String titulo, String tiempo, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            tiempo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeguridadItem(
      String titulo, String descripcion, IconData icono) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLigth,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:  AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:  AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icono, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color:  AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookieItem(String tipo, String descripcion, bool activo,
      List<String> detalles) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:  AppColors.backgroundLigth,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:  AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tipo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:  AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: activo ?  AppColors.checkValidation : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activo ? 'ACTIVO' : 'INACTIVO',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descripcion,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...detalles
              .map((detalle) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color:  AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            detalle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildContactCard(String titulo, String email, String telefono,
      String horario, IconData icono) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:  AppColors.backgroundLigth,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:  AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:  AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icono, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:  AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactInfo(
              Icons.email, email, () => _launchUrl('mailto:$email')),
          _buildContactInfo(
              Icons.phone, telefono, () => _launchUrl('tel:$telefono')),
          _buildContactInfo(Icons.schedule, horario, null),
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icono, String texto, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 30),
        child: Row(
          children: [
            Icon(icono, size: onTap != null ?  18 : 12, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: onTap != null ?  15 : 12,
                  color: onTap != null ?  AppColors.textLDark : AppColors.textInput ,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton(String titulo, String url, String subtitulo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchUrl(url),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLigth,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.backgroundtInput.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.open_in_new,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.primary.withOpacity(0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          SnackBarManager.showError(context, 'No se pudo abrir: $url');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarManager.showError(context, 'Error al abrir el enlace: $e');
      }
    }
  }
}

