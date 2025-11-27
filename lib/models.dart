class Income {
  final String source;
  final double amount;
  final String description;
  final DateTime date;

  Income({
    required this.source,
    required this.amount,
    required this.description,
    required this.date,
  });
}

class Expense {
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final String? photoUrl;
  final String? location;
  final double? amountSaved;

  Expense({
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.photoUrl,
    this.location,
    this.amountSaved,
  });
}

enum GoalType {
  savings,
  emergencyFund,
  debtPayment,
  investment,
  vacation,
  purchase,
  custom
}

enum GoalPeriod {
  monthly,
  yearly,
  custom
}

enum GoalPriority {
  low,
  medium,
  high,
  critical
}

class FinancialGoal {
  final String id;
  final String title;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final GoalType type;
  final GoalPeriod period;
  final DateTime createdDate;
  final DateTime? targetDate;
  final bool isCompleted;
  final bool isActive;

  // Nuevos campos para asignación automática
  final bool autoAssignEnabled; // Si recibe asignaciones automáticas
  final double autoAssignAmount; // Monto fijo mensual o porcentaje (0-1)
  final bool autoAssignIsPercentage; // true = porcentaje, false = monto fijo
  final GoalPriority priority; // Prioridad para asignaciones automáticas
  final DateTime? lastAutoAssignDate; // Última fecha de asignación automática
  final double totalAutoAssigned; // Total asignado automáticamente

  FinancialGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.type,
    required this.period,
    required this.createdDate,
    this.targetDate,
    this.isCompleted = false,
    this.isActive = true,
    this.autoAssignEnabled = false,
    this.autoAssignAmount = 0.0,
    this.autoAssignIsPercentage = false,
    this.priority = GoalPriority.medium,
    this.lastAutoAssignDate,
    this.totalAutoAssigned = 0.0,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0.0, double.infinity);
  }

  int get daysRemaining {
    if (targetDate == null) return -1;
    return targetDate!.difference(DateTime.now()).inDays;
  }

  // Monto sugerido mensual para completar la meta a tiempo
  double get suggestedMonthlyAmount {
    if (targetDate == null) return targetAmount / 12; // Asumir 12 meses por defecto

    final monthsRemaining = (targetDate!.difference(DateTime.now()).inDays / 30).ceil();
    if (monthsRemaining <= 0) return remainingAmount;

    return remainingAmount / monthsRemaining;
  }

  // Monto disponible para asignación automática este mes
  double get availableForAutoAssign {
    if (!autoAssignEnabled || isCompleted) return 0.0;

    if (autoAssignIsPercentage) {
      // Si es porcentaje, devolver el porcentaje del remainingAmount
      return remainingAmount * autoAssignAmount.clamp(0.0, 1.0);
    } else {
      // Si es monto fijo, devolver el mínimo entre el monto configurado y el restante
      return autoAssignAmount.clamp(0.0, remainingAmount);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'type': type.toString(),
      'period': period.toString(),
      'createdDate': createdDate.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'isActive': isActive,
      'autoAssignEnabled': autoAssignEnabled,
      'autoAssignAmount': autoAssignAmount,
      'autoAssignIsPercentage': autoAssignIsPercentage,
      'priority': priority.toString(),
      'lastAutoAssignDate': lastAutoAssignDate?.toIso8601String(),
      'totalAutoAssigned': totalAutoAssigned,
    };
  }

  factory FinancialGoal.fromMap(Map<String, dynamic> map) {
    return FinancialGoal(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0.0).toDouble(),
      type: GoalType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => GoalType.custom,
      ),
      period: GoalPeriod.values.firstWhere(
        (e) => e.toString() == map['period'],
        orElse: () => GoalPeriod.monthly,
      ),
      createdDate: DateTime.parse(map['createdDate'] ?? DateTime.now().toIso8601String()),
      targetDate: map['targetDate'] != null ? DateTime.parse(map['targetDate']) : null,
      isCompleted: map['isCompleted'] ?? false,
      isActive: map['isActive'] ?? true,
      autoAssignEnabled: map['autoAssignEnabled'] ?? false,
      autoAssignAmount: (map['autoAssignAmount'] ?? 0.0).toDouble(),
      autoAssignIsPercentage: map['autoAssignIsPercentage'] ?? false,
      priority: GoalPriority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => GoalPriority.medium,
      ),
      lastAutoAssignDate: map['lastAutoAssignDate'] != null ? DateTime.parse(map['lastAutoAssignDate']) : null,
      totalAutoAssigned: (map['totalAutoAssigned'] ?? 0.0).toDouble(),
    );
  }
}