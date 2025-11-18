import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models.dart';

class FinancialGoalsWidget extends StatefulWidget {
  const FinancialGoalsWidget({super.key});

  @override
  State<FinancialGoalsWidget> createState() => _FinancialGoalsWidgetState();
}

class _FinancialGoalsWidgetState extends State<FinancialGoalsWidget> {
  final List<FinancialGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final goalsSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('metas')
          .orderBy('createdDate', descending: true)
          .get();

      final goals = goalsSnapshot.docs
          .map((doc) => FinancialGoal.fromMap(doc.data()))
          .toList();

      setState(() {
        _goals.clear();
        _goals.addAll(goals);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading goals: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGoal(FinancialGoal goal) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('metas')
          .doc(goal.id)
          .set(goal.toMap());

      await _loadGoals();
    } catch (e) {
      print('Error saving goal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar meta: $e')),
      );
    }
  }

  Future<void> _deleteGoal(String goalId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('metas')
          .doc(goalId)
          .delete();

      setState(() {
        _goals.removeWhere((goal) => goal.id == goalId);
      });
    } catch (e) {
      print('Error deleting goal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar meta: $e')),
      );
    }
  }

  void _showCreateGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateGoalDialog(
        onSave: (goal) async {
          await _saveGoal(goal);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.pink],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.flag, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis Metas Financieras',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Gestiona tus objetivos de ahorro',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _showCreateGoalDialog,
                      icon: const Icon(Icons.add, size: 28),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_goals.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No tienes metas financieras',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crea tu primera meta para empezar a ahorrar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showCreateGoalDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Primera Meta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    return GoalCard(
                      goal: goal,
                      onDelete: () => _deleteGoal(goal.id),
                      onUpdate: _saveGoal,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  final FinancialGoal goal;
  final VoidCallback onDelete;
  final Function(FinancialGoal) onUpdate;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onDelete,
    required this.onUpdate,
  });

  Color _getGoalColor(FinancialGoal goal) {
    if (goal.isCompleted) return Colors.green;
    if (goal.progressPercentage >= 0.8) return Colors.blue;
    if (goal.progressPercentage >= 0.5) return Colors.orange;
    return Colors.grey;
  }

  String _getGoalTypeText(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return 'Ahorro General';
      case GoalType.emergencyFund:
        return 'Fondo de Emergencia';
      case GoalType.debtPayment:
        return 'Pago de Deudas';
      case GoalType.investment:
        return 'Inversión';
      case GoalType.vacation:
        return 'Vacaciones';
      case GoalType.purchase:
        return 'Compra';
      case GoalType.custom:
        return 'Personalizada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGoalColor(goal);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      goal.isCompleted ? Icons.check_circle : Icons.flag,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getGoalTypeText(goal.type),
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminar Meta'),
                            content: const Text('¿Estás seguro de que quieres eliminar esta meta?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  onDelete();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Eliminar'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${goal.currentAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '\$${goal.targetAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey.shade200,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: goal.progressPercentage,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(goal.progressPercentage * 100).toStringAsFixed(1)}% completado',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (goal.remainingAmount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Te faltan \$${goal.remainingAmount.toStringAsFixed(2)} para completar esta meta',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (goal.daysRemaining > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${goal.daysRemaining} días restantes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CreateGoalDialog extends StatefulWidget {
  final Function(FinancialGoal) onSave;

  const CreateGoalDialog({super.key, required this.onSave});

  @override
  State<CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<CreateGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();

  GoalType _selectedType = GoalType.savings;
  GoalPeriod _selectedPeriod = GoalPeriod.monthly;
  DateTime? _targetDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final goal = FinancialGoal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        targetAmount: double.parse(_targetAmountController.text.replaceAll(',', '.')),
        currentAmount: 0,
        type: _selectedType,
        period: _selectedPeriod,
        createdDate: DateTime.now(),
        targetDate: _targetDate,
      );

      widget.onSave(goal);
    }
  }

  String _getGoalTypeText(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return 'Ahorro General';
      case GoalType.emergencyFund:
        return 'Fondo de Emergencia';
      case GoalType.debtPayment:
        return 'Pago de Deudas';
      case GoalType.investment:
        return 'Inversión';
      case GoalType.vacation:
        return 'Vacaciones';
      case GoalType.purchase:
        return 'Compra';
      case GoalType.custom:
        return 'Personalizada';
    }
  }

  String _getGoalPeriodText(GoalPeriod period) {
    switch (period) {
      case GoalPeriod.monthly:
        return 'Mensual';
      case GoalPeriod.yearly:
        return 'Anual';
      case GoalPeriod.custom:
        return 'Personalizado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF0FFF4),
              const Color(0xFFE6FBFF),
              const Color(0xFFFFF6EA),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2ECC71), Color(0xFF4FA3FF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.flag, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF2ECC71), Color(0xFF4FA3FF)],
                    ).createShader(bounds),
                    child: const Text(
                      'Nueva Meta Financiera',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la meta',
                  hintText: 'Ej: Comprar un carro',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Detalles adicionales de tu meta',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Monto objetivo',
                  hintText: 'Ej: 5000.00',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un monto';
                  }
                  final amount = double.tryParse(value.replaceAll(',', '.'));
                  if (amount == null || amount <= 0) {
                    return 'Ingresa un monto válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<GoalType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de meta',
                  border: OutlineInputBorder(),
                ),
                items: GoalType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getGoalTypeText(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<GoalPeriod>(
                value: _selectedPeriod,
                decoration: const InputDecoration(
                  labelText: 'Período',
                  border: OutlineInputBorder(),
                ),
                items: GoalPeriod.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(_getGoalPeriodText(period)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPeriod = value!);
                },
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (date != null) {
                    setState(() => _targetDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha objetivo (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _targetDate != null
                        ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      color: _targetDate != null ? null : Colors.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2ECC71)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Color(0xFF2ECC71)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Crear Meta'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}