import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_icons/country_icons.dart';
import '../../../../../configuration/providers/app_languaje_provider.dart';
import '../../../../../configuration/themes/app_colors.dart';
import '../../../../requestSnacbar/snackBar_manager.dart';


class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Seleccionar por defecto Perú
    final languageProvider = context.read<LanguageProvider>();
    if (languageProvider.currentLocale.languageCode != 'es' ||
        languageProvider.currentLocale.countryCode != 'PE') {
      languageProvider.setLocale(const Locale('es', 'PE'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    // Lista de idiomas
    final languages = [
      {
        'name': 'Español',
        'enabled': true,
        'locale': const Locale('es', 'PE'),
        'countryCode': 'pe'
      },
      {
        'name': 'Inglés',
        'enabled': false,
        'locale': const Locale('en', 'US'),
        'countryCode': 'us'
      },
      {
        'name': 'Francés',
        'enabled': false,
        'locale': const Locale('fr', 'FR'),
        'countryCode': 'fr'
      },
      {
        'name': 'Alemán',
        'enabled': false,
        'locale': const Locale('de', 'DE'),
        'countryCode': 'de'
      },
      {
        'name': 'Italiano',
        'enabled': false,
        'locale': const Locale('it', 'IT'),
        'countryCode': 'it'
      },
      {
        'name': 'Portugués',
        'enabled': false,
        'locale': const Locale('pt', 'PT'),
        'countryCode': 'pt'
      },
    ];

    // Filtrar idiomas según búsqueda en tiempo real
    final filteredLanguages = languages
        .where((lang) => lang['name']
        .toString()
        .toLowerCase()
        .contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Idioma',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              onChanged: (value) => setState(() {
                searchQuery = value;
              }),
              decoration: InputDecoration(
                hintText: 'Buscar idioma',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Grid de idiomas
            Expanded(
              child: filteredLanguages.isEmpty
                  ? const Center(
                child: Text(
                  'No se encontró ningún idioma',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : GridView.builder(
                itemCount: filteredLanguages.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, index) {
                  final lang = filteredLanguages[index];
                  final langLocale = lang['locale'] as Locale;
                  final countryCode = lang['countryCode'] as String;
                  final isSelected =
                      languageProvider.currentLocale.languageCode ==
                          langLocale.languageCode &&
                          languageProvider.currentLocale.countryCode ==
                              langLocale.countryCode;

                  return GestureDetector(
                    onTap: lang['enabled'] == true
                        ? () {
                      languageProvider.setLocale(langLocale);
                      SnackBarManager.showSuccess(
                          context, '${lang['name']} seleccionado');
                    }
                        : () {
                      SnackBarManager.showWarning(context,
                          'Este idioma está deshabilitado por ahora');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: lang['enabled'] == true && isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                        border: lang['enabled'] == true && isSelected
                            ? Border.all(
                          color: Colors.white,
                          width: 2,
                        )
                            : null,
                        boxShadow: lang['enabled'] == true && isSelected
                            ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'icons/flags/png/$countryCode.png',
                            package: 'country_icons',
                            width: 32,
                            height: 24,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lang['name'] as String,
                            style: TextStyle(
                              color: lang['enabled'] == true && isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
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
