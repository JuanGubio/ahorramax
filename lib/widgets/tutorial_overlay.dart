import 'package:flutter/material.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialOverlay({super.key, required this.onComplete});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final List<Map<String, dynamic>> _tutorialSteps = [
    {
      'title': '¡Bienvenido a AhorraMax! 👋',
      'description': 'Tu asistente financiero personal. Vamos a hacer un tour rápido.',
      'target': 'balance-section',
      'position': 'center',
    },
    {
      'title': 'Tu Balance Actual 💰',
      'description': 'Aquí verás todo tu dinero disponible. Puedes agregar más haciendo clic en el botón +.',
      'target': 'balance-section',
      'position': 'top',
    },
    {
      'title': 'Ahorros y Gastos 📊',
      'description': 'Monitorea tus ahorros totales y gastos del mes. ¡Mantén el equilibrio!',
      'target': 'ahorros-section',
      'position': 'top',
    },
    {
      'title': 'Agregar Gasto 💸',
      'description': 'Registra tus gastos aquí. Categorízalos correctamente para mejores recomendaciones.',
      'target': 'add-expense-form',
      'position': 'bottom',
    },
    {
      'title': 'Recomendaciones IA 🤖',
      'description': 'La IA te dará consejos personalizados basados en tus hábitos de gasto.',
      'target': 'recommendations-section',
      'position': 'top',
    },
    {
      'title': '¡Listo para empezar! 🚀',
      'description': 'Ahora puedes comenzar a gestionar tus finanzas. ¡Recuerda registrar todo!',
      'target': 'center',
      'position': 'center',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _tutorialSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _tutorialSteps[_currentStep];

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _opacityAnimation]),
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.7 * _opacityAnimation.value),
          child: Stack(
            children: [
              // Spotlight effect
              if (step['target'] != 'center')
                Positioned.fill(
                  child: CustomPaint(
                    painter: SpotlightPainter(
                      targetElement: step['target'],
                      opacity: _opacityAnimation.value,
                    ),
                  ),
                ),

              // Tutorial content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Spacer(),
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Mascot
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Colors.yellow, Colors.orange],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.emoji_emotions,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Title
                              Text(
                                step['title'],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),

                              // Description
                              Text(
                                step['description'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Progress indicator
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _tutorialSteps.length,
                                  (index) => Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index <= _currentStep
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Buttons
                              Row(
                                children: [
                                  if (_currentStep > 0)
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _previousStep,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Anterior'),
                                      ),
                                    ),
                                  if (_currentStep > 0) const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _nextStep,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        _currentStep == _tutorialSteps.length - 1
                                            ? '¡Comenzar!'
                                            : 'Siguiente',
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Skip button
                              if (_currentStep < _tutorialSteps.length - 1)
                                TextButton(
                                  onPressed: widget.onComplete,
                                  child: const Text(
                                    'Omitir tutorial',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final String targetElement;
  final double opacity;

  SpotlightPainter({required this.targetElement, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7 * opacity)
      ..style = PaintingStyle.fill;

    // Create a path that covers the entire screen
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create a spotlight hole (this would need to be positioned based on the actual element)
    // For now, we'll create a general spotlight effect
    final spotlightRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 200,
      height: 150,
    );

    final spotlightPath = Path()
      ..addRRect(RRect.fromRectAndRadius(spotlightRect, const Radius.circular(16)));

    // Subtract the spotlight from the overlay
    final combinedPath = Path.combine(
      PathOperation.difference,
      path,
      spotlightPath,
    );

    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}