import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../../domain/services/auth_provider.dart';

class PersonalInfoScreenn extends StatelessWidget {
  const PersonalInfoScreenn({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user ?? {};

    final String name = user['fullName'] ??
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final String email = user['email'] ?? 'No disponible';
    final String phone = user['phone'] ?? 'No disponible';
    final String cnp = user['cnpCode'] ?? 'No disponible';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Información Personal',
          style: TextStyle(color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          5,
          1,
          5,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Card(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow(Icons.person, 'Nombre', name),
                const Divider(height: 30, thickness: 0.3),
                _buildInfoRow(Icons.email, 'Email', _maskEmail(email)),
                const Divider(height: 30, thickness: 0.3),
                _buildInfoRow(Icons.phone, 'Teléfono', _maskPhone(phone)),
                const Divider(height: 30, thickness: 0.3),
                _buildInfoRow(Icons.badge, 'CNP / Carnet', _displayCNP(cnp)),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 2) return '${name[0]}*****@$domain';

    return '${name[0]}*****${name[name.length - 1]}@$domain';
  }

  String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'No disponible';

    final last3 = digits.length >= 3 ? digits.substring(digits.length - 3) : digits;
    return '+51 ******$last3';
  }

  String _displayCNP(String cnp) {
    if (cnp.isEmpty) return 'No disponible';
    return cnp;
  }
}
