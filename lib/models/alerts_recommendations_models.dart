import 'financial_analysis_models.dart';
import 'trends_analysis_models.dart';
import 'category_analysis_models.dart';
import 'predictive_insights_models.dart';

// Sistema completo de alertas y recomendaciones
class AlertsAndRecommendations {
  final List<FinancialAlert> activeAlerts;
  final List<Recommendation> personalizedRecommendations;
  final List<BillReminder> upcomingBills;
  final List<GoalAlert> goalAlerts;
  final List<BehavioralInsight> behavioralInsights;
  final WeeklyActionPlan weeklyPlan;

  AlertsAndRecommendations({
    required this.activeAlerts,
    required this.personalizedRecommendations,
    required this.upcomingBills,
    required this.goalAlerts,
    required this.behavioralInsights,
    required this.weeklyPlan,
  });

  static AlertsAndRecommendations generate(
    List<Transaction> transactions,
    FinancialAnalysis analysis,
  ) {
    return AlertsAndRecommendations(
      activeAlerts: _generateAlerts(transactions, analysis),
      personalizedRecommendations: _generateRecommendations(transactions, analysis),
      upcomingBills: _generateBillReminders(transactions),
      goalAlerts: _generateGoalAlerts(transactions, analysis),
      behavioralInsights: _generateBehavioralInsights(transactions, analysis),
      weeklyPlan: _generateWeeklyPlan(transactions, analysis),
    );
  }

  static List<FinancialAlert> _generateAlerts(
    List<Transaction> transactions,
    FinancialAnalysis analysis,
  ) {
    final alerts = <FinancialAlert>[];
    
    // Alertas de sobregasto
    final overspendAlerts = _generateOverspendAlerts(transactions, analysis);
    alerts.addAll(overspendAlerts);
    
    // Alertas de comportamiento
    final behaviorAlerts = _generateBehaviorAlerts(transactions, analysis);
    alerts.addAll(behaviorAlerts);
    
    // Alertas de tendencias
    final trendAlerts = _generateTrendAlerts(transactions, analysis);
    alerts.addAll(trendAlerts);
    
    // Alertas de anomalías
    final anomalyAlerts = _generateAnomalyAlerts(transactions, analysis);
    alerts.addAll(anomalyAlerts);
    
    return alerts.where((alert) => alert.severity != SeverityLevel.low).toList();
  }

  static List<FinancialAlert> _generateOverspendAlerts(
    List<Transaction> transactions,
    FinancialAnalysis analysis,
  ) {
    final alerts = <FinancialAlert>[];
    
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    final currentMonth = DateTime.now();
    final startOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    
    final currentMonthExpenses = expenseTransactions
        .where((t) => t.date.isAfter(startOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
    
    // Alerta si ha gastado más del 80% del presupuesto estimado
    final estimatedMonthlyBudget = analysis.recommendations.budgetOptimization.recommendedMonthlyBudget;
    final spendingPercentage = estimatedMonthlyBudget > 0 ? 
        (currentMonthExpenses / estimatedMonthlyBudget) * 100 : 0;
    
    if (spendingPercentage > 80) {
      alerts.add(FinancialAlert(
        id: 'overspend_${currentMonth.month}',
        type: AlertType.overBudget,
        severity: spendingPercentage > 100 ? SeverityLevel.critical : SeverityLevel.high,
        title: 'Gastos elevados este mes',
        message: 'Has gastado ${spendingPercentage.toStringAsFixed(1)}% de tu presupuesto mensual',
        amount: currentMonthExpenses - estimatedMonthlyBudget,
        actionable: true,
        suggestedAction: 'Revisar gastos de las últimas semanas y reducir gastos no esenciales',
        category: 'Presupuesto',
        timestamp: DateTime.now(),
      ));
    }
    
    // Alerta por categoría específica
    final categoryTotals = <String, double>{};
    for (final transaction in expenseTransactions.where((t) => t.date.isAfter(startOfMonth))) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }
    
    for (final entry in categoryTotals.entries) {
      final categoryBudget = analysis.recommendations.budgetOptimization.categoryBudgets[entry.key] ?? 0;
      if (categoryBudget > 0) {
        final categoryPercentage = (entry.value / categoryBudget) * 100;
        if (categoryPercentage > 90) {
          alerts.add(FinancialAlert(
            id: 'category_overspend_${entry.key}',
            type: AlertType.categoryLimit,
            severity: categoryPercentage > 100 ? SeverityLevel.high : SeverityLevel.medium,
            title: 'Límite de categoría alcanzado',
            message: 'Has gastado ${categoryPercentage.toStringAsFixed(1)}% del presupuesto para ${entry.key}',
            amount: entry.value - categoryBudget,
            actionable: true,
            suggestedAction: 'Controlar gastos en ${entry.key} por el resto del mes',
            category: entry.key,
            timestamp: DateTime.now(),
          ));
        }
      }
    }
    
    return alerts;
  }

  static List<FinancialAlert> _generateBehaviorAlerts(
    List<Transaction> transactions,
    FinancialAnalysis analysis,
  ) {
    final alerts = <FinancialAlert>[];
    
    // Alerta por comportamiento impulsivo
    if (analysis.behavior.impulseScore < 40) {
      alerts.add(FinancialAlert(
        id: 'impulsive_behavior',
        type: AlertType.behavioral,
        severity: SeverityLevel.medium,
        title: 'Patrón de gastos impulsivos detectado',
        message: 'Tu puntuación de control de impulsos es baja (${analysis.behavior.impulseScore.toStringAsFixed(0)}/100)',
        amount: 0,
        actionable: true,
        suggestedAction: 'Implementar la regla de "esperar 24 horas" antes de compras no planificadas',
        category: 'Comportamiento',
        timestamp: DateTime.now(),
      ));
    }
    
    // Alerta por inconsistencia
    if (analysis.behavior.consistencyScore < 30) {
      alerts.add(FinancialAlert(
        id: 'inconsistent_behavior',
        type: AlertType.behavioral,
        severity: SeverityLevel.medium,
        title: 'Patrones de gasto inconsistentes',
        message: 'Tus patrones de gasto varían significativamente',
        amount: 0,
        actionable: true,
        suggestedAction: 'Establecer una rutina financiera más consistente',
        category: 'Comportamiento',
        timestamp: DateTime.now(),
      ));
    }
    
    return alerts;
  }

  static List<FinancialAlert> _generateTrendAlerts(
    List<Transaction> transactions,
    FinancialAnalysis analysis,
  ) {
    final alerts = <FinancialAlert>[];
    
    // Alerta por tendencia creciente
    if (analysis.trends.daily.trend == TrendDirection.increasing) {
      alerts.add(FinancialAlert(
        id: 'increasing_trend',
        type: AlertType.trend,
        severity: SeverityLevel.medium,
        title: 'Tendencia de gastos al alza',
        message: 'Tus gastos diarios muestran una tendencia creciente',
        amount: 0,
        actionable: true,
        suggestedAction: 'Revisar y optimizar gastos para revertir la tendencia',
        category: 'Tendencias',
        timestamp: DateTime.now(),
      ));
    }
    
    // Alerta por alta volatilidad
    if (analysis.trends.daily.volatility > 50) {
      alerts.add(FinancialAlert(
        id: 'high_volatility',
        type: AlertType.trend,
        severity: SeverityLevel.medium,
        title: 'Alta volatilidad en gastos',
        message: 'Tus gastos varían significativamente día a día',
        amount: 0,
        actionable: true,
        suggestedAction: 'Estabilizar gastos creando un presupuesto más predecible',
        category: 'Tendencias',
        timestamp: DateTime.now(),
      ));
    }
    
    return alerts;
  }

  static List<FinancialAlert> _generateAnomalyAlerts(
    List<Transaction> transactions,
    FinancialAnalysis analysis,
  ) {
    final alerts = <FinancialAlert>[];
    
    final recentAnomalies = analysis.trends.anomalies.detectedAnomalies
        .where((anomaly) => anomaly.severity == SeverityLevel.high || 
                           anomaly.severity == SeverityLevel.critical)
        .toList();
    
    for (final anomaly in recentAnomalies.take(3)) {
      alerts.add(FinancialAlert(
        id: 'anomaly_${anomaly.transaction.id}',
        type: AlertType.anomaly,
        severity: anomaly.severity,
        title: 'Actividad financiera inusual',
        message: anomaly.description,
        amount: anomaly.transaction.amount,
        actionable: anomaly.severity != SeverityLevel.critical,
        suggestedAction: anomaly.severity == SeverityLevel.critical ? 
            'Revisar inmediatamente esta transacción' : 
            'Verificar si esta transacción fue intencional',
        category: anomaly.transaction.category,
        timestamp: anomaly.transaction.date,
      ));
    }
    
    return alerts;
  }

  static List<Recommendation> _generateRecommendations(
    List<Transaction> transactions,
    FinancialAnalysis analysis,
  ) {
    final recommendations = <Recommendation>[];
    
    // Recomendaciones basadas en oportunidades de ahorro
    for (final opportunity in analysis.categories.savingsOpportunities.identifiedOpportunities) {
      recommendations.add(Recommendation(
        id: 'savings_${opportunity.category}',
        type: RecommendationType.savings,
        priority: Priority.high,
        title: opportunity.title,
        description: opportunity.description,
        potentialSavings: opportunity.potentialMonthlySavings,
        effortLevel: opportunity.effortLevel,
        timeframe: opportunity.timeframe,
        actionableSteps: opportunity.actionableSteps,
        category: opportunity.category,
        isImplemented: false,
        impact: ImpactLevel.high,
      ));
    }
    
    // Recomendaciones basadas en optimización
    for (final suggestion in analysis.categories.spendingOptimization.suggestions) {
      recommendations.add(Recommendation(
        id: 'optimization_${suggestion.type}',
        type: RecommendationType.optimization,
        priority: suggestion.priority,
        title: suggestion.title,
        description: suggestion.description,
        potentialSavings: suggestion.estimatedSavings,
        effortLevel: _mapImpactToEffort(suggestion.impact),
        timeframe: Timeframe.shortTerm,
        actionableSteps: _generateOptimizationSteps(suggestion),
        category: 'Optimización',
        isImplemented: false,
        impact: suggestion.impact,
      ));
    }
    
    // Recomendaciones predictivas
    if (analysis.predictions.nextMonthPrediction > 0) {
      recommendations.add(Recommendation(
        id: 'prediction_based',
        type: RecommendationType.preventive,
        priority: Priority.medium,
        title: 'Preparación para próximo mes',
        description: 'Basado en tus patrones, se proyecta un gasto de \$${analysis.predictions.nextMonthPrediction.toStringAsFixed(2)} el próximo mes',
        potentialSavings: analysis.predictions.nextMonthPrediction * 0.15, // 15% de reducción proyectada
        effortLevel: EffortLevel.medium,
        timeframe: Timeframe.shortTerm,
        actionableSteps: [
          'Revisar y ajustar presupuesto para el próximo mes',
          'Identificar gastos opcionales que se pueden reducir',
          'Planificar gastos grandes con anticipación',
        ],
        category: 'Planificación',
        isImplemented: false,
        impact: ImpactLevel.medium,
      ));
    }
    
    return recommendations;
  }

  static List<BillReminder> _generateBillReminders(List<Transaction> transactions) {
    final reminders = <BillReminder>[];
    
    // Buscar patrones de pagos recurrentes
    final recurringPayments = <String, List<Transaction>>{};
    
    for (final transaction in transactions) {
      final key = _identifyRecurringBill(transaction);
      if (key.isNotEmpty) {
        recurringPayments[key] = (recurringPayments[key] ?? [])..add(transaction);
      }
    }
    
    for (final entry in recurringPayments.entries) {
      final payments = entry.value;
      if (payments.length >= 2) {
        payments.sort((a, b) => a.date.compareTo(b.date));
        
        final lastPayment = payments.last;
        final amount = lastPayment.amount;
        final description = lastPayment.description;
        
        // Calcular próxima fecha de pago
        final nextPaymentDate = _calculateNextPaymentDate(lastPayment.date, payments);
        
        reminders.add(BillReminder(
          id: 'bill_${entry.key}',
          description: description,
          amount: amount,
          dueDate: nextPaymentDate,
          category: lastPayment.category,
          isRecurring: true,
          urgency: _calculateBillUrgency(nextPaymentDate),
        ));
      }
    }
    
    return reminders;
  }

  static List<GoalAlert> _generateGoalAlerts(
    List<Transaction> transactions,
    FinancialAnalysis analysis,
  ) {
    final alerts = <GoalAlert>[];
    
    // Simular metas basadas en comportamiento de ahorro
    final incomeTransactions = transactions.where((t) => t.isIncome).toList();
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    
    final monthlyIncome = _calculateMonthlyAverage(incomeTransactions);
    final monthlyExpenses = _calculateMonthlyAverage(expenseTransactions);
    final monthlySavings = monthlyIncome - monthlyExpenses;
    
    if (monthlySavings > 0) {
      // Meta de emergencia (3 meses de gastos)
      final emergencyFund = monthlyExpenses * 3;
      final currentSavings = monthlySavings * _getMonthsOfData(transactions);
      final progressPercentage = (currentSavings / emergencyFund) * 100;
      
      if (progressPercentage > 0 && progressPercentage < 100) {
        alerts.add(GoalAlert(
          id: 'emergency_fund',
          goalType: GoalType.emergencyFund,
          title: 'Fondo de Emergencia',
          targetAmount: emergencyFund,
          currentAmount: currentSavings,
          progressPercentage: progressPercentage,
          daysRemaining: _calculateDaysToGoal(monthlySavings, emergencyFund, currentSavings),
          isOnTrack: _isGoalOnTrack(monthlySavings, emergencyFund, currentSavings),
          milestone: _getNextMilestone(progressPercentage),
        ));
      }
      
      // Meta de ahorro anual
      final annualSavingsGoal = monthlySavings * 12;
      final yearProgress = (currentSavings / annualSavingsGoal) * 100;
      
      if (yearProgress > 0 && yearProgress < 100) {
        alerts.add(GoalAlert(
          id: 'annual_savings',
          goalType: GoalType.savings,
          title: 'Ahorro Anual',
          targetAmount: annualSavingsGoal,
          currentAmount: currentSavings,
          progressPercentage: yearProgress,
          daysRemaining: _calculateDaysToGoal(monthlySavings, annualSavingsGoal, currentSavings),
          isOnTrack: _isGoalOnTrack(monthlySavings, annualSavingsGoal, currentSavings),
          milestone: _getNextMilestone(yearProgress),
        ));
      }
    }
    
    return alerts;
  }

  static List<BehavioralInsight> _generateBehavioralInsights(
    List<Transaction> transactions,
    FinancialAnalysis analysis,
  ) {
    final insights = <BehavioralInsight>[];
    
    // Insight sobre horarios de gasto
    final hourlySpending = <int, double>{};
    for (final transaction in transactions.where((t) => !t.isIncome)) {
      hourlySpending[transaction.date.hour] = 
          (hourlySpending[transaction.date.hour] ?? 0) + transaction.amount;
    }
    
    final peakHour = hourlySpending.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    if (peakHour.value > 50) {
      insights.add(BehavioralInsight(
        id: 'peak_hour_spending',
        type: InsightType.timing,
        title: 'Gastos concentrados en horario específico',
        description: 'Realizas la mayoría de tus gastos alrededor de las ${peakHour.key}:00',
        actionable: true,
        confidence: 75.0,
        suggestion: 'Considera evitar compras durante tu horario de gasto peak',
        category: 'Timing',
      ));
    }
    
    // Insight sobre categorías dominantes
    final categoryTotals = <String, double>{};
    for (final transaction in transactions.where((t) => !t.isIncome)) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }
    
    final totalSpent = categoryTotals.values.reduce((a, b) => a + b);
    final dominantCategory = categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    final categoryPercentage = (dominantCategory.value / totalSpent) * 100;
    if (categoryPercentage > 40) {
      insights.add(BehavioralInsight(
        id: 'dominant_category',
        type: InsightType.category,
        title: 'Dependencia en una categoría principal',
        description: '${categoryPercentage.toStringAsFixed(1)}% de tus gastos se concentran en ${dominantCategory.key}',
        actionable: true,
        confidence: 85.0,
        suggestion: 'Considera diversificar tus gastos o establecer límites para esta categoría',
        category: dominantCategory.key,
      ));
    }
    
    // Insight sobre patrones de fin de semana
    final weekendSpending = transactions
        .where((t) => !t.isIncome && (t.date.weekday == 6 || t.date.weekday == 7))
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final weekdaySpending = transactions
        .where((t) => !t.isIncome && t.date.weekday >= 1 && t.date.weekday <= 5)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final weekendDays = 2;
    final weekdayDays = 5;
    final avgWeekend = weekendSpending / weekendDays;
    const avgWeekday = weekdaySpending / weekdayDays;
    
    if (avgWeekend > avgWeekday * 1.5) {
      insights.add(BehavioralInsight(
        id: 'weekend_spending',
        type: InsightType.timing,
        title: 'Gastos elevados en fin de semana',
        description: 'Gastas ${((avgWeekend / avgWeekday - 1) * 100).toStringAsFixed(1)}% más los fines de semana',
        actionable: true,
        confidence: 80.0,
        suggestion: 'Planifica actividades económicas para el fin de semana',
        category: 'Timing',
      ));
    }
    
    return insights;
  }

  static WeeklyActionPlan _generateWeeklyPlan(
    List<Transaction> transactions,
    FinancialAnalysis analysis,
  ) {
    final actions = <WeeklyAction>[];
    
    // Acciones basadas en recomendaciones prioritarias
    final topRecommendations = analysis.recommendations.personalizedRecommendations
        .where((r) => r.priority == Priority.high)
        .take(3);
    
    for (final recommendation in topRecommendations) {
      actions.add(WeeklyAction(
        id: 'action_${recommendation.id}',
        title: recommendation.title,
        description: recommendation.description,
        category: recommendation.category,
        effortLevel: recommendation.effortLevel,
        estimatedTime: _estimateActionTime(recommendation.effortLevel),
        potentialSavings: recommendation.potentialSavings,
        isCompleted: false,
        deadline: DateTime.now().add(Duration(days: 7)),
      ));
    }
    
    // Acciones basadas en alertas activas
    final urgentAlerts = analysis.recommendations.activeAlerts
        .where((a) => a.severity == SeverityLevel.high || a.severity == SeverityLevel.critical)
        .take(2);
    
    for (final alert in urgentAlerts) {
      actions.add(WeeklyAction(
        id: 'alert_action_${alert.id}',
        title: 'Resolver: ${alert.title}',
        description: alert.suggestedAction,
        category: alert.category,
        effortLevel: EffortLevel.medium,
        estimatedTime: const Duration(hours: 2),
        potentialSavings: alert.amount > 0 ? alert.amount * 0.5 : 0,
        isCompleted: false,
        deadline: DateTime.now().add(Duration(days: 3)),
      ));
    }
    
    // Acciones de seguimiento
    actions.add(WeeklyAction(
      id: 'review_budget',
      title: 'Revisar y ajustar presupuesto',
      description: 'Evaluar el progreso del presupuesto actual y hacer ajustes necesarios',
      category: 'Presupuesto',
      effortLevel: EffortLevel.low,
      estimatedTime: const Duration(minutes: 30),
      potentialSavings: 0,
      isCompleted: false,
      deadline: DateTime.now().add(Duration(days: 5)),
    ));
    
    return WeeklyActionPlan(
      weekStartDate: _getWeekStart(DateTime.now()),
      actions: actions,
      totalPotentialSavings: actions.fold(0.0, (sum, action) => sum + action.potentialSavings),
      priority: actions.isNotEmpty ? Priority.high : Priority.medium,
    );
  }

  // Métodos auxiliares
  static String _identifyRecurringBill(Transaction transaction) {
    final description = transaction.description.toLowerCase();
    if (description.contains('netflix') || description.contains('spotify')) {
      return 'streaming_${transaction.description}';
    } else if (description.contains('luz') || description.contains('agua') || description.contains('internet')) {
      return 'utilities_${transaction.description}';
    } else if (description.contains('seguro')) {
      return 'insurance_${transaction.description}';
    }
    return '';
  }

  static DateTime _calculateNextPaymentDate(DateTime lastPayment, List<Transaction> payments) {
    // Analizar frecuencia de pagos
    if (payments.length < 2) {
      return lastPayment.add(const Duration(days: 30)); // Asumir mensual
    }
    
    final sortedPayments = payments.toList()..sort((a, b) => a.date.compareTo(b.date));
    final intervals = <int>[];
    
    for (int i = 1; i < sortedPayments.length; i++) {
      final daysDiff = sortedPayments[i].date.difference(sortedPayments[i-1].date).inDays;
      intervals.add(daysDiff);
    }
    
    // Determinar frecuencia más común
    intervals.sort();
    final medianInterval = intervals[intervals.length ~/ 2];
    
    return lastPayment.add(Duration(days: medianInterval));
  }

  static UrgencyLevel _calculateBillUrgency(DateTime dueDate) {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    
    if (daysUntilDue <= 3) return UrgencyLevel.urgent;
    if (daysUntilDue <= 7) return UrgencyLevel.high;
    if (daysUntilDue <= 14) return UrgencyLevel.medium;
    return UrgencyLevel.low;
  }

  static double _calculateMonthlyAverage(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;
    
    final sorted = transactions.toList()..sort((a, b) => a.date.compareTo(b.date));
    final firstDate = sorted.first.date;
    final lastDate = sorted.last.date;
    final daysDiff = lastDate.difference(firstDate).inDays;
    
    if (daysDiff == 0) return 0.0;
    
    final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final monthsDiff = daysDiff / 30.0;
    return totalAmount / monthsDiff;
  }

  static int _getMonthsOfData(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0;
    
    final sorted = transactions.toList()..sort((a, b) => a.date.compareTo(b.date));
    final firstDate = sorted.first.date;
    final lastDate = sorted.last.date;
    final daysDiff = lastDate.difference(firstDate).inDays;
    
    return (daysDiff / 30).ceil();
  }

  static int _calculateDaysToGoal(double monthlySavings, double targetAmount, double currentAmount) {
    if (monthlySavings <= 0) return 0;
    final remaining = targetAmount - currentAmount;
    return (remaining / monthlySavings * 30).ceil();
  }

  static bool _isGoalOnTrack(double monthlySavings, double targetAmount, double currentAmount) {
    final remaining = targetAmount - currentAmount;
    final projectedMonths = remaining / monthlySavings;
    return projectedMonths <= 12; // Meta a 12 meses
  }

  static String _getNextMilestone(double progressPercentage) {
    if (progressPercentage >= 75) return 'Meta casi alcanzada';
    if (progressPercentage >= 50) return 'Meta a mitad de camino';
    if (progressPercentage >= 25) return 'Primer cuarto completado';
    return 'Inicio del progreso';
  }

  static EffortLevel _mapImpactToEffort(ImpactLevel impact) {
    switch (impact) {
      case ImpactLevel.high: return EffortLevel.high;
      case ImpactLevel.medium: return EffortLevel.medium;
      case ImpactLevel.low: return EffortLevel.low;
    }
  }

  static List<String> _generateOptimizationSteps(OptimizationSuggestion suggestion) {
    final steps = <String>[];
    
    switch (suggestion.type) {
      case SuggestionType.savingsRate:
        steps.addAll([
          'Calcular ingresos y gastos actuales',
          'Reducir gastos no esenciales en 15%',
          'Automatizar ahorros mensuales',
          'Revisar suscripciones y cancelar las no utilizadas',
        ]);
        break;
      case SuggestionType.categoryDiversification:
        steps.addAll([
          'Identificar la categoría dominante',
          'Establecer límite mensual para esa categoría',
          'Buscar alternativas más económicas',
          'Distribuir gastos en otras categorías',
        ]);
        break;
      default:
        steps.add('Revisar y optimizar patrones de gasto');
    }
    
    return steps;
  }

  static Duration _estimateActionTime(EffortLevel effortLevel) {
    switch (effortLevel) {
      case EffortLevel.low: return const Duration(hours: 1);
      case EffortLevel.medium: return const Duration(hours: 3);
      case EffortLevel.high: return const Duration(days: 1);
    }
  }

  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  Map<String, dynamic> toMap() {
    return {
      'activeAlerts': activeAlerts.map((a) => a.toMap()).toList(),
      'personalizedRecommendations': personalizedRecommendations.map((r) => r.toMap()).toList(),
      'upcomingBills': upcomingBills.map((b) => b.toMap()).toList(),
      'goalAlerts': goalAlerts.map((g) => g.toMap()).toList(),
      'behavioralInsights': behavioralInsights.map((i) => i.toMap()).toList(),
      'weeklyPlan': weeklyPlan.toMap(),
    };
  }

  factory AlertsAndRecommendations.fromMap(Map<String, dynamic> map) {
    return AlertsAndRecommendations(
      activeAlerts: (map['activeAlerts'] as List<dynamic>?)
          ?.map((data) => FinancialAlert.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      personalizedRecommendations: (map['personalizedRecommendations'] as List<dynamic>?)
          ?.map((data) => Recommendation.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      upcomingBills: (map['upcomingBills'] as List<dynamic>?)
          ?.map((data) => BillReminder.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      goalAlerts: (map['goalAlerts'] as List<dynamic>?)
          ?.map((data) => GoalAlert.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      behavioralInsights: (map['behavioralInsights'] as List<dynamic>?)
          ?.map((data) => BehavioralInsight.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      weeklyPlan: WeeklyPlan.fromMap(map['weeklyPlan'] ?? {}),
    );
  }
}

// Alerta financiera
class FinancialAlert {
  final String id;
  final AlertType type;
  final SeverityLevel severity;
  final String title;
  final String message;
  final double amount;
  final bool actionable;
  final String suggestedAction;
  final String category;
  final DateTime timestamp;

  FinancialAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.amount,
    required this.actionable,
    required this.suggestedAction,
    required this.category,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'severity': severity.toString(),
      'title': title,
      'message': message,
      'amount': amount,
      'actionable': actionable,
      'suggestedAction': suggestedAction,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FinancialAlert.fromMap(Map<String, dynamic> map) {
    return FinancialAlert(
      id: map['id'] ?? '',
      type: AlertType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => AlertType.general,
      ),
      severity: SeverityLevel.values.firstWhere(
        (e) => e.toString() == map['severity'],
        orElse: () => SeverityLevel.medium,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      actionable: map['actionable'] ?? false,
      suggestedAction: map['suggestedAction'] ?? '',
      category: map['category'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Recomendación personalizada
class Recommendation {
  final String id;
  final RecommendationType type;
  final Priority priority;
  final String title;
  final String description;
  final double potentialSavings;
  final EffortLevel effortLevel;
  final Timeframe timeframe;
  final List<String> actionableSteps;
  final String category;
  final bool isImplemented;
  final ImpactLevel impact;

  Recommendation({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.potentialSavings,
    required this.effortLevel,
    required this.timeframe,
    required this.actionableSteps,
    required this.category,
    required this.isImplemented,
    required this.impact,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'priority': priority.toString(),
      'title': title,
      'description': description,
      'potentialSavings': potentialSavings,
      'effortLevel': effortLevel.toString(),
      'timeframe': timeframe.toString(),
      'actionableSteps': actionableSteps,
      'category': category,
      'isImplemented': isImplemented,
      'impact': impact.toString(),
    };
  }

  factory Recommendation.fromMap(Map<String, dynamic> map) {
    return Recommendation(
      id: map['id'] ?? '',
      type: RecommendationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => RecommendationType.general,
      ),
      priority: Priority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => Priority.medium,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      potentialSavings: (map['potentialSavings'] ?? 0.0).toDouble(),
      effortLevel: EffortLevel.values.firstWhere(
        (e) => e.toString() == map['effortLevel'],
        orElse: () => EffortLevel.medium,
      ),
      timeframe: Timeframe.values.firstWhere(
        (e) => e.toString() == map['timeframe'],
        orElse: () => Timeframe.mediumTerm,
      ),
      actionableSteps: List<String>.from(map['actionableSteps'] ?? []),
      category: map['category'] ?? '',
      isImplemented: map['isImplemented'] ?? false,
      impact: ImpactLevel.values.firstWhere(
        (e) => e.toString() == map['impact'],
        orElse: () => ImpactLevel.medium,
      ),
    );
  }
}

// Recordatorio de facturas
class BillReminder {
  final String id;
  final String description;
  final double amount;
  final DateTime dueDate;
  final String category;
  final bool isRecurring;
  final UrgencyLevel urgency;

  BillReminder({
    required this.id,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.category,
    required this.isRecurring,
    required this.urgency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'category': category,
      'isRecurring': isRecurring,
      'urgency': urgency.toString(),
    };
  }

  factory BillReminder.fromMap(Map<String, dynamic> map) {
    return BillReminder(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      dueDate: DateTime.parse(map['dueDate'] ?? DateTime.now().toIso8601String()),
      category: map['category'] ?? '',
      isRecurring: map['isRecurring'] ?? false,
      urgency: UrgencyLevel.values.firstWhere(
        (e) => e.toString() == map['urgency'],
        orElse: () => UrgencyLevel.medium,
      ),
    );
  }
}

// Alerta de metas
class GoalAlert {
  final String id;
  final GoalType goalType;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final double progressPercentage;
  final int daysRemaining;
  final bool isOnTrack;
  final String milestone;

  GoalAlert({
    required this.id,
    required this.goalType,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.progressPercentage,
    required this.daysRemaining,
    required this.isOnTrack,
    required this.milestone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalType': goalType.toString(),
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'progressPercentage': progressPercentage,
      'daysRemaining': daysRemaining,
      'isOnTrack': isOnTrack,
      'milestone': milestone,
    };
  }

  factory GoalAlert.fromMap(Map<String, dynamic> map) {
    return GoalAlert(
      id: map['id'] ?? '',
      goalType: GoalType.values.firstWhere(
        (e) => e.toString() == map['goalType'],
        orElse: () => GoalType.savings,
      ),
      title: map['title'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0.0).toDouble(),
      progressPercentage: (map['progressPercentage'] ?? 0.0).toDouble(),
      daysRemaining: map['daysRemaining'] ?? 0,
      isOnTrack: map['isOnTrack'] ?? false,
      milestone: map['milestone'] ?? '',
    );
  }
}

// Insight de comportamiento
class BehavioralInsight {
  final String id;
  final InsightType type;
  final String title;
  final String description;
  final bool actionable;
  final double confidence;
  final String suggestion;
  final String category;

  BehavioralInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.actionable,
    required this.confidence,
    required this.suggestion,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'description': description,
      'actionable': actionable,
      'confidence': confidence,
      'suggestion': suggestion,
      'category': category,
    };
  }

  factory BehavioralInsight.fromMap(Map<String, dynamic> map) {
    return BehavioralInsight(
      id: map['id'] ?? '',
      type: InsightType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => InsightType.general,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      actionable: map['actionable'] ?? false,
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      suggestion: map['suggestion'] ?? '',
      category: map['category'] ?? '',
    );
  }
}

// Plan de acción semanal
class WeeklyActionPlan {
  final DateTime weekStartDate;
  final List<WeeklyAction> actions;
  final double totalPotentialSavings;
  final Priority priority;

  WeeklyActionPlan({
    required this.weekStartDate,
    required this.actions,
    required this.totalPotentialSavings,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekStartDate': weekStartDate.toIso8601String(),
      'actions': actions.map((a) => a.toMap()).toList(),
      'totalPotentialSavings': totalPotentialSavings,
      'priority': priority.toString(),
    };
  }

  factory WeeklyActionPlan.fromMap(Map<String, dynamic> map) {
    return WeeklyActionPlan(
      weekStartDate: DateTime.parse(map['weekStartDate'] ?? DateTime.now().toIso8601String()),
      actions: (map['actions'] as List<dynamic>?)
          ?.map((data) => WeeklyAction.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      totalPotentialSavings: (map['totalPotentialSavings'] ?? 0.0).toDouble(),
      priority: Priority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => Priority.medium,
      ),
    );
  }
}

// Acción semanal
class WeeklyAction {
  final String id;
  final String title;
  final String description;
  final String category;
  final EffortLevel effortLevel;
  final Duration estimatedTime;
  final double potentialSavings;
  final bool isCompleted;
  final DateTime deadline;

  WeeklyAction({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.effortLevel,
    required this.estimatedTime,
    required this.potentialSavings,
    required this.isCompleted,
    required this.deadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'effortLevel': effortLevel.toString(),
      'estimatedTime': estimatedTime.inMinutes,
      'potentialSavings': potentialSavings,
      'isCompleted': isCompleted,
      'deadline': deadline.toIso8601String(),
    };
  }

  factory WeeklyAction.fromMap(Map<String, dynamic> map) {
    return WeeklyAction(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      effortLevel: EffortLevel.values.firstWhere(
        (e) => e.toString() == map['effortLevel'],
        orElse: () => EffortLevel.medium,
      ),
      estimatedTime: Duration(minutes: map['estimatedTime'] ?? 60),
      potentialSavings: (map['potentialSavings'] ?? 0.0).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      deadline: DateTime.parse(map['deadline'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Enums adicionales
enum RecommendationType {
  general,
  savings,
  optimization,
  preventive,
  behavioral
}

enum InsightType {
  general,
  timing,
  category,
  amount,
  frequency
}

enum UrgencyLevel {
  low,
  medium,
  high,
  urgent
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