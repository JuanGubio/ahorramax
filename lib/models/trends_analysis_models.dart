import 'financial_analysis_models.dart';

// Análisis de tendencias de gasto
class SpendingTrends {
  final DailyTrends daily;
  final WeeklyTrends weekly;
  final MonthlyTrends monthly;
  final YearlyTrends yearly;
  final PredictionTrend nextMonthPrediction;
  final TrendAnalysis seasonalPatterns;
  final AnomalyDetection anomalies;

  SpendingTrends({
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.yearly,
    required this.nextMonthPrediction,
    required this.seasonalPatterns,
    required this.anomalies,
  });

  static SpendingTrends analyze(List<Transaction> transactions) {
    final now = DateTime.now();
    
    return SpendingTrends(
      daily: DailyTrends.analyze(transactions, now),
      weekly: WeeklyTrends.analyze(transactions, now),
      monthly: MonthlyTrends.analyze(transactions, now),
      yearly: YearlyTrends.analyze(transactions, now),
      nextMonthPrediction: PredictionTrend.predict(transactions, now),
      seasonalPatterns: TrendAnalysis.analyzeSeasonal(transactions),
      anomalies: AnomalyDetection.detect(transactions),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'daily': daily.toMap(),
      'weekly': weekly.toMap(),
      'monthly': monthly.toMap(),
      'yearly': yearly.toMap(),
      'nextMonthPrediction': nextMonthPrediction.toMap(),
      'seasonalPatterns': seasonalPatterns.toMap(),
      'anomalies': anomalies.toMap(),
    };
  }

  factory SpendingTrends.fromMap(Map<String, dynamic> map) {
    return SpendingTrends(
      daily: DailyTrends.fromMap(map['daily'] ?? {}),
      weekly: WeeklyTrends.fromMap(map['weekly'] ?? {}),
      monthly: MonthlyTrends.fromMap(map['monthly'] ?? {}),
      yearly: YearlyTrends.fromMap(map['yearly'] ?? {}),
      nextMonthPrediction: PredictionTrend.fromMap(map['nextMonthPrediction'] ?? {}),
      seasonalPatterns: TrendAnalysis.fromMap(map['seasonalPatterns'] ?? {}),
      anomalies: AnomalyDetection.fromMap(map['anomalies'] ?? {}),
    );
  }
}

// Tendencias diarias
class DailyTrends {
  final double averageDailySpent;
  final double medianDailySpent;
  final List<double> dailyAmounts; // Últimos 30 días
  final double standardDeviation;
  final List<String> peakSpendingDays; // Días de la semana con más gasto
  final List<String> lowSpendingDays;
  final TrendDirection trend; // increasing, decreasing, stable
  final double volatility;

  DailyTrends({
    required this.averageDailySpent,
    required this.medianDailySpent,
    required this.dailyAmounts,
    required this.standardDeviation,
    required this.peakSpendingDays,
    required this.lowSpendingDays,
    required this.trend,
    required this.volatility,
  });

  static DailyTrends analyze(List<Transaction> transactions, DateTime now) {
    final last30Days = now.subtract(const Duration(days: 30));
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(last30Days) && !t.isIncome)
        .toList();

    // Agrupar por día
    final dailyTotals = <String, double>{};
    for (final transaction in recentTransactions) {
      final dayKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}-${transaction.date.day.toString().padLeft(2, '0')}';
      dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + transaction.amount;
    }

    final dailyAmounts = dailyTotals.values.toList()..sort();
    
    // Calcular estadísticas
    final averageDailySpent = dailyAmounts.isEmpty ? 0 : 
        dailyAmounts.reduce((a, b) => a + b) / dailyAmounts.length;
    final medianDailySpent = dailyAmounts.isEmpty ? 0 :
        dailyAmounts[dailyAmounts.length ~/ 2];
    
    // Calcular desviación estándar
    final variance = dailyAmounts.isEmpty ? 0 : 
        dailyAmounts.map((amount) => (amount - averageDailySpent) * (amount - averageDailySpent))
            .reduce((a, b) => a + b) / dailyAmounts.length;
    final standardDeviation = variance > 0 ? variance.sqrt() : 0;

    // Analizar días de la semana
    final dayOfWeekTotals = <int, double>{};
    for (final transaction in recentTransactions) {
      final dayOfWeek = transaction.date.weekday; // 1 = Monday, 7 = Sunday
      dayOfWeekTotals[dayOfWeek] = (dayOfWeekTotals[dayOfWeek] ?? 0) + transaction.amount;
    }

    final sortedDays = dayOfWeekTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final peakSpendingDays = sortedDays.take(3).map((e) => _getDayName(e.key)).toList();
    final lowSpendingDays = sortedDays.reversed.take(3).map((e) => _getDayName(e.key)).toList();

    // Determinar tendencia
    final trend = _calculateTrend(dailyAmounts);
    
    // Calcular volatilidad (coeficiente de variación)
    final volatility = averageDailySpent > 0 ? (standardDeviation / averageDailySpent) * 100 : 0;

    return DailyTrends(
      averageDailySpent: averageDailySpent,
      medianDailySpent: medianDailySpent,
      dailyAmounts: dailyAmounts,
      standardDeviation: standardDeviation,
      peakSpendingDays: peakSpendingDays,
      lowSpendingDays: lowSpendingDays,
      trend: trend,
      volatility: volatility,
    );
  }

  static String _getDayName(int dayOfWeek) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[dayOfWeek - 1];
  }

  static TrendDirection _calculateTrend(List<double> amounts) {
    if (amounts.length < 7) return TrendDirection.stable;
    
    final recent = amounts.takeLast(7).toList();
    final previous = amounts.skip((amounts.length - 14).clamp(0, amounts.length)).take(7).toList();
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final previousAvg = previous.reduce((a, b) => a + b) / previous.length;
    
    final change = ((recentAvg - previousAvg) / previousAvg) * 100;
    
    if (change > 10) return TrendDirection.increasing;
    if (change < -10) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  Map<String, dynamic> toMap() {
    return {
      'averageDailySpent': averageDailySpent,
      'medianDailySpent': medianDailySpent,
      'dailyAmounts': dailyAmounts,
      'standardDeviation': standardDeviation,
      'peakSpendingDays': peakSpendingDays,
      'lowSpendingDays': lowSpendingDays,
      'trend': trend.toString(),
      'volatility': volatility,
    };
  }

  factory DailyTrends.fromMap(Map<String, dynamic> map) {
    return DailyTrends(
      averageDailySpent: (map['averageDailySpent'] ?? 0.0).toDouble(),
      medianDailySpent: (map['medianDailySpent'] ?? 0.0).toDouble(),
      dailyAmounts: List<double>.from(map['dailyAmounts'] ?? []),
      standardDeviation: (map['standardDeviation'] ?? 0.0).toDouble(),
      peakSpendingDays: List<String>.from(map['peakSpendingDays'] ?? []),
      lowSpendingDays: List<String>.from(map['lowSpendingDays'] ?? []),
      trend: TrendDirection.values.firstWhere(
        (e) => e.toString() == map['trend'],
        orElse: () => TrendDirection.stable,
      ),
      volatility: (map['volatility'] ?? 0.0).toDouble(),
    );
  }
}

// Tendencias semanales
class WeeklyTrends {
  final double averageWeeklySpent;
  final List<double> weeklyTotals; // Últimas 12 semanas
  final List<String> weekLabels;
  final TrendDirection trend;
  final double weekOverWeekChange;

  WeeklyTrends({
    required this.averageWeeklySpent,
    required this.weeklyTotals,
    required this.weekLabels,
    required this.trend,
    required this.weekOverWeekChange,
  });

  static WeeklyTrends analyze(List<Transaction> transactions, DateTime now) {
    final last12Weeks = now.subtract(Duration(days: 12 * 7));
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(last12Weeks) && !t.isIncome)
        .toList();

    final weeklyTotals = <double>[];
    final weekLabels = <String>[];

    // Calcular totales por semana
    for (int i = 11; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: i * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      final weekTransactions = recentTransactions
          .where((t) => t.date.isAfter(weekStart) && t.date.isBefore(weekEnd))
          .toList();
      
      final weekTotal = weekTransactions.fold(0.0, (sum, t) => sum + t.amount);
      weeklyTotals.add(weekTotal);
      weekLabels.add('Sem ${_getWeekNumber(weekStart)}');
    }

    final averageWeeklySpent = weeklyTotals.isEmpty ? 0 :
        weeklyTotals.reduce((a, b) => a + b) / weeklyTotals.length;
    
    final trend = _calculateWeeklyTrend(weeklyTotals);
    
    // Calcular cambio semana a semana
    final weekOverWeekChange = weeklyTotals.length >= 2 ?
        ((weeklyTotals.last - weeklyTotals[weeklyTotals.length - 2]) / weeklyTotals[weeklyTotals.length - 2]) * 100 : 0;

    return WeeklyTrends(
      averageWeeklySpent: averageWeeklySpent,
      weeklyTotals: weeklyTotals,
      weekLabels: weekLabels,
      trend: trend,
      weekOverWeekChange: weekOverWeekChange,
    );
  }

  static String _getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();
    return weekNumber.toString();
  }

  static TrendDirection _calculateWeeklyTrend(List<double> totals) {
    if (totals.length < 4) return TrendDirection.stable;
    
    final recent = totals.takeLast(4).toList();
    final previous = totals.skip((totals.length - 8).clamp(0, totals.length)).take(4).toList();
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final previousAvg = previous.reduce((a, b) => a + b) / previous.length;
    
    final change = ((recentAvg - previousAvg) / previousAvg) * 100;
    
    if (change > 15) return TrendDirection.increasing;
    if (change < -15) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  Map<String, dynamic> toMap() {
    return {
      'averageWeeklySpent': averageWeeklySpent,
      'weeklyTotals': weeklyTotals,
      'weekLabels': weekLabels,
      'trend': trend.toString(),
      'weekOverWeekChange': weekOverWeekChange,
    };
  }

  factory WeeklyTrends.fromMap(Map<String, dynamic> map) {
    return WeeklyTrends(
      averageWeeklySpent: (map['averageWeeklySpent'] ?? 0.0).toDouble(),
      weeklyTotals: List<double>.from(map['weeklyTotals'] ?? []),
      weekLabels: List<String>.from(map['weekLabels'] ?? []),
      trend: TrendDirection.values.firstWhere(
        (e) => e.toString() == map['trend'],
        orElse: () => TrendDirection.stable,
      ),
      weekOverWeekChange: (map['weekOverWeekChange'] ?? 0.0).toDouble(),
    );
  }
}

// Tendencias mensuales
class MonthlyTrends {
  final double averageMonthlySpent;
  final List<double> monthlyTotals; // Últimos 12 meses
  final List<String> monthLabels;
  final TrendDirection trend;
  final double monthOverMonthChange;
  final double yearOverYearChange;

  MonthlyTrends({
    required this.averageMonthlySpent,
    required this.monthlyTotals,
    required this.monthLabels,
    required this.trend,
    required this.monthOverMonthChange,
    required this.yearOverYearChange,
  });

  static MonthlyTrends analyze(List<Transaction> transactions, DateTime now) {
    final last12Months = DateTime(now.year - 1, now.month, now.day);
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(last12Months) && !t.isIncome)
        .toList();

    final monthlyTotals = <double>[];
    final monthLabels = <String>[];

    // Calcular totales por mes
    for (int i = 11; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 1);
      
      final monthTransactions = recentTransactions
          .where((t) => t.date.isAfter(monthStart) && t.date.isBefore(monthEnd))
          .toList();
      
      final monthTotal = monthTransactions.fold(0.0, (sum, t) => sum + t.amount);
      monthlyTotals.add(monthTotal);
      monthLabels.add(_getMonthName(monthStart.month));
    }

    final averageMonthlySpent = monthlyTotals.isEmpty ? 0 :
        monthlyTotals.reduce((a, b) => a + b) / monthlyTotals.length;
    
    final trend = _calculateMonthlyTrend(monthlyTotals);
    
    // Calcular cambio mes a mes
    final monthOverMonthChange = monthlyTotals.length >= 2 ?
        ((monthlyTotals.last - monthlyTotals[monthlyTotals.length - 2]) / monthlyTotals[monthlyTotals.length - 2]) * 100 : 0;
    
    // Calcular cambio año a año (si hay datos de 12 meses)
    final yearOverYearChange = monthlyTotals.length == 12 && monthlyTotals[0] > 0 ?
        ((monthlyTotals.last - monthlyTotals[0]) / monthlyTotals[0]) * 100 : 0;

    return MonthlyTrends(
      averageMonthlySpent: averageMonthlySpent,
      monthlyTotals: monthlyTotals,
      monthLabels: monthLabels,
      trend: trend,
      monthOverMonthChange: monthOverMonthChange,
      yearOverYearChange: yearOverYearChange,
    );
  }

  static String _getMonthName(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                   'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month - 1];
  }

  static TrendDirection _calculateMonthlyTrend(List<double> totals) {
    if (totals.length < 3) return TrendDirection.stable;
    
    final recent = totals.takeLast(3).toList();
    final previous = totals.skip((totals.length - 6).clamp(0, totals.length)).take(3).toList();
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final previousAvg = previous.reduce((a, b) => a + b) / previous.length;
    
    final change = ((recentAvg - previousAvg) / previousAvg) * 100;
    
    if (change > 20) return TrendDirection.increasing;
    if (change < -20) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  Map<String, dynamic> toMap() {
    return {
      'averageMonthlySpent': averageMonthlySpent,
      'monthlyTotals': monthlyTotals,
      'monthLabels': monthLabels,
      'trend': trend.toString(),
      'monthOverMonthChange': monthOverMonthChange,
      'yearOverYearChange': yearOverYearChange,
    };
  }

  factory MonthlyTrends.fromMap(Map<String, dynamic> map) {
    return MonthlyTrends(
      averageMonthlySpent: (map['averageMonthlySpent'] ?? 0.0).toDouble(),
      monthlyTotals: List<double>.from(map['monthlyTotals'] ?? []),
      monthLabels: List<String>.from(map['monthLabels'] ?? []),
      trend: TrendDirection.values.firstWhere(
        (e) => e.toString() == map['trend'],
        orElse: () => TrendDirection.stable,
      ),
      monthOverMonthChange: (map['monthOverMonthChange'] ?? 0.0).toDouble(),
      yearOverYearChange: (map['yearOverYearChange'] ?? 0.0).toDouble(),
    );
  }
}

// Tendencias anuales
class YearlyTrends {
  final double averageYearlySpent;
  final List<double> yearlyTotals; // Últimos 5 años
  final List<String> yearLabels;
  final TrendDirection trend;
  final double yearOverYearChange;
  final double growthRate;

  YearlyTrends({
    required this.averageYearlySpent,
    required this.yearlyTotals,
    required this.yearLabels,
    required this.trend,
    required this.yearOverYearChange,
    required this.growthRate,
  });

  static YearlyTrends analyze(List<Transaction> transactions, DateTime now) {
    final last5Years = DateTime(now.year - 4, now.month, now.day);
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(last5Years) && !t.isIncome)
        .toList();

    final yearlyTotals = <double>[];
    final yearLabels = <String>[];

    // Calcular totales por año
    for (int i = 4; i >= 0; i--) {
      final year = now.year - i;
      final yearStart = DateTime(year, 1, 1);
      final yearEnd = DateTime(year + 1, 1, 1);
      
      final yearTransactions = recentTransactions
          .where((t) => t.date.isAfter(yearStart) && t.date.isBefore(yearEnd))
          .toList();
      
      final yearTotal = yearTransactions.fold(0.0, (sum, t) => sum + t.amount);
      yearlyTotals.add(yearTotal);
      yearLabels.add(year.toString());
    }

    final averageYearlySpent = yearlyTotals.isEmpty ? 0 :
        yearlyTotals.reduce((a, b) => a + b) / yearlyTotals.length;
    
    final trend = _calculateYearlyTrend(yearlyTotals);
    
    // Calcular cambio año a año
    final yearOverYearChange = yearlyTotals.length >= 2 ?
        ((yearlyTotals.last - yearlyTotals[yearlyTotals.length - 2]) / yearlyTotals[yearlyTotals.length - 2]) * 100 : 0;
    
    // Calcular tasa de crecimiento promedio anual
    final growthRate = _calculateGrowthRate(yearlyTotals);

    return YearlyTrends(
      averageYearlySpent: averageYearlySpent,
      yearlyTotals: yearlyTotals,
      yearLabels: yearLabels,
      trend: trend,
      yearOverYearChange: yearOverYearChange,
      growthRate: growthRate,
    );
  }

  static TrendDirection _calculateYearlyTrend(List<double> totals) {
    if (totals.length < 2) return TrendDirection.stable;
    
    final recent = totals.takeLast(2).toList();
    final previous = totals.take(2).toList();
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final previousAvg = previous.reduce((a, b) => a + b) / previous.length;
    
    final change = ((recentAvg - previousAvg) / previousAvg) * 100;
    
    if (change > 25) return TrendDirection.increasing;
    if (change < -25) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  static double _calculateGrowthRate(List<double> totals) {
    if (totals.length < 2) return 0.0;
    
    final firstValue = totals.first;
    final lastValue = totals.last;
    final years = totals.length - 1;
    
    if (firstValue <= 0 || years <= 0) return 0.0;
    
    // CAGR (Compound Annual Growth Rate)
    final cagr = (pow(lastValue / firstValue, 1 / years) - 1) * 100;
    return cagr;
  }

  Map<String, dynamic> toMap() {
    return {
      'averageYearlySpent': averageYearlySpent,
      'yearlyTotals': yearlyTotals,
      'yearLabels': yearLabels,
      'trend': trend.toString(),
      'yearOverYearChange': yearOverYearChange,
      'growthRate': growthRate,
    };
  }

  factory YearlyTrends.fromMap(Map<String, dynamic> map) {
    return YearlyTrends(
      averageYearlySpent: (map['averageYearlySpent'] ?? 0.0).toDouble(),
      yearlyTotals: List<double>.from(map['yearlyTotals'] ?? []),
      yearLabels: List<String>.from(map['yearLabels'] ?? []),
      trend: TrendDirection.values.firstWhere(
        (e) => e.toString() == map['trend'],
        orElse: () => TrendDirection.stable,
      ),
      yearOverYearChange: (map['yearOverYearChange'] ?? 0.0).toDouble(),
      growthRate: (map['growthRate'] ?? 0.0).toDouble(),
    );
  }
}

// Predicción de tendencias
class PredictionTrend {
  final double predictedNextMonth;
  final double predictedConfidence; // 0-100%
  final List<double> predictedWeeklyTotals; // Próximas 4 semanas
  final TrendDirection predictedTrend;
  final List<String> keyFactors; // Factores que influyen en la predicción

  PredictionTrend({
    required this.predictedNextMonth,
    required this.predictedConfidence,
    required this.predictedWeeklyTotals,
    required this.predictedTrend,
    required this.keyFactors,
  });

  static PredictionTrend predict(List<Transaction> transactions, DateTime now) {
    final last3Months = now.subtract(Duration(days: 90));
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(last3Months) && !t.isIncome)
        .toList();

    // Calcular promedio mensual reciente
    final monthlyTotals = <double>[];
    for (int i = 2; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 1);
      
      final monthTransactions = recentTransactions
          .where((t) => t.date.isAfter(monthStart) && t.date.isBefore(monthEnd))
          .toList();
      
      final monthTotal = monthTransactions.fold(0.0, (sum, t) => sum + t.amount);
      monthlyTotals.add(monthTotal);
    }

    // Predicción usando promedio móvil y tendencias
    final predictedNextMonth = _calculatePrediction(monthlyTotals);
    final predictedConfidence = _calculateConfidence(monthlyTotals);
    final predictedWeeklyTotals = _predictWeeklyTotals(predictedNextMonth);
    final predictedTrend = _determinePredictedTrend(monthlyTotals, predictedNextMonth);
    final keyFactors = _identifyKeyFactors(transactions, recentTransactions);

    return PredictionTrend(
      predictedNextMonth: predictedNextMonth,
      predictedConfidence: predictedConfidence,
      predictedWeeklyTotals: predictedWeeklyTotals,
      predictedTrend: predictedTrend,
      keyFactors: keyFactors,
    );
  }

  static double _calculatePrediction(List<double> monthlyTotals) {
    if (monthlyTotals.isEmpty) return 0.0;
    
    // Usar promedio móvil ponderado (más peso a meses recientes)
    final weights = [0.2, 0.3, 0.5]; // Pesos para 3 meses
    double weightedSum = 0;
    double totalWeight = 0;
    
    for (int i = 0; i < monthlyTotals.length; i++) {
      weightedSum += monthlyTotals[i] * weights[i];
      totalWeight += weights[i];
    }
    
    return totalWeight > 0 ? weightedSum / totalWeight : 0;
  }

  static double _calculateConfidence(List<double> monthlyTotals) {
    if (monthlyTotals.length < 2) return 30.0;
    
    // Calcular coeficiente de variación para determinar confianza
    final mean = monthlyTotals.reduce((a, b) => a + b) / monthlyTotals.length;
    final variance = monthlyTotals.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / monthlyTotals.length;
    final standardDeviation = variance.sqrt();
    final coefficientOfVariation = mean > 0 ? (standardDeviation / mean) * 100 : 0;
    
    // Menor variación = mayor confianza
    return (100 - coefficientOfVariation).clamp(30.0, 95.0);
  }

  static List<double> _predictWeeklyTotals(double monthlyPrediction) {
    final weeklyAverage = monthlyPrediction / 4.33; // 4.33 semanas promedio por mes
    final variance = weeklyAverage * 0.2; // 20% de variación
    
    return List.generate(4, (index) {
      final randomFactor = 0.8 + (0.4 * (index / 3)); // Ligeramente creciente
      return (weeklyAverage * randomFactor).clamp(0, double.infinity);
    });
  }

  static TrendDirection _determinePredictedTrend(List<double> monthlyTotals, double prediction) {
    if (monthlyTotals.length < 2) return TrendDirection.stable;
    
    final lastMonth = monthlyTotals.last;
    final change = ((prediction - lastMonth) / lastMonth) * 100;
    
    if (change > 10) return TrendDirection.increasing;
    if (change < -10) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  static List<String> _identifyKeyFactors(List<Transaction> allTransactions, List<Transaction> recentTransactions) {
    final factors = <String>[];
    
    // Analizar estacionalidad
    final currentMonth = DateTime.now().month;
    if ([11, 12, 1].contains(currentMonth)) {
      factors.add('temporada_festiva');
    }
    
    // Analizar cambios en comportamiento
    final olderTransactions = allTransactions
        .where((t) => t.date.isBefore(recentTransactions.isNotEmpty ? recentTransactions.first.date : DateTime.now()))
        .toList();
    
    if (olderTransactions.isNotEmpty && recentTransactions.isNotEmpty) {
      final olderAvg = olderTransactions.fold(0.0, (sum, t) => sum + t.amount) / olderTransactions.length;
      final recentAvg = recentTransactions.fold(0.0, (sum, t) => sum + t.amount) / recentTransactions.length;
      
      if (recentAvg > olderAvg * 1.2) {
        factors.add('aumento_gastos');
      } else if (recentAvg < olderAvg * 0.8) {
        factors.add('reduccion_gastos');
      }
    }
    
    // Analizar categorías dominantes
    final categoryTotals = <String, double>{};
    for (final transaction in recentTransactions) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }
    
    final dominantCategory = categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    factors.add('categoria_principal_$dominantCategory');
    
    return factors;
  }

  Map<String, dynamic> toMap() {
    return {
      'predictedNextMonth': predictedNextMonth,
      'predictedConfidence': predictedConfidence,
      'predictedWeeklyTotals': predictedWeeklyTotals,
      'predictedTrend': predictedTrend.toString(),
      'keyFactors': keyFactors,
    };
  }

  factory PredictionTrend.fromMap(Map<String, dynamic> map) {
    return PredictionTrend(
      predictedNextMonth: (map['predictedNextMonth'] ?? 0.0).toDouble(),
      predictedConfidence: (map['predictedConfidence'] ?? 0.0).toDouble(),
      predictedWeeklyTotals: List<double>.from(map['predictedWeeklyTotals'] ?? []),
      predictedTrend: TrendDirection.values.firstWhere(
        (e) => e.toString() == map['predictedTrend'],
        orElse: () => TrendDirection.stable,
      ),
      keyFactors: List<String>.from(map['keyFactors'] ?? []),
    );
  }
}

// Análisis de patrones estacionales
class TrendAnalysis {
  final Map<String, double> seasonalAverages; // {month: average_spending}
  final List<String> peakSpendingMonths;
  final List<String> lowSpendingMonths;
  final double seasonalVariance;

  TrendAnalysis({
    required this.seasonalAverages,
    required this.peakSpendingMonths,
    required this.lowSpendingMonths,
    required this.seasonalVariance,
  });

  static TrendAnalysis analyzeSeasonal(List<Transaction> transactions) {
    final monthlyTotals = <int, List<double>>{};
    
    // Agrupar transacciones por mes
    for (final transaction in transactions.where((t) => !t.isIncome)) {
      final month = transaction.date.month;
      monthlyTotals[month] = (monthlyTotals[month] ?? [])..add(transaction.amount);
    }
    
    // Calcular promedios por mes
    final seasonalAverages = <String, double>{};
    for (final entry in monthlyTotals.entries) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      seasonalAverages[_getMonthName(entry.key)] = average;
    }
    
    // Identificar meses pico y bajos
    final sortedMonths = seasonalAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final peakSpendingMonths = sortedMonths.take(3).map((e) => e.key).toList();
    final lowSpendingMonths = sortedMonths.reversed.take(3).map((e) => e.key).toList();
    
    // Calcular varianza estacional
    final values = seasonalAverages.values.toList();
    final mean = values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
    final variance = values.isEmpty ? 0 : 
        values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    final seasonalVariance = variance.sqrt();
    
    return TrendAnalysis(
      seasonalAverages: seasonalAverages,
      peakSpendingMonths: peakSpendingMonths,
      lowSpendingMonths: lowSpendingMonths,
      seasonalVariance: seasonalVariance,
    );
  }

  static String _getMonthName(int month) {
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                   'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return months[month - 1];
  }

  Map<String, dynamic> toMap() {
    return {
      'seasonalAverages': seasonalAverages,
      'peakSpendingMonths': peakSpendingMonths,
      'lowSpendingMonths': lowSpendingMonths,
      'seasonalVariance': seasonalVariance,
    };
  }

  factory TrendAnalysis.fromMap(Map<String, dynamic> map) {
    return TrendAnalysis(
      seasonalAverages: Map<String, double>.from(map['seasonalAverages'] ?? {}),
      peakSpendingMonths: List<String>.from(map['peakSpendingMonths'] ?? []),
      lowSpendingMonths: List<String>.from(map['lowSpendingMonths'] ?? []),
      seasonalVariance: (map['seasonalVariance'] ?? 0.0).toDouble(),
    );
  }
}

// Detección de anomalías
class AnomalyDetection {
  final List<TransactionAnomaly> detectedAnomalies;
  final double anomalyThreshold;
  final int totalAnomaliesLast30Days;

  AnomalyDetection({
    required this.detectedAnomalies,
    required this.anomalyThreshold,
    required this.totalAnomaliesLast30Days,
  });

  static AnomalyDetection detect(List<Transaction> transactions) {
    final anomalies = <TransactionAnomaly>[];
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));
    
    // Detectar anomalías en los últimos 30 días
    final recentTransactions = transactions
        .where((t) => t.date.isAfter(last30Days) && !t.isIncome)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (recentTransactions.isEmpty) {
      return AnomalyDetection(
        detectedAnomalies: [],
        anomalyThreshold: 2.0,
        totalAnomaliesLast30Days: 0,
      );
    }

    // Calcular umbrales basados en datos históricos
    final historicalData = transactions
        .where((t) => t.date.isBefore(last30Days) && !t.isIncome)
        .toList();

    final amountThreshold = _calculateAmountThreshold(historicalData, recentTransactions);
    final frequencyThreshold = _calculateFrequencyThreshold(historicalData);
    final timeThreshold = _calculateTimeThreshold(historicalData);

    // Detectar anomalías por cantidad
    for (final transaction in recentTransactions) {
      if (transaction.amount > amountThreshold) {
        anomalies.add(TransactionAnomaly(
          transaction: transaction,
          type: AnomalyType.unusualAmount,
          severity: _calculateSeverity(transaction.amount, amountThreshold),
          description: 'Monto inusualmente alto: \$${transaction.amount.toStringAsFixed(2)}',
        ));
      }
    }

    // Detectar anomalías por frecuencia
    final categoryFrequency = <String, List<Transaction>>{};
    for (final transaction in recentTransactions) {
      categoryFrequency[transaction.category] = 
          (categoryFrequency[transaction.category] ?? [])..add(transaction);
    }

    for (final entry in categoryFrequency.entries) {
      if (entry.value.length > frequencyThreshold) {
        anomalies.add(TransactionAnomaly(
          transaction: entry.value.last,
          type: AnomalyType.highFrequency,
          severity: _calculateSeverity(entry.value.length, frequencyThreshold),
          description: 'Frecuencia alta en ${entry.key}: ${entry.value.length} transacciones',
        ));
      }
    }

    // Detectar anomalías por tiempo
    final nightTransactions = recentTransactions
        .where((t) => t.date.hour < 6 || t.date.hour > 23)
        .toList();
    
    for (final transaction in nightTransactions) {
      if (transaction.amount > 20) { // Solo alertar por montos significativos
        anomalies.add(TransactionAnomaly(
          transaction: transaction,
          type: AnomalyType.unusualTime,
          severity: SeverityLevel.medium,
          description: 'Gasto inusual en horario nocturno: ${transaction.date.hour}:00',
        ));
      }
    }

    return AnomalyDetection(
      detectedAnomalies: anomalies,
      anomalyThreshold: 2.0,
      totalAnomaliesLast30Days: anomalies.length,
    );
  }

  static double _calculateAmountThreshold(List<Transaction> historical, List<Transaction> recent) {
    if (historical.isEmpty) return 100.0; // Umbral por defecto
    
    final amounts = historical.map((t) => t.amount).toList()
      ..sort();
    final percentile95 = amounts[(amounts.length * 0.95).floor()];
    
    return percentile95 * 1.5; // 50% arriba del percentil 95
  }

  static int _calculateFrequencyThreshold(List<Transaction> historical) {
    if (historical.isEmpty) return 10; // Umbral por defecto
    
    final categoryCounts = <String, int>{};
    for (final transaction in historical) {
      categoryCounts[transaction.category] = 
          (categoryCounts[transaction.category] ?? 0) + 1;
    }
    
    final maxCount = categoryCounts.values.isEmpty ? 0 :
        categoryCounts.values.reduce((a, b) => a > b ? a : b);
    
    return (maxCount * 2).clamp(5, 20).toInt(); // Entre 5 y 20
  }

  static double _calculateTimeThreshold(List<Transaction> historical) {
    // Para tiempo, usamos un enfoque diferente - detectar patrones inusuales
    return 0.0;
  }

  static SeverityLevel _calculateSeverity(double value, double threshold) {
    final ratio = value / threshold;
    if (ratio > 3.0) return SeverityLevel.critical;
    if (ratio > 2.0) return SeverityLevel.high;
    if (ratio > 1.5) return SeverityLevel.medium;
    return SeverityLevel.low;
  }

  Map<String, dynamic> toMap() {
    return {
      'detectedAnomalies': detectedAnomalies.map((a) => a.toMap()).toList(),
      'anomalyThreshold': anomalyThreshold,
      'totalAnomaliesLast30Days': totalAnomaliesLast30Days,
    };
  }

  factory AnomalyDetection.fromMap(Map<String, dynamic> map) {
    return AnomalyDetection(
      detectedAnomalies: (map['detectedAnomalies'] as List<dynamic>?)
          ?.map((data) => TransactionAnomaly.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      anomalyThreshold: (map['anomalyThreshold'] ?? 2.0).toDouble(),
      totalAnomaliesLast30Days: map['totalAnomaliesLast30Days'] ?? 0,
    );
  }
}

// Anomalía específica de transacción
class TransactionAnomaly {
  final Transaction transaction;
  final AnomalyType type;
  final SeverityLevel severity;
  final String description;

  TransactionAnomaly({
    required this.transaction,
    required this.type,
    required this.severity,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'transaction': transaction.toMap(),
      'type': type.toString(),
      'severity': severity.toString(),
      'description': description,
    };
  }

  factory TransactionAnomaly.fromMap(Map<String, dynamic> map) {
    return TransactionAnomaly(
      transaction: Transaction.fromMap(map['transaction'] ?? {}),
      type: AnomalyType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => AnomalyType.unusualAmount,
      ),
      severity: SeverityLevel.values.firstWhere(
        (e) => e.toString() == map['severity'],
        orElse: () => SeverityLevel.medium,
      ),
      description: map['description'] ?? '',
    );
  }
}

// Enums adicionales
enum TrendDirection {
  increasing,
  decreasing,
  stable
}

enum AnomalyType {
  unusualAmount,
  highFrequency,
  unusualTime,
  suspiciousPattern
}

enum SeverityLevel {
  low,
  medium,
  high,
  critical
}