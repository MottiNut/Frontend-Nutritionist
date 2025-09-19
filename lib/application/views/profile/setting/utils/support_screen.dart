import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../configuration/themes/app_colors.dart';
import '../../../../requestSnacbar/snackBar_manager.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _isSending = false;

  Future<void> _openWhatsApp() async {
    final url = Uri.parse("https://wa.me/51902411155");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail() async {
    final url = Uri(
      scheme: 'mailto',
      path: 'mottinutsoporte@gmail.com',
      query: 'subject=Soporte Mottinut&body=Hola equipo, necesito ayuda con...',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _callPhone() async {
    final url = Uri.parse("tel:902411155");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _simulateSend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    await Future.delayed(const Duration(seconds: 2)); // simulación de envío

    setState(() {
      _isSending = false;
      _nameCtrl.clear();
      _emailCtrl.clear();
      _msgCtrl.clear();
    });

    if (mounted) {
      SnackBarManager.showSuccess(context, "Mensaje enviado correctamente");

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Soporte y ayuda',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          15,
          5,
          15,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        children: [
          const Text(
            "¿Necesitas ayuda?",
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            "Nuestro equipo está disponible para apoyarte en cualquier consulta relacionada con tu plan nutricional.",
            style: TextStyle(color: Colors.black54, fontSize: 15),
          ),
          const SizedBox(height: 24),

          _buildSupportOption(
            icon: LucideIcons.messageCircle,
            color: AppColors.primary,
            title: "Chatear por WhatsApp",
            subtitle: "Atención rápida y personalizada",
            onTap: _openWhatsApp,
          ),
          _buildSupportOption(
            icon: LucideIcons.mail,
            color: AppColors.primary,
            title: "Enviar correo",
            subtitle: "Respondemos en menos de 24 horas",
            onTap: _openEmail,
          ),
          _buildSupportOption(
            icon: LucideIcons.phone,
            color: AppColors.primary,
            title: "Llamar al soporte",
            subtitle: "Todos los días las 24h",
            onTap: _callPhone,
          ),
          const SizedBox(height: 20),

          Text(
            "Formulario de contacto",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),

          Card(
            elevation: 3,
            color: Colors.grey.shade200,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      style: TextStyle(fontSize: 14),
                      controller: _nameCtrl,
                      decoration: _inputDecoration("Escribe tu nombre"),
                      validator: (v) => v!.trim().isEmpty ? "Ingresa tu nombre" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      style: TextStyle(fontSize: 14),
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration("Tu correo electrónico"),
                      validator: (v) {
                        if (v!.trim().isEmpty) return "Ingresa tu correo";
                        final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        return emailReg.hasMatch(v) ? null : "Correo inválido";
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      style: TextStyle(fontSize: 14),
                      controller: _msgCtrl,
                      maxLines: 4,
                      decoration: _inputDecoration("Escribe tu mensaje..."),
                      validator: (v) => v!.trim().isEmpty ? "Ingresa un mensaje" : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _simulateSend,
                        icon: _isSending
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(LucideIcons.send),
                        label: Text(
                          _isSending ? "Enviando..." : "Enviar mensaje",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _buildSupportOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 27),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 25),
          ],
        ),
      ),
    );
  }
}
