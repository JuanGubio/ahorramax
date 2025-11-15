import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models.dart';

class AIRecommendations extends StatefulWidget {
  final List<Expense> expenses;
  final Function(double) onAcceptSavings;

  const AIRecommendations({
    super.key,
    required this.expenses,
    required this.onAcceptSavings,
  });

  @override
  State<AIRecommendations> createState() => _AIRecommendationsState();
}

class _AIRecommendationsState extends State<AIRecommendations> {
  late GenerativeModel _model;
  bool _isLoadingRecommendations = false;

  // API Key de Gemini
  static const String _apiKey = 'AIzaSyA1tTTe2loIRAAUNnkYIIVhwP0TvTck_Ac';

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.expenses.isEmpty) {
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

    final recommendations = _isLoadingRecommendations ? [] : _generateRecommendations();

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

  Future<List<Map<String, dynamic>>> _generateGeminiRecommendations() async {
    if (widget.expenses.isEmpty) return [];

    setState(() => _isLoadingRecommendations = true);

    try {
      // Crear prompt para Gemini
      final expensesData = widget.expenses.map((e) =>
        '${e.category}: \$${e.amount.toStringAsFixed(2)} - ${e.description}'
      ).join('\n');

      final prompt = '''
Eres Gemini AI, el asistente financiero más avanzado. Analiza estos gastos del usuario y genera recomendaciones inteligentes de ahorro:

GASTOS DEL USUARIO:
$expensesData

INSTRUCCIONES:
1. Analiza patrones de gasto y categorías
2. Identifica oportunidades de ahorro realistas
3. Proporciona recomendaciones específicas y accionables
4. Incluye montos de ahorro potenciales
5. Mantén un tono amigable y motivador
6. Enfócate en ofertas locales cuando sea relevante (Quito, Ecuador)

GENERA EXACTAMENTE 3-4 recomendaciones en formato JSON:
[
  {
    "title": "Título claro y conciso",
    "description": "Descripción detallada de la recomendación",
    "savings": monto_numerico_de_ahorro_potencial,
    "type": "savings|warning|tip|goal",
    "icon": "icon_name",
    "color": "green|blue|orange|purple"
  }
]

IMPORTANTE: Responde SOLO con el JSON válido, sin texto adicional.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        final cleanJson = response.text!.trim();
        // Intentar parsear el JSON
        try {
          final recommendations = _parseGeminiResponse(cleanJson);
          setState(() => _isLoadingRecommendations = false);
          return recommendations;
        } catch (e) {
          print('Error parseando respuesta de Gemini: $e');
          // Fallback a recomendaciones locales
          setState(() => _isLoadingRecommendations = false);
          return _generateLocalRecommendations();
        }
      } else {
        setState(() => _isLoadingRecommendations = false);
        return _generateLocalRecommendations();
      }
    } catch (e) {
      print('Error conectando con Gemini API: $e');
      setState(() => _isLoadingRecommendations = false);
      return _generateLocalRecommendations();
    }
  }

  List<Map<String, dynamic>> _parseGeminiResponse(String response) {
    // Limpiar respuesta y extraer JSON
    final jsonStart = response.indexOf('[');
    final jsonEnd = response.lastIndexOf(']');

    if (jsonStart == -1 || jsonEnd == -1) {
      throw Exception('No se encontró JSON válido');
    }

    final jsonString = response.substring(jsonStart, jsonEnd + 1);

    // Parsear JSON manualmente ya que no tenemos json.decode aquí
    final recommendations = <Map<String, dynamic>>[];

    // Implementación simple de parsing JSON
    final items = jsonString.substring(1, jsonString.length - 1).split('},{');

    for (final item in items) {
      final cleanItem = item.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '');
      final pairs = cleanItem.split(',');

      final rec = <String, dynamic>{};
      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim();
          final value = keyValue[1].trim();

          if (key == 'savings') {
            rec[key] = double.tryParse(value) ?? 0.0;
          } else if (key == 'title' || key == 'description' || key == 'type' || key == 'icon' || key == 'color') {
            rec[key] = value;
          }
        }
      }

      // Agregar iconos y colores por defecto
      if (!rec.containsKey('icon')) {
        rec['icon'] = _getIconForType(rec['type'] ?? 'tip');
      }
      if (!rec.containsKey('color')) {
        rec['color'] = _getColorForType(rec['type'] ?? 'tip');
      }

      recommendations.add(rec);
    }

    return recommendations.take(4).toList();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'savings': return Icons.savings;
      case 'warning': return Icons.warning_amber;
      case 'goal': return Icons.flag;
      default: return Icons.lightbulb;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'savings': return Colors.green;
      case 'warning': return Colors.orange;
      case 'goal': return Colors.purple;
      default: return Colors.blue;
    }
  }

  List<Map<String, dynamic>> _generateLocalRecommendations() {
    final recommendations = <Map<String, dynamic>>[];

    // Analizar gastos por categoría
    final categoryTotals = <String, double>{};
    for (final expense in widget.expenses) {
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

    // Recomendación 2: Oportunidades locales
    recommendations.add({
      'type': 'savings',
      'title': 'Ofertas locales en Quito',
      'description': 'Pizza Hut tiene 2x1 en pizzas medianas. Mi Comisariato ofrece 30% descuento en lácteos.',
      'savings': 15.0,
      'icon': Icons.local_offer,
      'color': Colors.green,
    });

    // Recomendación 3: Meta de ahorro semanal
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

  List<Map<String, dynamic>> _generateRecommendations() {
    // Este método ahora es síncrono y llama al asíncrono
    // En un widget real, usaríamos FutureBuilder
    _generateGeminiRecommendations().then((recs) {
      if (mounted) {
        setState(() {
          // Aquí podríamos almacenar las recomendaciones
        });
      }
    });

    // Retornar recomendaciones locales mientras tanto
    return _generateLocalRecommendations();
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
                    'Ahorra \$${rec['savings'].toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onAcceptSavings(rec['savings']);
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