
import 'package:flutter/material.dart';

import '../../patient_screen.dart';

class ObesidadScreen extends StatelessWidget {
  final CategoryItem category;

  const ObesidadScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.title.replaceAll('\n', ' ')),
        backgroundColor: category.color,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (category.icon != null) category.icon!,
              const SizedBox(height: 20),
              Text(
                'Información sobre ${category.title.replaceAll('\n', ' ')}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Guías sobre obesidad y sobrepeso, incluyendo planes alimentarios, ejercicios y recomendaciones médicas.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}