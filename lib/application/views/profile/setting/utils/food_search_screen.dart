import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';

import '../../../../../configuration/themes/app_colors.dart';

class Food {
  final String id;
  final String title;
  final String image;
  final double calories;
  final Map<String, double> nutrients;
  final String category;

  Food({
    required this.id,
    required this.title,
    required this.image,
    required this.calories,
    required this.nutrients,
    required this.category,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    final nutriments = json['nutriments'] ?? {};

    return Food(
      id: json['id']?.toString() ?? '',
      title: json['product_name'] ?? 'Sin título',
      image: json['image_front_url'] ?? '',
      calories: (nutriments['energy-kcal_100g'] ?? 0).toDouble(),
      nutrients: {
        'Proteína': (nutriments['proteins_100g'] ?? 0).toDouble(),
        'Grasa': (nutriments['fat_100g'] ?? 0).toDouble(),
        'Carbohidratos': (nutriments['carbohydrates_100g'] ?? 0).toDouble(),
        'Azúcares': (nutriments['sugars_100g'] ?? 0).toDouble(),
      },
      category: json['categories'] ?? 'General',
    );
  }
}

class FoodDatabaseScreen extends StatefulWidget {
  const FoodDatabaseScreen({super.key});

  @override
  State<FoodDatabaseScreen> createState() => _FoodDatabaseScreenState();
}

class _FoodDatabaseScreenState extends State<FoodDatabaseScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Food> _allFoods = []; // Todos los alimentos cargados
  List<Food> _filteredFoods = []; // Alimentos filtrados por búsqueda
  bool _isLoading = false;
  String _errorMessage = '';
  String _lastQuery = '';

  final List<String> _defaultFoods = ["manzana", "banana", "arroz", "pollo"];

  late Debouncer<String> _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _loadDefaultFoods();

    _searchDebouncer = Debouncer<String>(const Duration(milliseconds: 500), initialValue: "");
    _searchDebouncer.values.listen((query) {
      if (query.isNotEmpty) {
        _searchFoods(query);
      } else {
        // Si la consulta está vacía, mostrar todos los alimentos
        setState(() {
          _filteredFoods = _allFoods;
        });
      }
    });
  }

  Future<void> _loadDefaultFoods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (final item in _defaultFoods) {
        await _searchFoods(item, append: true);
      }
    } finally {
      setState(() {
        _isLoading = false;
        _filteredFoods = _allFoods;
      });
    }
  }

  // Función para calcular la distancia de Levenshtein (similitud entre palabras)
  int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    // Convertir a minúsculas para hacer la comparación sin distinción de mayúsculas/minúsculas
    a = a.toLowerCase();
    b = b.toLowerCase();

    final matrix = List.generate(
      a.length + 1,
          (i) => List.generate(b.length + 1, (j) => 0),
    );

    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }

    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // Eliminación
          matrix[i][j - 1] + 1, // Inserción
          matrix[i - 1][j - 1] + cost // Sustitución
        ].reduce((value, element) => value < element ? value : element);
      }
    }

    return matrix[a.length][b.length];
  }

  // Función para buscar alimentos con corrección de errores
  void _filterFoods(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredFoods = _allFoods;
      });
      return;
    }

    final queryLower = query.toLowerCase();
    final List<Food> results = [];

    // Primero buscar coincidencias exactas o que comiencen con la consulta
    for (final food in _allFoods) {
      final titleLower = food.title.toLowerCase();

      if (titleLower.contains(queryLower)) {
        results.add(food);
      }
    }

    // Si no hay suficientes resultados, buscar coincidencias aproximadas
    if (results.length < 5) {
      final List<Map<String, dynamic>> scoredFoods = [];

      for (final food in _allFoods) {
        if (!results.contains(food)) {
          final titleLower = food.title.toLowerCase();
          final distance = _levenshteinDistance(queryLower, titleLower);

          // Considerar como coincidencia si la distancia es pequeña (máximo 3 cambios)
          if (distance <= 3) {
            scoredFoods.add({
              'food': food,
              'score': distance,
            });
          }
        }
      }

      // Ordenar por similitud (menor distancia primero)
      scoredFoods.sort((a, b) => a['score'].compareTo(b['score']));

      // Añadir los resultados más similares
      for (var i = 0; i < scoredFoods.length && results.length < 10; i++) {
        results.add(scoredFoods[i]['food']);
      }
    }

    setState(() {
      _filteredFoods = results;
    });
  }

  Future<void> _searchFoods(String query, {bool append = false}) async {
    if (query.isEmpty) return;
    if (_lastQuery == query) return; // Evitar búsquedas duplicadas

    _lastQuery = query;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
          "https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1&page_size=20",
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> products = data['products'] ?? [];

        setState(() {
          if (append) {
            // Añadir nuevos alimentos sin eliminar los existentes
            final newFoods = products.map((p) => Food.fromJson(p)).toList();
            _allFoods.addAll(newFoods);
          } else {
            // Para búsquedas manuales, reemplazar los resultados pero mantener los alimentos iniciales
            final newFoods = products.map((p) => Food.fromJson(p)).toList();

            // Si ya tenemos alimentos cargados por defecto, mantenerlos
            if (_allFoods.isNotEmpty) {
              // Filtrar para no duplicar alimentos
              for (var newFood in newFoods) {
                if (!_allFoods.any((food) => food.id == newFood.id)) {
                  _allFoods.add(newFood);
                }
              }
            } else {
              _allFoods = newFoods;
            }
          }

          // Aplicar filtro con la consulta actual
          _filterFoods(_searchController.text);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error en la búsqueda: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            "assets/loading/palta_saltarina.json",
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 16),
          const Text(
            "Cargando alimentos...",
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showFoodDetails(Food food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      height: 5,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Imagen pequeña y centrada
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 160,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: food.image.isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: food.image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) =>
                        const Icon(Icons.fastfood,
                            size: 60, color: Colors.grey),
                      )
                          : const Icon(Icons.fastfood,
                          size: 60, color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Contenido con scroll
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${food.calories.toStringAsFixed(1)} kcal / 100g",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Información Nutricional",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...food.nutrients.entries.map((nutrient) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    nutrient.key,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    "${nutrient.value.toStringAsFixed(1)} g",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildFoodCard(Food food) {
    return GestureDetector(
      onTap: () => _showFoodDetails(food),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen (parte principal como TikTok)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 150,
                color: Colors.grey.shade100,
                child: food.image.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: food.image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Lottie.asset(
                        "assets/loading/palta_saltarina.json",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),

                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
                    ),
                  ),
                )
                    : const Center(
                  child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
                ),
              ),
            ),

            // Información básica debajo de la imagen
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${food.calories.toStringAsFixed(1)} kcal",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Base de Alimentos',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 1, 16, 6),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontSize: 14
              ),
              decoration: InputDecoration(
                hintText: 'Buscar alimentos, frutas, bebidas...',
                hintStyle: TextStyle(
                  fontSize: 14
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      if (_searchController.text.isEmpty)
                        const Icon(Icons.search, color: Colors.black54),

                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _filterFoods('');
                            setState(() {});
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            margin: EdgeInsets.only(left: 6, right: 4),
                            decoration:  BoxDecoration(
                              color: Colors.grey.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.clear,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _filterFoods(value);
                _searchDebouncer.value = value;
                setState(() {});
              },
            ),
          ),

          //if (_isLoading) LinearProgressIndicator(color: AppColors.backgroundHipertencion, backgroundColor: Colors.grey.shade200,),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _isLoading && _filteredFoods.isEmpty
                ? _buildLoading()
                : _filteredFoods.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
              ),
              padding: const EdgeInsets.all(3),
              itemCount: _filteredFoods.length,
              itemBuilder: (context, index) {
                return _buildFoodCard(_filteredFoods[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            "assets/icons/recetas_icon_grey.svg",
            width: 70,
            height: 70,
            color: Colors.grey,
          ),

          const SizedBox(height: 16),
          const Text(
            "No encontramos este alimento 🍽️",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Prueba con otra palabra o revisa la ortografía.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _searchDebouncer.cancel();
    _searchController.dispose();
    super.dispose();
  }
}