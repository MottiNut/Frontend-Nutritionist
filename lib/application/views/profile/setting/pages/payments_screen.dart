import 'package:flutter/material.dart';
import 'package:mottinutnutriotinist/configuration/themes/app_colors.dart';

// Pantalla de Pagos
class PaymentPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String interval; // Ej: "mensual", "anual"
  final List<String> features;
  final bool isActive;

  PaymentPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.interval,
    required this.features,
    required this.isActive,
  });
}
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}
class _PaymentsScreenState extends State<PaymentsScreen> {
  final List<PaymentPlan> _paymentPlans = [
    PaymentPlan(
      id: 'basico',
      name: 'Plan Básico',
      price: 29.99,
      currency: 'USD',
      interval: 'mensual',
      features: [
        'Hasta 20 pacientes',
        'Planes nutricionales básicos',
        'Seguimiento semanal',
        'Soporte por email'
      ],
      isActive: true,
    ),
    PaymentPlan(
      id: 'profesional',
      name: 'Plan Profesional',
      price: 59.99,
      currency: 'USD',
      interval: 'mensual',
      features: [
        'Hasta 100 pacientes',
        'Planes nutricionales avanzados',
        'Seguimiento diario',
        'Análisis nutricional completo',
        'Videollamadas integradas',
        'Soporte prioritario'
      ],
      isActive: false,
    ),
    PaymentPlan(
      id: 'premium',
      name: 'Plan Premium',
      price: 99.99,
      currency: 'USD',
      interval: 'mensual',
      features: [
        'Pacientes ilimitados',
        'IA para recomendaciones',
        'Reportes avanzados',
        'Integración con laboratorios',
        'Marca personalizada',
        'Soporte 24/7'
      ],
      isActive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarifas y Pagos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentPlanCard(),
            const SizedBox(height: 24),
            Text(
              'Planes Disponibles',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ..._paymentPlans.map((plan) => _buildPlanCard(plan)),
            const SizedBox(height: 24),
            _buildPaymentMethodsSection(),
            const SizedBox(height: 24),
            _buildBillingHistorySection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    final currentPlan = _paymentPlans.firstWhere((plan) => plan.isActive);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Plan Actual',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currentPlan.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${currentPlan.price}/${currentPlan.interval}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Próximo pago: 15 Ago 2024',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                TextButton(
                  onPressed: () => _showCancelSubscriptionDialog(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(PaymentPlan plan) {
    final isCurrentPlan = plan.isActive;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCurrentPlan ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isCurrentPlan
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCurrentPlan ? AppColors.primary : null,
                    ),
                  ),
                  if (isCurrentPlan)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Actual',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '\$${plan.price}/${plan.interval}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...plan.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCurrentPlan ? null : () => _selectPlan(plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentPlan ? Colors.grey : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isCurrentPlan ? 'Plan Actual' : 'Seleccionar Plan',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métodos de Pago',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('**** **** **** 1234'),
            subtitle: const Text('Visa - Expira 12/25'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showPaymentMethodDialog(),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _showAddPaymentMethodDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Agregar método de pago'),
        ),
      ],
    );
  }

  Widget _buildBillingHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial de Facturación',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _buildBillingHistoryItem('15 Jul 2024', '\$29.99', 'Pagado'),
              _buildBillingHistoryItem('15 Jun 2024', '\$29.99', 'Pagado'),
              _buildBillingHistoryItem('15 May 2024', '\$29.99', 'Pagado'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _showFullBillingHistory(),
          icon: const Icon(Icons.history),
          label: const Text('Ver historial completo'),
        ),
      ],
    );
  }

  Widget _buildBillingHistoryItem(String date, String amount, String status) {
    return ListTile(
      leading: const Icon(Icons.receipt),
      title: Text(date),
      subtitle: Text(status),
      trailing: Text(
        amount,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _selectPlan(PaymentPlan plan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Cambio de Plan'),
          content: Text('¿Estás seguro de que deseas cambiar al ${plan.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processPlanChange(plan);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _processPlanChange(PaymentPlan plan) {
    // Implementar lógica de cambio de plan
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cambiando al ${plan.name}...')),
    );
  }

  void _showCancelSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Suscripción'),
          content: const Text(
            '¿Estás seguro de que deseas cancelar tu suscripción? '
                'Perderás acceso a todas las funciones premium.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mantener Plan'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implementar lógica de cancelación
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancelar Suscripción'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentMethodDialog() {
    // Implementar diálogo para editar método de pago
  }

  void _showAddPaymentMethodDialog() {
    // Implementar diálogo para agregar método de pago
  }

  void _showFullBillingHistory() {
    // Implementar navegación a historial completo
  }
}

// Pantalla de Objetivos - Versión Profesional
enum GoalCategory {
  education,
  business,
  research,
  personal,
}
enum GoalStatus {
  completed,
  inProgress,
  pending,
  overdue,
}
class ProfessionalGoal {
  final String id;
  final String title;
  final String description;
  final GoalCategory category;
  final double progress; // de 0.0 a 1.0
  final DateTime dueDate;
  final GoalStatus status;
  final List<String> milestones;

  ProfessionalGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.progress,
    required this.dueDate,
    required this.status,
    required this.milestones,
  });
}
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}
class _GoalsScreenState extends State<GoalsScreen> {
  final List<ProfessionalGoal> _goals = [
    ProfessionalGoal(
      id: '1',
      title: 'Certificación en Nutrición Deportiva',
      description: 'Obtener certificación especializada en nutrición deportiva',
      category: GoalCategory.education,
      progress: 0.65,
      dueDate: DateTime(2024, 12, 15),
      status: GoalStatus.inProgress,
      milestones: [
        'Inscribirse al curso',
        'Completar módulo 1',
        'Completar módulo 2',
        'Realizar examen final',
      ],
    ),
    ProfessionalGoal(
      id: '2',
      title: 'Alcanzar 100 Pacientes Activos',
      description: 'Expandir la base de pacientes activos',
      category: GoalCategory.business,
      progress: 0.8,
      dueDate: DateTime(2024, 10, 30),
      status: GoalStatus.inProgress,
      milestones: [
        'Definir estrategia de marketing',
        'Crear contenido en redes sociales',
        'Implementar sistema de referencias',
        'Alcanzar meta de pacientes',
      ],
    ),
    ProfessionalGoal(
      id: '3',
      title: 'Publicar Artículo Científico',
      description: 'Publicar investigación sobre nutrición personalizada',
      category: GoalCategory.research,
      progress: 0.3,
      dueDate: DateTime(2025, 3, 30),
      status: GoalStatus.inProgress,
      milestones: [
        'Definir tema de investigación',
        'Revisar literatura científica',
        'Recopilar datos',
        'Escribir artículo',
        'Enviar a revista',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Mis Objetivos Profesionales'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressSummary(),
            const SizedBox(height: 24),
            _buildGoalFilters(),
            const SizedBox(height: 16),
            ..._goals.map((goal) => _buildGoalCard(goal)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    final totalGoals = _goals.length;
    final completedGoals = _goals.where((g) => g.status == GoalStatus.completed).length;
    final averageProgress = _goals.fold(0.0, (sum, goal) => sum + goal.progress) / totalGoals;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Progreso',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProgressStat('Objetivos Totales', totalGoals.toString(), Icons.flag),
                _buildProgressStat('Completados', completedGoals.toString(), Icons.check_circle),
                _buildProgressStat('Progreso Promedio', '${(averageProgress * 100).toInt()}%', Icons.trending_up),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGoalFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Todos', true),
          _buildFilterChip('En progreso', false),
          _buildFilterChip('Completados', false),
          _buildFilterChip('Pendientes', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          // Implementar filtrado
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _buildGoalCard(ProfessionalGoal goal) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(goal.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              goal.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getCategoryIcon(goal.category),
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _getCategoryName(goal.category),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${goal.dueDate.day}/${goal.dueDate.month}/${goal.dueDate.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso: ${(goal.progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(goal.progress * goal.milestones.length).toInt()}/${goal.milestones.length} hitos',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: goal.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _showGoalDetails(goal),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Ver detalles'),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _editGoal(goal),
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      onPressed: () => _deleteGoal(goal),
                      icon: const Icon(Icons.delete),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(GoalStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case GoalStatus.completed:
        color = Colors.green;
        label = 'Completado';
        icon = Icons.check_circle;
        break;
      case GoalStatus.inProgress:
        color = Colors.blue;
        label = 'En progreso';
        icon = Icons.access_time;
        break;
      case GoalStatus.pending:
        color = Colors.orange;
        label = 'Pendiente';
        icon = Icons.pause_circle;
        break;
      case GoalStatus.overdue:
        color = Colors.red;
        label = 'Atrasado';
        icon = Icons.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(GoalCategory category) {
    switch (category) {
      case GoalCategory.education:
        return Icons.school;
      case GoalCategory.business:
        return Icons.business;
      case GoalCategory.research:
        return Icons.science;
      case GoalCategory.personal:
        return Icons.person;
    }
  }

  String _getCategoryName(GoalCategory category) {
    switch (category) {
      case GoalCategory.education:
        return 'Educación';
      case GoalCategory.business:
        return 'Negocio';
      case GoalCategory.research:
        return 'Investigación';
      case GoalCategory.personal:
        return 'Personal';
    }
  }

  void _showAddGoalDialog() {
    // Implementar diálogo para agregar nuevo objetivo
  }

  void _showGoalDetails(ProfessionalGoal goal) {
    // Implementar pantalla de detalles del objetivo
  }

  void _editGoal(ProfessionalGoal goal) {
    // Implementar edición de objetivo
  }

  void _deleteGoal(ProfessionalGoal goal) {
    // Implementar eliminación de objetivo
  }
}

// Pantalla de Registro de Agua
class WaterLogScreen extends StatelessWidget {
  const WaterLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Agua'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Objetivo diario: 2 litros',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Día ${index + 1}'),
                  trailing: Text('${1.5 + index * 0.1} L'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Pantalla de Unidades
class UnitsScreen extends StatelessWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unidades de Medida'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildUnitSwitch('Sistema métrico', true),
          _buildUnitSwitch('Sistema imperial', false),
        ],
      ),
    );
  }

  Widget _buildUnitSwitch(String title, bool value) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (bool newValue) {},
    );
  }
}

// Pantalla de Base de Datos de Alimentos
class FoodDatabaseScreen extends StatelessWidget {
  const FoodDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Base de Datos de Alimentos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar alimentos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.fastfood),
                  title: Text('Alimento ${index + 1}'),
                  subtitle: Text('${100 + index * 10} kcal'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de Recordatorios
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: Text('Recordatorio ${index + 1}'),
              subtitle: Text('08:0${index + 1} AM - Diario'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Pantalla de Idioma
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idioma'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLanguageOption('Español', true),
          _buildLanguageOption('English', false),
          _buildLanguageOption('Português', false),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String language, bool selected) {
    return Card(
      child: ListTile(
        title: Text(language),
        trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
        onTap: () {},
      ),
    );
  }
}

// Pantalla de Copia de Seguridad
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copia de Seguridad'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBackupOption(
              icon: Icons.cloud_upload,
              title: 'Respaldar ahora',
              subtitle: 'Copia completa de tus datos',
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildBackupOption(
              icon: Icons.cloud_download,
              title: 'Restaurar copia',
              subtitle: 'Recupera tus datos guardados',
              onTap: () {},
            ),
            const SizedBox(height: 16),
            Text(
              'Última copia: 12/06/2023 14:30',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 40, color: AppColors.primary),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pantalla de Ayuda
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Ayuda y Preguntas Frecuentes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHelpItem('Cómo crear un plan nutricional', Icons.help),
          _buildHelpItem('Configurar horarios de consulta', Icons.schedule),
          _buildHelpItem('Gestionar pagos', Icons.payment),
          _buildHelpItem('Problemas con la aplicación', Icons.error),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, IconData icon) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {},
      ),
    );
  }
}

// Pantalla de Soporte
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Contactar Soporte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSupportOption(
              icon: Icons.email,
              title: 'Enviar correo',
              subtitle: 'soporte@mottinut.com',
            ),

            _buildSupportOption(
              icon: Icons.phone,
              title: 'Llamar por teléfono',
              subtitle: '+0800 00 200',
            ),

            _buildSupportOption(
              icon: Icons.chat,
              title: 'Chat en vivo',
              subtitle: 'Disponible 24/7',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, size: 25, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18,),
        onTap: () {},
      ),
    );
  }
}

// Pantalla Acerca de
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de MottiNut'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/app_icon.png'), // Asegúrate de tener esta imagen
            ),
            const SizedBox(height: 16),
            const Text(
              'MottiNut',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text('Versión 2.1.0'),
            const SizedBox(height: 24),
            const Text(
              'La aplicación líder para nutricionistas profesionales',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Text('© 2023 MottiNut Team'),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text('Términos y Condiciones'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Política de Privacidad'),
            ),
          ],
        ),
      ),
    );
  }
}