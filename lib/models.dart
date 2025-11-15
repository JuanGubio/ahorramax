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
    );
  }
}