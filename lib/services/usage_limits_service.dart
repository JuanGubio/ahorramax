import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class UsageLimitsService {
  static const String _chatUsageKey = 'chat_usage_count';
  static const String _chatLastResetKey = 'chat_last_reset';
  static const String _voiceUsageKey = 'voice_usage_count';
  static const String _voiceLastResetKey = 'voice_last_reset';
  static const String _voiceFailedAttemptsKey = 'voice_failed_attempts';

  // Límites diarios
  static const int maxChatQuestionsPerDay = 10;
  static const int maxVoiceAttemptsPerDay = 20;
  static const int maxVoiceFailedAttempts = 3;

  // Categorías permitidas para preguntas
  static const List<String> allowedQuestionCategories = [
    'gastos', 'ingresos', 'presupuesto', 'ahorros', 'finanzas',
    'balance', 'categorías', 'tendencias', 'consejos', 'análisis',
    'recomendaciones', 'metas', 'objetivos', 'planes', 'estrategias'
  ];

  // Palabras clave para detectar preguntas financieras válidas
  static const List<String> financialKeywords = [
    'dinero', 'gastar', 'gasto', 'ingreso', 'presupuesto', 'ahorro',
    'balance', 'cuenta', 'banco', 'financiero', 'económico', 'presupuestario',
    'meta', 'objetivo', 'plan', 'estrategia', 'recomendación', 'consejo',
    'análisis', 'tendencia', 'categoría', 'transacción'
  ];

  static Future<bool> canUseChat(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastReset = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(_chatLastResetKey) ?? 0
    );

    // Reset diario
    if (!_isSameDay(now, lastReset)) {
      await _resetChatUsage();
      return true;
    }

    final usageCount = prefs.getInt(_chatUsageKey) ?? 0;

    if (usageCount >= maxChatQuestionsPerDay) {
      _showLimitReachedDialog(context, 'Chatbot', maxChatQuestionsPerDay, 'preguntas');
      return false;
    }

    return true;
  }

  static Future<bool> canUseVoice(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastReset = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(_voiceLastResetKey) ?? 0
    );

    // Reset diario
    if (!_isSameDay(now, lastReset)) {
      await _resetVoiceUsage();
      return true;
    }

    final usageCount = prefs.getInt(_voiceUsageKey) ?? 0;

    if (usageCount >= maxVoiceAttemptsPerDay) {
      _showLimitReachedDialog(context, 'Voz', maxVoiceAttemptsPerDay, 'intentos');
      return false;
    }

    return true;
  }

  static Future<void> incrementChatUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_chatUsageKey) ?? 0;
    await prefs.setInt(_chatUsageKey, current + 1);
  }

  static Future<void> incrementVoiceUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_voiceUsageKey) ?? 0;
    await prefs.setInt(_voiceUsageKey, current + 1);
  }

  static Future<void> incrementVoiceFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_voiceFailedAttemptsKey) ?? 0;
    await prefs.setInt(_voiceFailedAttemptsKey, current + 1);
  }

  static Future<bool> hasExceededVoiceFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final failedAttempts = prefs.getInt(_voiceFailedAttemptsKey) ?? 0;
    return failedAttempts >= maxVoiceFailedAttempts;
  }

  static Future<void> resetVoiceFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_voiceFailedAttemptsKey, 0);
  }

  static Future<Map<String, int>> getUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'chat_used': prefs.getInt(_chatUsageKey) ?? 0,
      'chat_limit': maxChatQuestionsPerDay,
      'voice_used': prefs.getInt(_voiceUsageKey) ?? 0,
      'voice_limit': maxVoiceAttemptsPerDay,
      'voice_failed': prefs.getInt(_voiceFailedAttemptsKey) ?? 0,
    };
  }

  static bool isQuestionFinanciallyRelevant(String question) {
    final lowerQuestion = question.toLowerCase();

    // Verificar si contiene palabras clave financieras
    final hasFinancialKeywords = financialKeywords.any(
      (keyword) => lowerQuestion.contains(keyword)
    );

    // Verificar si pertenece a categorías permitidas
    final hasAllowedCategories = allowedQuestionCategories.any(
      (category) => lowerQuestion.contains(category)
    );

    return hasFinancialKeywords || hasAllowedCategories;
  }

  static String getVoiceHelpMessage() {
    return '''
💡 Para usar la voz correctamente, di frases como:

• "50 dólares en comida"
• "Gasté 25 en transporte"
• "Ingreso de 1000 por salario"
• "Pago de 200 por servicios"

Recuerda:
• Menciona el monto primero
• Luego la categoría o descripción
• Habla claro y despacio
''';
  }

  static String getChatWarningMessage() {
    return '''
🤖 Chatbot de AhorraMax

• Máximo 10 preguntas por día
• Solo preguntas sobre finanzas personales
• Evita preguntas irrelevantes para ahorrar tokens

Preguntas permitidas:
• ¿Cómo mejorar mis ahorros?
• ¿Qué categorías gasto más?
• ¿Cuál es mi balance mensual?
• Recomendaciones para presupuesto
''';
  }

  static Future<void> _resetChatUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chatUsageKey, 0);
    await prefs.setInt(_chatLastResetKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> _resetVoiceUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_voiceUsageKey, 0);
    await prefs.setInt(_voiceLastResetKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_voiceFailedAttemptsKey, 0);
  }

  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static void _showLimitReachedDialog(BuildContext context, String feature, int limit, String unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Límite alcanzado - $feature'),
        content: Text(
          'Has alcanzado el límite diario de $limit $unit para $feature.\n\n'
          'El límite se resetea automáticamente cada día.\n\n'
          'Esto nos ayuda a mantener los costos bajos y asegurar '
          'que todos puedan usar la aplicación.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  static void showVoiceValidationDialog(BuildContext context, String voiceText, VoidCallback onConfirm, VoidCallback onRetry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar entrada de voz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Es correcta esta transcripción?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                '"$voiceText"',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              getVoiceHelpMessage(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: const Text('Reintentar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  static void showChatWarningDialog(BuildContext context, VoidCallback onContinue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🤖 Chatbot de AhorraMax'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getChatWarningMessage(),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Usa el chatbot responsablemente para mantener los costos bajos.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onContinue();
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}