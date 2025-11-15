import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models.dart';

class WeeklyInsights extends StatefulWidget {
  final List<Expense> expenses;
  final List<Income> incomes;

  const WeeklyInsights({
    super.key,
    required this.expenses,
    required this.incomes,
  });

  @override
  State<WeeklyInsights> createState() => _WeeklyInsightsState();
}

class _WeeklyInsightsState extends State<WeeklyInsights> {
  late GenerativeModel _model;
  List<Map<String, dynamic>> _insights = [];
  bool _isLoading = true;

  static const String _apiKey = 'AIzaSyA1tTTe2loIRAAUNnkYIIVhwP0TvTck_Ac';
  

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );
    _generateWeeklyInsights();
  }

  @override
  void didUpdateWidget(WeeklyInsights oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regenerate insights when data changes
    if (oldWidget.expenses != widget.expenses || oldWidget.incomes != widget.incomes) {
      _generateWeeklyInsights();
    }
  }

  Future<void> _generateWeeklyInsights() async {
    if (widget.expenses.isEmpty && widget.incomes.isEmpty) {
      setState(() {
        _insights = _getDefaultInsights();
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final insights = await _analyzeWithGemini();
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      print('Error generating insights: $e');
      setState(() {
        _insights = _getFallbackInsights();
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _analyzeWithGemini() async {
    // Get last 7 days data
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    final recentExpenses = widget.expenses.where((e) => e.date.isAfter(weekAgo)).toList();
    final recentIncomes = widget.incomes.where((i) => i.date.isAfter(weekAgo)).toList();

    // Get previous week data for comparison
    final previousExpenses = widget.expenses.where((e) => e.date.isAfter(twoWeeksAgo) && e.date.isBefore(weekAgo)).toList();
    final previousIncomes = widget.incomes.where((i) => i.date.isAfter(twoWeeksAgo) && i.date.isBefore(weekAgo)).toList();

    if (recentExpenses.isEmpty && recentIncomes.isEmpty) {
      return _getDefaultInsights();
    }

    // Calculate comprehensive metrics
    final totalSpent = recentExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalEarned = recentIncomes.fold<double>(0, (sum, i) => sum + i.amount);
    final netSavings = totalEarned - totalSpent;

    // Previous week metrics
    final prevTotalSpent = previousExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final prevTotalEarned = previousIncomes.fold<double>(0, (sum, i) => sum + i.amount);
    final prevNetSavings = prevTotalEarned - prevTotalSpent;

    // Daily averages
    final dailyAverageSpent = totalSpent / 7;
    final dailyAverageEarned = totalEarned / 7;

    // Category breakdown
    final categorySpending = <String, double>{};
    for (final expense in recentExpenses) {
      categorySpending[expense.category] = (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    final topCategory = categorySpending.isNotEmpty
        ? categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    // Transaction frequency
    final transactionsPerDay = recentExpenses.length / 7;
    final incomeTransactions = recentIncomes.length;

    // Savings rate
    final savingsRate = totalEarned > 0 ? (netSavings / totalEarned) * 100 : 0;

    // Build comprehensive prompt for Gemini
    final prompt = '''
    Eres un analista financiero experto especializado en finanzas personales ecuatorianas. Analiza estos datos semanales detallados y genera insights profundos y accionables:

    📊 MÉTRICAS FINANCIERAS DETALLADAS:

    SEMANA ACTUAL (últimos 7 días):
    • Gastos totales: \$${totalSpent.toStringAsFixed(2)}
    • Ingresos totales: \$${totalEarned.toStringAsFixed(2)}
    • Ahorro neto: \$${netSavings.toStringAsFixed(2)}
    • Tasa de ahorro: ${savingsRate.toStringAsFixed(1)}%
    • Promedio diario gastado: \$${dailyAverageSpent.toStringAsFixed(2)}
    • Promedio diario ganado: \$${dailyAverageEarned.toStringAsFixed(2)}
    • Transacciones de gastos: ${recentExpenses.length} (${transactionsPerDay.toStringAsFixed(1)} por día)
    • Transacciones de ingresos: $incomeTransactions

    SEMANA ANTERIOR (comparación):
    • Gastos: \$${prevTotalSpent.toStringAsFixed(2)} (${prevTotalSpent > 0 ? ((totalSpent - prevTotalSpent) / prevTotalSpent * 100).toStringAsFixed(1) : 'N/A'}%)
    • Ingresos: \$${prevTotalEarned.toStringAsFixed(2)} (${prevTotalEarned > 0 ? ((totalEarned - prevTotalEarned) / prevTotalEarned * 100).toStringAsFixed(1) : 'N/A'}%)
    • Ahorro neto: \$${prevNetSavings.toStringAsFixed(2)}

    🏷️ DESGLOSE POR CATEGORÍAS:
    ${categorySpending.entries.map((e) => '• ${e.key}: \$${e.value.toStringAsFixed(2)} (${totalSpent > 0 ? (e.value / totalSpent * 100).toStringAsFixed(1) : '0'}% del total)').join('\n')}

    💰 DETALLE DE INGRESOS:
    ${recentIncomes.map((i) => '• ${i.source}: \$${i.amount.toStringAsFixed(2)} - ${i.description}').join('\n')}

    🎯 INSTRUCCIONES PARA ANÁLISIS:

    1. ANALIZA PATRONES: Identifica tendencias, hábitos positivos y áreas críticas
    2. COMPARACIONES: Compara con semana anterior y establece benchmarks realistas
    3. MÉTRICAS CLAVE: Incluye números específicos (porcentajes, promedios, frecuencias)
    4. RECOMENDACIONES CONCRETAS: Sugerencias medibles con impacto financiero claro
    5. CONTEXTO ECUATORIANO: Referencias a precios locales, ofertas, transporte público
    6. MOTIVACIÓN: Mantén tono positivo y constructivo, celebra logros
    7. ACCIONES PRÁCTICAS: Recomendaciones implementables en la vida diaria

    📈 GENERA EXACTAMENTE 6-8 insights detallados en formato JSON:

    [
      {
        "title": "Título específico con números cuando aplique",
        "description": "Análisis detallado con métricas financieras específicas y contexto",
        "type": "positive|warning|tip|suggestion|analysis|goal",
        "impact": "high|medium|low",
        "action": "Acción concreta con resultado esperado medible",
        "metric": "Métrica financiera específica para seguimiento (opcional)"
      }
    ]

    EJEMPLOS DE INSIGHTS BUSCADOS:
    • "Gasto diario de \$12.50 excede presupuesto recomendado"
    • "Categoría 'Comida' representa 45% del presupuesto semanal"
    • "Ahorro del 23% está 12% por encima del promedio nacional"
    • "3.2 transacciones diarias indican oportunidad de consolidación"

    IMPORTANTE: Responde SOLO con el JSON válido, sin texto adicional.
    ''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);

    if (response.text != null) {
      try {
        final insights = _parseGeminiInsights(response.text!);
        return insights.take(8).toList(); // Aumentado de 4 a 8 insights
      } catch (e) {
        print('Error parsing insights: $e');
        return _getFallbackInsights();
      }
    }

    return _getFallbackInsights();
  }

  List<Map<String, dynamic>> _parseGeminiInsights(String response) {
    final jsonStart = response.indexOf('[');
    final jsonEnd = response.lastIndexOf(']');

    if (jsonStart == -1 || jsonEnd == -1) {
      throw Exception('No JSON found');
    }

    final jsonString = response.substring(jsonStart, jsonEnd + 1);

    // Simple JSON parsing (in production, use json.decode)
    final insights = <Map<String, dynamic>>[];
    final items = jsonString.substring(1, jsonString.length - 1).split('},{');

    for (final item in items) {
      final cleanItem = item.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '');
      final pairs = cleanItem.split(',');

      final insight = <String, dynamic>{};
      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length >= 2) {
          final key = keyValue[0].trim();
          final value = keyValue.sublist(1).join(':').trim();

          if (['title', 'description', 'type', 'impact', 'action'].contains(key)) {
            insight[key] = value;
          }
        }
      }

      // Set defaults for missing fields
      insight['type'] ??= 'tip';
      insight['impact'] ??= 'medium';

      insights.add(insight);
    }

    return insights;
  }

  List<Map<String, dynamic>> _getDefaultInsights() {
    return [
      {
        'title': '¡Comienza tu viaje financiero!',
        'description': 'Registra tus primeros gastos e ingresos para recibir análisis detallado con métricas específicas como tasa de ahorro, promedio diario y comparación semanal.',
        'type': 'suggestion',
        'impact': 'high',
        'action': 'Agrega al menos 5 transacciones para análisis completo',
        'metric': '0% tasa de ahorro actual'
      },
      {
        'title': 'Establece metas financieras SMART',
        'description': 'Define objetivos Específicos, Medibles, Alcanzables, Relevantes y con Tiempo definido. Una meta inicial podría ser ahorrar el 20% de tus ingresos.',
        'type': 'goal',
        'impact': 'high',
        'action': 'Crea una meta de ahorro del 15-20% mensual',
        'metric': 'Meta: 20% de ingresos ahorrados'
      },
      {
        'title': 'Categoriza para controlar',
        'description': 'Organizar gastos por categorías revela patrones ocultos. El 80% de los ahorros vienen de identificar gastos innecesarios en categorías específicas.',
        'type': 'analysis',
        'impact': 'medium',
        'action': 'Revisa y categoriza tus últimos 10 gastos',
        'metric': 'Categorización: 0% completada'
      },
      {
        'title': 'Ahorro automático inteligente',
        'description': 'Configura transferencias automáticas del 10-15% de ingresos. En Ecuador, bancos como Pichincha ofrecen cuentas de ahorro con 4-6% de interés anual.',
        'type': 'suggestion',
        'impact': 'high',
        'action': 'Configura ahorro automático del 10% semanal',
        'metric': 'Ahorro automático: 0.00 USD configurado'
      },
      {
        'title': 'Presupuesto semanal efectivo',
        'description': 'Establece límites por categoría. Un presupuesto equilibrado dedica 30% a vivienda, 15% a alimentación, 10% a transporte y 20% a ahorro.',
        'type': 'tip',
        'impact': 'medium',
        'action': 'Crea presupuesto semanal con límites por categoría',
        'metric': 'Presupuesto: No establecido'
      },
      {
        'title': 'Hábitos de compra inteligentes',
        'description': 'Espera 24 horas antes de compras impulsivas. Compara precios en apps como Picap y aprovecha ofertas en Mi Comisariato o Tía.',
        'type': 'warning',
        'impact': 'low',
        'action': 'Implementa regla 24 horas para compras >\$20',
        'metric': 'Compras impulsivas: No controladas'
      }
    ];
  }

  List<Map<String, dynamic>> _getFallbackInsights() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final recentExpenses = widget.expenses.where((e) => e.date.isAfter(weekAgo)).toList();
    final recentIncomes = widget.incomes.where((i) => i.date.isAfter(weekAgo)).toList();

    final totalSpent = recentExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalEarned = recentIncomes.fold<double>(0, (sum, i) => sum + i.amount);
    final netSavings = totalEarned - totalSpent;
    final dailyAverage = totalSpent / 7;
    final transactionsCount = recentExpenses.length;

    // Category analysis
    final categorySpending = <String, double>{};
    for (final expense in recentExpenses) {
      categorySpending[expense.category] = (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    final topCategory = categorySpending.isNotEmpty
        ? categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    // Pre-calculate complex expressions
    final savingsText = netSavings >= 0
        ? 'Ahorraste \$${netSavings.toStringAsFixed(2)}'
        : 'Tuviste un déficit de \$${netSavings.abs().toStringAsFixed(2)}';

    final topCategoryPercentage = totalSpent > 0 && topCategory != null
        ? (topCategory.value / totalSpent * 100).toStringAsFixed(1)
        : '0';

    return [
      {
        'title': 'Resumen semanal: \$${totalSpent.toStringAsFixed(2)} gastados',
        'description': 'En los últimos 7 días realizaste $transactionsCount transacciones con un promedio diario de \$${dailyAverage.toStringAsFixed(2)}. $savingsText.',
        'type': 'analysis',
        'impact': 'medium',
        'action': 'Revisa el detalle de gastos para identificar patrones',
        'metric': 'Promedio diario: \$${dailyAverage.toStringAsFixed(2)}'
      },
      {
        'title': 'Categoría principal: ${topCategory?.key ?? 'Sin datos'}',
        'description': 'La categoría ${topCategory?.key ?? 'principal'} representa el ${topCategoryPercentage}% de tus gastos semanales con \$${topCategory?.value.toStringAsFixed(2) ?? '0'} totales.',
        'type': 'analysis',
        'impact': 'high',
        'action': 'Analiza si puedes reducir gastos en ${topCategory?.key.toLowerCase() ?? 'esta categoría'}',
        'metric': '${topCategory?.key ?? 'N/A'}: \$${topCategory?.value.toStringAsFixed(2) ?? '0'}'
      },
      {
        'title': 'Oportunidad de ahorro en alimentación',
        'description': 'Cocinar en casa puede ahorrarte hasta \$80 semanales. En Ecuador, mercados locales ofrecen productos frescos a precios accesibles.',
        'type': 'tip',
        'impact': 'high',
        'action': 'Prepara almuerzo en casa 4 días a la semana',
        'metric': 'Ahorro potencial: 60-80 USD/semana'
      },
      {
        'title': 'Transporte público inteligente',
        'description': 'La tarjeta Ecovía cuesta \$0.35 vs \$0.50 en efectivo. Un ahorro de \$27 mensuales para 60 viajes. Apps como InDriver ofrecen descuentos.',
        'type': 'suggestion',
        'impact': 'medium',
        'action': 'Usa transporte público para viajes cortos',
        'metric': 'Ahorro mensual: 27 USD en transporte'
      },
      {
        'title': 'Compras inteligentes en supermercados',
        'description': 'Mi Comisariato ofrece descuentos del 20% los martes en lácteos. Compara precios con la app Picap antes de comprar.',
        'type': 'tip',
        'impact': 'medium',
        'action': 'Compra en días de oferta y compara precios',
        'metric': 'Descuentos disponibles: 15-40% semanal'
      },
      {
        'title': 'Hábitos de gasto consciente',
        'description': 'Espera 24 horas antes de compras impulsivas. Establece un límite diario de \$20 para gastos no esenciales.',
        'type': 'warning',
        'impact': 'low',
        'action': 'Implementa regla de 24 horas para compras >\$15',
        'metric': 'Compras impulsivas: Reducir 30%'
      },
      {
        'title': 'Construye un fondo de emergencias',
        'description': 'Un fondo de 3-6 meses de gastos es esencial. Comienza ahorrando el 10% de ingresos automáticamente.',
        'type': 'goal',
        'impact': 'high',
        'action': 'Configura transferencia automática del 10% a ahorros',
        'metric': 'Meta: 3 meses de gastos ahorrados'
      },
      {
        'title': 'Presupuesto por categorías',
        'description': 'Establece límites: 30% vivienda, 20% alimentación, 15% transporte, 20% ahorro. Ajusta según tus prioridades.',
        'type': 'suggestion',
        'impact': 'medium',
        'action': 'Crea presupuesto mensual con límites específicos',
        'metric': 'Presupuesto: Personalizado por necesidades'
      }
    ];
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'positive':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'tip':
        return Colors.blue;
      case 'suggestion':
        return Colors.purple;
      case 'analysis':
        return Colors.teal;
      case 'goal':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'positive':
        return Icons.trending_up;
      case 'warning':
        return Icons.warning_amber;
      case 'tip':
        return Icons.lightbulb;
      case 'suggestion':
        return Icons.rocket;
      case 'analysis':
        return Icons.analytics;
      case 'goal':
        return Icons.flag;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.indigo, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.insights, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Insights Semanales',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _generateWeeklyInsights,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar insights',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Análisis detallado con métricas financieras específicas, comparaciones semanales y recomendaciones personalizadas',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),

            if (_isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analizando tus patrones financieros...'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _insights.length,
                itemBuilder: (context, index) {
                  final insight = _insights[index];
                  final color = _getInsightColor(insight['type']);
                  final icon = _getInsightIcon(insight['type']);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  insight['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getImpactColor(insight['impact']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getImpactText(insight['impact']),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            insight['description'],
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.rocket_launch, color: color, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    insight['action'],
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getImpactColor(String impact) {
    switch (impact) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getImpactText(String impact) {
    switch (impact) {
      case 'high':
        return 'ALTO';
      case 'medium':
        return 'MEDIO';
      case 'low':
        return 'BAJO';
      default:
        return 'NORMAL';
    }
  }
}