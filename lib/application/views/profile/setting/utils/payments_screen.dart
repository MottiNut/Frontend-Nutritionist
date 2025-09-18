import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../configuration/themes/app_colors.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;

  // Listas dinámicas que se llenan desde el backend
  List<ServicePlan> plans = [];
  List<PaymentTransaction> transactions = [];
  PaymentStats? stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Cargar datos del backend
  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        _loadPlans(),
        _loadTransactions(),
        _loadStats(),
      ]);
    } catch (e) {
      _showError('Error al cargar datos: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Cargar planes desde el backend
  Future<void> _loadPlans() async {
    try {
      // TODO: Implementar llamada real al backend
      // final response = await ApiService.getServicePlans();
      // setState(() => plans = response.data);

      // Simular carga del backend
      await Future.delayed(const Duration(milliseconds: 500));
      // Si no hay planes, la lista queda vacía
      setState(() => plans = []);
    } catch (e) {
      throw Exception('Error cargando planes: $e');
    }
  }

  // Cargar transacciones desde el backend
  Future<void> _loadTransactions() async {
    try {
      // TODO: Implementar llamada real al backend
      // final response = await ApiService.getTransactions();
      // setState(() => transactions = response.data);

      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => transactions = []);
    } catch (e) {
      throw Exception('Error cargando transacciones: $e');
    }
  }

  // Cargar estadísticas desde el backend
  Future<void> _loadStats() async {
    try {
      // TODO: Implementar llamada real al backend
      // final response = await ApiService.getPaymentStats();
      // setState(() => stats = response.data);

      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => stats = PaymentStats(
          totalClients: 0,
          monthlyEarnings: 0.0,
          pendingConsultations: 0,
          popularPlan: 'Sin datos'
      ));
    } catch (e) {
      throw Exception('Error cargando estadísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tarifas y Pagos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddPlanBottomSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.payment), text: 'Tarifas'),
            Tab(icon: Icon(Icons.history), text: 'Historial'),
            Tab(icon: Icon(Icons.analytics), text: 'Estadísticas'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildPlansTab(),
          _buildHistoryTab(),
          _buildStatsTab(),
        ],
      ),
      /*floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGeneratePaymentLinkSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.link, color: Colors.white),
        label: const Text(
          'Generar Link',
          style: TextStyle(color: Colors.white),
        ),
      ),*/
    );
  }

  Widget _buildPlansTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: plans.isEmpty
          ? _buildEmptyPlansState()
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEarningsCard(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Tarifas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showAddPlanBottomSheet,
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: plans.length,
                itemBuilder: (context, index) => _buildPlanCard(plans[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlansState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes tarifas configuradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Crea tu primera tarifa para empezar a recibir pagos de tus clientes',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddPlanBottomSheet,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Crear Primera Tarifa', style: TextStyle(color: Colors.white, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: transactions.isEmpty
          ? _buildEmptyTransactionsState()
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Pagos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) => _buildTransactionCard(transactions[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactionsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Sin transacciones aún',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aquí aparecerán los pagos de tus clientes',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (stats != null) ...[
              _buildStatsCard('Total Clientes', '${stats!.totalClients}', Icons.people, Colors.blue),
              const SizedBox(height: 12),
              _buildStatsCard('Ingresos Mes', 'S/. ${stats!.monthlyEarnings.toStringAsFixed(2)}', Icons.trending_up, Colors.green),
              const SizedBox(height: 12),
              _buildStatsCard('Plan Más Popular', stats!.popularPlan, Icons.star, Colors.orange),
              const SizedBox(height: 12),
              _buildStatsCard('Consultas Pendientes', '${stats!.pendingConsultations}', Icons.schedule, Colors.red),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    final totalEarnings = stats?.monthlyEarnings ?? 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingresos del Mes',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    'S/. ${totalEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (totalEarnings > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Activo',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(ServicePlan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getPlanIcon(plan.type), color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (plan.description.isNotEmpty)
                        Text(
                          plan.description,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handlePlanAction(value, plan),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(value: 'share', child: Text('Compartir')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Precio', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      'S/. ${plan.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _generateLinkForPlan(plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Generar Link'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(PaymentTransaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(transaction.status),
          child: Icon(
            _getStatusIcon(transaction.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          transaction.clientName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.planName),
            Text(
              _formatDate(transaction.date),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'S/. ${transaction.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(transaction.status),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600)),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mostrar bottom sheet para añadir nueva tarifa
  void _showAddPlanBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPlanBottomSheet(
        onPlanCreated: (plan) {
          _createPlan(plan);
        },
      ),
    );
  }

  // Mostrar bottom sheet para generar link de pago
  void _showGeneratePaymentLinkSheet() {
    if (plans.isEmpty) {
      _showSnackBar('Primero crea una tarifa para generar links de pago');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GeneratePaymentLinkSheet(
        plans: plans,
        onLinkGenerated: (link) {
          _showSnackBar('Link de pago generado y copiado');
        },
      ),
    );
  }

  // Crear nueva tarifa en el backend
  Future<void> _createPlan(ServicePlan plan) async {
    try {
      setState(() => isLoading = true);

      // TODO: Implementar llamada real al backend
      // await ApiService.createServicePlan(plan);

      await Future.delayed(const Duration(seconds: 1)); // Simular llamada
      await _loadPlans(); // Recargar planes
      _showSnackBar('Tarifa creada exitosamente');
    } catch (e) {
      _showError('Error al crear tarifa: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Manejar acciones del menú de tarifa
  void _handlePlanAction(String action, ServicePlan plan) {
    switch (action) {
      case 'edit':
        _editPlan(plan);
        break;
      case 'share':
        _sharePlan(plan);
        break;
      case 'delete':
        _deletePlan(plan);
        break;
    }
  }

  // Editar tarifa
  void _editPlan(ServicePlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPlanBottomSheet(
        plan: plan,
        onPlanCreated: (updatedPlan) {
          _updatePlan(updatedPlan);
        },
      ),
    );
  }

  // Actualizar tarifa
  Future<void> _updatePlan(ServicePlan plan) async {
    try {
      setState(() => isLoading = true);

      // TODO: Implementar llamada real al backend
      // await ApiService.updateServicePlan(plan);

      await _loadPlans();
      _showSnackBar('Tarifa actualizada exitosamente');
    } catch (e) {
      _showError('Error al actualizar tarifa: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Compartir tarifa
  void _sharePlan(ServicePlan plan) {
    // TODO: Implementar compartir tarifa
    _showSnackBar('Link de ${plan.name} copiado al portapapeles');
  }

  // Eliminar tarifa
  void _deletePlan(ServicePlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tarifa'),
        content: Text('¿Estás seguro de que deseas eliminar "${plan.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeletePlan(plan);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeletePlan(ServicePlan plan) async {
    try {
      setState(() => isLoading = true);

      // TODO: Implementar llamada real al backend
      // await ApiService.deleteServicePlan(plan.id);

      await _loadPlans();
      _showSnackBar('Tarifa eliminada exitosamente');
    } catch (e) {
      _showError('Error al eliminar tarifa: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Generar link para plan específico
  void _generateLinkForPlan(ServicePlan plan) {
    // TODO: Implementar generación de link
    _showSnackBar('Link generado para ${plan.name}');
  }

  // Métodos auxiliares
  IconData _getPlanIcon(PlanType type) {
    switch (type) {
      case PlanType.consultation:
        return Icons.medical_services;
      case PlanType.monthly:
        return Icons.calendar_month;
      case PlanType.virtual:
        return Icons.videocam;
      case PlanType.custom:
        return Icons.star;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Icons.check;
      case TransactionStatus.pending:
        return Icons.schedule;
      case TransactionStatus.cancelled:
        return Icons.close;
    }
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return 'Completado';
      case TransactionStatus.pending:
        return 'Pendiente';
      case TransactionStatus.cancelled:
        return 'Cancelado';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Bottom Sheet para añadir nueva tarifa
class AddPlanBottomSheet extends StatefulWidget {
  final ServicePlan? plan;
  final Function(ServicePlan) onPlanCreated;

  const AddPlanBottomSheet({
    super.key,
    this.plan,
    required this.onPlanCreated,
  });

  @override
  State<AddPlanBottomSheet> createState() => _AddPlanBottomSheetState();
}

class _AddPlanBottomSheetState extends State<AddPlanBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  PlanType _selectedType = PlanType.consultation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _nameController.text = widget.plan!.name;
      _descriptionController.text = widget.plan!.description;
      _priceController.text = widget.plan!.price.toString();
      _selectedType = widget.plan!.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.plan == null ? 'Nueva Tarifa' : 'Editar Tarifa',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del servicio *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Precio (S/.) *',
                            border: OutlineInputBorder(),
                            prefixText: 'S/. ',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Campo requerido';
                            if (double.tryParse(value!) == null) return 'Ingrese un precio válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Tipo de servicio:', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...PlanType.values.map((type) => RadioListTile<PlanType>(
                          value: type,
                          groupValue: _selectedType,
                          onChanged: (value) => setState(() => _selectedType = value!),
                          title: Text(_getPlanTypeName(type)),
                          contentPadding: EdgeInsets.zero,
                        )),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : Text(widget.plan == null ? 'Crear Tarifa' : 'Actualizar Tarifa'),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final plan = ServicePlan(
      id: widget.plan?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text),
      currency: 'PEN',
      type: _selectedType,
      features: [],
      isPopular: false,
    );

    // Simular delay de guardado
    await Future.delayed(const Duration(seconds: 1));

    widget.onPlanCreated(plan);
    Navigator.pop(context);
  }

  String _getPlanTypeName(PlanType type) {
    switch (type) {
      case PlanType.consultation:
        return 'Consulta Individual';
      case PlanType.monthly:
        return 'Plan Mensual';
      case PlanType.virtual:
        return 'Consulta Virtual';
      case PlanType.custom:
        return 'Personalizado';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}

// Bottom Sheet para generar link de pago
class GeneratePaymentLinkSheet extends StatefulWidget {
  final List<ServicePlan> plans;
  final Function(String) onLinkGenerated;

  const GeneratePaymentLinkSheet({
    super.key,
    required this.plans,
    required this.onLinkGenerated,
  });

  @override
  State<GeneratePaymentLinkSheet> createState() => _GeneratePaymentLinkSheetState();
}

class _GeneratePaymentLinkSheetState extends State<GeneratePaymentLinkSheet> {
  ServicePlan? _selectedPlan;
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Generar Link de Pago',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selecciona el servicio:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<ServicePlan>(
                          value: _selectedPlan,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          hint: const Text('Seleccionar servicio'),
                          items: widget.plans.map((plan) {
                            return DropdownMenuItem(
                              value: plan,
                              child: Row(
                                children: [
                                  Icon(_getPlanIcon(plan.type), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                        Text('S/. ${plan.price.toStringAsFixed(2)}',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (plan) => setState(() => _selectedPlan = plan),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Datos del cliente (opcional):', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del cliente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _clientEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email del cliente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 32),
                      if (_selectedPlan != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Resumen:', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_selectedPlan!.name),
                                  Text('S/. ${_selectedPlan!.price.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedPlan == null || _isGenerating ? null : _generateLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isGenerating
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Generar Link de Pago'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPlanIcon(PlanType type) {
    switch (type) {
      case PlanType.consultation:
        return Icons.medical_services;
      case PlanType.monthly:
        return Icons.calendar_month;
      case PlanType.virtual:
        return Icons.videocam;
      case PlanType.custom:
        return Icons.star;
    }
  }

  Future<void> _generateLink() async {
    setState(() => _isGenerating = true);

    try {
      // TODO: Implementar generación real de link de pago
      // final paymentLink = await ApiService.generatePaymentLink(
      //   planId: _selectedPlan!.id,
      //   clientName: _clientNameController.text.trim(),
      //   clientEmail: _clientEmailController.text.trim(),
      // );

      await Future.delayed(const Duration(seconds: 1)); // Simular API call

      final mockLink = 'https://pay.miapp.com/link/${_selectedPlan!.id}/${DateTime.now().millisecondsSinceEpoch}';

      widget.onLinkGenerated(mockLink);
      Navigator.pop(context);

      // Mostrar dialog con el link generado
      _showLinkGeneratedDialog(mockLink);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _showLinkGeneratedDialog(String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Link Generado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tu link de pago ha sido generado exitosamente:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                link,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar copiar al portapapeles
              // Clipboard.setData(ClipboardData(text: link));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copiado al portapapeles')),
              );
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientEmailController.dispose();
    super.dispose();
  }
}

// Modelos de datos actualizados
enum PlanType { consultation, monthly, virtual, custom }
enum TransactionStatus { completed, pending, cancelled }

class ServicePlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final PlanType type;
  final List<String> features;
  final bool isPopular;

  ServicePlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.type,
    required this.features,
    required this.isPopular,
  });

  // Métodos para serialización JSON (para API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'type': type.toString().split('.').last,
      'features': features,
      'isPopular': isPopular,
    };
  }

  factory ServicePlan.fromJson(Map<String, dynamic> json) {
    return ServicePlan(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] ?? 'PEN',
      type: PlanType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
        orElse: () => PlanType.custom,
      ),
      features: List<String>.from(json['features'] ?? []),
      isPopular: json['isPopular'] ?? false,
    );
  }
}

class PaymentTransaction {
  final String id;
  final String clientName;
  final double amount;
  final String currency;
  final DateTime date;
  final TransactionStatus status;
  final String planName;

  PaymentTransaction({
    required this.id,
    required this.clientName,
    required this.amount,
    required this.currency,
    required this.date,
    required this.status,
    required this.planName,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'],
      clientName: json['clientName'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'PEN',
      date: DateTime.parse(json['date']),
      status: TransactionStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      planName: json['planName'],
    );
  }
}

class PaymentStats {
  final int totalClients;
  final double monthlyEarnings;
  final int pendingConsultations;
  final String popularPlan;

  PaymentStats({
    required this.totalClients,
    required this.monthlyEarnings,
    required this.pendingConsultations,
    required this.popularPlan,
  });

  factory PaymentStats.fromJson(Map<String, dynamic> json) {
    return PaymentStats(
      totalClients: json['totalClients'] ?? 0,
      monthlyEarnings: (json['monthlyEarnings'] as num?)?.toDouble() ?? 0.0,
      pendingConsultations: json['pendingConsultations'] ?? 0,
      popularPlan: json['popularPlan'] ?? 'Sin datos',
    );
  }
}


// TODO: Implementar ApiService para conectar con el backend
/*
class ApiService {
  static const String baseUrl = 'https://tu-backend.com/api';

  static Future<List<ServicePlan>> getServicePlans() async {
    final response = await http.get(Uri.parse('$baseUrl/plans'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ServicePlan.fromJson(json)).toList();
    }
    throw Exception('Error loading plans');
  }

  static Future<ServicePlan> createServicePlan(ServicePlan plan) async {
    final response = await http.post(
      Uri.parse('$baseUrl/plans'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(plan.toJson()),
    );
    if (response.statusCode == 201) {
      return ServicePlan.fromJson(json.decode(response.body));
    }
    throw Exception('Error creating plan');
  }

  static Future<void> updateServicePlan(ServicePlan plan) async {
    final response = await http.put(
      Uri.parse('$baseUrl/plans/${plan.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(plan.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Error updating plan');
    }
  }

  static Future<void> deleteServicePlan(String planId) async {
    final response = await http.delete(Uri.parse('$baseUrl/plans/$planId'));
    if (response.statusCode != 200) {
      throw Exception('Error deleting plan');
    }
  }

  static Future<List<PaymentTransaction>> getTransactions() async {
    final response = await http.get(Uri.parse('$baseUrl/transactions'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => PaymentTransaction.fromJson(json)).toList();
    }
    throw Exception('Error loading transactions');
  }

  static Future<PaymentStats> getPaymentStats() async {
    final response = await http.get(Uri.parse('$baseUrl/stats'));
    if (response.statusCode == 200) {
      return PaymentStats.fromJson(json.decode(response.body));
    }
    throw Exception('Error loading stats');
  }

  static Future<String> generatePaymentLink({
    required String planId,
    String? clientName,
    String? clientEmail,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payment-links'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'planId': planId,
        'clientName': clientName,
        'clientEmail': clientEmail,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['paymentUrl'];
    }
    throw Exception('Error generating payment link');
  }
}
*/