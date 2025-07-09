import 'package:flutter/material.dart';

import '../../../configuration/themes/app_colors.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();

  List<Map<String, dynamic>> _ingredients = [];
  List<String> _instructions = [];
  List<Map<String, dynamic>> _savedRecipes = [];
  String _selectedCategory = 'Desayuno';
  final List<String> _categories = ['Desayuno', 'Almuerzo', 'Cena', 'Merienda', 'Postre'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recipeNameController.dispose();
    _ingredientController.dispose();
    _instructionController.dispose();
    _messageController.dispose();
    _servingsController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    if (_ingredientController.text.isNotEmpty) {
      setState(() {
        _ingredients.add({
          'name': _ingredientController.text,
          'amount': '1',
          'unit': 'unidad'
        });
        _ingredientController.clear();
      });
    }
  }

  void _addInstruction() {
    if (_instructionController.text.isNotEmpty) {
      setState(() {
        _instructions.add(_instructionController.text);
        _instructionController.clear();
      });
    }
  }

  void _saveRecipe() {
    if (_recipeNameController.text.isNotEmpty && _ingredients.isNotEmpty && _instructions.isNotEmpty) {
      setState(() {
        _savedRecipes.add({
          'name': _recipeNameController.text,
          'category': _selectedCategory,
          'ingredients': List.from(_ingredients),
          'instructions': List.from(_instructions),
          'servings': _servingsController.text.isEmpty ? '1' : _servingsController.text,
          'prepTime': _prepTimeController.text.isEmpty ? '30 min' : '${_prepTimeController.text} min',
          'createdAt': DateTime.now(),
        });

        // Limpiar formulario
        _recipeNameController.clear();
        _servingsController.clear();
        _prepTimeController.clear();
        _ingredients.clear();
        _instructions.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receta guardada exitosamente'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      // Aquí iría la lógica para enviar el mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mensaje enviado a pacientes'),
          backgroundColor: AppColors.primary,
        ),
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLigth,
      appBar: AppBar(
        title: const Text(
          'Gestión de Recetas',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textLight,
          labelColor: AppColors.textLight,
          unselectedLabelColor: AppColors.textLight.withOpacity(0.7),
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Crear Receta'),
            Tab(text: 'Mis Recetas'),
            Tab(text: 'Mensajes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateRecipeTab(),
          _buildMyRecipesTab(),
          _buildMessagesTab(),
        ],
      ),
    );
  }

  Widget _buildCreateRecipeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Información Básica'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _recipeNameController,
            label: 'Nombre de la receta',
            hint: 'Ej: Ensalada mediterránea',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _servingsController,
                  label: 'Porciones',
                  hint: '1',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _prepTimeController,
                  label: 'Tiempo (min)',
                  hint: '30',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCategoryDropdown(),

          const SizedBox(height: 24),
          _buildSectionHeader('Ingredientes'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _ingredientController,
                  label: 'Ingrediente',
                  hint: 'Ej: Tomate cherry',
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                onPressed: _addIngredient,
                icon: Icons.add,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildIngredientsList(),

          const SizedBox(height: 24),
          _buildSectionHeader('Preparación'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _instructionController,
                  label: 'Paso de preparación',
                  hint: 'Describe el paso a seguir',
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                onPressed: _addInstruction,
                icon: Icons.add,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionsList(),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saveRecipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Guardar Receta',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRecipesTab() {
    return _savedRecipes.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: AppColors.iconPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes recetas guardadas',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera receta en la pestaña anterior',
            style: TextStyle(
              color: AppColors.textCuatary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _savedRecipes[index];
        return _buildRecipeCard(recipe, index);
      },
    );
  }

  Widget _buildMessagesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Enviar mensaje a pacientes'),
          const SizedBox(height: 12),
          Text(
            'Comparte consejos nutricionales o recordatorios con tus pacientes',
            style: TextStyle(
              color: AppColors.textCuatary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _messageController,
            label: 'Mensaje',
            hint: 'Escribe un mensaje motivacional o consejo nutricional...',
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Enviar Mensaje',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: _buildQuickMessages(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: maxLines == 1 ? 48 : null,
          decoration: BoxDecoration(
            color: AppColors.backgroundLigth,
            border: Border.all(color: AppColors.iconPrimary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.textCuatary,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundLigth,
            border: Border.all(color: AppColors.iconPrimary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: AppColors.textLight,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildIngredientsList() {
    if (_ingredients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.iconPrimary.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            'No hay ingredientes agregados',
            style: TextStyle(
              color: AppColors.textCuatary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.iconPrimary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _ingredients.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: AppColors.iconPrimary.withOpacity(0.2),
        ),
        itemBuilder: (context, index) {
          final ingredient = _ingredients[index];
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Text(
              ingredient['name'],
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            trailing: IconButton(
              onPressed: () {
                setState(() {
                  _ingredients.removeAt(index);
                });
              },
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.errorIcon,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructionsList() {
    if (_instructions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.iconPrimary.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            'No hay pasos de preparación agregados',
            style: TextStyle(
              color: AppColors.textCuatary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.iconPrimary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _instructions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: AppColors.iconPrimary.withOpacity(0.2),
        ),
        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            title: Text(
              _instructions[index],
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            trailing: IconButton(
              onPressed: () {
                setState(() {
                  _instructions.removeAt(index);
                });
              },
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.errorIcon,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.iconPrimary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recipe['name'],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    recipe['category'],
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.group,
                  size: 16,
                  color: AppColors.textCuatary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${recipe['servings']} porciones',
                  style: TextStyle(
                    color: AppColors.textCuatary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textCuatary,
                ),
                const SizedBox(width: 4),
                Text(
                  recipe['prepTime'],
                  style: TextStyle(
                    color: AppColors.textCuatary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Ver detalles de la receta
                  },
                  icon: const Icon(
                    Icons.visibility,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Ver',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _savedRecipes.removeAt(index);
                    });
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppColors.errorIcon,
                  ),
                  label: const Text(
                    'Eliminar',
                    style: TextStyle(
                      color: AppColors.errorIcon,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMessages() {
    final quickMessages = [
      'Recuerda tomar 8 vasos de agua al día 💧',
      'Las frutas son excelentes para el desayuno 🍎',
      'Incluye proteínas en cada comida principal 🥗',
      'Los vegetales deben ocupar la mitad de tu plato 🥬',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Mensajes rápidos'),
        const SizedBox(height: 12),
        ...quickMessages.map((message) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          child: TextButton(
            onPressed: () {
              _messageController.text = message;
            },
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(12),
              backgroundColor: AppColors.surfaceVariant.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppColors.iconPrimary.withOpacity(0.2)),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }
}
