import 'package:flutter/material.dart';

// Enums para categorías y tipos de análisis
enum ExpenseCategory {
  alimentacion,
  transporte,
  entretenimiento,
  salud,
  ropa,
  casa,
  educacion,
  servicios,
  otros
}

enum SpendingPattern {
  conservative,
  moderate,
  aggressive,
  irregular
}

enum RiskLevel {
  low,
  medium,
  high,
  critical
}

// Modelo principal para análisis financiero
class FinancialAnalysis {
  final String userId;
  final DateTime analysisDate;
  final SpendingBehavior behavior;
  final FinancialHealth health;
  final SpendingTrends trends;
  final CategoryAnalysis categories;
  final PredictiveInsights predictions;
  final AlertsAndRecommendations recommendations;

  FinancialAnalysis({
    required this.userId,
    required this.analysisDate,
    required this.behavior,
    required this.health,
    required this.trends,
    required this.categories,
    required this.predictions,
    required this.recommendations,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'analysisDate': analysisDate.toIso8601String(),
      'behavior': behavior.toMap(),
      'health': health.toMap(),
      'trends': trends.toMap(),
      'categories': categories.toMap(),
      'predictions': predictions.toMap(),
      'recommendations': recommendations.toMap(),
    };
  }

  factory FinancialAnalysis.fromMap(Map<String, dynamic> map) {
    return FinancialAnalysis(
      userId: map['userId'] ?? '',
      analysisDate: DateTime.parse(map['analysisDate'] ?? DateTime.now().toIso8601String()),
      behavior: SpendingBehavior.fromMap(map['behavior'] ?? {}),
      health: FinancialHealth.fromMap(map['health'] ?? {}),
      trends: SpendingTrends.fromMap(map['trends'] ?? {}),
      categories: CategoryAnalysis.fromMap(map['categories'] ?? {}),
      predictions: PredictiveInsights.fromMap(map['predictions'] ?? {}),
      recommendations: AlertsAndRecommendations.fromMap(map['recommendations'] ?? {}),
    );
  }
}

// Análisis de comportamiento del usuario
class SpendingBehavior {
  final double impulseScore; // 0-100, menor = más controlado
  final double planningScore; // 0-100, mayor = mejor planificación
  final double consistencyScore; // 0-100, mayor = más consistente
  final SpendingPattern pattern;
  final RiskLevel riskLevel;
  final List<String> behaviorFlags;
  final DateTime lastAnalysis;

  SpendingBehavior({
    required this.impulseScore,
    required this.planningScore,
    required this.consistencyScore,
    required this.pattern,
    required this.riskLevel,
    required this.behaviorFlags,
    required this.lastAnalysis,
  });

  // Calcular scores basados en datos de transacciones
  static SpendingBehavior analyzeTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(thirtyDaysAgo))
        .toList();

    // Calcular impulse score
    final impulseScore = _calculateImpulseScore(recentTransactions);
    
    // Calcular planning score
    final planningScore = _calculatePlanningScore(recentTransactions);
    
    // Calcular consistency score
    final consistencyScore = _calculateConsistencyScore(recentTransactions);
    
    // Determinar patrón de gasto
    final pattern = _determineSpendingPattern(recentTransactions);
    
    // Determinar nivel de riesgo
    final riskLevel = _determineRiskLevel(impulseScore, planningScore, consistencyScore);
    
    // Identificar flags de comportamiento
    final behaviorFlags = _identifyBehaviorFlags(recentTransactions);

    return SpendingBehavior(
      impulseScore: impulseScore,
      planningScore: planningScore,
      consistencyScore: consistencyScore,
      pattern: pattern,
      riskLevel: riskLevel,
      behaviorFlags: behaviorFlags,
      lastAnalysis: now,
    );
  }

  static double _calculateImpulseScore(List<Transaction> transactions) {
    if (transactions.isEmpty) return 100.0;
    
    final impulseTransactions = transactions.where((t) {
      // Gastos impulsivos: montos aleatorios, horarios raros, categorías no planificadas
      return _isImpulseTransaction(t, transactions);
    }).toList();
    
    final impulsePercentage = (impulseTransactions.length / transactions.length) * 100;
    return (100 - impulsePercentage).clamp(0.0, 100.0);
  }

  static double _calculatePlanningScore(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;
    
    final plannedTransactions = transactions.where((t) {
      // Transacciones planificadas: montos redondos, categorías regulares, horarios normales
      return _isPlannedTransaction(t, transactions);
    }).toList();
    
    final plannedPercentage = (plannedTransactions.length / transactions.length) * 100;
    return plannedPercentage.clamp(0.0, 100.0);
  }

  static double _calculateConsistencyScore(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;
    
    // Analizar consistencia en montos y categorías
    final categoryCounts = <String, int>{};
    final amountRanges = <String, int>{};
    
    for (final transaction in transactions) {
      categoryCounts[transaction.category] = 
          (categoryCounts[transaction.category] ?? 0) + 1;
      
      final range = _getAmountRange(transaction.amount);
      amountRanges[range] = (amountRanges[range] ?? 0) + 1;
    }
    
    // Mayor concentración = mayor consistencia
    final maxCategoryCount = categoryCounts.values.isEmpty ? 0 : 
        categoryCounts.values.reduce((a, b) => a > b ? a : b);
    final totalTransactions = transactions.length;
    
    final categoryConsistency = (maxCategoryCount / totalTransactions) * 100;
    
    return categoryConsistency.clamp(0.0, 100.0);
  }

  static SpendingPattern _determineSpendingPattern(List<Transaction> transactions) {
    if (transactions.isEmpty) return SpendingPattern.moderate;
    
    final totalSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final averageAmount = totalSpent / transactions.length;
    final variance = _calculateVariance(transactions.map((t) => t.amount).toList());
    
    if (averageAmount < 10 && variance < 50) {
      return SpendingPattern.conservative;
    } else if (averageAmount > 50 && variance > 200) {
      return SpendingPattern.aggressive;
    } else if (variance > 300) {
      return SpendingPattern.irregular;
    } else {
      return SpendingPattern.moderate;
    }
  }

  static RiskLevel _determineRiskLevel(double impulseScore, double planningScore, double consistencyScore) {
    final riskScore = (100 - impulseScore) + (100 - planningScore) + (100 - consistencyScore);
    
    if (riskScore < 50) return RiskLevel.low;
    if (riskScore < 100) return RiskLevel.medium;
    if (riskScore < 150) return RiskLevel.high;
    return RiskLevel.critical;
  }

  static List<String> _identifyBehaviorFlags(List<Transaction> transactions) {
    final flags = <String>[];
    
    // Flags comunes de comportamiento
    if (_hasIrregularSpending(transactions)) {
      flags.add('gastos_irregulares');
    }
    
    if (_hasLateNightSpending(transactions)) {
      flags.add('gastos_nocturnos');
    }
    
    if (_hasDiningOutPattern(transactions)) {
      flags.add('gastos_frecuentes_restaurantes');
    }
    
    if (_hasImpulseCategories(transactions)) {
      flags.add('categorias_impulsivas');
    }
    
    if (_hasIncreasingTrend(transactions)) {
      flags.add('tendencia_creciente');
    }
    
    return flags;
  }

  // Helpers para identificación de patrones
  static bool _isImpulseTransaction(Transaction t, List<Transaction> allTransactions) {
    final hour = t.date.hour;
    final isLate = hour < 7 || hour > 22;
    final amount = t.amount;
    final isRandomAmount = amount % 1 != 0 && amount > 20;
    
    // Cantidad pequeña pero frecuente puede indicar impulso
    final smallFrequent = amount < 15 && allTransactions
        .where((x) => x.category == t.category).length > 5;
    
    return isLate || isRandomAmount || smallFrequent;
  }

  static bool _isPlannedTransaction(Transaction t, List<Transaction> allTransactions) {
    final hour = t.date.hour;
    final isNormalHours = hour >= 8 && hour <= 20;
    final amount = t.amount;
    final isRoundAmount = amount % 5 == 0 || amount % 10 == 0;
    final isRegularCategory = _isRegularCategory(t.category, allTransactions);
    
    return isNormalHours && (isRoundAmount || isRegularCategory);
  }

  static bool _isRegularCategory(String category, List<Transaction> transactions) {
    final categoryTransactions = transactions
        .where((t) => t.category == category)
        .toList();
    return categoryTransactions.length >= 3; // Al menos 3 transacciones = categoría regular
  }

  static String _getAmountRange(double amount) {
    if (amount < 10) return 'small';
    if (amount < 25) return 'medium';
    if (amount < 50) return 'large';
    return 'xlarge';
  }

  static double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((x) => (x - mean) * (x - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  static bool _hasIrregularSpending(List<Transaction> transactions) {
    final amounts = transactions.map((t) => t.amount).toList();
    final variance = _calculateVariance(amounts);
    return variance > 500;
  }

  static bool _hasLateNightSpending(List<Transaction> transactions) {
    final lateNightCount = transactions
        .where((t) => t.date.hour < 7 || t.date.hour > 22)
        .length;
    return (lateNightCount / transactions.length) > 0.3;
  }

  static bool _hasDiningOutPattern(List<Transaction> transactions) {
    final diningCount = transactions
        .where((t) => t.category.toLowerCase().contains('restaurante') ||
                     t.category.toLowerCase().contains('comida') ||
                     t.category.toLowerCase().contains('delivery'))
        .length;
    return (diningCount / transactions.length) > 0.4;
  }

  static bool _hasImpulseCategories(List<Transaction> transactions) {
    final impulseCategories = ['ropa', 'entretenimiento', 'electronicos', 'compras_online'];
    final impulseCount = transactions
        .where((t) => impulseCategories.any((cat) => t.category.toLowerCase().contains(cat)))
        .length;
    return (impulseCount / transactions.length) > 0.3;
  }

  static bool _hasIncreasingTrend(List<Transaction> transactions) {
    if (transactions.length < 10) return false;
    
    final sortedTransactions = transactions.toList()..sort((a, b) => a.date.compareTo(b.date));
    final recentHalf = sortedTransactions.take(sortedTransactions.length ~/ 2).toList();
    final olderHalf = sortedTransactions.skip(sortedTransactions.length ~/ 2).toList();
    
    final recentAvg = recentHalf.fold(0.0, (sum, t) => sum + t.amount) / recentHalf.length;
    const olderAvg = olderHalf.fold(0.0, (sum, t) => sum + t.amount) / olderHalf.length;
    
    return recentAvg > olderAvg * 1.3; // 30% más alto indica tendencia creciente
  }

  Map<String, dynamic> toMap() {
    return {
      'impulseScore': impulseScore,
      'planningScore': planningScore,
      'consistencyScore': consistencyScore,
      'pattern': pattern.toString(),
      'riskLevel': riskLevel.toString(),
      'behaviorFlags': behaviorFlags,
      'lastAnalysis': lastAnalysis.toIso8601String(),
    };
  }

  factory SpendingBehavior.fromMap(Map<String, dynamic> map) {
    return SpendingBehavior(
      impulseScore: (map['impulseScore'] ?? 0.0).toDouble(),
      planningScore: (map['planningScore'] ?? 0.0).toDouble(),
      consistencyScore: (map['consistencyScore'] ?? 0.0).toDouble(),
      pattern: SpendingPattern.values.firstWhere(
        (e) => e.toString() == map['pattern'],
        orElse: () => SpendingPattern.moderate,
      ),
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.toString() == map['riskLevel'],
        orElse: () => RiskLevel.medium,
      ),
      behaviorFlags: List<String>.from(map['behaviorFlags'] ?? []),
      lastAnalysis: DateTime.parse(map['lastAnalysis'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Modelo para salud financiera general
class FinancialHealth {
  final double healthScore; // 0-100
  final double savingsRate; // Porcentaje ahorrado vs ingresos
  final double debtToIncomeRatio; // Ratio deuda/ingresos
  final double emergencyFundMonths; // Meses de emergencia cubiertos
  final bool hasEmergencyFund;
  final double monthlyBudgetAdherence; // % de adherencia al presupuesto
  final RiskLevel overallRisk;
  final List<String> healthFlags;
  final DateTime lastCalculation;

  FinancialHealth({
    required this.healthScore,
    required this.savingsRate,
    required this.debtToIncomeRatio,
    required this.emergencyFundMonths,
    required this.hasEmergencyFund,
    required this.monthlyBudgetAdherence,
    required this.overallRisk,
    required this.healthFlags,
    required this.lastCalculation,
  });

  Map<String, dynamic> toMap() {
    return {
      'healthScore': healthScore,
      'savingsRate': savingsRate,
      'debtToIncomeRatio': debtToIncomeRatio,
      'emergencyFundMonths': emergencyFundMonths,
      'hasEmergencyFund': hasEmergencyFund,
      'monthlyBudgetAdherence': monthlyBudgetAdherence,
      'overallRisk': overallRisk.toString(),
      'healthFlags': healthFlags,
      'lastCalculation': lastCalculation.toIso8601String(),
    };
  }

  factory FinancialHealth.fromMap(Map<String, dynamic> map) {
    return FinancialHealth(
      healthScore: (map['healthScore'] ?? 0.0).toDouble(),
      savingsRate: (map['savingsRate'] ?? 0.0).toDouble(),
      debtToIncomeRatio: (map['debtToIncomeRatio'] ?? 0.0).toDouble(),
      emergencyFundMonths: (map['emergencyFundMonths'] ?? 0.0).toDouble(),
      hasEmergencyFund: map['hasEmergencyFund'] ?? false,
      monthlyBudgetAdherence: (map['monthlyBudgetAdherence'] ?? 0.0).toDouble(),
      overallRisk: RiskLevel.values.firstWhere(
        (e) => e.toString() == map['overallRisk'],
        orElse: () => RiskLevel.medium,
      ),
      healthFlags: List<String>.from(map['healthFlags'] ?? []),
      lastCalculation: DateTime.parse(map['lastCalculation'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Modelo simplificado de transacción
class Transaction {
  final String id;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final bool isIncome;
  final String? location;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.isIncome,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'isIncome': isIncome,
      'location': location ?? '',
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      isIncome: map['isIncome'] ?? false,
      location: map['location'],
    );
  }
}