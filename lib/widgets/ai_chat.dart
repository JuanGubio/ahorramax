import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AIChat extends StatefulWidget {
  final String initialCategory;
  final VoidCallback? onClose;

  const AIChat({super.key, required this.initialCategory, this.onClose});

  @override
  State<AIChat> createState() => _AIChatState();
}

class _AIChatState extends State<AIChat> with TickerProviderStateMixin {
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

  // API Key de Gemini
  static const String _apiKey = 'AIzaSyBjQ9EZdV56NFAPbEBs77HiWKN4PM-If_I';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();

    // Inicializar speech-to-text
    _speech = stt.SpeechToText();

    // Inicializar modelo de Gemini
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );

    // Mensaje de bienvenida
    _addBotMessage('¡Hola! 👋 Soy Gemini AI, tu asistente financiero inteligente de Google. ¿En qué puedo ayudarte hoy? 💰🎙️ También puedes hablar presionando el micrófono.');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addBotMessage(String message) {
    setState(() {
      _messages.add({
        'text': message,
        'isBot': true,
        'timestamp': DateTime.now(),
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

    _addUserMessage(message);
    _messageController.clear();

    setState(() => _isTyping = true);

    try {
      final response = await _getGeminiResponse(message);
      setState(() => _isTyping = false);
      _addBotMessage(response);
    } catch (e) {
      setState(() => _isTyping = false);
      _addBotMessage('Lo siento, tuve un problema conectándome con la IA. ¿Puedes intentar de nuevo?');
      print('Error en chat IA: $e');
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _speechText = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
            // Auto-fill the text field
            _messageController.text = _speechText;
          }),
          localeId: 'es_ES', // Spanish locale
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      // If we have recognized text, send it
      if (_speechText.isNotEmpty) {
        _sendMessage();
      }
    }
  }

  Future<String> _getGeminiResponse(String userMessage) async {
    try {
      // Usar modelo correcto de Gemini
      final prompt = '''
Eres Gemini AI, el asistente de IA más avanzado de Google integrado en AhorraMax.

Usuario: "$userMessage"

Responde de manera inteligente, útil y enfocada en finanzas personales. Menciona ofertas locales cuando sea relevante.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      } else {
        return _generateFallbackResponse(userMessage);
      }
    } catch (e) {
      print('Error al conectar con Gemini API: $e');

      // Check for quota/rate limit errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('quota') ||
          errorString.contains('limit') ||
          errorString.contains('rate') ||
          errorString.contains('429')) {
        return '¡Hola! Soy el asistente financiero de AhorraMax. Actualmente estoy usando una clave de API de demostración que ha alcanzado su límite gratuito. Para continuar usando todas las funciones de IA, puedes obtener tu propia clave gratuita de Google AI Studio en https://makersuite.google.com/app/apikey y reemplazarla en la configuración de la app. Mientras tanto, puedo ayudarte con consejos financieros básicos. ¿En qué puedo asistirte?';
      }

      return _generateFallbackResponse(userMessage);
    }
  }

  String _generateFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    // Respuestas basadas en categorías
    if (message.contains('comida') || message.contains('restaurante') || message.contains('pizza')) {
      return '🍕 ¡Buena elección! Te recomiendo revisar las ofertas de Pizza Hut hoy - tienen 2x1 en pizzas medianas. También puedes cocinar en casa para ahorrar más 🏠. ¿Te ayudo con alguna receta económica? 👨‍🍳';
    }

    if (message.contains('transporte') || message.contains('bus') || message.contains('taxi')) {
      return '🚌 Para transporte, considera usar la tarjeta Ecovía - tiene descuentos. Si vas a lugares cercanos, ¡la bicicleta es gratis y saludable! 🚲 ¿A dónde necesitas ir?';
    }

    if (message.contains('supermercado') || message.contains('compras') || message.contains('tienda')) {
      return '🛒 Mi Comisariato tiene 30% descuento en lácteos esta semana. Tía ofrece productos de limpieza con 20% off. ¿Qué necesitas comprar?';
    }

    if (message.contains('ahorro') || message.contains('dinero') || message.contains('presupuesto')) {
      return '💰 Excelente pregunta sobre ahorro. Te sugiero: 1️⃣ Establece un presupuesto semanal, 2️⃣ Revisa ofertas antes de comprar, 3️⃣ Cocina en casa. ¿Quieres que analice tus gastos recientes? 📈';
    }

    if (message.contains('gasto') || message.contains('cuánto') || message.contains('precio')) {
      return '📊 Puedo ayudarte a rastrear tus gastos. Registra cada compra en la app y te daré recomendaciones personalizadas. ¿Qué tipo de gasto quieres analizar? 🔍';
    }

    if (message.contains('oferta') || message.contains('descuento') || message.contains('promoción')) {
      return '🎉 ¡Genial! Hoy tenemos: Pizza Hut 2x1 🍕, Mi Comisariato 30% en lácteos 🥛, Tía productos de limpieza con descuento 🧹. ¿En qué categoría te interesa?';
    }

    if (message.contains('hola') || message.contains('hi') || message.contains('buenos')) {
      return '¡Hola! 👋 Soy Gemini AI, el asistente de IA de Google integrado en AhorraMax. Estoy aquí para ayudarte con tus finanzas 💰, recomendaciones de ahorro 📈 y ofertas locales 🏷️. ¿En qué puedo asistirte hoy?';
    }

    if (message.contains('gracias') || message.contains('thank')) {
      return '¡De nada! 😊 Estoy aquí para ayudarte a ahorrar y tomar mejores decisiones financieras. ¿Hay algo más en lo que pueda asistirte? 🤝';
    }

    // Respuestas genéricas
    final genericResponses = [
      '¡Excelente pregunta! 💭 Déjame pensar en la mejor manera de ayudarte con eso.',
      'Entiendo tu consulta 🤔. Basándome en patrones similares, te recomiendo revisar las ofertas locales primero 🏷️.',
      'Buena observación 👀. El ahorro inteligente viene de pequeñas decisiones diarias. ¿Quieres que te dé tips específicos? 💡',
      'Interesante 📊. Puedo analizar tus hábitos de gasto para darte recomendaciones más personalizadas.',
    ];

    return genericResponses[DateTime.now().millisecondsSinceEpoch % genericResponses.length];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                  Colors.purple.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(-5, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Modern Header with Glass Effect
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6366F1), // Indigo
                        const Color(0xFF8B5CF6), // Purple
                        const Color(0xFF3B82F6), // Blue
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // AI Avatar with Glow Effect
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white, Colors.white70],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.smart_toy_rounded,
                              color: Color(0xFF6366F1),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gemini AI Assistant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Tu asesor financiero inteligente',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Close Button with Glass Effect
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              onPressed: widget.onClose ?? () {
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Status Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'En línea',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Messages Area with Gradient Background
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.blue.shade50.withOpacity(0.3),
                          Colors.purple.shade50.withOpacity(0.2),
                        ],
                      ),
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
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
                ),

                // Modern Input Area
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Voice Status with Modern Design
                      if (_isListening) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade50, Colors.pink.shade50],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red.shade200.withOpacity(0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade500,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.shade500.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Escuchando... Confianza: ${(_confidence * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Input Row with Modern Design
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: _isListening ? Colors.red.shade200 : Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                  boxShadow: _isListening ? [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : null,
                                ),
                                child: TextField(
                                controller: _messageController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: _isListening ? '🎤 Habla ahora...' : '💬 Pregunta sobre finanzas...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  suffixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: _isListening
                                          ? LinearGradient(colors: [Colors.red.shade400, Colors.pink.shade400])
                                          : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade600]),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        _isListening ? Icons.mic_off : Icons.mic,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: _listen,
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                        ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6366F1),
                                  const Color(0xFF8B5CF6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _sendMessage,
                              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                              padding: const EdgeInsets.all(14),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      // Quick Suggestions
                      if (!_isListening) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildQuickSuggestion('💰 ¿Cómo ahorrar más?'),
                              const SizedBox(width: 8),
                              _buildQuickSuggestion('🏪 ¿Qué ofertas hay hoy?'),
                              const SizedBox(width: 8),
                              _buildQuickSuggestion('📊 Analiza mis gastos'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickSuggestion(String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _messageController.text = text;
        });
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isBot = message['isBot'] as bool;
    final text = message['text'] as String;

    if (isBot) {
      return _buildBotMessageBubble(text);
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBotMessageBubble(String text) {
    // Detect keywords to add relevant icons
    IconData? icon;
    Color? iconColor;

    final lowerText = text.toLowerCase();

    if (lowerText.contains('dinero') || lowerText.contains('ahorro') || lowerText.contains('presupuesto')) {
      icon = Icons.savings;
      iconColor = Colors.green;
    } else if (lowerText.contains('comida') || lowerText.contains('restaurante') || lowerText.contains('pizza')) {
      icon = Icons.restaurant;
      iconColor = Colors.orange;
    } else if (lowerText.contains('transporte') || lowerText.contains('bus') || lowerText.contains('taxi')) {
      icon = Icons.directions_car;
      iconColor = Colors.blue;
    } else if (lowerText.contains('supermercado') || lowerText.contains('compras') || lowerText.contains('tienda')) {
      icon = Icons.shopping_cart;
      iconColor = Colors.purple;
    } else if (lowerText.contains('salud') || lowerText.contains('médico') || lowerText.contains('hospital')) {
      icon = Icons.favorite;
      iconColor = Colors.red;
    } else if (lowerText.contains('educación') || lowerText.contains('estudio') || lowerText.contains('escuela')) {
      icon = Icons.school;
      iconColor = Colors.indigo;
    } else if (lowerText.contains('entretenimiento') || lowerText.contains('cine') || lowerText.contains('música')) {
      icon = Icons.movie;
      iconColor = Colors.pink;
    } else if (lowerText.contains('oferta') || lowerText.contains('descuento') || lowerText.contains('promoción')) {
      icon = Icons.local_offer;
      iconColor = Colors.teal;
    } else if (lowerText.contains('gasto') || lowerText.contains('cuánto') || lowerText.contains('precio')) {
      icon = Icons.receipt;
      iconColor = Colors.red;
    } else if (lowerText.contains('hola') || lowerText.contains('buenos') || lowerText.contains('ayuda')) {
      icon = Icons.waving_hand;
      iconColor = Colors.amber;
    } else if (lowerText.contains('gracias') || lowerText.contains('thank')) {
      icon = Icons.thumb_up;
      iconColor = Colors.blue;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? Colors.grey,
                  size: 20,
                ),
              ),
            ],
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
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
              'Escribiendo',
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