import 'financial_analysis_models.dart';

// Insights predictivos basados en ML
class PredictiveInsights {
  final double nextMonthPrediction;
  final double predictionConfidence; // 0-100%
  final List<CategoryPrediction> categoryPredictions;
  final List<TrendPrediction> trendPredictions;
  final List<RiskForecast> riskForecasts;
  final SavingsPrediction savingsPrediction;
  final CashFlowForecast cashFlowForecast;

  PredictiveInsights({
    required this.nextMonthPrediction,
    required this.predictionConfidence,
    required this.categoryPredictions,
    required this.trendPredictions,
    required this.riskForecasts,
    required this.savingsPrediction,
    required this.cashFlowForecast,
  });

  static PredictiveInsights analyze(List<Transaction> transactions) {
    return PredictiveInsights(
      nextMonthPrediction: _predictNextMonth(transactions),
      predictionConfidence: _calculatePredictionConfidence(transactions),
      categoryPredictions: _predictCategoryTrends(transactions),
      trendPredictions: _predictOverallTrends(transactions),
      riskForecasts: _forecastRisks(transactions),
      savingsPrediction: _predictSavings(transactions),
      cashFlowForecast: _forecastCashFlow(transactions),
    );
  }

  static double _predictNextMonth(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;
    
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    if (expenseTransactions.isEmpty) return 0.0;
    
    // Usar promedio móvil de los últimos 3 meses
    final monthlyTotals = _getMonthlyTotals(expenseTransactions);
    if (monthlyTotals.length < 2) return 0.0;
    
    final recentMonths = monthlyTotals.takeLast(3).toList();
    final weights = [0.2, 0.3, 0.5]; // Más peso al mes más reciente
    
    double weightedSum = 0;
    double totalWeight = 0;
    
    for (int i = 0; i < recentMonths.length; i++) {
      weightedSum += recentMonths[i] * weights[i];
      totalWeight += weights[i];
    }
    
    return totalWeight > 0 ? weightedSum / totalWeight : 0;
  }

  static double _calculatePredictionConfidence(List<Transaction> transactions) {
    if (transactions.length < 20) return 30.0;
    
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    final monthlyTotals = _getMonthlyTotals(expenseTransactions);
    
    if (monthlyTotals.length < 3) return 50.0;
    
    // Calcular varianza en gastos mensuales
    final mean = monthlyTotals.reduce((a, b) => a + b) / monthlyTotals.length;
    final variance = monthlyTotals.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / monthlyTotals.length;
    final coefficientOfVariation = mean > 0 ? (variance.sqrt() / mean) * 100 : 100;
    
    // Menor varianza = mayor confianza
    return (100 - coefficientOfVariation).clamp(30.0, 95.0);
  }

  static List<CategoryPrediction> _predictCategoryTrends(List<Transaction> transactions) {
    final categoryTotals = <String, List<double>>{};
    
    // Agrupar por categoría y mes
    for (final transaction in transactions.where((t) => !t.isIncome)) {
      final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? [])..add(transaction.amount);
    }
    
    final predictions = <CategoryPrediction>[];
    
    for (final entry in categoryTotals.entries) {
      if (entry.value.length >= 2) {
        final recentTrend = entry.value.takeLast(3).toList();
        final olderTrend = entry.value.skip((entry.value.length - 6).clamp(0, entry.value.length)).take(3).toList();
        
        final recentAvg = recentTrend.isEmpty ? 0 : recentTrend.reduce((a, b) => a + b) / recentTrend.length;
        const olderAvg = olderTrend.isEmpty ? 0 : olderTrend.reduce((a, b) => a + b) / olderTrend.length;
        
        final change = olderAvg > 0 ? ((recentAvg - olderAvg) / olderAvg) * 100 : 0;
        final predictedTrend = change > 10 ? TrendDirection.increasing : 
                               change < -10 ? TrendDirection.decreasing : TrendDirection.stable;
        
        predictions.add(CategoryPrediction(
          category: entry.key,
          predictedChange: change,
          predictedAmount: recentAvg * (1 + change / 100),
          confidence: entry.value.length >= 6 ? 80.0 : 60.0,
          trend: predictedTrend,
        ));
      }
    }
    
    return predictions;
  }

  static List<TrendPrediction> _predictOverallTrends(List<Transaction> transactions) {
    final predictions = <TrendPrediction>[];
    
    // Predicción de crecimiento anual
    final yearlyGrowth = _calculateYearlyGrowth(transactions);
    predictions.add(TrendPrediction(
      type: 'Crecimiento Anual',
      currentValue: yearlyGrowth['current'] ?? 0,
      predictedValue: yearlyGrowth['predicted'] ?? 0,
      confidence: yearlyGrowth['confidence'] ?? 70.0,
      timeframe: '12 meses',
    ));
    
    // Predicción de volatilidad
    final volatilityTrend = _calculateVolatilityTrend(transactions);
    predictions.add(TrendPrediction(
      type: 'Volatilidad de Gastos',
      currentValue: volatilityTrend['current'] ?? 0,
      predictedValue: volatilityTrend['predicted'] ?? 0,
      confidence: volatilityTrend['confidence'] ?? 65.0,
      timeframe: '6 meses',
    ));
    
    return predictions;
  }

  static List<RiskForecast> _forecastRisks(List<Transaction> transactions) {
    final forecasts = <RiskForecast>[];
    
    // Riesgo de sobregasto
    final overspendRisk = _calculateOverspendRisk(transactions);
    forecasts.add(RiskForecast(
      riskType: RiskType.overspending,
      probability: overspendRisk['probability'] ?? 0.3,
      impact: ImpactLevel.medium,
      timeframe: '30 días',
      mitigation: 'Establecer límites de gasto por categoría',
    ));
    
    // Riesgo de falta de liquidez
    final liquidityRisk = _calculateLiquidityRisk(transactions);
    forecasts.add(RiskForecast(
      riskType: RiskType.liquidity,
      probability: liquidityRisk['probability'] ?? 0.2,
      impact: ImpactLevel.high,
      timeframe: '45 días',
      mitigation: 'Mantener fondo de emergencia de 3 meses',
    ));
    
    // Riesgo de dependencia en una categoría
    final categoryRisk = _calculateCategoryDependencyRisk(transactions);
    forecasts.add(RiskForecast(
      riskType: RiskType.categoryDependency,
      probability: categoryRisk['probability'] ?? 0.4,
      impact: ImpactLevel.medium,
      timeframe: '60 días',
      mitigation: 'Diversificar gastos entre categorías',
    ));
    
    return forecasts;
  }

  static SavingsPrediction _predictSavings(List<Transaction> transactions) {
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    final incomeTransactions = transactions.where((t) => t.isIncome).toList();
    
    final totalExpenses = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);
    
    final monthlyExpenses = _getMonthlyAverage(expenseTransactions);
    final monthlyIncome = _getMonthlyAverage(incomeTransactions);
    
    final projectedSavings = monthlyIncome - monthlyExpenses;
    final savingsRate = monthlyIncome > 0 ? (projectedSavings / monthlyIncome) * 100 : 0;
    
    return SavingsPrediction(
      predictedMonthlySavings: projectedSavings,
      savingsRate: savingsRate,
      timeToEmergencyFund: _calculateTimeToEmergencyFund(projectedSavings),
      potentialYearlySavings: projectedSavings * 12,
      confidence: _calculatePredictionConfidence(transactions),
    );
  }

  static CashFlowForecast _forecastCashFlow(List<Transaction> transactions) {
    final incomeTransactions = transactions.where((t) => t.isIncome).toList();
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    
    final monthlyIncome = _getMonthlyAverage(incomeTransactions);
    final monthlyExpenses = _getMonthlyAverage(expenseTransactions);
    
    final netCashFlow = monthlyIncome - monthlyExpenses;
    
    // Proyectar 6 meses
    final projectedBalances = <double>[];
    double currentBalance = netCashFlow; // Asumir balance inicial = flujo mensual
    
    for (int i = 0; i < 6; i++) {
      currentBalance += netCashFlow;
      projectedBalances.add(currentBalance);
    }
    
    return CashFlowForecast(
      monthlyNetFlow: netCashFlow,
      projectedBalances: projectedBalances,
      cashFlowPattern: _analyzeCashFlowPattern(transactions),
      recommendations: _generateCashFlowRecommendations(netCashFlow, projectedBalances),
    );
  }

  // Métodos auxiliares
  static List<double> _getMonthlyTotals(List<Transaction> transactions) {
    final monthlyTotals = <String, double>{};
    
    for (final transaction in transactions) {
      final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + transaction.amount;
    }
    
    return monthlyTotals.values.toList()..sort();
  }

  static double _getMonthlyAverage(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;
    
    final monthlyTotals = _getMonthlyTotals(transactions);
    return monthlyTotals.isEmpty ? 0 : 
        monthlyTotals.reduce((a, b) => a + b) / monthlyTotals.length;
  }

  static Map<String, dynamic> _calculateYearlyGrowth(List<Transaction> transactions) {
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    final currentYear = DateTime.now().year;
    
    final currentYearTotals = expenseTransactions
        .where((t) => t.date.year == currentYear)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final previousYearTotals = expenseTransactions
        .where((t) => t.date.year == currentYear - 1)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final growthRate = previousYearTotals > 0 ? 
        ((currentYearTotals - previousYearTotals) / previousYearTotals) * 100 : 0;
    
    return {
      'current': currentYearTotals,
      'predicted': currentYearTotals * (1 + growthRate / 100),
      'confidence': 75.0,
    };
  }

  static Map<String, dynamic> _calculateVolatilityTrend(List<Transaction> transactions) {
    final monthlyTotals = _getMonthlyTotals(transactions.where((t) => !t.isIncome).toList());
    
    if (monthlyTotals.length < 3) {
      return {'current': 0, 'predicted': 0, 'confidence': 50.0};
    }
    
    final recentMonths = monthlyTotals.takeLast(3).toList();
    final currentVolatility = _calculateStandardDeviation(recentMonths);
    
    // Proyectar volatilidad (asumiendo tendencia estable)
    return {
      'current': currentVolatility,
      'predicted': currentVolatility * 1.1, // 10% de aumento
      'confidence': 65.0,
    };
  }

  static double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    return variance.sqrt();
  }

  static Map<String, dynamic> _calculateOverspendRisk(List<Transaction> transactions) {
    final monthlyTotals = _getMonthlyTotals(transactions.where((t) => !t.isIncome).toList());
    
    if (monthlyTotals.length < 3) {
      return {'probability': 0.3};
    }
    
    final recentMonths = monthlyTotals.takeLast(3).toList();
    final increasingMonths = _countIncreasingTrend(recentMonths);
    final probability = increasingMonths / recentMonths.length;
    
    return {'probability': probability};
  }

  static Map<String, dynamic> _calculateLiquidityRisk(List<Transaction> transactions) {
    // Simplificado: basado en ratio gastos/ingresos
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    final incomeTransactions = transactions.where((t) => t.isIncome).toList();
    
    final monthlyExpenses = _getMonthlyAverage(expenseTransactions);
    final monthlyIncome = _getMonthlyAverage(incomeTransactions);
    
    final expenseRatio = monthlyIncome > 0 ? monthlyExpenses / monthlyIncome : 1;
    final probability = expenseRatio > 0.9 ? 0.7 : expenseRatio > 0.8 ? 0.4 : 0.1;
    
    return {'probability': probability};
  }

  static Map<String, dynamic> _calculateCategoryDependencyRisk(List<Transaction> transactions) {
    final categoryTotals = <String, double>{};
    
    for (final transaction in transactions.where((t) => !t.isIncome)) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }
    
    if (categoryTotals.isEmpty) {
      return {'probability': 0.2};
    }
    
    final totalSpent = categoryTotals.values.reduce((a, b) => a + b);
    final maxCategoryAmount = categoryTotals.values.reduce((a, b) => a > b ? a : b);
    final dependencyRatio = maxCategoryAmount / totalSpent;
    
    final probability = dependencyRatio > 0.5 ? 0.6 : dependencyRatio > 0.4 ? 0.3 : 0.1;
    
    return {'probability': probability};
  }

  static int _countIncreasingTrend(List<double> values) {
    if (values.length < 2) return 0;
    
    int increasingCount = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[i-1] * 1.1) { // 10% de aumento
        increasingCount++;
      }
    }
    return increasingCount;
  }

  static double _calculateTimeToEmergencyFund(double monthlySavings) {
    if (monthlySavings <= 0) return double.infinity;
    
    final emergencyFundTarget = 3; // 3 meses de gastos (asumiendo gastos = ahorros * 2)
    return emergencyFundTarget / (monthlySavings / (monthlySavings * 2));
  }

  static CashFlowPattern _analyzeCashFlowPattern(List<Transaction> transactions) {
    final incomeTransactions = transactions.where((t) => t.isIncome).toList();
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    
    final incomeDays = <int>{};
    final expenseDays = <int>{};
    
    for (final transaction in incomeTransactions) {
      incomeDays.add(transaction.date.day);
    }
    
    for (final transaction in expenseTransactions) {
      expenseDays.add(transaction.date.day);
    }
    
    // Analizar concentración de ingresos vs gastos
    final incomeConcentration = incomeDays.length / 31.0;
    final expenseDistribution = expenseDays.length / 31.0;
    
    if (incomeConcentration < 0.3) {
      return CashFlowPattern.concentratedIncome;
    } else if (expenseDistribution > 0.8) {
      return CashFlowPattern.evenExpenses;
    } else {
      return CashFlowPattern.normal;
    }
  }

  static List<String> _generateCashFlowRecommendations(double netFlow, List<double> balances) {
    final recommendations = <String>[];
    
    if (netFlow < 0) {
      recommendations.add('Reducir gastos para mejorar flujo de efectivo');
    } else if (netFlow > 500) {
      recommendations.add('Considerar aumentar ahorro o inversión con exceso de flujo');
    }
    
    if (balances.any((balance) => balance < 0)) {
      recommendations.add('Planificar mejor la distribución de gastos');
    }
    
    return recommendations;
  }

  Map<String, dynamic> toMap() {
    return {
      'nextMonthPrediction': nextMonthPrediction,
      'predictionConfidence': predictionConfidence,
      'categoryPredictions': categoryPredictions.map((p) => p.toMap()).toList(),
      'trendPredictions': trendPredictions.map((p) => p.toMap()).toList(),
      'riskForecasts': riskForecasts.map((r) => r.toMap()).toList(),
      'savingsPrediction': savingsPrediction.toMap(),
      'cashFlowForecast': cashFlowForecast.toMap(),
    };
  }

  factory PredictiveInsights.fromMap(Map<String, dynamic> map) {
    return PredictiveInsights(
      nextMonthPrediction: (map['nextMonthPrediction'] ?? 0.0).toDouble(),
      predictionConfidence: (map['predictionConfidence'] ?? 0.0).toDouble(),
      categoryPredictions: (map['categoryPredictions'] as List<dynamic>?)
          ?.map((data) => CategoryPrediction.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      trendPredictions: (map['trendPredictions'] as List<dynamic>?)
          ?.map((data) => TrendPrediction.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      riskForecasts: (map['riskForecasts'] as List<dynamic>?)
          ?.map((data) => RiskForecast.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      savingsPrediction: SavingsPrediction.fromMap(map['savingsPrediction'] ?? {}),
      cashFlowForecast: CashFlowForecast.fromMap(map['cashFlowForecast'] ?? {}),
    );
  }
}

// Predicción por categoría
class CategoryPrediction {
  final String category;
  final double predictedChange; // Porcentaje de cambio
  final double predictedAmount;
  final double confidence; // 0-100%
  final TrendDirection trend;

  CategoryPrediction({
    required this.category,
    required this.predictedChange,
    required this.predictedAmount,
    required this.confidence,
    required this.trend,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'predictedChange': predictedChange,
      'predictedAmount': predictedAmount,
      'confidence': confidence,
      'trend': trend.toString(),
    };
  }

  factory CategoryPrediction.fromMap(Map<String, dynamic> map) {
    return CategoryPrediction(
      category: map['category'] ?? '',
      predictedChange: (map['predictedChange'] ?? 0.0).toDouble(),
      predictedAmount: (map['predictedAmount'] ?? 0.0).toDouble(),
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      trend: TrendDirection.values.firstWhere(
        (e) => e.toString() == map['trend'],
        orElse: () => TrendDirection.stable,
      ),
    );
  }
}

// Predicción de tendencias
class TrendPrediction {
  final String type;
  final double currentValue;
  final double predictedValue;
  final double confidence;
  final String timeframe;

  TrendPrediction({
    required this.type,
    required this.currentValue,
    required this.predictedValue,
    required this.confidence,
    required this.timeframe,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'currentValue': currentValue,
      'predictedValue': predictedValue,
      'confidence': confidence,
      'timeframe': timeframe,
    };
  }

  factory TrendPrediction.fromMap(Map<String, dynamic> map) {
    return TrendPrediction(
      type: map['type'] ?? '',
      currentValue: (map['currentValue'] ?? 0.0).toDouble(),
      predictedValue: (map['predictedValue'] ?? 0.0).toDouble(),
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      timeframe: map['timeframe'] ?? '',
    );
  }
}

// Forecast de riesgos
class RiskForecast {
  final RiskType riskType;
  final double probability; // 0-1
  final ImpactLevel impact;
  final String timeframe;
  final String mitigation;

  RiskForecast({
    required this.riskType,
    required this.probability,
    required this.impact,
    required this.timeframe,
    required this.mitigation,
  });

  Map<String, dynamic> toMap() {
    return {
      'riskType': riskType.toString(),
      'probability': probability,
      'impact': impact.toString(),
      'timeframe': timeframe,
      'mitigation': mitigation,
    };
  }

  factory RiskForecast.fromMap(Map<String, dynamic> map) {
    return RiskForecast(
      riskType: RiskType.values.firstWhere(
        (e) => e.toString() == map['riskType'],
        orElse: () => RiskType.general,
      ),
      probability: (map['probability'] ?? 0.0).toDouble(),
      impact: ImpactLevel.values.firstWhere(
        (e) => e.toString() == map['impact'],
        orElse: () => ImpactLevel.medium,
      ),
      timeframe: map['timeframe'] ?? '',
      mitigation: map['mitigation'] ?? '',
    );
  }
}

// Predicción de ahorros
class SavingsPrediction {
  final double predictedMonthlySavings;
  final double savingsRate; // Porcentaje
  final double timeToEmergencyFund; // Meses
  final double potentialYearlySavings;
  final double confidence;

  SavingsPrediction({
    required this.predictedMonthlySavings,
    required this.savingsRate,
    required this.timeToEmergencyFund,
    required this.potentialYearlySavings,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'predictedMonthlySavings': predictedMonthlySavings,
      'savingsRate': savingsRate,
      'timeToEmergencyFund': timeToEmergencyFund,
      'potentialYearlySavings': potentialYearlySavings,
      'confidence': confidence,
    };
  }

  factory SavingsPrediction.fromMap(Map<String, dynamic> map) {
    return SavingsPrediction(
      predictedMonthlySavings: (map['predictedMonthlySavings'] ?? 0.0).toDouble(),
      savingsRate: (map['savingsRate'] ?? 0.0).toDouble(),
      timeToEmergencyFund: (map['timeToEmergencyFund'] ?? 0.0).toDouble(),
      potentialYearlySavings: (map['potentialYearlySavings'] ?? 0.0).toDouble(),
      confidence: (map['confidence'] ?? 0.0).toDouble(),
    );
  }
}

// Forecast de flujo de efectivo
class CashFlowForecast {
  final double monthlyNetFlow;
  final List<double> projectedBalances;
  final CashFlowPattern cashFlowPattern;
  final List<String> recommendations;

  CashFlowForecast({
    required this.monthlyNetFlow,
    required this.projectedBalances,
    required this.cashFlowPattern,
    required this.recommendations,
  });

  Map<String, dynamic> toMap() {
    return {
      'monthlyNetFlow': monthlyNetFlow,
      'projectedBalances': projectedBalances,
      'cashFlowPattern': cashFlowPattern.toString(),
      'recommendations': recommendations,
    };
  }

  factory CashFlowForecast.fromMap(Map<String, dynamic> map) {
    return CashFlowForecast(
      monthlyNetFlow: (map['monthlyNetFlow'] ?? 0.0).toDouble(),
      projectedBalances: List<double>.from(map['projectedBalances'] ?? []),
      cashFlowPattern: CashFlowPattern.values.firstWhere(
        (e) => e.toString() == map['cashFlowPattern'],
        orElse: () => CashFlowPattern.normal,
      ),
      recommendations: List<String>.from(map['recommendations'] ?? []),
    );
  }
}

// Enums adicionales para insights predictivos
enum RiskType {
  general,
  overspending,
  liquidity,
  categoryDependency,
  inflation,
  incomeLoss
}

enum CashFlowPattern {
  normal,
  concentratedIncome,
  evenExpenses,
  irregular
}