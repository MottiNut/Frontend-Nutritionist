import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../configuration/themes/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // 📞 WhatsApp
  Future<void> _openWhatsApp() async {
    final url = Uri.parse("https://wa.me/51902411155"); // Perú (+51)
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // 📧 Email
  Future<void> _openEmail() async {
    final url = Uri(
      scheme: 'mailto',
      path: 'mottinut@gmail.com',
      query: 'subject=Soporte Mottinut&body=Hola equipo, necesito ayuda con...',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // 📱 Teléfono
  Future<void> _callPhone() async {
    final url = Uri.parse("tel:902411155");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Soporte y ayuda',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "¿Necesitas ayuda?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Nuestro equipo está disponible para apoyarte en cualquier consulta relacionada con tu plan nutricional.",
            style: TextStyle(color: Colors.black54, fontSize: 15),
          ),
          const SizedBox(height: 24),

          // WhatsApp
          _buildSupportOption(
            icon: LucideIcons.messageCircle,
            color: AppColors.primary,
            title: "Chatear por WhatsApp",
            subtitle: "Atención rápida y personalizada",
            onTap: _openWhatsApp,
          ),

          // Email
          _buildSupportOption(
            icon: LucideIcons.mail,
            color: AppColors.primary,
            title: "Enviar correo",
            subtitle: "Respondemos en menos de 24 horas",
            onTap: _openEmail,
          ),

          // Teléfono
          _buildSupportOption(
            icon: LucideIcons.phone,
            color: AppColors.primary,
            title: "Llamar al soporte",
            subtitle: "Horario: Lunes a Viernes, 9:00 - 18:00",
            onTap: _callPhone,
          ),

          const SizedBox(height: 30),
          const Text(
            "Formulario de contacto",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            decoration: InputDecoration(
              hintText: "Escribe tu nombre",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: "Tu correo electrónico",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Escribe tu mensaje...",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Mensaje enviado ✅")),
              );
            },
            icon: const Icon(LucideIcons.send),
            label: Text("Enviar mensaje", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
