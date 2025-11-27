import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'financial_analysis_models.dart';
import 'trends_analysis_models.dart';
import 'category_analysis_models.dart';
import 'predictive_insights_models.dart';
import 'alerts_recommendations_models.dart';

/// Servicio principal para análisis financiero completo
class FinancialAnalysisService {
  static final FinancialAnalysisService _instance = FinancialAnalysisService._internal();
  factory FinancialAnalysisService() => _instance;
  FinancialAnalysisService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Streams para actualizaciones en tiempo real
  final StreamController<FinancialAnalysis> _analysisController = 
      StreamController<FinancialAnalysis>.broadcast();
  final StreamController<Map<String, dynamic>> _dashboardController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters para streams
  Stream<FinancialAnalysis> get analysisUpdates => _analysisController.stream;
  Stream<Map<String, dynamic>> get dashboardUpdates => _dashboardController.stream;

  /// Genera análisis financiero completo
  Future<FinancialAnalysis> generateCompleteAnalysis(List<Transaction> transactions) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    // Crear análisis base
    final behavior = SpendingBehavior.analyzeTransactions(transactions);
    final trends = SpendingTrends.analyze(transactions);
    final categories = CategoryAnalysis.analyze(transactions);
    final predictions = PredictiveInsights.analyze(transactions);
    final health = _calculateFinancialHealth(transactions, behavior);
    final recommendations = AlertsAndRecommendations.generate(transactions, 
        FinancialAnalysis(
          userId: userId,
          analysisDate: DateTime.now(),
          behavior: behavior,
          health: health,
          trends: trends,
          categories: categories,
          predictions: predictions,
          recommendations: recommendations,
        ));

    final analysis = FinancialAnalysis(
      userId: userId,
      analysisDate: DateTime.now(),
      behavior: behavior,
      health: health,
      trends: trends,
      categories: categories,
      predictions: predictions,
      recommendations: recommendations,
    );

    // Guardar en Firestore
    await _saveAnalysisToFirestore(analysis);

    // Emitir actualización
    _analysisController.add(analysis);

    return analysis;
  }

  /// Obtiene análisis existente desde Firestore
  Future<FinancialAnalysis?> getStoredAnalysis(String userId) async {
    try {
      final doc = await _firestore
          .collection('financialAnalysis')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return FinancialAnalysis.fromMap(doc.data()!);
    } catch (e) {
      print('Error obteniendo análisis: $e');
      return null;
    }
  }

  /// Actualiza análisis con nuevas transacciones
  Future<FinancialAnalysis> updateAnalysisWithNewTransaction(
    Transaction newTransaction, 
    List<Transaction> allTransactions
  ) async {
    // Validar la nueva transacción
    if (!_validateTransaction(newTransaction)) {
      throw Exception('Transacción inválida');
    }

    // Regenerar análisis completo
    final updatedTransactions = List<Transaction>.from(allTransactions)..add(newTransaction);
    return await generateCompleteAnalysis(updatedTransactions);
  }

  /// Genera métricas específicas del dashboard
  Future<Map<String, dynamic>> generateDashboardMetrics(List<Transaction> transactions) async {
    final analysis = await generateCompleteAnalysis(transactions);
    
    final metrics = {
      // Métricas principales
      'totalBalance': _calculateTotalBalance(transactions),
      'monthlyExpenses': analysis.trends.monthly.averageMonthlySpent,
      'savingsRate': analysis.health.savingsRate,
      'healthScore': analysis.health.healthScore,
      
      // Tendencias
      'expenseTrend': analysis.trends.monthly.trend.toString(),
      'monthlyGrowth': analysis.trends.monthly.monthOverMonthChange,
      'predictedNextMonth': analysis.predictions.nextMonthPrediction,
      
      // Alertas
      'activeAlertsCount': analysis.recommendations.activeAlerts.length,
      'criticalAlertsCount': analysis.recommendations.activeAlerts
          .where((a) => a.severity == SeverityLevel.critical).length,
      
      // Oportunidades
      'savingsOpportunities': analysis.categories.savingsOpportunities.identifiedOpportunities.length,
      'potentialMonthlySavings': analysis.categories.savingsOpportunities.totalPotentialSavings,
      
      // Comportamiento
      'impulseScore': analysis.behavior.impulseScore,
      'planningScore': analysis.behavior.planningScore,
      'consistencyScore': analysis.behavior.consistencyScore,
      
      // Predicciones
      'predictionConfidence': analysis.predictions.predictionConfidence,
      'riskForecast': analysis.predictions.riskForecasts.length,
      
      // Metas
      'goalsOnTrack': analysis.recommendations.goalAlerts
          .where((g) => g.isOnTrack).length,
      'goalsTotal': analysis.recommendations.goalAlerts.length,
      
      // Insights semanales
      'weeklyActionCount': analysis.recommendations.weeklyPlan.actions.length,
      'weeklyPotentialSavings': analysis.recommendations.weeklyPlan.totalPotentialSavings,
    };

    _dashboardController.add(metrics);
    return metrics;
  }

  /// Obtiene insights específicos por categoría
  Future<CategoryBreakdown> getCategoryInsights(String categoryName, List<Transaction> transactions) async {
    final categoryTransactions = transactions
        .where((t) => t.category == categoryName && !t.isIncome)
        .toList();

    if (categoryTransactions.isEmpty) {
      throw Exception('No se encontraron transacciones para la categoría');
    }

    final breakdowns = CategoryBreakdown.analyzeAll(transactions);
    return breakdowns.firstWhere((b) => b.categoryName == categoryName);
  }

  /// Analiza progreso hacia metas financieras
  Future<Map<String, dynamic>> analyzeGoalProgress(String userId) async {
    // Obtener metas del usuario desde Firestore
    final goalsSnapshot = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('metas')
        .get();

    final goals = goalsSnapshot.docs.map((doc) => doc.data()).toList();
    
    // Obtener transacciones para calcular progreso
    final transactionsSnapshot = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('gastos')
        .get();

    final transactions = transactionsSnapshot.docs
        .map((doc) => Transaction.fromMap(doc.data()))
        .toList();

    final analysis = await generateCompleteAnalysis(transactions);

    final goalProgress = <String, dynamic>{};
    
    for (final goal in goals) {
      final category = goal['categoria'] ?? 'general';
      final targetAmount = (goal['monto_objetivo'] ?? 0.0).toDouble();
      final currentAmount = transactions
          .where((t) => t.category.toLowerCase().contains(category.toLowerCase()))
          .fold(0.0, (sum, t) => sum + t.amount);
      
      goalProgress[goal['id'] ?? category] = {
        'title': goal['titulo'] ?? 'Meta General',
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'progress': targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0,
        'remaining': targetAmount - currentAmount,
        'daysRemaining': _calculateDaysToGoal(currentAmount, targetAmount),
        'isOnTrack': _isGoalOnTrack(currentAmount, targetAmount),
        'recommendations': _getGoalRecommendations(category, currentAmount, targetAmount),
      };
    }

    return goalProgress;
  }

  /// Genera reporte de análisis para exportar
  Future<Map<String, dynamic>> generateAnalysisReport(String userId) async {
    final analysis = await getStoredAnalysis(userId);
    if (analysis == null) {
      throw Exception('No se encontró análisis para generar reporte');
    }

    final transactionsSnapshot = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('gastos')
        .get();

    final transactions = transactionsSnapshot.docs
        .map((doc) => Transaction.fromMap(doc.data()))
        .toList();

    final report = {
      'generatedAt': DateTime.now().toIso8601String(),
      'period': _getAnalysisPeriod(transactions),
      'summary': {
        'totalIncome': transactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount),
        'totalExpenses': transactions.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount),
        'netSavings': transactions.fold(0.0, (sum, t) => sum + (t.isIncome ? t.amount : -t.amount)),
        'topExpenseCategory': _getTopExpenseCategory(transactions),
      },
      'analysis': analysis.toMap(),
      'insights': {
        'behavior': _summarizeBehavior(analysis.behavior),
        'trends': _summarizeTrends(analysis.trends),
        'opportunities': _summarizeOpportunities(analysis.categories.savingsOpportunities),
        'risks': _summarizeRisks(analysis.predictions.riskForecasts),
      },
      'recommendations': _prioritizeRecommendations(analysis.recommendations.personalizedRecommendations),
    };

    return report;
  }

  /// Monitorea cambios en tiempo real
  StreamSubscription<void> startRealTimeMonitoring(String userId) {
    // Escuchar cambios en gastos
    final expensesSubscription = _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('gastos')
        .snapshots()
        .listen((snapshot) async {
          final transactions = snapshot.docs
              .map((doc) => Transaction.fromMap(doc.data()))
              .toList();
          
          if (transactions.isNotEmpty) {
            await generateDashboardMetrics(transactions);
          }
        });

    // Escuchar cambios en ingresos
    final incomeSubscription = _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('ingresos')
        .snapshots()
        .listen((snapshot) async {
          final transactions = snapshot.docs
              .map((doc) => Transaction.fromMap({
                    'id': doc.id,
                    'amount': (doc.data()['monto'] ?? 0.0).toDouble(),
                    'category': 'ingreso',
                    'description': doc.data()['descripcion'] ?? '',
                    'date': (doc.data()['fecha'] as Timestamp).toDate().toIso8601String(),
                    'isIncome': true,
                  }))
              .toList();
          
          if (transactions.isNotEmpty) {
            // Combinar con gastos existentes y regenerar análisis
            final expensesSnapshot = await _firestore
                .collection('usuarios')
                .doc(userId)
                .collection('gastos')
                .get();
            
            final allTransactions = [
              ...transactions,
              ...expensesSnapshot.docs.map((doc) => Transaction.fromMap(doc.data())),
            ];
            
            await generateDashboardMetrics(allTransactions);
          }
        });

    // Retornar un subscription que maneje ambos streams
    return Stream.value(null).listen((_) {
      expensesSubscription.cancel();
      incomeSubscription.cancel();
    });
  }

  /// Métodos privados auxiliares

  Future<void> _saveAnalysisToFirestore(FinancialAnalysis analysis) async {
    try {
      await _firestore
          .collection('financialAnalysis')
          .doc(analysis.userId)
          .set(analysis.toMap());
    } catch (e) {
      print('Error guardando análisis: $e');
    }
  }

  bool _validateTransaction(Transaction transaction) {
    return transaction.amount > 0 &&
           transaction.category.isNotEmpty &&
           transaction.description.isNotEmpty;
  }

  FinancialHealth _calculateFinancialHealth(List<Transaction> transactions, SpendingBehavior behavior) {
    final incomeTransactions = transactions.where((t) => t.isIncome).toList();
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    
    final totalIncome = incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
    
    final savingsRate = totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0;
    final healthScore = _calculateHealthScore(behavior, savingsRate, totalExpenses, totalIncome);
    
    return FinancialHealth(
      healthScore: healthScore,
      savingsRate: savingsRate,
      debtToIncomeRatio: 0.0, // Simplificado
      emergencyFundMonths: 0.0, // Requiere datos adicionales
      hasEmergencyFund: savingsRate > 20,
      monthlyBudgetAdherence: _calculateBudgetAdherence(transactions),
      overallRisk: behavior.riskLevel,
      healthFlags: _identifyHealthFlags(behavior, savingsRate),
      lastCalculation: DateTime.now(),
    );
  }

  double _calculateHealthScore(SpendingBehavior behavior, double savingsRate, double expenses, double income) {
    final behaviorScore = (behavior.planningScore + behavior.consistencyScore) / 2;
    final savingsScore = savingsRate > 20 ? 100 : savingsRate * 5;
    final riskScore = behavior.riskLevel == RiskLevel.low ? 100 : 
                     behavior.riskLevel == RiskLevel.medium ? 70 : 40;
    
    return (behaviorScore + savingsScore + riskScore) / 3;
  }

  double _calculateBudgetAdherence(List<Transaction> transactions) {
    // Simplificado: asumir adherencia basada en consistencia
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    if (expenseTransactions.isEmpty) return 100.0;
    
    final categoryTotals = <String, double>{};
    for (final transaction in expenseTransactions) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }
    
    final maxCategory = categoryTotals.values.isEmpty ? 0 : 
        categoryTotals.values.reduce((a, b) => a > b ? a : b);
    final totalSpent = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
    
    final concentrationRatio = totalSpent > 0 ? maxCategory / totalSpent : 0;
    return (100 - (concentrationRatio * 100)).clamp(0.0, 100.0);
  }

  List<String> _identifyHealthFlags(SpendingBehavior behavior, double savingsRate) {
    final flags = <String>[];
    
    if (behavior.impulseScore < 30) {
      flags.add('gastos_impulsivos');
    }
    
    if (savingsRate < 10) {
      flags.add('baja_tasa_ahorro');
    }
    
    if (behavior.consistencyScore < 40) {
      flags.add('patrones_inconsistentes');
    }
    
    if (behavior.riskLevel == RiskLevel.high || behavior.riskLevel == RiskLevel.critical) {
      flags.add('alto_riesgo_financiero');
    }
    
    return flags;
  }

  double _calculateTotalBalance(List<Transaction> transactions) {
    return transactions.fold(0.0, (sum, t) => 
        sum + (t.isIncome ? t.amount : -t.amount));
  }

  String _getTopExpenseCategory(List<Transaction> transactions) {
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    if (expenseTransactions.isEmpty) return 'N/A';
    
    final categoryTotals = <String, double>{};
    for (final transaction in expenseTransactions) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }
    
    final topCategory = categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return topCategory.key;
  }

  String _getAnalysisPeriod(List<Transaction> transactions) {
    if (transactions.isEmpty) return 'Sin datos';
    
    final sorted = transactions.toList()..sort((a, b) => a.date.compareTo(b.date));
    final firstDate = sorted.first.date;
    final lastDate = sorted.last.date;
    final daysDiff = lastDate.difference(firstDate).inDays;
    
    if (daysDiff < 30) return 'Últimos ${daysDiff} días';
    if (daysDiff < 365) return 'Últimos ${(daysDiff / 30).round()} meses';
    return 'Últimos ${(daysDiff / 365).round()} años';
  }

  String _summarizeBehavior(SpendingBehavior behavior) {
    final score = (behavior.planningScore + behavior.consistencyScore) / 2;
    if (score > 80) return 'Excelente disciplina financiera';
    if (score > 60) return 'Buen control financiero con algunas áreas de mejora';
    if (score > 40) return 'Necesita mejorar hábitos de gasto';
    return 'Requiere atención urgente en gestión financiera';
  }

  String _summarizeTrends(SpendingTrends trends) {
    final direction = trends.monthly.trend;
    switch (direction) {
      case TrendDirection.increasing:
        return 'Gastos en tendencia creciente - requiere atención';
      case TrendDirection.decreasing:
        return 'Gastos decreasing - excelente progreso';
      case TrendDirection.stable:
        return 'Gastos estables - buen control';
    }
  }

  String _summarizeOpportunities(SavingsOpportunities opportunities) {
    if (opportunities.identifiedOpportunities.isEmpty) {
      return 'No se identificaron oportunidades específicas de ahorro';
    }
    
    final topOpp = opportunities.identifiedOpportunities.first;
    return 'Principal oportunidad: ${topOpp.title} (potencial \$${topOpp.potentialMonthlySavings.toStringAsFixed(0)}/mes)';
  }

  String _summarizeRisks(List<RiskForecast> risks) {
    final highRiskCount = risks.where((r) => r.probability > 0.5).length;
    if (highRiskCount == 0) return 'Bajo riesgo financiero detectado';
    if (highRiskCount == 1) return 'Un riesgo financiero requiere atención';
    return '$highRiskCount riesgos financieros necesitan monitoreo';
  }

  List<Map<String, dynamic>> _prioritizeRecommendations(List<Recommendation> recommendations) {
    return recommendations
        .where((r) => r.priority == Priority.high)
        .take(5)
        .map((r) => {
              'title': r.title,
              'description': r.description,
              'potentialSavings': r.potentialSavings,
              'effortLevel': r.effortLevel.toString(),
            })
        .toList();
  }

  int _calculateDaysToGoal(double currentAmount, double targetAmount) {
    final monthlySavings = 100.0; // Asumir $100/mes - se puede calcular con datos reales
    final remaining = targetAmount - currentAmount;
    return remaining > 0 ? (remaining / monthlySavings * 30).round() : 0;
  }

  bool _isGoalOnTrack(double currentAmount, double targetAmount) {
    final progress = targetAmount > 0 ? currentAmount / targetAmount : 0;
    return progress >= 0.5; // Al menos 50% del progreso para estar "en camino"
  }

  List<String> _getGoalRecommendations(String category, double currentAmount, double targetAmount) {
    final recommendations = <String>[];
    
    if (currentAmount < targetAmount * 0.3) {
      recommendations.add('Aumentar frecuencia de ahorro para esta meta');
    }
    
    if (category.toLowerCase().contains('ahorro')) {
      recommendations.add('Automatizar transferencias mensuales');
    }
    
    return recommendations;
  }

  /// Libera recursos
  void dispose() {
    _analysisController.close();
    _dashboardController.close();
  }
}