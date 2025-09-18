import 'package:flutter/material.dart';
import '../../../../requestSnacbar/snackBar_manager.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  void _createBackup(BuildContext context) {
    // Aquí iría la lógica real para crear la copia
    SnackBarManager.showSuccess(context, 'Copia de seguridad creada exitosamente');
  }

  void _restoreBackup(BuildContext context) {
    // Aquí iría la lógica real para restaurar la copia
    SnackBarManager.showWarning(context, 'Función de restauración aún no disponible');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text(
          'Copia de Seguridad',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.cloud_upload_outlined,
                size: 100, color: Colors.blueGrey),
            const SizedBox(height: 16),
            const Text(
              'Gestiona tus copias de seguridad',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),

            // Crear copia
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => _createBackup(context),
              icon: const Icon(Icons.save_alt),
              label: const Text('Crear copia de seguridad', style: TextStyle(fontSize: 15)),
            ),
            const SizedBox(height: 16),

            // Restaurar copia
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => _restoreBackup(context),
              icon: const Icon(Icons.restore, color: Colors.black,),
              label: const Text('Restaurar copia', style: TextStyle(fontSize: 15, color: Colors.black),),
            ),
            const SizedBox(height: 40),

            // Info última copia
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blueGrey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Última copia: No disponible',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
