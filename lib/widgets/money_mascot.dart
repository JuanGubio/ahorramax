import 'package:flutter/material.dart';
import 'dart:math' as math;

class MoneyMascot extends StatefulWidget {
  const MoneyMascot({super.key});

  @override
  State<MoneyMascot> createState() => _MoneyMascotState();
}

class _MoneyMascotState extends State<MoneyMascot> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _waveController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceAnimation, _waveAnimation]),
      builder: (context, child) {
        return Positioned(
          bottom: 16 + _bounceAnimation.value,
          left: 16,
          child: GestureDetector(
            onTap: () {
              _showMascotDialog(context);
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.yellow, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cara del monito
                  const Icon(
                    Icons.emoji_emotions,
                    color: Colors.white,
                    size: 40,
                  ),

                  // Brazos moviéndose
                  Positioned(
                    left: 5 + math.sin(_waveAnimation.value * 2) * 3,
                    top: 25,
                    child: Container(
                      width: 15,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 5 + math.sin(_waveAnimation.value * 2 + 3.14159) * 3,
                    top: 25,
                    child: Container(
                      width: 15,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // Monedas flotando
                  Positioned(
                    top: 5 + math.sin(_waveAnimation.value * 3) * 2,
                    right: 10,
                    child: const Text(
                      '💰',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),

                  Positioned(
                    bottom: 5 + math.sin(_waveAnimation.value * 2 + 1.5) * 2,
                    left: 10,
                    child: const Text(
                      '💵',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMascotDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.yellow, Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¡Hola! 👋',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Soy tu amigo financiero',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getRandomMessage(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💰', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          const Text('¡A ahorrar!', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const Text('💰', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('¡Entendido!'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRandomMessage() {
    final messages = [
      '¡Recuerda registrar tus gastos para mantener un mejor control!',
      '¿Ya revisaste las ofertas de hoy? ¡Hay descuentos increíbles!',
      '¡Sigue así! Cada peso ahorrado cuenta para tu futuro.',
      '¿Sabías que cocinar en casa puede ahorrarte hasta 50%?',
      '¡Excelente trabajo! Tu racha de ahorro va en aumento.',
      '¿Has pensado en establecer una meta de ahorro mensual?',
      '¡Las pequeñas decisiones diarias suman grandes ahorros!',
      '¿Quieres que te ayude con recomendaciones personalizadas?',
    ];

    return messages[DateTime.now().millisecondsSinceEpoch % messages.length];
  }
}