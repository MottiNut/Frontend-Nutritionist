import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Asesoría Nutricional',
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
      body: Column(
        children: [
          // 🔎 Barra de búsqueda estilo TikTok
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar consejos, recetas o preguntas...',
                prefixIcon: const Icon(LucideIcons.search, color: Colors.black54),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 📋 Contenido scrollable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 20),
                Text(
                  "Preguntas frecuentes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                _buildFaqItem(
                  question: "¿Es malo comer carbohidratos en la noche?",
                  answer:
                  "No necesariamente. Lo importante es la cantidad total diaria y la calidad del carbohidrato.",
                ),
                _buildFaqItem(
                  question: "¿Qué suplementos necesito para ganar músculo?",
                  answer:
                  "La mayoría de nutrientes los obtienes de la comida. La proteína en polvo puede ayudar si no llegas con alimentos.",
                ),
                _buildFaqItem(
                  question: "¿El ayuno intermitente funciona para bajar de peso?",
                  answer:
                  "Es una estrategia válida, pero no es la única. Lo clave es mantener un déficit calórico sostenible.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Tarjeta de consejos
  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade50,
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 30),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ),
    );
  }

  // ✅ Item de FAQ expandible
  Widget _buildFaqItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            answer,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }
}
