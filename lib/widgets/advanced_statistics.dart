import 'package:flutter/material.dart';
import '../models.dart';

class AdvancedStatisticsWidget extends StatelessWidget {
  final List<Expense> expenses;
  final List<Income> incomes;

  const AdvancedStatisticsWidget({
    super.key,
    required this.expenses,
    required this.incomes,
  });

  @override
  Widget build(BuildContext context) {
    final expenseStats = _calculateExpenseStatistics();
    final incomeStats = _calculateIncomeStatistics();

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
                      colors: [Colors.blue, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Estadísticas Avanzadas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Estadísticas de gastos
            if (expenseStats.isNotEmpty) ...[
              const Text(
                '📊 Categorías de Gastos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...expenseStats.entries.take(5).map((entry) {
                final percentage = (entry.value['percentage'] as double).toStringAsFixed(1);
                final amount = entry.value['amount'] as double;
                final count = entry.value['count'] as int;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$count transacción${count != 1 ? 'es' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (entry.value['percentage'] as double) / 100,
                        backgroundColor: Colors.red.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade400),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Estadísticas de ingresos
            if (incomeStats.isNotEmpty) ...[
              const Text(
                '💰 Categorías de Ingresos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...incomeStats.entries.take(5).map((entry) {
                final percentage = (entry.value['percentage'] as double).toStringAsFixed(1);
                final amount = entry.value['amount'] as double;
                final count = entry.value['count'] as int;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '+\$${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$count transacción${count != 1 ? 'es' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (entry.value['percentage'] as double) / 100,
                        backgroundColor: Colors.green.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Mensaje si no hay datos
            if (expenseStats.isEmpty && incomeStats.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay suficientes datos para mostrar estadísticas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Agrega más gastos e ingresos para ver análisis detallados',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _calculateExpenseStatistics() {
    if (expenses.isEmpty) return {};

    final categoryTotals = <String, Map<String, dynamic>>{};

    // Calcular totales por categoría
    for (final expense in expenses) {
      if (!categoryTotals.containsKey(expense.category)) {
        categoryTotals[expense.category] = {
          'amount': 0.0,
          'count': 0,
        };
      }
      categoryTotals[expense.category]!['amount'] += expense.amount;
      categoryTotals[expense.category]!['count'] += 1;
    }

    final totalExpenses = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    // Calcular porcentajes y ordenar
    final stats = categoryTotals.map((category, data) {
      final amount = data['amount'] as double;
      final percentage = (amount / totalExpenses) * 100;
      return MapEntry(category, {
        ...data,
        'percentage': percentage,
      });
    });

    // Ordenar por monto descendente
    final sortedStats = Map.fromEntries(
      stats.entries.toList()
        ..sort((a, b) => (b.value['amount'] as double).compareTo(a.value['amount'] as double)),
    );

    return sortedStats;
  }

  Map<String, Map<String, dynamic>> _calculateIncomeStatistics() {
    if (incomes.isEmpty) return {};

    final sourceTotals = <String, Map<String, dynamic>>{};

    // Calcular totales por fuente
    for (final income in incomes) {
      if (!sourceTotals.containsKey(income.source)) {
        sourceTotals[income.source] = {
          'amount': 0.0,
          'count': 0,
        };
      }
      sourceTotals[income.source]!['amount'] += income.amount;
      sourceTotals[income.source]!['count'] += 1;
    }

    final totalIncomes = incomes.fold<double>(0, (sum, income) => sum + income.amount);

    // Calcular porcentajes y ordenar
    final stats = sourceTotals.map((source, data) {
      final amount = data['amount'] as double;
      final percentage = (amount / totalIncomes) * 100;
      return MapEntry(source, {
        ...data,
        'percentage': percentage,
      });
    });

    // Ordenar por monto descendente
    final sortedStats = Map.fromEntries(
      stats.entries.toList()
        ..sort((a, b) => (b.value['amount'] as double).compareTo(a.value['amount'] as double)),
    );

    return sortedStats;
  }
}