import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../configuration/themes/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Preguntas Frecuentes',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.8,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              height: 43,
              child: TextField(
                style: TextStyle(fontSize: 14, ),
                decoration: InputDecoration(
                  suffixIcon: Icon(
                    LucideIcons.search,
                    color: Colors.grey.shade400,
                  ),
                  hintText: 'Buscar consejos o preguntas...',
                  hintStyle: const TextStyle(fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // 🔹 Padding interno del texto
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 6),
              children: [
                _buildTipCard(
                  icon: LucideIcons.apple,
                  title: "Plan de alimentación balanceado",
                  description:
                  "Aprende cómo equilibrar tus macronutrientes de manera efectiva para mejorar tu salud.",
                ),
                _buildTipCard(
                  icon: LucideIcons.droplet,
                  title: "Importancia de la hidratación",
                  description:
                  "Descubre cuánta agua deberías tomar al día según tu peso y estilo de vida.",
                ),
                _buildTipCard(
                  icon: LucideIcons.dumbbell,
                  title: "Nutrición y ejercicio",
                  description:
                  "Cómo potenciar tu rendimiento físico a través de una dieta adecuada.",
                ),

                const SizedBox(height: 15),

                Text(
                  "Respuestas Rápidas",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),

                _buildFaqItem(
                  context: context,
                  question: "¿Cómo puedo agendar una cita con mi nutricionista?",
                  answer:
                  "Ingresa a la sección 'Citas' de la app, elige el profesional disponible, selecciona la fecha y confirma el horario.",
                ),
                _buildFaqItem(
                  context: context,
                  question: "¿Puedo modificar mi plan de alimentación después de recibirlo?",
                  answer:
                  "Sí, puedes solicitar cambios enviando un mensaje directo a tu nutricionista o agendando una nueva consulta.",
                ),
                _buildFaqItem(
                  context: context,
                  question: "¿La app genera recordatorios para mis comidas?",
                  answer:
                  "Sí, puedes activar notificaciones en tu perfil para recibir alertas en los horarios indicados en tu plan.",
                ),
                _buildFaqItem(
                  context: context,
                  question: "¿Qué debo hacer si olvidé mi contraseña?",
                  answer:
                  "En la pantalla de inicio de sesión, toca en '¿Olvidaste tu contraseña?' y sigue las instrucciones para restablecerla.",
                ),
                _buildFaqItem(
                  context: context,
                  question: "¿Cómo actualizo mi peso y mis medidas?",
                  answer:
                  "Ve a tu perfil, selecciona 'Datos de salud' y actualiza tu información para que el plan se ajuste automáticamente.",
                ),
                _buildFaqItem(
                  context: context,
                  question: "¿Puedo compartir mi progreso con mi nutricionista?",
                  answer:
                  "Sí, todos los registros de peso, fotos y mediciones son visibles para tu nutricionista en tiempo real.",
                ),
                _buildFaqItem(
                  context: context,
                  question: "¿Qué pasa si tengo alergias o restricciones alimentarias?",
                  answer:
                  "Al completar tu formulario inicial, indica tus alergias o restricciones para que el plan sea 100% personalizado.",
                ),
                _buildFaqItem(
                  context: context,
                  question: "¿La app funciona sin conexión a internet?",
                  answer:
                  "Puedes consultar tu plan guardado sin conexión, pero para sincronizar cambios necesitas conexión a internet.",
                ),
                _buildFaqItem(
                  context: context,
                  question: "¿Los planes son generados por IA o por un nutricionista?",
                  answer:
                  "El plan es creado por un nutricionista, pero la IA sugiere opciones personalizadas según tus datos clínicos.",
                ),
                _buildFaqItem(
                  context: context,
                  question: "¿Cómo elimino mi cuenta?",
                  answer:
                  "Ve a 'Configuración' → 'Privacidad y seguridad' → 'Eliminar cuenta'. Recuerda que esta acción es irreversible.",
                ),
                SizedBox(height: 20),
                Card(
                  color: Colors.grey.shade100,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '¿Si tienes alguna pregunta contáctanos?',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () async {
                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: 'mottinutsoporte@gmail.com',
                              query: encodeQueryParameters(<String, String>{
                                'subject': 'Consulta de soporte',
                                'body': ' '
                              }),
                            );
                            if (await canLaunchUrl(emailLaunchUri)) {
                              await launchUrl(emailLaunchUri);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No se pudo abrir el correo')),
                              );
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.mail,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'mottinutsoporte@gmail.com',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 38,)
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade50,
      elevation: 0.6,
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        leading: Icon(icon, color: AppColors.primary, size: 30),
        title: Text(
          title,
          style:  TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.4,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
