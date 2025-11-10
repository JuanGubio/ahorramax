import 'package:flutter/material.dart';

class AIChat extends StatefulWidget {
  final String initialCategory;

  const AIChat({super.key, required this.initialCategory});

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();

    // Mensaje de bienvenida
    _addBotMessage('¡Hola! Soy tu asistente financiero IA. ¿En qué puedo ayudarte hoy? 💰');
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

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _addUserMessage(message);
    _messageController.clear();

    setState(() => _isTyping = true);

    // Simular respuesta de IA
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isTyping = false);
      _addBotMessage(_generateResponse(message));
    });
  }

  String _generateResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    // Respuestas basadas en categorías
    if (message.contains('comida') || message.contains('restaurante') || message.contains('pizza')) {
      return '🍕 ¡Buena elección! Te recomiendo revisar las ofertas de Pizza Hut hoy - tienen 2x1 en pizzas medianas. También puedes cocinar en casa para ahorrar más. ¿Te ayudo con alguna receta económica?';
    }

    if (message.contains('transporte') || message.contains('bus') || message.contains('taxi')) {
      return '🚌 Para transporte, considera usar la tarjeta Ecovía - tiene descuentos. Si vas a lugares cercanos, ¡la bicicleta es gratis y saludable! ¿A dónde necesitas ir?';
    }

    if (message.contains('supermercado') || message.contains('compras') || message.contains('tienda')) {
      return '🛒 Mi Comisariato tiene 30% descuento en lácteos esta semana. Tía ofrece productos de limpieza con 20% off. ¿Qué necesitas comprar?';
    }

    if (message.contains('ahorro') || message.contains('dinero') || message.contains('presupuesto')) {
      return '💡 Excelente pregunta sobre ahorro. Te sugiero: 1) Establece un presupuesto semanal, 2) Revisa ofertas antes de comprar, 3) Cocina en casa. ¿Quieres que analice tus gastos recientes?';
    }

    if (message.contains('gasto') || message.contains('cuánto') || message.contains('precio')) {
      return '📊 Puedo ayudarte a rastrear tus gastos. Registra cada compra en la app y te daré recomendaciones personalizadas. ¿Qué tipo de gasto quieres analizar?';
    }

    if (message.contains('oferta') || message.contains('descuento') || message.contains('promoción')) {
      return '🎉 ¡Genial! Hoy tenemos: Pizza Hut 2x1, Mi Comisariato 30% en lácteos, Tía productos de limpieza con descuento. ¿En qué categoría te interesa?';
    }

    if (message.contains('hola') || message.contains('hi') || message.contains('buenos')) {
      return '¡Hola! 👋 Soy tu asistente financiero personal. Puedo ayudarte con recomendaciones de ahorro, ofertas locales, análisis de gastos y mucho más. ¿Qué necesitas?';
    }

    if (message.contains('gracias') || message.contains('thank')) {
      return '¡De nada! 😊 Estoy aquí para ayudarte a ahorrar y tomar mejores decisiones financieras. ¿Hay algo más en lo que pueda asistirte?';
    }

    // Respuestas genéricas
    final genericResponses = [
      '¡Excelente pregunta! Déjame pensar en la mejor manera de ayudarte con eso. 💭',
      'Entiendo tu consulta. Basándome en patrones similares, te recomiendo revisar las ofertas locales primero. 🛍️',
      'Buena observación. El ahorro inteligente viene de pequeñas decisiones diarias. ¿Quieres que te dé tips específicos? 💡',
      'Interesante. Puedo analizar tus hábitos de gasto para darte recomendaciones más personalizadas. 📊',
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
            width: 350,
            height: 500,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
                        child: const Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asistente IA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Tu guía financiera',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Pregunta sobre finanzas...',
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
          maxWidth: MediaQuery.of(context).size.width * 0.7,
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