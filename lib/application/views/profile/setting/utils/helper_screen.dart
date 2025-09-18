import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String searchQuery = '';

  // Preguntas frecuentes (ejemplo)
  final List<Map<String, String>> faqs = [
    {
      'question': '¿Cómo funciona Mottinut?',
      'answer': 'Mottinut te ayuda a llevar un control nutricional con planes personalizados y consejos de expertos.'
    },
    {
      'question': '¿Puedo cambiar mi plan nutricional?',
      'answer': 'Sí, en la sección de configuración puedes actualizar tus objetivos y preferencias.'
    },
    {
      'question': '¿Cómo contacto a un nutricionista?',
      'answer': 'Puedes chatear directamente con un nutricionista desde el menú principal de la app.'
    },
    {
      'question': '¿Qué pasa si olvido registrar mis comidas?',
      'answer': 'No te preocupes, puedes añadirlas después y el sistema recalculará tus métricas.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = faqs
        .where((faq) =>
        faq['question']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ayuda',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra de búsqueda
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar preguntas...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Lista de FAQs
            Expanded(
              child: filteredFaqs.isEmpty
                  ? const Center(
                child: Text(
                  'No se encontraron resultados',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.separated(
                itemCount: filteredFaqs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final faq = filteredFaqs[index];
                  return Card(
                    elevation: 0,
                    color: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        faq['question']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            faq['answer']!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
