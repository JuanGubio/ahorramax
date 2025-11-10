import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _loadingWidthAnimation;

  String _currentTip = '';
  Timer? _navigationTimer;

  final List<String> _savingsTips = [
    "Ahorra el 20% de tus ingresos cada mes",
    "Evita compras impulsivas, espera 24 horas",
    "Prepara comida en casa, ahorra hasta 40%",
    "Cancela suscripciones que no uses",
    "Usa transporte público cuando sea posible",
    "Compara precios antes de comprar",
    "Establece metas de ahorro claras",
    "Revisa tus gastos cada semana",
    "Compra en Mi Comisariato los miércoles, hay descuentos especiales",
    "Evita comer fuera, cocinar en casa ahorra hasta \$200/mes",
    "Usa apps de descuentos como Rappi y Uber Eats con cupones",
    "Compra productos genéricos, ahorras hasta 30%",
    "Planifica tus compras con lista, evita gastos innecesarios",
    "Aprovecha los días sin IVA en Ecuador",
    "Compra en mercados locales, son más económicos",
    "Usa bicicleta o camina distancias cortas, ahorra en transporte",
    "Compra en Santa María en horarios de ofertas nocturnas",
    "Aprovecha el 2x1 en Tía los fines de semana",
    "Revisa tu suscripción de Netflix, comparte con familia",
    "Usa WiFi público en cafés para ahorrar datos móviles",
    "Compra ropa en temporada de liquidación, ahorras 50%",
    "Prepara café en casa, ahorras \$60/mes vs cafeterías",
    "Lleva lunch al trabajo, ahorras \$100/mes",
    "Compra productos de temporada, son más baratos",
    "Usa cupones digitales antes de comprar online",
    "Repara en vez de reemplazar cuando sea posible",
    "Apaga luces y electrodomésticos, reduce tu factura eléctrica",
    "Usa termos para agua, evita comprar botellas",
    "Compra al por mayor en Makro o PriceSmart",
  ];

  @override
  void initState() {
    super.initState();

    // Inicializar controladores de animación
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Configurar animaciones
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _loadingWidthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    // Seleccionar tip aleatorio
    final random = Random();
    _currentTip = _savingsTips[random.nextInt(_savingsTips.length)];

    // Iniciar animaciones secuenciales
    _startAnimations();

    // Navegar después de 4 segundos (después de que termine la barra de carga)
    _navigationTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    });
  }

  void _startAnimations() {
    // Logo aparece primero
    _logoController.forward().then((_) {
      // Texto aparece después
      Future.delayed(const Duration(milliseconds: 300), () {
        _textController.forward().then((_) {
          // Barra de carga inicia después
          Future.delayed(const Duration(milliseconds: 300), () {
            _loadingController.forward();
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF0FFF4), // Verde pastel suave
              const Color(0xFFE6FBFF), // Azul pastel
              const Color(0xFFFFF6EA), // Naranja pastel
            ],
          ),
        ),
        child: Stack(
          children: [
            // Fondos decorativos animados
            Positioned(
              top: 100,
              left: 50,
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(),
              ),
            ),
            Positioned(
              bottom: 150,
              right: 50,
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF4FA3FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              left: MediaQuery.of(context).size.width * 0.3,
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(),
              ),
            ),

            // Contenido principal
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo animado
                    AnimatedBuilder(
                      animation: _logoScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  color: Colors.white,
                                  colorBlendMode: BlendMode.srcIn,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: const Color(0xFF2ECC71),
                                      child: const Icon(
                                        Icons.attach_money,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Nombre de la app
                    AnimatedBuilder(
                      animation: _textOpacityAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textOpacityAnimation.value,
                          child: Column(
                            children: [
                              Text(
                                'AhorraMax',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..shader = LinearGradient(
                                      colors: [
                                        const Color(0xFF2ECC71), // Verde
                                        const Color(0xFF4FA3FF), // Azul
                                        const Color(0xFF00C853), // Verde brillante
                                      ],
                                    ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tu asistente financiero inteligente',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 48),

                    // Solo mostrar barra de carga sin tip

                    const SizedBox(height: 48),

                    // Barra de carga
                    AnimatedBuilder(
                      animation: _loadingWidthAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 200,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _loadingWidthAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF2ECC71),
                                    const Color(0xFF4FA3FF),
                                    const Color(0xFF00C853),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}