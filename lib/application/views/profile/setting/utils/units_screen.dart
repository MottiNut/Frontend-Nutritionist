import 'package:flutter/material.dart';
import '../../../../../configuration/themes/app_colors.dart';

class UnitsScreen extends StatelessWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final units = {
      "Antropometría": [
        {
          "icon": Icons.monitor_weight,
          "title": "Peso",
          "unit": "kg / lb",
          "tip": "1 kg = 2.2046 lb"
        },
        {
          "icon": Icons.height,
          "title": "Talla",
          "unit": "cm / m",
          "tip": "1 m = 100 cm"
        },
        {
          "icon": Icons.accessibility_new,
          "title": "IMC",
          "unit": "kg/m²",
          "tip": "IMC = Peso (kg) / Talla² (m²)"
        },
      ],
      "Nutrientes": [
        {
          "icon": Icons.local_fire_department,
          "title": "Energía",
          "unit": "kcal / kJ",
          "tip": "1 kcal = 4.184 kJ"
        },
        {
          "icon": Icons.fastfood,
          "title": "Macronutrientes",
          "unit": "g (proteínas, grasas, carbohidratos)",
          "tip": "1 g proteína/carb = 4 kcal, 1 g grasa = 9 kcal"
        },
        {
          "icon": Icons.cookie,
          "title": "Micronutrientes",
          "unit": "mg / µg",
          "tip": "Ej: Vitamina C se mide en mg, Vitamina D en µg"
        },
        {
          "icon": Icons.local_drink,
          "title": "Volumen Líquidos",
          "unit": "ml / L",
          "tip": "1 L = 1000 ml"
        },
      ],
      "Clínicos": [
        {
          "icon": Icons.bloodtype,
          "title": "Glucosa",
          "unit": "mg/dl ↔ mmol/L",
          "tip": "1 mmol/L = 18 mg/dl"
        },
        {
          "icon": Icons.favorite,
          "title": "Presión arterial",
          "unit": "mmHg",
          "tip": "Ej: 120/80 mmHg considerado normal"
        },
        {
          "icon": Icons.health_and_safety,
          "title": "Colesterol",
          "unit": "mg/dl ↔ mmol/L",
          "tip": "1 mmol/L = 38.67 mg/dl"
        },
      ]
    };

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Unidades de Medida',
          style: TextStyle(color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          10,
          1,
          10,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: units.entries.map((category) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                category.key,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...category.value.map((item) {
                return Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          radius: 26,
                          child: Icon(
                            item["icon"] as IconData,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["title"] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Unidad: ${item["unit"]}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lightbulb_outline,
                                        color: AppColors.secondary, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item["tip"] as String,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }
}
