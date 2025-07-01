import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../configuration/themes/app_colors.dart';


class TerminosCondicionesScreen extends StatefulWidget {
  const TerminosCondicionesScreen({Key? key}) : super(key: key);

  @override
  State<TerminosCondicionesScreen> createState() =>
      _TerminosCondicionesScreenState();
}

class _TerminosCondicionesScreenState extends State<TerminosCondicionesScreen> {
  bool _acepto = false;
  final ScrollController _scrollController = ScrollController();
  final List<bool> _expandedSections = List.generate(8, (index) => false);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildAvisoLegal(),
                  _buildContenidoLegal(),
                ],
              ),
            ),
          ),
          SizedBox(height: 55,)
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Términos y Condiciones',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      backgroundColor: AppColors.backgroundLigth,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.search_rounded,
            color: Colors.black.withOpacity(0.8),
            size: 24,
          ),
          onPressed: () {

            //_showSearchDialog();
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.backgroundLigth,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/images/logos/mottinut.svg',
                width: 50, height:50,
                ),
                const SizedBox(height: 6),
                Container(
                  child: const Text(
                    'últ. actualización: 30 de Junio, 2025',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisoLegal() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),

      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorText.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: AppColors.errorIcon,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVISO LEGAL IMPORTANTE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'MOTTINUT proporciona herramientas de apoyo nutricional y NO constituye asesoramiento médico, diagnóstico, tratamiento o sustituto de atención médica profesional. Siempre consulte con un profesional de la salud calificado.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContenidoLegal() {
    final secciones = [
      {
        'titulo': '1. Marco Legal y Jurisdicción',
        'icono': Icons.account_balance,
        'contenido': _buildMarcoLegal(),
      },
      {
        'titulo': '2. Naturaleza y Alcance del Servicio',
        'icono': Icons.description,
        'contenido': _buildNaturalezaServicio(),
      },
      {
        'titulo': '3. Protección de Datos Personales',
        'icono': Icons.security,
        'contenido': _buildProteccionDatos(),
      },
      {
        'titulo': '4. Obligaciones del Usuario',
        'icono': Icons.person_outline,
        'contenido': _buildObligacionesUsuario(),
      },
      {
        'titulo': '5. Profesionales y Validaciones',
        'icono': Icons.verified_user,
        'contenido': _buildProfesionales(),
      },
      {
        'titulo': '6. Limitaciones de Responsabilidad',
        'icono': Icons.gavel,
        'contenido': _buildLimitaciones(),
      },
      {
        'titulo': '7. Protocolos de Emergencia',
        'icono': Icons.emergency,
        'contenido': _buildEmergencias(),
      },
      {
        'titulo': '8. Contacto y Recursos Legales',
        'icono': Icons.contact_support,
        'contenido': _buildContacto(),
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: secciones.asMap().entries.map((entry) {
          final index = entry.key;
          final seccion = entry.value;
          return _buildSeccionLegal(
            index,
            seccion['titulo'] as String,
            seccion['icono'] as IconData,
            seccion['contenido'] as Widget,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSeccionLegal(
      int index, String titulo, IconData icono, Widget contenido) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLigth,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 0.03, color: AppColors.backgroundtInput),

      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedSections[index] = !_expandedSections[index];
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icono,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _expandedSections[index]
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expandedSections[index]) ...[
            Container(
              width: double.infinity,
              height: 0.3,
              color: AppColors.backgroundtInput,
            ),
            Container(
              padding: const EdgeInsets.all(15),
              child: contenido,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarcoLegal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildParrafoLegal(
          'Estos términos se rigen por la legislación peruana vigente:',
        ),
        const SizedBox(height: 12),
        _buildReferenciaLegal(
          'Ley N° 26842 - Ley General de Salud',
          'Normativa fundamental para servicios relacionados con salud',
        ),
        _buildReferenciaLegal(
          'Ley N° 29733 - Protección de Datos Personales',
          'Protección de datos sensibles de salud',
        ),
        _buildReferenciaLegal(
          'D.S. N° 016-2024-JUS',
          'Reglamento actualizado de protección de datos (vigente desde marzo 2025)',
        ),
        _buildReferenciaLegal(
          'Resoluciones MINSA sobre Telemedicina',
          'Regulación de servicios digitales de salud',
        ),
        const SizedBox(height: 12),
        _buildParrafoLegal(
          'Jurisdicción: Los tribunales de Lima, Perú, tendrán jurisdicción exclusiva para resolver cualquier disputa derivada de estos términos.',
        ),
      ],
    );
  }

  Widget _buildNaturalezaServicio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtituloLegal('MOTTINUT proporciona:'),
        _buildListaLegal([
          'Herramientas de seguimiento nutricional personalizado',
          'Contenido educativo basado en evidencia científica',
          'Conexión con profesionales nutricionistas colegiados',
          'Recomendaciones para el manejo de patologías crónicas',
        ]),
        const SizedBox(height: 16),
        _buildSubtituloLegal('EXCLUSIONES EXPRESAS:'),
        _buildCajaAdvertencia([
          'No constituye diagnóstico médico ni tratamiento',
          'No reemplaza consulta médica presencial',
          'No prescribe medicamentos ni tratamientos médicos',
          'No maneja emergencias médicas',
        ]),
      ],
    );
  }

  Widget _buildProteccionDatos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtituloLegal('Categorías de Datos Tratados:'),
        _buildListaLegal([
          'Datos de identificación personal',
          'Datos de salud y condiciones médicas (categoría especial)',
          'Información nutricional y dietética',
          'Datos de uso y preferencias de la aplicación',
        ]),
        const SizedBox(height: 16),
        _buildSubtituloLegal('Ejercicio de Derechos ARCO:'),
        _buildParrafoLegal(
          'Conforme al artículo 18° de la Ley N° 29733, usted puede ejercer sus derechos de Acceso, Rectificación, Cancelación y Oposición contactando a:',
        ),
        const SizedBox(height: 8),
        _buildContactoOficial('privacidad@mottinut.pe'),
        const SizedBox(height: 12),
        _buildParrafoLegal(
          'Plazo de respuesta: 10 días hábiles conforme a la normativa vigente.',
        ),
      ],
    );
  }

  Widget _buildObligacionesUsuario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtituloLegal('Obligaciones Fundamentales:'),
        _buildListaLegal([
          'Proporcionar información veraz, completa y actualizada',
          'Informar inmediatamente cambios en su condición de salud',
          'Mantener confidencialidad de sus credenciales de acceso',
          'Utilizar el servicio conforme a su finalidad establecida',
        ]),
        const SizedBox(height: 16),
        _buildSubtituloLegal('Responsabilidades Médicas:'),
        _buildCajaAdvertencia([
          'Consultar con su médico antes de implementar recomendaciones',
          'No suspender tratamientos médicos prescritos',
          'Reportar reacciones adversas a su profesional de salud',
          'Acudir a servicios de emergencia en casos urgentes',
        ]),
      ],
    );
  }

  Widget _buildProfesionales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtituloLegal('Requisitos de Habilitación:'),
        _buildListaLegal([
          'Colegiatura vigente en el Colegio de Nutricionistas del Perú',
          'Experiencia mínima de 3 años en nutrición clínica',
          'Certificación en manejo de patologías crónicas',
          'Capacitación en telemedicina y salud digital',
        ]),
        const SizedBox(height: 16),
        _buildParrafoLegal(
          'Verificación: Todos los profesionales son validados mensualmente contra el registro oficial del colegio profesional.',
        ),
        const SizedBox(height: 8),
        _buildContactoOficial(
            'Verificar colegiatura: colegionutricionistas.org.pe'),
      ],
    );
  }

  Widget _buildLimitaciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildParrafoLegal(
          'LIMITACIÓN DE RESPONSABILIDAD: MOTTINUT no será responsable por:',
        ),
        const SizedBox(height: 12),
        _buildCajaAdvertencia([
          'Decisiones médicas basadas exclusivamente en recomendaciones nutricionales',
          'Daños resultantes de información de salud incompleta o inexacta',
          'Incumplimiento de indicaciones médicas profesionales',
          'Fallas técnicas, interrupciones del servicio o pérdida de datos',
          'Reacciones adversas no reportadas previamente',
        ]),
        const SizedBox(height: 16),
        _buildParrafoLegal(
          'LÍMITE MÁXIMO: La responsabilidad total de MOTTINUT no excederá el monto pagado por el usuario en los últimos 12 meses.',
        ),
      ],
    );
  }

  Widget _buildEmergencias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.errorText.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.errorText.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emergency, color: AppColors.errorIcon, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'PROTOCOLOS DE EMERGENCIA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.errorText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'MOTTINUT NO MANEJA EMERGENCIAS MÉDICAS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'En caso de emergencia médica, contacte inmediatamente:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              _buildNumeroEmergencia('SAMU', '106'),
              _buildNumeroEmergencia('Bomberos', '116'),
              _buildNumeroEmergencia('Policía Nacional', '105'),
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
        _buildSubtituloLegal('Contactos Oficiales:'),
        _buildContactoOficial('Protección de Datos: privacidad@mottinut.pe'),
        _buildContactoOficial('Soporte Legal: legal@mottinut.pe'),
        _buildContactoOficial('Soporte Técnico: soporte@mottinut.pe'),
        const SizedBox(height: 16),
        _buildSubtituloLegal('Autoridades de Control:'),
        _buildContactoOficial(
            'Autoridad Nacional de Protección de Datos Personales'),
        _buildContactoOficial('Ministerio de Salud (MINSA)'),
        _buildContactoOficial('Colegio de Nutricionistas del Perú'),
      ],
    );
  }


  // Widgets de apoyo para contenido legal
  Widget _buildParrafoLegal(String texto) {
    return Text(

      texto,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.2,
      ),
    );
  }

  Widget _buildSubtituloLegal(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildListaLegal(List<String> items) {
    return Column(
      children: items
          .map((item) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, right: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildReferenciaLegal(String titulo, String descripcion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),

      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            descripcion,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCajaAdvertencia(List<String> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorText.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.errorText.withOpacity(0.2)),
      ),
      child: Column(
        children: items
            .map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.priority_high,
                        color: AppColors.errorIcon,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildContactoOficial(String contacto) {
    final esEmail = contacto.contains('@');
    final esUrl = contacto.contains('http') ||
        contacto.contains('.pe') ||
        contacto.contains('.com');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          if (esEmail) {
            _launchUrl('mailto:$contacto');
          } else if (esUrl && !contacto.contains('Verificar')) {
            _launchUrl('https://$contacto');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(
                esEmail ? Icons.email_outlined : Icons.language,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  contacto,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (esEmail || esUrl) ...[
                Icon(
                  Icons.open_in_new,
                  color: AppColors.primary,
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumeroEmergencia(String servicio, String numero) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _launchUrl('tel:$numero'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.errorText.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                Icons.phone,
                color: AppColors.errorIcon,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '$servicio: $numero',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enlace copiado al portapapeles'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enlace copiado al portapapeles'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _aceptarTerminos() {
    // Aquí implementas la lógica cuando el usuario acepta
    // Por ejemplo, guardar en SharedPreferences, navegar a otra pantalla, etc.

    // Feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Términos y condiciones aceptados'),
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 2),
      ),
    );

    // Ejemplo: navegar de vuelta o a la siguiente pantalla
    Navigator.of(context).pop(true); // Retorna true indicando que aceptó

    // O navegar a otra pantalla:
    // Navigator.of(context).pushReplacementNamed('/home');
  }
}
