import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/financial_analysis_models.dart';
import '../../models/trends_analysis_models.dart';
import '../../models/category_analysis_models.dart';
import '../../models/predictive_insights_models.dart';
import '../../models/alerts_recommendations_models.dart';
import '../../services/financial_analysis_service.dart';

/// Provider para el estado del análisis financiero
class FinancialAnalysisProvider extends ChangeNotifier {
  final FinancialAnalysisService _service = FinancialAnalysisService();
  
  FinancialAnalysis? _analysis;
  Map<String, dynamic> _dashboardMetrics = {};
  bool _isLoading = true;
  String? _error;

  // Getters
  FinancialAnalysis? get analysis => _analysis;
  Map<String, dynamic> get dashboardMetrics => _dashboardMetrics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Inicializar el análisis
  Future<void> initializeAnalysis(List<Transaction> transactions) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Generar análisis completo
      _analysis = await _service.generateCompleteAnalysis(transactions);
      _dashboardMetrics = await _service.generateDashboardMetrics(transactions);
      
      _isLoading = false;
      notifyListeners();

      // Suscribirse a actualizaciones en tiempo real
      _service.analysisUpdates.listen((analysis) {
        _analysis = analysis;
        notifyListeners();
      });

      _service.dashboardUpdates.listen((metrics) {
        _dashboardMetrics = metrics;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualizar con nueva transacción
  Future<void> updateWithNewTransaction(Transaction newTransaction, List<Transaction> allTransactions) async {
    if (_analysis == null) return;
    
    try {
      _analysis = await _service.updateAnalysisWithNewTransaction(newTransaction, allTransactions);
      _dashboardMetrics = await _service.generateDashboardMetrics(allTransactions);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Generar reporte completo
  Future<Map<String, dynamic>> generateReport(String userId) async {
    return await _service.generateAnalysisReport(userId);
  }

  /// Obtener insights de categoría específica
  Future<CategoryBreakdown> getCategoryInsights(String categoryName, List<Transaction> transactions) async {
    return await _service.getCategoryInsights(categoryName, transactions);
  }

  /// Analizar progreso de metas
  Future<Map<String, dynamic>> analyzeGoalProgress(String userId) async {
    return await _service.analyzeGoalProgress(userId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Widget principal del análisis financiero avanzado
class AdvancedFinancialAnalysisWidget extends StatefulWidget {
  final List<Transaction> transactions;

  const AdvancedFinancialAnalysisWidget({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  @override
  State<AdvancedFinancialAnalysisWidget> createState() => _AdvancedFinancialAnalysisWidgetState();
}

class _AdvancedFinancialAnalysisWidgetState extends State<AdvancedFinancialAnalysisWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Inicializar análisis al cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinancialAnalysisProvider>().initializeAnalysis(widget.transactions);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinancialAnalysisProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Análisis Financiero IA'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.trending_up), text: 'Tendencias'),
              Tab(icon: Icon(Icons.category), text: 'Categorías'),
              Tab(icon: Icon(Icons.lightbulb), text: 'Insights'),
              Tab(icon: Icon(Icons.analytics), text: 'Predicciones'),
            ],
          ),
        ),
        body: Consumer<FinancialAnalysisProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analizando tus datos financieros...'),
                  ],
                ),
              );
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text('Error: ${provider.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.clearError(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(provider),
                _buildTrendsTab(provider),
                _buildCategoriesTab(provider),
                _buildInsightsTab(provider),
                _buildPredictionsTab(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardTab(FinancialAnalysisProvider provider) {
    final metrics = provider.dashboardMetrics;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score de salud financiera
          _buildHealthScoreCard(metrics['healthScore'] ?? 0),
          const SizedBox(height: 16),
          
          // Métricas principales
          _buildMainMetricsGrid(metrics),
          const SizedBox(height: 16),
          
          // Alertas críticas
          _buildAlertsSection(provider.analysis),
          const SizedBox(height: 16),
          
          // Oportunidades de ahorro
          _buildSavingsOpportunitiesCard(provider.analysis),
          const SizedBox(height: 16),
          
          // Plan de acción semanal
          _buildWeeklyActionPlanCard(provider.analysis),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(FinancialAnalysisProvider provider) {
    final analysis = provider.analysis;
    if (analysis == null) return const Center(child: Text('No hay datos disponibles'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Predicción del próximo mes
          _buildNextMonthPredictionCard(analysis.predictions),
          const SizedBox(height: 16),
          
          // Tendencias mensuales
          _buildMonthlyTrendsCard(analysis.trends.monthly),
          const SizedBox(height: 16),
          
          // Volatilidad y anomalías
          _buildVolatilityCard(analysis.trends.daily),
          const SizedBox(height: 16),
          
          // Patrones estacionales
          _buildSeasonalPatternsCard(analysis.trends.seasonalPatterns),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(FinancialAnalysisProvider provider) {
    final analysis = provider.analysis;
    if (analysis == null) return const Center(child: Text('No hay datos disponibles'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Desglose por categorías
          _buildCategoryBreakdownCard(analysis.categories.categoryBreakdowns),
          const SizedBox(height: 16),
          
          // Comparaciones entre categorías
          _buildCategoryComparisonsCard(analysis.categories.comparison),
          const SizedBox(height: 16),
          
          // Recomendaciones de optimización
          _buildOptimizationSuggestionsCard(analysis.categories.spendingOptimization),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(FinancialAnalysisProvider provider) {
    final analysis = provider.analysis;
    if (analysis == null) return const Center(child: Text('No hay datos disponibles'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insights de comportamiento
          _buildBehavioralInsightsCard(analysis.recommendations.behavioralInsights),
          const SizedBox(height: 16),
          
          // Alertas activas
          _buildActiveAlertsCard(analysis.recommendations.activeAlerts),
          const SizedBox(height: 16),
          
          // Recordatorios de facturas
          _buildBillRemindersCard(analysis.recommendations.upcomingBills),
          const SizedBox(height: 16),
          
          // Recomendaciones priorizadas
          _buildPrioritizedRecommendationsCard(analysis.recommendations.personalizedRecommendations),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab(FinancialAnalysisProvider provider) {
    final analysis = provider.analysis;
    if (analysis == null) return const Center(child: Text('No hay datos disponibles'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Predicciones por categoría
          _buildCategoryPredictionsCard(analysis.predictions.categoryPredictions),
          const SizedBox(height: 16),
          
          // Forecast de riesgos
          _buildRiskForecastsCard(analysis.predictions.riskForecasts),
          const SizedBox(height: 16),
          
          // Predicción de ahorros
          _buildSavingsPredictionCard(analysis.predictions.savingsPrediction),
          const SizedBox(height: 16),
          
          // Forecast de flujo de efectivo
          _buildCashFlowForecastCard(analysis.predictions.cashFlowForecast),
        ],
      ),
    );
  }

  /// Cards individuales

  Widget _buildHealthScoreCard(double score) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Salud Financiera',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getHealthScoreColor(score),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${score.toStringAsFixed(0)}/100',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getHealthScoreColor(score),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_getHealthScoreDescription(score)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMetricsGrid(Map<String, dynamic> metrics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildMetricCard(
          'Balance Total',
          '\$${(metrics['totalBalance'] ?? 0).toStringAsFixed(2)}',
          Icons.account_balance_wallet,
          Colors.blue,
        ),
        _buildMetricCard(
          'Gastos Mensuales',
          '\$${(metrics['monthlyExpenses'] ?? 0).toStringAsFixed(2)}',
          Icons.trending_down,
          Colors.red,
        ),
        _buildMetricCard(
          'Tasa de Ahorro',
          '${(metrics['savingsRate'] ?? 0).toStringAsFixed(1)}%',
          Icons.savings,
          Colors.green,
        ),
        _buildMetricCard(
          'Puntuación Impulso',
          '${(metrics['impulseScore'] ?? 0).toStringAsFixed(0)}/100',
          Icons.self_improvement,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextMonthPredictionCard(PredictiveInsights predictions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Predicción Próximo Mes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${predictions.nextMonthPrediction.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Gasto proyectado',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(predictions.predictionConfidence),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${predictions.predictionConfidence.toStringAsFixed(0)}% confianza',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...predictions.keyFactors.take(3).map(
              (factor) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.info, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_formatKeyFactor(factor))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(FinancialAnalysis? analysis) {
    if (analysis == null || analysis.recommendations.activeAlerts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green[400], size: 48),
              const SizedBox(height: 8),
              const Text('¡Excelente! No hay alertas activas'),
              Text(
                'Tu situación financiera está bajo control',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final criticalAlerts = analysis.recommendations.activeAlerts
        .where((alert) => alert.severity == SeverityLevel.critical)
        .toList();
    final highAlerts = analysis.recommendations.activeAlerts
        .where((alert) => alert.severity == SeverityLevel.high)
        .toList();

    return Column(
      children: [
        if (criticalAlerts.isNotEmpty) ...[
          Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Alertas Críticas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...criticalAlerts.map((alert) => _buildAlertItem(alert)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (highAlerts.isNotEmpty) Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Alertas Importantes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...highAlerts.take(3).map((alert) => _buildAlertItem(alert)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem(FinancialAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alert.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(alert.message),
          if (alert.actionable) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showAlertDetails(alert),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Ver Detalles'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSavingsOpportunitiesCard(FinancialAnalysis? analysis) {
    if (analysis == null || analysis.categories.savingsOpportunities.identifiedOpportunities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.savings, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              const Text('¡Optimización Completa!'),
              Text(
                'No se identificaron oportunidades específicas de ahorro',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final topOpportunity = analysis.categories.savingsOpportunities.identifiedOpportunities.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Oportunidad de Ahorro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              topOpportunity.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(topOpportunity.description),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'Potencial: \$${topOpportunity.potentialMonthlySavings.toStringAsFixed(2)}/mes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _showOpportunityDetails(topOpportunity),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Ver Plan de Acción'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyActionPlanCard(FinancialAnalysis? analysis) {
    if (analysis == null || analysis.recommendations.weeklyPlan.actions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.checklist, color: Colors.blue, size: 48),
              const SizedBox(height: 8),
              const Text('Plan Completo'),
              Text(
                'No hay acciones pendientes esta semana',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final plan = analysis.recommendations.weeklyPlan;
    final urgentActions = plan.actions.where((action) => 
        action.deadline.difference(DateTime.now()).inDays <= 3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(
                  'Plan Semanal',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (urgentActions.isNotEmpty) ...[
              Text(
                'Acciones Urgentes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 8),
              ...urgentActions.take(2).map((action) => _buildActionItem(action)),
              const SizedBox(height: 12),
            ],
            Text(
              'Total: \$${plan.totalPotentialSavings.toStringAsFixed(2)} potencial',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(WeeklyAction action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            action.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(action.description, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: action.deadline.difference(DateTime.now()).inDays <= 1 
                    ? Colors.red : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                'Due: ${_formatDate(action.deadline)}',
                style: TextStyle(
                  fontSize: 12,
                  color: action.deadline.difference(DateTime.now()).inDays <= 1 
                      ? Colors.red : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendsCard(MonthlyTrends monthly) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tendencias Mensuales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTrendMetric(
                  'Promedio',
                  '\$${monthly.averageMonthlySpent.toStringAsFixed(2)}',
                  Icons.trending_up,
                ),
                _buildTrendMetric(
                  'Cambio MoM',
                  '${monthly.monthOverMonthChange.toStringAsFixed(1)}%',
                  monthly.monthOverMonthChange > 0 ? Icons.trending_up : Icons.trending_down,
                  color: monthly.monthOverMonthChange > 0 ? Colors.red : Colors.green,
                ),
                _buildTrendMetric(
                  'Tendencia',
                  _getTrendDirectionText(monthly.trend),
                  _getTrendIcon(monthly.trend),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendMetric(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdownCard(List<CategoryBreakdown> breakdowns) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Desglose por Categorías',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...breakdowns.take(5).map((breakdown) => _buildCategoryItem(breakdown)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(CategoryBreakdown breakdown) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breakdown.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('\$${breakdown.totalSpent.toStringAsFixed(2)}'),
                Text(
                  '${breakdown.percentageOfTotal.toStringAsFixed(1)}% del total',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${breakdown.transactionCount}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'transacciones',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPredictionsCard(List<CategoryPrediction> predictions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Predicciones por Categoría',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...predictions.take(5).map((prediction) => _buildPredictionItem(prediction)),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionItem(CategoryPrediction prediction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                prediction.category,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPredictionColor(prediction.trend),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${prediction.predictedChange > 0 ? '+' : ''}${prediction.predictedChange.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('\$${prediction.predictedAmount.toStringAsFixed(2)} proyectado'),
          Text(
            'Confianza: ${prediction.confidence.toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskForecastsCard(List<RiskForecast> risks) {
    if (risks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.security, color: Colors.green[600], size: 48),
              const SizedBox(height: 8),
              const Text('Bajo Riesgo'),
              Text(
                'No se identificaron riesgos financieros significativos',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Forecast de Riesgos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...risks.map((risk) => _buildRiskItem(risk)),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskItem(RiskForecast risk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getRiskColor(risk.probability),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getRiskTypeText(risk.riskType),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Probabilidad: ${(risk.probability * 100).toStringAsFixed(0)}%'),
          Text('Impacto: ${_getImpactText(risk.impact)}'),
          const SizedBox(height: 8),
          Text(
            'Mitigación: ${risk.mitigation}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares

  Color _getHealthScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getHealthScoreDescription(double score) {
    if (score >= 80) return 'Excelente salud financiera';
    if (score >= 60) return 'Buena salud con algunas áreas de mejora';
    if (score >= 40) return 'Salud financiera moderada - necesita atención';
    return 'Requiere atención urgente en gestión financiera';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getPredictionColor(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.increasing: return Colors.red;
      case TrendDirection.decreasing: return Colors.green;
      case TrendDirection.stable: return Colors.blue;
    }
  }

  Color _getRiskColor(double probability) {
    if (probability > 0.7) return Colors.red[100]!;
    if (probability > 0.4) return Colors.orange[100]!;
    return Colors.green[100]!;
  }

  String _getTrendDirectionText(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.increasing: return 'Creciente';
      case TrendDirection.decreasing: return 'Decreciente';
      case TrendDirection.stable: return 'Estable';
    }
  }

  IconData _getTrendIcon(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.increasing: return Icons.trending_up;
      case TrendDirection.decreasing: return Icons.trending_down;
      case TrendDirection.stable: return Icons.trending_flat;
    }
  }

  String _getRiskTypeText(RiskType riskType) {
    switch (riskType) {
      case RiskType.overspending: return 'Sobregasto';
      case RiskType.liquidity: return 'Liquidez';
      case RiskType.categoryDependency: return 'Dependencia de Categoría';
      default: return 'Riesgo General';
    }
  }

  String _getImpactText(ImpactLevel impact) {
    switch (impact) {
      case ImpactLevel.high: return 'Alto';
      case ImpactLevel.medium: return 'Medio';
      case ImpactLevel.low: return 'Bajo';
    }
  }

  String _formatKeyFactor(String factor) {
    switch (factor) {
      case 'temporada_festiva': return 'Temporada festiva incrementa gastos';
      case 'aumento_gastos': return 'Aumento reciente en gastos';
      case 'reduccion_gastos': return 'Reducción reciente en gastos';
      case 'categoria_principal_alimentacion': return 'Alimentación es la categoría principal';
      default: return factor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Mañana';
    if (difference > 1) return '$difference días';
    if (difference == -1) return 'Ayer';
    return '${date.day}/${date.month}';
  }

  void _showAlertDetails(FinancialAlert alert) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(alert.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alert.message),
              const SizedBox(height: 16),
              Text(
                'Acción Sugerida:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(alert.suggestedAction),
              if (alert.amount > 0) ...[
                const SizedBox(height: 16),
                Text(
                  'Monto Afectado: \$${alert.amount.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showOpportunityDetails(SavingsOpportunity opportunity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(opportunity.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(opportunity.description),
              const SizedBox(height: 16),
              Text(
                'Potencial de Ahorro:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('\$${opportunity.potentialMonthlySavings.toStringAsFixed(2)}/mes'),
              const SizedBox(height: 16),
              Text(
                'Pasos de Acción:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...opportunity.actionableSteps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(step)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Placeholder methods para widgets faltantes
  Widget _buildVolatilityCard(DailyTrends daily) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Volatilidad de Gastos'),
          const SizedBox(height: 8),
          Text('${daily.volatility.toStringAsFixed(1)}%'),
        ],
      ),
    ),
  );

  Widget _buildSeasonalPatternsCard(TrendAnalysis analysis) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Patrones Estacionales'),
          const SizedBox(height: 8),
          Text('Variación: \$${analysis.seasonalVariance.toStringAsFixed(2)}'),
        ],
      ),
    ),
  );

  Widget _buildCategoryComparisonsCard(CategoryComparison comparison) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Comparación de Categorías'),
          const SizedBox(height: 8),
          Text('Top spender: ${comparison.topSpenderCategory}'),
        ],
      ),
    ),
  );

  Widget _buildOptimizationSuggestionsCard(SpendingOptimization optimization) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Sugerencias de Optimización'),
          const SizedBox(height: 8),
          Text('${optimization.suggestions.length} sugerencias'),
        ],
      ),
    ),
  );

  Widget _buildBehavioralInsightsCard(List<BehavioralInsight> insights) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Insights de Comportamiento'),
          const SizedBox(height: 8),
          Text('${insights.length} insights encontrados'),
        ],
      ),
    ),
  );

  Widget _buildActiveAlertsCard(List<FinancialAlert> alerts) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Alertas Activas'),
          const SizedBox(height: 8),
          Text('${alerts.length} alertas'),
        ],
      ),
    ),
  );

  Widget _buildBillRemindersCard(List<BillReminder> bills) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Recordatorios de Facturas'),
          const SizedBox(height: 8),
          Text('${bills.length} facturas próximas'),
        ],
      ),
    ),
  );

  Widget _buildPrioritizedRecommendationsCard(List<Recommendation> recommendations) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Recomendaciones Prioritarias'),
          const SizedBox(height: 8),
          Text('${recommendations.length} recomendaciones'),
        ],
      ),
    ),
  );

  Widget _buildSavingsPredictionCard(SavingsPrediction prediction) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Predicción de Ahorros'),
          const SizedBox(height: 8),
          Text('\$${prediction.predictedMonthlySavings.toStringAsFixed(2)}/mes'),
        ],
      ),
    ),
  );

  Widget _buildCashFlowForecastCard(CashFlowForecast forecast) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Forecast de Flujo de Efectivo'),
          const SizedBox(height: 8),
          Text('\$${forecast.monthlyNetFlow.toStringAsFixed(2)}/mes neto'),
        ],
      ),
    ),
  );
}