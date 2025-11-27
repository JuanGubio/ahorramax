import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models.dart';
import '../services/usage_limits_service.dart';

class FinancialChatbot extends StatefulWidget {
  final List<Expense> expenses;
  final List<Income> incomes;
  final double balance;
  final double savings;

  const FinancialChatbot({
    super.key,
    required this.expenses,
    required this.incomes,
    required this.balance,
    required this.savings,
  });

  @override
  State<FinancialChatbot> createState() => _FinancialChatbotState();
}

class _FinancialChatbotState extends State<FinancialChatbot> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late GenerativeModel _model;

  // Speech-to-text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _speechText = '';
  double _confidence = 1.0;

  // Usage stats
  Map<String, int> _usageStats = {};

  static const String _apiKey = 'AIzaSyBxg6Ot1ZHCeXMnbHA8t9eVC9CL8aiJKWo';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();

    // Initialize speech-to-text
    _speech = stt.SpeechToText();

    // Initialize Gemini
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );

    // Load usage stats
    _loadUsageStats();

    // Welcome message with financial context
    _addBotMessage(_getWelcomeMessage());
  }

  Future<void> _loadUsageStats() async {
    _usageStats = await UsageLimitsService.getUsageStats();
    setState(() {});
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _getWelcomeMessage() {
    final totalExpenses = widget.expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalIncome = widget.incomes.fold<double>(0, (sum, i) => sum + i.amount);

    if (totalExpenses == 0 && totalIncome == 0) {
      return '¡Hola! Soy tu asistente financiero personal. Veo que aún no has registrado transacciones. ¿Te gustaría que te ayude a comenzar con consejos básicos de ahorro? 💰';
    }

    return '¡Hola! Soy tu asistente financiero personal. He analizado tus finanzas: tienes \$${widget.balance.toStringAsFixed(2)} en balance y \$${widget.savings.toStringAsFixed(2)} ahorrados. ¿En qué puedo ayudarte hoy? 📊';
  }

  void _addBotMessage(String message) {
    setState(() {
      _messages.add({
        'text': message,
        'isBot': true,
        'timestamp': DateTime.now(),
        'type': 'text',
      });
    });
    _scrollToBottom();
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add({
        'text': message,
        'isBot': false,
        'timestamp': DateTime.now(),
        'type': 'text',
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Verificar límites de uso
    final canUse = await UsageLimitsService.canUseChat(context);
    if (!canUse) return;

    // Verificar si la pregunta es financieramente relevante
    if (!UsageLimitsService.isQuestionFinanciallyRelevant(message)) {
      _showIrrelevantQuestionDialog(message);
      return;
    }

    _addUserMessage(message);
    _messageController.clear();

    setState(() => _isTyping = true);

    try {
      final response = await _getFinancialResponse(message);
      await UsageLimitsService.incrementChatUsage();
      setState(() => _isTyping = false);
      _addBotMessage(response);
    } catch (e) {
      setState(() => _isTyping = false);
      _addBotMessage('Lo siento, tuve un problema conectándome con la IA. ¿Puedes intentar de nuevo?');
      print('Error en chatbot financiero: $e');
    }
  }

  void _showIrrelevantQuestionDialog(String question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pregunta no relacionada con finanzas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tu pregunta no parece estar relacionada con finanzas personales.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                'Preguntas permitidas:\n• ¿Cuánto gasto al mes?\n• ¿Cómo ahorrar más?\n• ¿Cuál es mi balance?\n• Consejos de presupuesto\n• Análisis de gastos',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
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

  Future<String> _getFinancialResponse(String userMessage) async {
    try {
      // Analyze user data for context
      final financialContext = _buildFinancialContext();

      final prompt = '''
      Eres Gemini AI, el asistente financiero más avanzado integrado en AhorraMax.

      CONTEXTO FINANCIERO DEL USUARIO:
      $financialContext

      MENSAJE DEL USUARIO: "$userMessage"

      INSTRUCCIONES:
      1. Responde de manera específica y personalizada usando los datos financieros del usuario
      2. Sé útil, motivador y constructivo
      3. Proporciona consejos accionables basados en sus patrones reales
      4. Menciona ofertas locales en Quito/Ecuador cuando sea relevante
      5. Si preguntan sobre gastos específicos, analiza sus datos reales
      6. Mantén un tono profesional pero amigable
      7. Si no tienes suficiente contexto, pide más información específica

      TIPOS DE PREGUNTAS COMUNES:
      - "¿Cuánto gasté en [categoría]?" → Analiza sus gastos reales
      - "¿Cómo puedo ahorrar más?" → Sugerencias basadas en sus patrones
      - "¿Cuál es mi gasto promedio?" → Calcula basado en sus datos
      - "¿Dónde puedo encontrar ofertas?" → Sugiere lugares locales

      Responde de manera natural y conversacional, como un asesor financiero personal.
      Responde en español.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout: La respuesta tomó demasiado tiempo'),
      );

      if (response.text != null && response.text!.trim().isNotEmpty) {
        return response.text!.trim();
      } else {
        return _generateFallbackResponse(userMessage);
      }
    } catch (e) {
      print('Error al conectar con Gemini API: $e');
      // Check if it's a quota/rate limit error
      if (e.toString().contains('quota') || e.toString().contains('rate limit') || e.toString().contains('429')) {
        return 'Lo siento, he alcanzado el límite de uso gratuito de la API. Te recomiendo:\n\n💡 Consejos sin IA:\n• Registra tus gastos regularmente\n• Establece un presupuesto mensual\n• Busca ofertas en supermercados locales\n• Usa transporte público para ahorrar\n\n¿Te gustaría que te ayude con alguna pregunta específica sobre finanzas?';
      }
      return _generateFallbackResponse(userMessage);
    }
  }

  String _buildFinancialContext() {
    final totalExpenses = widget.expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalIncome = widget.incomes.fold<double>(0, (sum, i) => sum + i.amount);
    final netSavings = totalIncome - totalExpenses;

    // Category breakdown
    final categorySpending = <String, double>{};
    for (final expense in widget.expenses) {
      categorySpending[expense.category] = (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(3);

    return '''
    Balance actual: \$${widget.balance.toStringAsFixed(2)}
    Ahorros totales: \$${widget.savings.toStringAsFixed(2)}
    Gastos totales registrados: \$${totalExpenses.toStringAsFixed(2)}
    Ingresos totales registrados: \$${totalIncome.toStringAsFixed(2)}
    Ahorro neto: \$${netSavings.toStringAsFixed(2)}
    Número de transacciones: ${widget.expenses.length + widget.incomes.length}
    Categorías principales: ${topCategories.map((e) => '${e.key} (\$${e.value.toStringAsFixed(2)})').join(', ')}
    ''';
  }

  String _generateFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    // Analyze based on available data
    if (message.contains('cuánto') && message.contains('gast')) {
      if (message.contains('mes')) {
        final thisMonth = DateTime.now();
        final monthlyExpenses = widget.expenses
            .where((e) => e.date.month == thisMonth.month && e.date.year == thisMonth.year)
            .fold<double>(0, (sum, e) => sum + e.amount);
        return 'Este mes has gastado \$${monthlyExpenses.toStringAsFixed(2)}. ¿Te gustaría ver un desglose por categorías?';
      }

      if (message.contains('hoy')) {
        final today = DateTime.now();
        final todayExpenses = widget.expenses
            .where((e) => e.date.day == today.day && e.date.month == today.month && e.date.year == today.year)
            .fold<double>(0, (sum, e) => sum + e.amount);
        return 'Hoy has gastado \$${todayExpenses.toStringAsFixed(2)}. ¡Buen trabajo controlando tus gastos! 💪';
      }

      final totalExpenses = widget.expenses.fold<double>(0, (sum, e) => sum + e.amount);
      return 'Has registrado gastos por un total de \$${totalExpenses.toStringAsFixed(2)}. ¿Quieres que analice alguna categoría específica?';
    }

    if (message.contains('ahorr') || message.contains('saving')) {
      if (widget.savings > 0) {
        return '¡Excelente! Ya tienes \$${widget.savings.toStringAsFixed(2)} ahorrados. Te recomiendo continuar con metas pequeñas pero consistentes. ¿Quieres que te ayude a crear una nueva meta?';
      } else {
        return 'Aún no tienes ahorros registrados. Te sugiero comenzar con el 10% de tus ingresos. ¿Quieres que te ayude a calcular cuánto podrías ahorrar mensualmente?';
      }
    }

    if (message.contains('balance') || message.contains('dinero')) {
      return 'Tu balance actual es de \$${widget.balance.toStringAsFixed(2)}. Esto incluye tus ingresos menos tus gastos registrados. ¿Te gustaría ver un resumen detallado?';
    }

    if (message.contains('categoría') || message.contains('category')) {
      final categories = widget.expenses.map((e) => e.category).toSet().join(', ');
      return 'Has registrado gastos en estas categorías: $categories. ¿Quieres que analice alguna en particular?';
    }

    if (message.contains('promedio') || message.contains('average')) {
      if (widget.expenses.isNotEmpty) {
        final avgExpense = widget.expenses.fold<double>(0, (sum, e) => sum + e.amount) / widget.expenses.length;
        return 'Tu gasto promedio por transacción es de \$${avgExpense.toStringAsFixed(2)}. ¿Te gustaría ver cómo se compara con otras categorías?';
      }
    }

    if (message.contains('meta') || message.contains('goal')) {
      return 'Las metas financieras son una excelente manera de mantener la motivación. ¿Quieres que te ayude a crear una nueva meta o revisar tus metas existentes? 🎯';
    }

    if (message.contains('oferta') || message.contains('descuento')) {
      return '¡Buena pregunta sobre ofertas! En Quito puedes encontrar descuentos en: • Mi Comisariato (30% en lácteos) • Pizza Hut (2x1 en pizzas) • Ecovía (descuentos en transporte). ¿En qué categoría te interesa? 🏪';
    }

    // Generic responses
    final genericResponses = [
      'Entiendo tu consulta. Basándome en tus finanzas actuales, ¿podrías darme más detalles sobre lo que necesitas? 💭',
      '¡Buena pregunta! Déjame analizar tus patrones de gasto para darte la mejor respuesta posible.',
      'Estoy aquí para ayudarte con tus finanzas. ¿Podrías ser más específico sobre qué aspecto te gustaría mejorar?',
      'Como tu asistente financiero, puedo analizar tus gastos, sugerir ahorros y dar consejos personalizados. ¿Qué te preocupa más ahora?',
    ];

    return genericResponses[DateTime.now().millisecondsSinceEpoch % genericResponses.length];
  }

  void _listen() async {
    if (!_isListening) {
      // Verificar límites de voz
      final canUseVoice = await UsageLimitsService.canUseVoice(context);
      if (!canUseVoice) return;

      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _speechText = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                _confidence = val.confidence;
              }
              _messageController.text = _speechText;
            });
          },
          localeId: 'es_ES',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_speechText.isNotEmpty) {
        // Mostrar diálogo de confirmación para voz
        UsageLimitsService.showVoiceValidationDialog(
          context,
          _speechText,
          () async {
            await UsageLimitsService.incrementVoiceUsage();
            _sendMessage();
          },
          () {
            // Limpiar texto y reiniciar
            _speechText = '';
            _messageController.clear();
          }
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            width: 380,
            height: 550,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🤖',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asistente Financiero',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'IA de Google',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Usage indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_usageStats['chat_used'] ?? 0}/${_usageStats['chat_limit'] ?? 10}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }

                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),

                // Input
                Material(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Voice status indicator
                        if (_isListening) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mic, color: Colors.red.shade600, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Escuchando... (${(_confidence * 100).toStringAsFixed(0)}% confianza)',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: _isListening ? 'Habla ahora...' : 'Pregunta sobre tus finanzas...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isListening ? Icons.mic_off : Icons.mic,
                                      color: _isListening ? Colors.red : Colors.grey.shade600,
                                    ),
                                    onPressed: _listen,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(context).primaryColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: IconButton(
                                onPressed: _sendMessage,
                                icon: const Icon(Icons.send, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isBot = message['isBot'] as bool;
    final text = message['text'] as String;

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isBot
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Theme.of(context).primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isBot ? const Radius.circular(4) : const Radius.circular(16),
            bottomRight: isBot ? const Radius.circular(16) : const Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isBot ? Theme.of(context).textTheme.bodyLarge?.color : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pensando',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}