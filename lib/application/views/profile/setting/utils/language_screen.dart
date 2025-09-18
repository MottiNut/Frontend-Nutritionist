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
        'enabled': true, // único habilitado
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
      {
        'name': 'Quechua',
        'enabled': false,
        'locale': const Locale('qu', 'PE'),
        'countryCode': 'pe'
      },
    ];

    final filteredLanguages = languages
        .where((lang) => lang['name']
        .toString()
        .toLowerCase()
        .contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
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
                  crossAxisCount: 3, // tres por fila
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8, // bandera arriba, texto abajo
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

                  final isEnabled = lang['enabled'] == true;

                  return GestureDetector(
                    onTap: isEnabled
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
                        color: isEnabled && isSelected
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEnabled && isSelected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ColorFiltered(
                            colorFilter: isEnabled
                                ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            )
                                : const ColorFilter.matrix(<double>[
                              0.5, 0.5, 0.5, 0, 0,
                              0.5, 0.5, 0.5, 0, 0,
                              0.5, 0.5, 0.5, 0, 0,
                              0,   0,   0,   1, 0,
                            ]),
                            child: Image.asset(
                              'icons/flags/png/$countryCode.png',
                              package: 'country_icons',
                              width: 45,
                              height: 35,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lang['name'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isEnabled
                                  ? (isSelected
                                  ? Colors.white
                                  : Colors.black87)
                                  : Colors.grey, // texto gris si está deshabilitado
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
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
