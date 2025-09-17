import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/services/auth_provider.dart';

class PersonalInfoScreenn extends StatelessWidget {
  const PersonalInfoScreenn({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user ?? {}; // Datos en Map<String, dynamic>

    // Datos básicos del usuario
    final String name = user['fullName'] ??
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final String email = user['email'] ?? 'No disponible';
    final String phone = user['phone'] ?? 'No disponible';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Información Personal', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Card(
          color: Colors.grey.shade100,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.person, 'Nombre', name),
                const Divider(height: 30, thickness: 0.3 ),
                _buildInfoRow(Icons.email, 'Email', email),
                const Divider(height: 30, thickness: 0.3,),
                _buildInfoRow(Icons.phone, 'Teléfono', phone),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget reutilizable para cada fila de información
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 26),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'No disponible',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}