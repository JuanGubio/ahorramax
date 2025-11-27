import 'financial_analysis_models.dart';
import 'trends_analysis_models.dart';

// Análisis detallado por categorías
class CategoryAnalysis {
  final List<CategoryBreakdown> categoryBreakdowns;
  final CategoryComparison comparison;
  final SavingsOpportunities savingsOpportunities;
  final SpendingOptimization optimization;

  CategoryAnalysis({
    required this.categoryBreakdowns,
    required this.comparison,
    required this.savingsOpportunities,
    required this.optimization,
  });

  static CategoryAnalysis analyze(List<Transaction> transactions) {
    return CategoryAnalysis(
      categoryBreakdowns: CategoryBreakdown.analyzeAll(transactions),
      comparison: CategoryComparison.analyze(transactions),
      savingsOpportunities: SavingsOpportunities.identify(transactions),
      spendingOptimization: SpendingOptimization.suggest(transactions),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryBreakdowns': categoryBreakdowns.map((c) => c.toMap()).toList(),
      'comparison': comparison.toMap(),
      'savingsOpportunities': savingsOpportunities.toMap(),
      'spendingOptimization': optimization.toMap(),
    };
  }

  factory CategoryAnalysis.fromMap(Map<String, dynamic> map) {
    return CategoryAnalysis(
      categoryBreakdowns: (map['categoryBreakdowns'] as List<dynamic>?)
          ?.map((data) => CategoryBreakdown.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      comparison: CategoryComparison.fromMap(map['comparison'] ?? {}),
      savingsOpportunities: SavingsOpportunities.fromMap(map['savingsOpportunities'] ?? {}),
      spendingOptimization: SpendingOptimization.fromMap(map['spendingOptimization'] ?? {}),
    );
  }
}

// Desglose detallado por categoría
class CategoryBreakdown {
  final String categoryName;
  final double totalSpent;
  final double percentageOfTotal;
  final int transactionCount;
  final double averageTransactionAmount;
  final List<Transaction> topTransactions;
  final SpendingPattern pattern;
  final List<String> insights;
  final double monthlyAverage;
  final TrendDirection trend;

  CategoryBreakdown({
    required this.categoryName,
    required this.totalSpent,
    required this.percentageOfTotal,
    required this.transactionCount,
    required this.averageTransactionAmount,
    required this.topTransactions,
    required this.pattern,
    required this.insights,
    required this.monthlyAverage,
    required this.trend,
  });

  static List<CategoryBreakdown> analyzeAll(List<Transaction> transactions) {
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    final totalSpent = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
    
    final categoryTotals = <String, List<Transaction>>{};
    
    // Agrupar transacciones por categoría
    for (final transaction in expenseTransactions) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? [])..add(transaction);
    }

    return categoryTotals.entries.map((entry) {
      final categoryTransactions = entry.value;
      final categoryTotal = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final percentage = totalSpent > 0 ? (categoryTotal / totalSpent) * 100 : 0;
      
      // Calcular promedio mensual (asumiendo 30 días por mes)
      final daysInData = _getDaysRange(categoryTransactions);
      final monthlyAverage = daysInData > 0 ? (categoryTotal / (daysInData / 30)) : 0;
      
      // Ordenar transacciones por monto y tomar las top 5
      final topTransactions = categoryTransactions
        ..sort((a, b) => b.amount.compareTo(a.amount))
        ..take(5)
        .toList();

      return CategoryBreakdown(
        categoryName: entry.key,
        totalSpent: categoryTotal,
        percentageOfTotal: percentage,
        transactionCount: categoryTransactions.length,
        averageTransactionAmount: categoryTransactions.isEmpty ? 0 : 
            categoryTotal / categoryTransactions.length,
        topTransactions: topTransactions,
        pattern: _analyzeCategoryPattern(categoryTransactions),
        insights: _generateCategoryInsights(entry.key, categoryTransactions, categoryTotal, totalSpent),
        monthlyAverage: monthlyAverage,
        trend: _calculateCategoryTrend(categoryTransactions),
      );
    }).toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
  }

  static int _getDaysRange(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0;
    
    final sorted = transactions.toList()..sort((a, b) => a.date.compareTo(b.date));
    return sorted.first.date.difference(sorted.last.date).inDays.abs() + 1;
  }

  static SpendingPattern _analyzeCategoryPattern(List<Transaction> transactions) {
    if (transactions.isEmpty) return SpendingPattern.moderate;
    
    final amounts = transactions.map((t) => t.amount).toList();
    final variance = _calculateVariance(amounts);
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    final coefficientOfVariation = mean > 0 ? (variance.sqrt() / mean) * 100 : 0;
    
    if (coefficientOfVariation > 100) return SpendingPattern.irregular;
    if (coefficientOfVariation < 30 && mean < 20) return SpendingPattern.conservative;
    if (coefficientOfVariation > 60 && mean > 50) return SpendingPattern.aggressive;
    return SpendingPattern.moderate;
  }

  static double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((x) => (x - mean) * (x - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  static List<String> _generateCategoryInsights(String category, List<Transaction> transactions, 
      double totalSpent, double grandTotal) {
    final insights = <String>[];
    
    if (transactions.isEmpty) return insights;
    
    final percentage = (totalSpent / grandTotal) * 100;
    final avgAmount = transactions.fold(0.0, (sum, t) => sum + t.amount) / transactions.length;
    
    // Insights basados en porcentaje
    if (percentage > 40) {
      insights.add('Esta categoría representa casi la mitad de tus gastos');
    } else if (percentage > 25) {
      insights.add('Gasto significativo en esta categoría');
    } else if (percentage < 5) {
      insights.add('Gasto controlado en esta categoría');
    }
    
    // Insights basados en patrones
    final hourlyDistribution = <int, int>{};
    for (final transaction in transactions) {
      hourlyDistribution[transaction.date.hour] = 
          (hourlyDistribution[transaction.date.hour] ?? 0) + 1;
    }
    
    final peakHour = hourlyDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    if (peakHour < 7 || peakHour > 22) {
      insights.add('La mayoría de gastos en esta categoría son en horarios inusuales');
    }
    
    // Insights específicos por categoría
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('comida') || lowerCategory.contains('restaurante')) {
      if (transactions.length > 20) {
        insights.add('Alta frecuencia de gastos en restaurantes - considera cocinar más');
      }
    } else if (lowerCategory.contains('transporte')) {
      if (avgAmount > 15) {
        insights.add('Gastos altos en transporte - evalúa alternativas más económicas');
      }
    } else if (lowerCategory.contains('ropa') || lowerCategory.contains('compras')) {
      if (transactions.length > 10) {
        insights.add('Compras frecuentes - verifica si son necesarias');
      }
    }
    
    return insights;
  }

  static TrendDirection _calculateCategoryTrend(List<Transaction> transactions) {
    if (transactions.length < 6) return TrendDirection.stable;
    
    final sorted = transactions.toList()..sort((a, b) => a.date.compareTo(b.date));
    final midPoint = sorted.length ~/ 2;
    
    final firstHalf = sorted.take(midPoint).toList();
    final secondHalf = sorted.skip(midPoint).toList();
    
    final firstHalfAvg = firstHalf.isEmpty ? 0 : 
        firstHalf.fold(0.0, (sum, t) => sum + t.amount) / firstHalf.length;
    const secondHalfAvg = secondHalf.isEmpty ? 0 :
        secondHalf.fold(0.0, (sum, t) => sum + t.amount) / secondHalf.length;
    
    final change = firstHalfAvg > 0 ? ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100 : 0;
    
    if (change > 15) return TrendDirection.increasing;
    if (change < -15) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'totalSpent': totalSpent,
      'percentageOfTotal': percentageOfTotal,
      'transactionCount': transactionCount,
      'averageTransactionAmount': averageTransactionAmount,
      'topTransactions': topTransactions.map((t) => t.toMap()).toList(),
      'pattern': pattern.toString(),
      'insights': insights,
      'monthlyAverage': monthlyAverage,
      'trend': trend.toString(),
    };
  }

  factory CategoryBreakdown.fromMap(Map<String, dynamic> map) {
    return CategoryBreakdown(
      categoryName: map['categoryName'] ?? '',
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
      percentageOfTotal: (map['percentageOfTotal'] ?? 0.0).toDouble(),
      transactionCount: map['transactionCount'] ?? 0,
      averageTransactionAmount: (map['averageTransactionAmount'] ?? 0.0).toDouble(),
      topTransactions: (map['topTransactions'] as List<dynamic>?)
          ?.map((data) => Transaction.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      pattern: SpendingPattern.values.firstWhere(
        (e) => e.toString() == map['pattern'],
        orElse: () => SpendingPattern.moderate,
      ),
      insights: List<String>.from(map['insights'] ?? []),
      monthlyAverage: (map['monthlyAverage'] ?? 0.0).toDouble(),
      trend: TrendDirection.values.firstWhere(
        (e) => e.toString() == map['trend'],
        orElse: () => TrendDirection.stable,
      ),
    );
  }
}

// Comparación entre categorías
class CategoryComparison {
  final List<CategoryComparisonItem> comparisons;
  final String topSpenderCategory;
  final String mostFrequentCategory;
  final String mostExpensiveCategory;
  final List<String> recommendations;

  CategoryComparison({
    required this.comparisons,
    required this.topSpenderCategory,
    required this.mostFrequentCategory,
    required this.mostExpensiveCategory,
    required this.recommendations,
  });

  static CategoryComparison analyze(List<Transaction> transactions) {
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    
    final categoryStats = <String, CategoryStats>{};
    
    // Calcular estadísticas por categoría
    for (final transaction in expenseTransactions) {
      final category = transaction.category;
      if (!categoryStats.containsKey(category)) {
        categoryStats[category] = CategoryStats();
      }
      categoryStats[category]!.addTransaction(transaction);
    }
    
    // Generar comparaciones entre categorías principales
    final topCategories = categoryStats.entries
        .toList()
        ..sort((a, b) => b.value.totalSpent.compareTo(a.value.totalSpent))
        ..take(5);
    
    final comparisons = <CategoryComparisonItem>[];
    
    for (int i = 0; i < topCategories.length - 1; i++) {
      for (int j = i + 1; j < topCategories.length; j++) {
        comparisons.add(CategoryComparisonItem(
          category1: topCategories.elementAt(i).key,
          category2: topCategories.elementAt(j).key,
          difference: topCategories.elementAt(i).value.totalSpent - topCategories.elementAt(j).value.totalSpent,
          percentageDifference: _calculatePercentageDifference(
            topCategories.elementAt(i).value.totalSpent,
            topCategories.elementAt(j).value.totalSpent
          ),
          insight: _generateComparisonInsight(
            topCategories.elementAt(i).key,
            topCategories.elementAt(j).key,
            topCategories.elementAt(i).value.totalSpent,
            topCategories.elementAt(j).value.totalSpent
          ),
        ));
      }
    }
    
    // Encontrar categorías destacadas
    final sortedByTotal = categoryStats.entries.toList()
        ..sort((a, b) => b.value.totalSpent.compareTo(a.value.totalSpent));
    final sortedByFrequency = categoryStats.entries.toList()
        ..sort((a, b) => b.value.transactionCount.compareTo(a.value.transactionCount));
    final sortedByAverage = categoryStats.entries.toList()
        ..sort((a, b) => b.value.averageAmount.compareTo(a.value.averageAmount));
    
    final topSpenderCategory = sortedByTotal.isEmpty ? '' : sortedByTotal.first.key;
    final mostFrequentCategory = sortedByFrequency.isEmpty ? '' : sortedByFrequency.first.key;
    final mostExpensiveCategory = sortedByAverage.isEmpty ? '' : sortedByAverage.first.key;
    
    // Generar recomendaciones
    final recommendations = _generateComparisonRecommendations(categoryStats);
    
    return CategoryComparison(
      comparisons: comparisons,
      topSpenderCategory: topSpenderCategory,
      mostFrequentCategory: mostFrequentCategory,
      mostExpensiveCategory: mostExpensiveCategory,
      recommendations: recommendations,
    );
  }

  static double _calculatePercentageDifference(double amount1, double amount2) {
    final base = amount1 > amount2 ? amount2 : amount1;
    if (base == 0) return 0;
    return ((amount1 - amount2) / base) * 100;
  }

  static String _generateComparisonInsight(String cat1, String cat2, double amount1, double amount2) {
    final diff = amount1 - amount2;
    final higher = amount1 > amount2 ? cat1 : cat2;
    final lower = amount1 > amount2 ? cat2 : cat1;
    
    return 'Gastas ${diff.toStringAsFixed(2)} más en $higher que en $lower';
  }

  static List<String> _generateComparisonRecommendations(Map<String, CategoryStats> stats) {
    final recommendations = <String>[];
    
    final topSpender = stats.entries
        .reduce((a, b) => a.value.totalSpent > b.value.totalSpent ? a : b);
    
    if (topSpender.value.totalSpent > 1000) {
      recommendations.add('Tu categoría principal ($topSpender.key) representa gastos significativos. Considera establecer un presupuesto específico.');
    }
    
    final lowFrequencyCategories = stats.entries
        .where((e) => e.value.transactionCount < 3)
        .toList();
    
    if (lowFrequencyCategories.length > stats.length * 0.5) {
      recommendations.add('Tienes muchas categorías con pocos gastos. Considera consolidar o revisar gastos menores.');
    }
    
    return recommendations;
  }

  Map<String, dynamic> toMap() {
    return {
      'comparisons': comparisons.map((c) => c.toMap()).toList(),
      'topSpenderCategory': topSpenderCategory,
      'mostFrequentCategory': mostFrequentCategory,
      'mostExpensiveCategory': mostExpensiveCategory,
      'recommendations': recommendations,
    };
  }

  factory CategoryComparison.fromMap(Map<String, dynamic> map) {
    return CategoryComparison(
      comparisons: (map['comparisons'] as List<dynamic>?)
          ?.map((data) => CategoryComparisonItem.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      topSpenderCategory: map['topSpenderCategory'] ?? '',
      mostFrequentCategory: map['mostFrequentCategory'] ?? '',
      mostExpensiveCategory: map['mostExpensiveCategory'] ?? '',
      recommendations: List<String>.from(map['recommendations'] ?? []),
    );
  }
}

// Estadísticas de categoría para cálculos internos
class CategoryStats {
  double totalSpent = 0;
  int transactionCount = 0;
  double totalAmount = 0;
  double averageAmount = 0;
  
  void addTransaction(Transaction transaction) {
    totalSpent += transaction.amount;
    transactionCount++;
    totalAmount += transaction.amount;
    averageAmount = transactionCount > 0 ? totalAmount / transactionCount : 0;
  }
}

// Item de comparación entre categorías
class CategoryComparisonItem {
  final String category1;
  final String category2;
  final double difference;
  final double percentageDifference;
  final String insight;

  CategoryComparisonItem({
    required this.category1,
    required this.category2,
    required this.difference,
    required this.percentageDifference,
    required this.insight,
  });

  Map<String, dynamic> toMap() {
    return {
      'category1': category1,
      'category2': category2,
      'difference': difference,
      'percentageDifference': percentageDifference,
      'insight': insight,
    };
  }

  factory CategoryComparisonItem.fromMap(Map<String, dynamic> map) {
    return CategoryComparisonItem(
      category1: map['category1'] ?? '',
      category2: map['category2'] ?? '',
      difference: (map['difference'] ?? 0.0).toDouble(),
      percentageDifference: (map['percentageDifference'] ?? 0.0).toDouble(),
      insight: map['insight'] ?? '',
    );
  }
}

// Oportunidades de ahorro identificadas
class SavingsOpportunities {
  final List<SavingsOpportunity> identifiedOpportunities;
  final double totalPotentialSavings;
  final List<String> quickWins;
  final List<String> longTermStrategies;

  SavingsOpportunities({
    required this.identifiedOpportunities,
    required this.totalPotentialSavings,
    required this.quickWins,
    required this.longTermStrategies,
  });

  static SavingsOpportunities identify(List<Transaction> transactions) {
    final opportunities = <SavingsOpportunity>[];
    final quickWins = <String>[];
    final longTermStrategies = <String>[];
    
    double totalPotential = 0;
    
    // Identificar oportunidades por categoría
    final categoryTotals = <String, double>{};
    final categoryTransactions = <String, List<Transaction>>{};
    
    for (final transaction in transactions.where((t) => !t.isIncome)) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      categoryTransactions[transaction.category] = 
          (categoryTransactions[transaction.category] ?? [])..add(transaction);
    }
    
    // Oportunidades en alimentación
    final foodOpportunities = _identifyFoodSavings(categoryTransactions['alimentacion'] ?? []);
    opportunities.addAll(foodOpportunities);
    
    // Oportunidades en transporte
    final transportOpportunities = _identifyTransportSavings(categoryTransactions['transporte'] ?? []);
    opportunities.addAll(transportOpportunities);
    
    // Oportunidades en entretenimiento
    final entertainmentOpportunities = _identifyEntertainmentSavings(categoryTransactions['entretenimiento'] ?? []);
    opportunities.addAll(entertainmentOpportunities);
    
    // Oportunidades en suscripciones
    final subscriptionOpportunities = _identifySubscriptionSavings(transactions);
    opportunities.addAll(subscriptionOpportunities);
    
    // Calcular potencial total de ahorro
    totalPotential = opportunities.fold(0.0, (sum, opp) => sum + opp.potentialMonthlySavings);
    
    // Generar quick wins y estrategias a largo plazo
    quickWins.addAll(_generateQuickWins(opportunities));
    longTermStrategies.addAll(_generateLongTermStrategies(opportunities));
    
    return SavingsOpportunities(
      identifiedOpportunities: opportunities,
      totalPotentialSavings: totalPotential,
      quickWins: quickWins,
      longTermStrategies: longTermStrategies,
    );
  }

  static List<SavingsOpportunity> _identifyFoodSavings(List<Transaction> transactions) {
    final opportunities = <SavingsOpportunity>[];
    
    if (transactions.isEmpty) return opportunities;
    
    final totalFoodSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final restaurantTransactions = transactions
        .where((t) => t.description.toLowerCase().contains('restaurante') ||
                     t.description.toLowerCase().contains('delivery') ||
                     t.description.toLowerCase().contains('comida_rapida'))
        .toList();
    
    final restaurantSpending = restaurantTransactions.fold(0.0, (sum, t) => sum + t.amount);
    
    if (restaurantSpending > totalFoodSpent * 0.3) {
      opportunities.add(SavingsOpportunity(
        category: 'Alimentación',
        title: 'Reducir gastos en restaurantes',
        description: 'Los gastos en restaurantes representan ${(restaurantSpending/totalFoodSpent*100).toStringAsFixed(1)}% de tu alimentación',
        potentialMonthlySavings: restaurantSpending * 0.4, // Ahorrar 40%
        effortLevel: EffortLevel.medium,
        timeframe: Timeframe.shortTerm,
        actionableSteps: [
          'Cocinar en casa 4 veces por semana',
          'Preparar almuerzos para el trabajo',
          'Usar apps de descuentos para restaurantes',
          'Planificar menús semanales'
        ],
      ));
    }
    
    return opportunities;
  }

  static List<SavingsOpportunity> _identifyTransportSavings(List<Transaction> transactions) {
    final opportunities = <SavingsOpportunity>[];
    
    if (transactions.isEmpty) return opportunities;
    
    final totalTransportSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final taxiTransactions = transactions
        .where((t) => t.description.toLowerCase().contains('taxi') ||
                     t.description.toLowerCase().contains('uber') ||
                     t.description.toLowerCase().contains('cabify'))
        .toList();
    
    final taxiSpending = taxiTransactions.fold(0.0, (sum, t) => sum + t.amount);
    
    if (taxiSpending > 100) {
      opportunities.add(SavingsOpportunity(
        category: 'Transporte',
        title: 'Optimizar gastos en taxi/ride-sharing',
        description: 'Los gastos en taxi representan ${(taxiSpending/totalTransportSpent*100).toStringAsFixed(1)}% de tu transporte',
        potentialMonthlySavings: taxiSpending * 0.6, // Ahorrar 60%
        effortLevel: EffortLevel.medium,
        timeframe: Timeframe.mediumTerm,
        actionableSteps: [
          'Usar transporte público para trayectos regulares',
          'Compartir viajes (carpool)',
          'Caminar o usar bicicleta para distancias cortas',
          'Planificar rutas para optimizar viajes'
        ],
      ));
    }
    
    return opportunities;
  }

  static List<SavingsOpportunity> _identifyEntertainmentSavings(List<Transaction> transactions) {
    final opportunities = <SavingsOpportunity>[];
    
    if (transactions.isEmpty) return opportunities;
    
    final totalEntertainmentSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
    
    if (totalEntertainmentSpent > 200) {
      opportunities.add(SavingsOpportunity(
        category: 'Entretenimiento',
        title: 'Reducir gastos en entretenimiento',
        description: 'Los gastos en entretenimiento son elevados: \$${totalEntertainmentSpent.toStringAsFixed(2)} mensuales',
        potentialMonthlySavings: totalEntertainmentSpent * 0.3, // Ahorrar 30%
        effortLevel: EffortLevel.low,
        timeframe: Timeframe.shortTerm,
        actionableSteps: [
          'Buscar eventos gratuitos en la ciudad',
          'Aprovechar ofertas y descuentos',
          'Usar bibliotecas y espacios públicos',
          'Organizar actividades en casa con amigos'
        ],
      ));
    }
    
    return opportunities;
  }

  static List<SavingsOpportunity> _identifySubscriptionSavings(List<Transaction> transactions) {
    final opportunities = <SavingsOpportunity>[];
    
    // Buscar suscripciones repetitivas
    final subscriptionPatterns = <String, List<Transaction>>{};
    
    for (final transaction in transactions.where((t) => !t.isIncome)) {
      final lowerDescription = transaction.description.toLowerCase();
      if (lowerDescription.contains('netflix') ||
          lowerDescription.contains('spotify') ||
          lowerDescription.contains('amazon prime') ||
          lowerDescription.contains('suscripcion') ||
          lowerDescription.contains('monthly')) {
        
        final key = _extractSubscriptionKey(transaction.description);
        subscriptionPatterns[key] = (subscriptionPatterns[key] ?? [])..add(transaction);
      }
    }
    
    // Analizar suscripciones activas
    for (final entry in subscriptionPatterns.entries) {
      final transactions = entry.value;
      if (transactions.length >= 2) { // Al menos 2 meses de suscripción
        final monthlyAmount = transactions.first.amount;
        final totalSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
        
        opportunities.add(SavingsOpportunity(
          category: 'Suscripciones',
          title: 'Revisar suscripción ${entry.key}',
          description: 'Suscripción activa por \$${monthlyAmount.toStringAsFixed(2)} mensuales',
          potentialMonthlySavings: monthlyAmount * 0.1, // Ahorrar 10%
          effortLevel: EffortLevel.low,
          timeframe: Timeframe.shortTerm,
          actionableSteps: [
            'Evaluar uso real de la suscripción',
            'Buscar planes más económicos',
            'Cancelar suscripciones no utilizadas',
            'Compartir suscripciones familiares'
          ],
        ));
      }
    }
    
    return opportunities;
  }

  static String _extractSubscriptionKey(String description) {
    final lower = description.toLowerCase();
    if (lower.contains('netflix')) return 'Netflix';
    if (lower.contains('spotify')) return 'Spotify';
    if (lower.contains('amazon')) return 'Amazon Prime';
    if (lower.contains('disney')) return 'Disney+';
    return 'Suscripción General';
  }

  static List<String> _generateQuickWins(List<SavingsOpportunity> opportunities) {
    return opportunities
        .where((opp) => opp.effortLevel == EffortLevel.low)
        .take(3)
        .map((opp) => '🎯 ${opp.title}: Ahorra \$${opp.potentialMonthlySavings.toStringAsFixed(2)}/mes')
        .toList();
  }

  static List<String> _generateLongTermStrategies(List<SavingsOpportunity> opportunities) {
    return opportunities
        .where((opp) => opp.timeframe == Timeframe.longTerm)
        .take(2)
        .map((opp) => '📈 ${opp.title}: Estrategia a largo plazo para \$${opp.potentialMonthlySavings.toStringAsFixed(2)}/mes')
        .toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'identifiedOpportunities': identifiedOpportunities.map((opp) => opp.toMap()).toList(),
      'totalPotentialSavings': totalPotentialSavings,
      'quickWins': quickWins,
      'longTermStrategies': longTermStrategies,
    };
  }

  factory SavingsOpportunities.fromMap(Map<String, dynamic> map) {
    return SavingsOpportunities(
      identifiedOpportunities: (map['identifiedOpportunities'] as List<dynamic>?)
          ?.map((data) => SavingsOpportunity.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      totalPotentialSavings: (map['totalPotentialSavings'] ?? 0.0).toDouble(),
      quickWins: List<String>.from(map['quickWins'] ?? []),
      longTermStrategies: List<String>.from(map['longTermStrategies'] ?? []),
    );
  }
}

// Oportunidad de ahorro específica
class SavingsOpportunity {
  final String category;
  final String title;
  final String description;
  final double potentialMonthlySavings;
  final EffortLevel effortLevel;
  final Timeframe timeframe;
  final List<String> actionableSteps;

  SavingsOpportunity({
    required this.category,
    required this.title,
    required this.description,
    required this.potentialMonthlySavings,
    required this.effortLevel,
    required this.timeframe,
    required this.actionableSteps,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'potentialMonthlySavings': potentialMonthlySavings,
      'effortLevel': effortLevel.toString(),
      'timeframe': timeframe.toString(),
      'actionableSteps': actionableSteps,
    };
  }

  factory SavingsOpportunity.fromMap(Map<String, dynamic> map) {
    return SavingsOpportunity(
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      potentialMonthlySavings: (map['potentialMonthlySavings'] ?? 0.0).toDouble(),
      effortLevel: EffortLevel.values.firstWhere(
        (e) => e.toString() == map['effortLevel'],
        orElse: () => EffortLevel.medium,
      ),
      timeframe: Timeframe.values.firstWhere(
        (e) => e.toString() == map['timeframe'],
        orElse: () => Timeframe.mediumTerm,
      ),
      actionableSteps: List<String>.from(map['actionableSteps'] ?? []),
    );
  }
}

// Optimización de gastos
class SpendingOptimization {
  final List<OptimizationSuggestion> suggestions;
  final BudgetOptimization budgetOptimization;
  final CashFlowOptimization cashFlowOptimization;

  SpendingOptimization({
    required this.suggestions,
    required this.budgetOptimization,
    required this.cashFlowOptimization,
  });

  static SpendingOptimization suggest(List<Transaction> transactions) {
    return SpendingOptimization(
      suggestions: _generateOptimizationSuggestions(transactions),
      budgetOptimization: BudgetOptimization.analyze(transactions),
      cashFlowOptimization: CashFlowOptimization.analyze(transactions),
    );
  }

  static List<OptimizationSuggestion> _generateOptimizationSuggestions(List<Transaction> transactions) {
    final suggestions = <OptimizationSuggestion>[];
    
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    final incomeTransactions = transactions.where((t) => t.isIncome).toList();
    
    final totalExpenses = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);
    
    // Sugerencia: Ratio ingresos/gastos
    if (totalIncome > 0) {
      final savingsRate = ((totalIncome - totalExpenses) / totalIncome) * 100;
      if (savingsRate < 10) {
        suggestions.add(OptimizationSuggestion(
          type: SuggestionType.savingsRate,
          priority: Priority.high,
          title: 'Mejorar tasa de ahorro',
          description: 'Tu tasa de ahorro actual es ${savingsRate.toStringAsFixed(1)}%. Ideal: mínimo 20%',
          impact: ImpactLevel.high,
          estimatedSavings: totalIncome * 0.1,
        ));
      }
    }
    
    // Sugerencia: Diversificación de gastos
    final categoryTotals = <String, double>{};
    for (final transaction in expenseTransactions) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }
    
    final maxCategory = categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    if (maxCategory.value > totalExpenses * 0.4) {
      suggestions.add(OptimizationSuggestion(
        type: SuggestionType.categoryDiversification,
        priority: Priority.medium,
        title: 'Diversificar gastos',
        description: 'La categoría ${maxCategory.key} representa ${(maxCategory.value/totalExpenses*100).toStringAsFixed(1)}% de tus gastos',
        impact: ImpactLevel.medium,
        estimatedSavings: maxCategory.value * 0.15,
      ));
    }
    
    return suggestions;
  }

  Map<String, dynamic> toMap() {
    return {
      'suggestions': suggestions.map((s) => s.toMap()).toList(),
      'budgetOptimization': budgetOptimization.toMap(),
      'cashFlowOptimization': cashFlowOptimization.toMap(),
    };
  }

  factory SpendingOptimization.fromMap(Map<String, dynamic> map) {
    return SpendingOptimization(
      suggestions: (map['suggestions'] as List<dynamic>?)
          ?.map((data) => OptimizationSuggestion.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      budgetOptimization: BudgetOptimization.fromMap(map['budgetOptimization'] ?? {}),
      cashFlowOptimization: CashFlowOptimization.fromMap(map['cashFlowOptimization'] ?? {}),
    );
  }
}

// Sugerencia de optimización
class OptimizationSuggestion {
  final SuggestionType type;
  final Priority priority;
  final String title;
  final String description;
  final ImpactLevel impact;
  final double estimatedSavings;

  OptimizationSuggestion({
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.impact,
    required this.estimatedSavings,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'priority': priority.toString(),
      'title': title,
      'description': description,
      'impact': impact.toString(),
      'estimatedSavings': estimatedSavings,
    };
  }

  factory OptimizationSuggestion.fromMap(Map<String, dynamic> map) {
    return OptimizationSuggestion(
      type: SuggestionType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => SuggestionType.general,
      ),
      priority: Priority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => Priority.medium,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      impact: ImpactLevel.values.firstWhere(
        (e) => e.toString() == map['impact'],
        orElse: () => ImpactLevel.medium,
      ),
      estimatedSavings: (map['estimatedSavings'] ?? 0.0).toDouble(),
    );
  }
}

// Optimización de presupuesto
class BudgetOptimization {
  final double recommendedMonthlyBudget;
  final Map<String, double> categoryBudgets;
  final List<BudgetAlert> alerts;
  final double optimalSavingsAmount;

  BudgetOptimization({
    required this.recommendedMonthlyBudget,
    required this.categoryBudgets,
    required this.alerts,
    required this.optimalSavingsAmount,
  });

  static BudgetOptimization analyze(List<Transaction> transactions) {
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    final incomeTransactions = transactions.where((t) => t.isIncome).toList();
    
    // Calcular gastos mensuales promedio
    final monthlyExpenses = _calculateMonthlyAverage(expenseTransactions);
    final monthlyIncome = _calculateMonthlyAverage(incomeTransactions);
    
    // Presupuesto recomendado (80% de ingresos para gastos, 20% para ahorro)
    final recommendedMonthlyBudget = monthlyIncome * 0.8;
    final optimalSavingsAmount = monthlyIncome * 0.2;
    
    // Distribución por categorías basada en datos históricos
    final categoryTotals = <String, double>{};
    for (final transaction in expenseTransactions) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }
    
    final categoryBudgets = <String, double>{};
    for (final entry in categoryTotals.entries) {
      final percentage = expenseTransactions.isEmpty ? 0 : entry.value / expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
      categoryBudgets[entry.key] = recommendedMonthlyBudget * percentage;
    }
    
    // Generar alertas
    final alerts = <BudgetAlert>[];
    if (monthlyExpenses > recommendedMonthlyBudget) {
      alerts.add(BudgetAlert(
        type: AlertType.overBudget,
        severity: SeverityLevel.high,
        message: 'Tus gastos mensuales exceden el presupuesto recomendado',
        amount: monthlyExpenses - recommendedMonthlyBudget,
      ));
    }
    
    return BudgetOptimization(
      recommendedMonthlyBudget: recommendedMonthlyBudget,
      categoryBudgets: categoryBudgets,
      alerts: alerts,
      optimalSavingsAmount: optimalSavingsAmount,
    );
  }

  static double _calculateMonthlyAverage(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;
    
    final sorted = transactions.toList()..sort((a, b) => a.date.compareTo(b.date));
    final firstDate = sorted.first.date;
    final lastDate = sorted.last.date;
    final daysDiff = lastDate.difference(firstDate).inDays;
    
    if (daysDiff == 0) return 0.0;
    
    final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final monthsDiff = daysDiff / 30.0; // Aproximación
    return totalAmount / monthsDiff;
  }

  Map<String, dynamic> toMap() {
    return {
      'recommendedMonthlyBudget': recommendedMonthlyBudget,
      'categoryBudgets': categoryBudgets,
      'alerts': alerts.map((a) => a.toMap()).toList(),
      'optimalSavingsAmount': optimalSavingsAmount,
    };
  }

  factory BudgetOptimization.fromMap(Map<String, dynamic> map) {
    return BudgetOptimization(
      recommendedMonthlyBudget: (map['recommendedMonthlyBudget'] ?? 0.0).toDouble(),
      categoryBudgets: Map<String, double>.from(map['categoryBudgets'] ?? {}),
      alerts: (map['alerts'] as List<dynamic>?)
          ?.map((data) => BudgetAlert.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      optimalSavingsAmount: (map['optimalSavingsAmount'] ?? 0.0).toDouble(),
    );
  }
}

// Optimización de flujo de efectivo
class CashFlowOptimization {
  final List<CashFlowPattern> patterns;
  final List<String> recommendations;
  final double projectedBalance;

  CashFlowOptimization({
    required this.patterns,
    required this.recommendations,
    required this.projectedBalance,
  });

  static CashFlowOptimization analyze(List<Transaction> transactions) {
    final patterns = <CashFlowPattern>[];
    final recommendations = <String>[];
    
    // Analizar patrones de ingresos vs gastos
    final incomeTransactions = transactions.where((t) => t.isIncome).toList();
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    
    final incomeByDay = <String, double>{};
    final expensesByDay = <String, double>{};
    
    for (final transaction in incomeTransactions) {
      final dayKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}-${transaction.date.day.toString().padLeft(2, '0')}';
      incomeByDay[dayKey] = (incomeByDay[dayKey] ?? 0) + transaction.amount;
    }
    
    for (final transaction in expenseTransactions) {
      final dayKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}-${transaction.date.day.toString().padLeft(2, '0')}';
      expensesByDay[dayKey] = (expensesByDay[dayKey] ?? 0) + transaction.amount;
    }
    
    // Identificar patrones
    patterns.add(CashFlowPattern(
      type: PatternType.incomeConcentration,
      description: 'Los ingresos están concentrados en días específicos del mes',
      severity: SeverityLevel.medium,
    ));
    
    // Generar recomendaciones
    recommendations.add('Considera distribuir gastos a lo largo del mes para mantener flujo constante');
    recommendations.add('Programa pagos importantes cerca de fechas de ingreso');
    recommendations.add('Mantén un fondo de emergencia equivalente a 3 meses de gastos');
    
    final projectedBalance = _calculateProjectedBalance(incomeTransactions, expenseTransactions);
    
    return CashFlowOptimization(
      patterns: patterns,
      recommendations: recommendations,
      projectedBalance: projectedBalance,
    );
  }

  static double _calculateProjectedBalance(List<Transaction> income, List<Transaction> expenses) {
    final totalIncome = income.fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
    return totalIncome - totalExpenses;
  }

  Map<String, dynamic> toMap() {
    return {
      'patterns': patterns.map((p) => p.toMap()).toList(),
      'recommendations': recommendations,
      'projectedBalance': projectedBalance,
    };
  }

  factory CashFlowOptimization.fromMap(Map<String, dynamic> map) {
    return CashFlowOptimization(
      patterns: (map['patterns'] as List<dynamic>?)
          ?.map((data) => CashFlowPattern.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      recommendations: List<String>.from(map['recommendations'] ?? []),
      projectedBalance: (map['projectedBalance'] ?? 0.0).toDouble(),
    );
  }
}

// Patrón de flujo de efectivo
class CashFlowPattern {
  final PatternType type;
  final String description;
  final SeverityLevel severity;

  CashFlowPattern({
    required this.type,
    required this.description,
    required this.severity,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'description': description,
      'severity': severity.toString(),
    };
  }

  factory CashFlowPattern.fromMap(Map<String, dynamic> map) {
    return CashFlowPattern(
      type: PatternType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => PatternType.general,
      ),
      description: map['description'] ?? '',
      severity: SeverityLevel.values.firstWhere(
        (e) => e.toString() == map['severity'],
        orElse: () => SeverityLevel.medium,
      ),
    );
  }
}

// Alerta de presupuesto
class BudgetAlert {
  final AlertType type;
  final SeverityLevel severity;
  final String message;
  final double amount;

  BudgetAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'severity': severity.toString(),
      'message': message,
      'amount': amount,
    };
  }

  factory BudgetAlert.fromMap(Map<String, dynamic> map) {
    return BudgetAlert(
      type: AlertType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => AlertType.general,
      ),
      severity: SeverityLevel.values.firstWhere(
        (e) => e.toString() == map['severity'],
        orElse: () => SeverityLevel.medium,
      ),
      message: map['message'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }
}

// Enums adicionales para optimización
enum EffortLevel {
  low,
  medium,
  high
}

enum Timeframe {
  shortTerm,
  mediumTerm,
  longTerm
}

enum SuggestionType {
  general,
  savingsRate,
  categoryDiversification,
  spendingPattern
}

enum Priority {
  low,
  medium,
  high
}

enum ImpactLevel {
  low,
  medium,
  high
}

enum AlertType {
  general,
  overBudget,
  underspending,
  anomaly
}

enum PatternType {
  general,
  incomeConcentration,
  expenseClustering,
  seasonalVariation
}