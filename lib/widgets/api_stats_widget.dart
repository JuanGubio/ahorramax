import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class ApiStatsWidget extends StatefulWidget {
  const ApiStatsWidget({super.key});

  @override
  State<ApiStatsWidget> createState() => _ApiStatsWidgetState();
}

class _ApiStatsWidgetState extends State<ApiStatsWidget> {
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _stats = GeminiService.getStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  'Estadísticas de IA',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadStats,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar estadísticas',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Monitoreo del uso de la API de Gemini',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Estadísticas principales
            Row(
              children: [
                _buildStatCard(
                  'Llamadas Totales',
                  _stats['totalCalls']?.toString() ?? '0',
                  Icons.call_made,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Respuestas en Cache',
                  _stats['cachedResponses']?.toString() ?? '0',
                  Icons.cached,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildStatCard(
                  'Tasa de Acierto Cache',
                  '${_stats['cacheHitRate'] ?? 0}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Tamaño Cache',
                  '${_stats['cacheSize'] ?? 0} items',
                  Icons.storage,
                  Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Última llamada
            if (_stats['lastApiCall'] != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Última llamada a API',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatLastCall(_stats['lastApiCall']),
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Información de optimización
            Container(
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
                    children: [
                      Icon(Icons.lightbulb, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Optimizaciones Activas',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Cache inteligente por 6 horas\n'
                    '• Límite de frecuencia (10 llamadas/min)\n'
                    '• Modelo compartido para eficiencia\n'
                    '• Solo llamadas cuando hay suficientes datos',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Botón de reset (solo para desarrollo)
            OutlinedButton.icon(
              onPressed: () {
                GeminiService.resetStats();
                _loadStats();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Estadísticas reseteadas')),
                );
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Resetear Estadísticas'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastCall(String? isoString) {
    if (isoString == null) return 'Nunca';

    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return 'Hace ${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
      } else if (difference.inHours > 0) {
        return 'Hace ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
      } else if (difference.inMinutes > 0) {
        return 'Hace ${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}';
      } else {
        return 'Ahora mismo';
      }
    } catch (e) {
      return isoString;
    }
  }
}