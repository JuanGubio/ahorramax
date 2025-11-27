import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models.dart';

class GoalAutoAssignService {
  static final GoalAutoAssignService _instance = GoalAutoAssignService._internal();
  factory GoalAutoAssignService() => _instance;
  GoalAutoAssignService._internal();

  /// Calcula el excedente mensual disponible para asignar a metas
  Future<double> calculateMonthlySurplus(String userId) async {
    try {
      // Obtener balance actual del usuario
      final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(userId).get();
      final currentBalance = (userDoc['balanceActual'] ?? 0.0).toDouble();
      final totalSavings = (userDoc['ahorroTotal'] ?? 0.0).toDouble();

      // Calcular ingresos del mes actual
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);

      final incomesSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('ingresos')
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('fecha', isLessThan: Timestamp.fromDate(endOfMonth))
          .get();

      final monthlyIncome = incomesSnapshot.docs
          .fold<double>(0, (sum, doc) => sum + (doc['monto'] ?? 0.0));

      // Calcular gastos del mes actual
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('gastos')
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('fecha', isLessThan: Timestamp.fromDate(endOfMonth))
          .get();

      final monthlyExpenses = expensesSnapshot.docs
          .fold<double>(0, (sum, doc) => sum + (doc['monto'] ?? 0.0));

      // Excedente = Ingresos - Gastos
      final surplus = monthlyIncome - monthlyExpenses;

      // Solo devolver excedente positivo y limitado a los ahorros disponibles
      return surplus > 0 ? surplus.clamp(0.0, totalSavings).toDouble() : 0.0;
    } catch (e) {
      print('Error calculating monthly surplus: $e');
      return 0.0;
    }
  }

  /// Obtiene todas las metas activas ordenadas por prioridad
  Future<List<FinancialGoal>> getActiveGoals(String userId) async {
    try {
      final goalsSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('metas')
          .where('isActive', isEqualTo: true)
          .where('isCompleted', isEqualTo: false)
          .where('autoAssignEnabled', isEqualTo: true)
          .get();

      final goals = goalsSnapshot.docs
          .map((doc) => FinancialGoal.fromMap(doc.data()))
          .where((goal) => goal.remainingAmount > 0)
          .toList();

      // Ordenar por prioridad (critical -> high -> medium -> low)
      goals.sort((a, b) {
        final priorityOrder = {
          GoalPriority.critical: 4,
          GoalPriority.high: 3,
          GoalPriority.medium: 2,
          GoalPriority.low: 1,
        };

        return priorityOrder[b.priority]!.compareTo(priorityOrder[a.priority]!);
      });

      return goals;
    } catch (e) {
      print('Error getting active goals: $e');
      return [];
    }
  }

  /// Distribuye automáticamente el excedente entre las metas activas
  Future<Map<String, double>> distributeSurplus(String userId, double surplus) async {
    final distribution = <String, double>{};
    final activeGoals = await getActiveGoals(userId);

    if (activeGoals.isEmpty || surplus <= 0) {
      return distribution;
    }

    double remainingSurplus = surplus;

    // Primera pasada: asignar a metas críticas y altas prioridad
    for (final goal in activeGoals.where((g) =>
        g.priority == GoalPriority.critical || g.priority == GoalPriority.high)) {
      if (remainingSurplus <= 0) break;

      final availableForGoal = goal.availableForAutoAssign;
      final assignAmount = remainingSurplus.clamp(0.0, availableForGoal).toDouble();

      if (assignAmount > 0) {
        distribution[goal.id] = assignAmount;
        remainingSurplus -= assignAmount;
      }
    }

    // Segunda pasada: distribuir el resto entre todas las metas activas
    if (remainingSurplus > 0) {
      final remainingGoals = activeGoals.where((g) => g.remainingAmount > 0).toList();
      final equalShare = remainingSurplus / remainingGoals.length;

      for (final goal in remainingGoals) {
        if (remainingSurplus <= 0) break;

        final availableForGoal = goal.availableForAutoAssign;
        final assignAmount = equalShare.clamp(0.0, availableForGoal).clamp(0.0, remainingSurplus).toDouble();

        if (assignAmount > 0) {
          distribution[goal.id] = (distribution[goal.id] ?? 0) + assignAmount;
          remainingSurplus -= assignAmount;
        }
      }
    }

    return distribution;
  }

  /// Aplica las asignaciones automáticas a las metas
  Future<void> applyAutoAssignments(String userId, Map<String, double> assignments) async {
    if (assignments.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Actualizar cada meta
      for (final entry in assignments.entries) {
        final goalId = entry.key;
        final amount = entry.value;

        final goalRef = FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('metas')
            .doc(goalId);

        // Obtener la meta actual
        final goalDoc = await goalRef.get();
        if (!goalDoc.exists) continue;

        final goal = FinancialGoal.fromMap(goalDoc.data()!);
        final newCurrentAmount = goal.currentAmount + amount;
        final newTotalAutoAssigned = goal.totalAutoAssigned + amount;
        final isCompleted = newCurrentAmount >= goal.targetAmount;

        // Actualizar la meta
        batch.update(goalRef, {
          'currentAmount': newCurrentAmount,
          'totalAutoAssigned': newTotalAutoAssigned,
          'lastAutoAssignDate': DateTime.now().toIso8601String(),
          'isCompleted': isCompleted,
        });

        // Registrar la transacción automática
        final transactionRef = FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('transacciones_automaticas')
            .doc();

        batch.set(transactionRef, {
          'tipo': 'meta_auto_assign',
          'metaId': goalId,
          'metaTitle': goal.title,
          'monto': amount,
          'fecha': DateTime.now().toIso8601String(),
          'descripcion': 'Asignación automática a meta: ${goal.title}',
        });
      }

      // Actualizar el total de ahorros del usuario
      final totalAssigned = assignments.values.fold<double>(0, (sum, amount) => sum + amount);
      final userRef = FirebaseFirestore.instance.collection('usuarios').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (userDoc.exists) {
          final currentSavings = (userDoc['ahorroTotal'] ?? 0.0).toDouble();
          transaction.update(userRef, {
            'ahorroTotal': currentSavings - totalAssigned,
          });
        }
      });

      await batch.commit();

      print('✅ Asignaciones automáticas aplicadas: ${assignments.length} metas, total: \$${totalAssigned.toStringAsFixed(2)}');

    } catch (e) {
      print('❌ Error applying auto assignments: $e');
      throw e;
    }
  }

  /// Ejecuta el proceso completo de asignación automática mensual
  Future<Map<String, double>> processMonthlyAutoAssignment(String userId) async {
    try {
      // Verificar si ya se ejecutó este mes
      final lastExecution = await _getLastMonthlyExecution(userId);
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      if (lastExecution != null && lastExecution.isAfter(startOfMonth)) {
        print('ℹ️ Asignación automática ya ejecutada este mes');
        return {};
      }

      // Calcular excedente
      final surplus = await calculateMonthlySurplus(userId);
      if (surplus <= 0) {
        print('ℹ️ No hay excedente disponible para asignar');
        return {};
      }

      // Distribuir entre metas
      final assignments = await distributeSurplus(userId, surplus);

      if (assignments.isNotEmpty) {
        // Aplicar asignaciones
        await applyAutoAssignments(userId, assignments);

        // Registrar ejecución
        await _recordMonthlyExecution(userId);
      }

      return assignments;

    } catch (e) {
      print('❌ Error in monthly auto assignment: $e');
      return {};
    }
  }

  Future<DateTime?> _getLastMonthlyExecution(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('configuracion')
          .doc('auto_assign')
          .get();

      if (doc.exists && doc['lastMonthlyExecution'] != null) {
        return DateTime.parse(doc['lastMonthlyExecution']);
      }
    } catch (e) {
      print('Error getting last execution: $e');
    }
    return null;
  }

  Future<void> _recordMonthlyExecution(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('configuracion')
          .doc('auto_assign')
          .set({
            'lastMonthlyExecution': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error recording execution: $e');
    }
  }

  /// Obtiene el historial de asignaciones automáticas
  Future<List<Map<String, dynamic>>> getAutoAssignmentHistory(String userId, {int limit = 20}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('transacciones_automaticas')
          .where('tipo', isEqualTo: 'meta_auto_assign')
          .orderBy('fecha', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting auto assignment history: $e');
      return [];
    }
  }
}