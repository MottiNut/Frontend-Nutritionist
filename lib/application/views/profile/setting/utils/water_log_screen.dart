import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/services/auth_provider.dart';

class WaterLogScreen extends StatelessWidget {
  const WaterLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user ?? {};

    final String name = user['fullName'] ??
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();

    // --- Simulación de cálculo de agua recomendada ---
    // Ejemplo: 35 ml por kg de peso (simulado con 70 kg)
    final double weight = 70;
    final double recommendedLiters = (weight * 35) / 1000; // litros recomendados

    // --- Simulación de consumo actual ---
    final int glassesTaken = 5; // cantidad ya tomada
    final int dailyGoal = (recommendedLiters * 4).round(); // 1 vaso ~250ml
    final double progress = glassesTaken / dailyGoal;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Hidratación Diaria',
          style: TextStyle(color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          5,
          1,
          5,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            // Mensaje motivador del nutricionista
            Card(
              color: AppColors.primary.withOpacity(0.08),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "💧 Hola $name, recuerda que tu meta de agua hoy es de "
                      "${recommendedLiters.toStringAsFixed(1)} litros "
                      "(${dailyGoal} vasos aprox). ¡Mantente hidratado!",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Progreso circular en Card
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      "Progreso Diario",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 160,
                            width: 160,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 12,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "$glassesTaken / $dailyGoal",
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Text(
                                "vasos",
                                style: TextStyle(
                                    fontSize: 15, color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Botón para agregar agua
            ElevatedButton.icon(
              onPressed: () {
                // Aquí iría la lógica para registrar un vaso tomado
              },
              icon: const Icon(Icons.local_drink, color: Colors.white),
              label: const Text("Registrar un vaso"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
