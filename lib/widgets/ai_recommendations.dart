import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';

class AIRecommendations extends StatelessWidget {
  final List<Expense> expenses;
  final Function(double) onAcceptSavings;

  const AIRecommendations({
    super.key,
    required this.expenses,
    required this.onAcceptSavings,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Agrega algunos gastos para recibir recomendaciones de IA',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      );
    }

    final recommendations = _generateRecommendations();

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
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.smart_toy, color: Colors.blue.shade600, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recomendaciones de IA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Basado en tus patrones de gasto, aquí tienes algunas sugerencias inteligentes:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ...recommendations.map((rec) => _buildRecommendationCard(context, rec)),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateRecommendations() {
    final recommendations = <Map<String, dynamic>>[];

    // Analizar gastos por categoría
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final totalExpenses = categoryTotals.values.reduce((a, b) => a + b);

    // Recomendación 1: Categoría con mayor gasto
    if (categoryTotals.isNotEmpty) {
      final topCategory = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      final percentage = (topCategory.value / totalExpenses) * 100;

      if (percentage > 30) {
        recommendations.add({
          'type': 'warning',
          'title': 'Gasto elevado en ${topCategory.key}',
          'description': 'Has gastado \$${topCategory.value.toStringAsFixed(2)} en ${topCategory.key} (${percentage.toStringAsFixed(1)}% del total). Considera reducir este gasto.',
          'savings': topCategory.value * 0.1, // 10% de ahorro potencial
          'icon': Icons.warning_amber,
          'color': Colors.orange,
        });
      }
    }

    // Recomendación 2: Gastos recurrentes similares
    final recentExpenses = expenses.where((e) =>
      e.date.isAfter(DateTime.now().subtract(const Duration(days: 30)))
    ).toList();

    if (recentExpenses.length >= 3) {
      recommendations.add({
        'type': 'tip',
        'title': 'Establece un presupuesto mensual',
        'description': 'Has tenido ${recentExpenses.length} gastos en el último mes. Te recomiendo establecer límites por categoría.',
        'savings': totalExpenses * 0.05, // 5% de ahorro potencial
        'icon': Icons.lightbulb,
        'color': Colors.blue,
      });
    }

    // Recomendación 3: Oportunidades de ahorro específicas por categoría
    for (final entry in categoryTotals.entries) {
      if (entry.key == 'Restaurantes' && entry.value > 50) {
        recommendations.add({
          'type': 'savings',
          'title': 'Ahorra en restaurantes',
          'description': 'Considera cocinar en casa o usar apps de delivery con descuento. Puedes ahorrar hasta \$15 por comida.',
          'savings': 15.0,
          'icon': Icons.restaurant,
          'color': Colors.green,
        });
      } else if (entry.key == 'Transporte' && entry.value > 30) {
        recommendations.add({
          'type': 'savings',
          'title': 'Optimiza tu transporte',
          'description': 'Usa transporte público o bicicleta para distancias cortas. Ahorra \$5-10 por viaje.',
          'savings': 7.5,
          'icon': Icons.directions_car,
          'color': Colors.green,
        });
      }
    }

    // Recomendación 4: Meta de ahorro semanal
    final weeklyAverage = totalExpenses / 4.33; // aproximado por semana
    if (weeklyAverage > 20) {
      recommendations.add({
        'type': 'goal',
        'title': 'Meta de ahorro semanal',
        'description': 'Tu promedio semanal es de \$${weeklyAverage.toStringAsFixed(2)}. Intenta ahorrar \$10 por semana.',
        'savings': 10.0,
        'icon': Icons.savings,
        'color': Colors.purple,
      });
    }

    return recommendations.take(4).toList(); // Máximo 4 recomendaciones
  }

  Widget _buildRecommendationCard(BuildContext context, Map<String, dynamic> rec) {
    return Card(
      elevation: 2,
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
                    color: rec['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    rec['icon'],
                    color: rec['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              rec['description'],
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '💰 Ahorra \$${rec['savings'].toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    onAcceptSavings(rec['savings']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('¡Excelente! Has aceptado ahorrar \$${rec['savings'].toStringAsFixed(2)}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Aplicar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rec['color'],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}