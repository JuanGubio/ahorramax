import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/add_expense_form.dart';
import '../widgets/add_income_form.dart';
import '../widgets/expense_chart.dart';
import '../widgets/expense_list.dart';
import '../widgets/ai_recommendations.dart';
import '../widgets/expense_calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/streak_tracker.dart';
import '../widgets/ai_chat.dart';
import '../widgets/money_mascot.dart';
import '../widgets/tutorial_overlay.dart';

class Expense {
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final String? photoUrl;
  final String? location;
  final double? amountSaved;

  Expense({
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.photoUrl,
    this.location,
    this.amountSaved,
  });
}

class Income {
  final String source;
  final double amount;
  final String description;
  final DateTime date;

  Income({
    required this.source,
    required this.amount,
    required this.description,
    required this.date,
  });
}

class DashboardScreen extends StatefulWidget {
  final VoidCallback? toggleTheme;

  const DashboardScreen({super.key, this.toggleTheme});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String userName = "Usuario";
  double balance = 0;
  double totalSavingsFromAI = 0;
  double savings = 0;
  double monthlyExpenses = 0;
  final List<Expense> userExpenses = [];
  final List<Income> incomes = [];
  bool showResetConfirm = false;
  bool showAddMoney = false;
  String addMoneyAmount = "";
  bool isDarkMode = false;
  String? chatCategory;
  bool showNavBar = false;
  bool showTutorial = false;
  final List<Map<String, String>> notifications = [];
  bool showNotifications = false;
  bool? currentStep;
  double? mainSavingsGoal;
  bool isLoading = true;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();

    _loadTutorialStatus();
    _startNotificationTimer();
    _playSound("enter");
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Cargar datos del usuario
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc['nombre'] ?? "Usuario";
          balance = (userDoc['balanceActual'] ?? 0.0).toDouble();
          savings = (userDoc['ahorroTotal'] ?? 0.0).toDouble();
        });
      } else {
        // Si no existe el documento, crear uno con valores por defecto
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
          'nombre': FirebaseAuth.instance.currentUser?.displayName ?? "Usuario",
          'email': FirebaseAuth.instance.currentUser?.email ?? "",
          'balanceActual': 0.0,
          'ahorroTotal': 0.0,
          'fechaRegistro': DateTime.now(),
        });
        setState(() {
          userName = FirebaseAuth.instance.currentUser?.displayName ?? "Usuario";
          balance = 0.0;
          savings = 0.0;
        });
      }

      // Cargar gastos
      QuerySnapshot expensesSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('gastos')
          .orderBy('fechaCreacion', descending: true)
          .get();

      List<Expense> loadedExpenses = [];
      double totalExpenses = 0;

      for (var doc in expensesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Expense expense = Expense(
          category: data['categoria'] ?? '',
          amount: data['monto'] ?? 0.0,
          description: data['descripcion'] ?? '',
          date: (data['fecha'] as Timestamp).toDate(),
          location: data['ubicacion'],
          amountSaved: data['montoAhorrado'],
          photoUrl: data['imagenUrl'],
        );
        loadedExpenses.add(expense);
        totalExpenses += expense.amount;
      }

      // Cargar ingresos
      QuerySnapshot incomesSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('ingresos')
          .orderBy('fechaCreacion', descending: true)
          .get();

      List<Income> loadedIncomes = [];

      for (var doc in incomesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Income income = Income(
          source: data['fuente'] ?? '',
          amount: data['monto'] ?? 0.0,
          description: data['descripcion'] ?? '',
          date: (data['fecha'] as Timestamp).toDate(),
        );
        loadedIncomes.add(income);
      }

      setState(() {
        userExpenses.clear();
        userExpenses.addAll(loadedExpenses);
        incomes.clear();
        incomes.addAll(loadedIncomes);
        monthlyExpenses = totalExpenses;
        isLoading = false;
      });

      print("Datos del usuario cargados correctamente");
    } catch (e) {
      print("Error al cargar datos del usuario: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;
    if (!hasSeenTutorial) {
      setState(() => showTutorial = true);
    }
  }

  void _startNotificationTimer() {
    const notificationMessages = [
      {'message': '🌟 Oferta especial: Pizza Hut 2x1 en pizzas medianas - ¡Ahorra \$8.50!', 'category': 'comida'},
      {'message': '🛒 Mi Comisariato: 30% descuento en productos lácteos esta semana', 'category': 'compras'},
      {'message': '🚌 Ecovía: Recarga tu tarjeta y obtén 10% extra gratis', 'category': 'transporte'},
      {'message': '🍔 KFC: Combo familiar por solo \$12.99 - ¡Ideal para compartir!', 'category': 'comida'},
      {'message': '🏪 Tía: Ofertas en productos de limpieza - Hasta 40% off', 'category': 'hogar'},
      {'message': '📱 Movistar: Plan de datos ilimitado con 50% descuento por tiempo limitado', 'category': 'servicios'},
      {'message': '👕 Ripley: 25% descuento en toda la sección de ropa', 'category': 'compras'},
      {'message': '☕ Juan Valdez: Café colombiano con 20% descuento en sucursales', 'category': 'comida'},
      {'message': '🎬 CineMark: Entradas 2x1 todos los miércoles', 'category': 'entretenimiento'},
      {'message': '💄 Yves Rocher: 30% off en productos de belleza y cuidado personal', 'category': 'salud'},
    ];

    Future.delayed(const Duration(seconds: 45), () {
      if (mounted) {
        final randomNotification = notificationMessages[DateTime.now().millisecondsSinceEpoch % notificationMessages.length];
        setState(() {
          notifications.add({
            'id': DateTime.now().toString(),
            'message': randomNotification['message']!,
            'category': randomNotification['category']!,
          });
          if (notifications.length > 5) {
            notifications.removeAt(0);
          }
        });
        _startNotificationTimer();
      }
    });
  }

  void _playSound(String type) async {
    try {
      String audioPath = '';
      switch (type) {
        case 'add':
          audioPath = 'assets/audio/coin.mp3';
          break;
        case 'remove':
          audioPath = 'assets/audio/cash-register.mp3';
          break;
        case 'success':
          audioPath = 'assets/audio/success.mp3';
          break;
        case 'enter':
          audioPath = 'assets/audio/welcome.mp3';
          break;
      }

      if (audioPath.isNotEmpty) {
        await _audioPlayer.play(AssetSource(audioPath));
      }
    } catch (e) {
      // Si no hay archivos de audio, usar Web Audio API como fallback
      _playWebAudio(type);
    }
  }

  void _playWebAudio(String type) {
    // Implementar sonidos usando Web Audio API como en el código original React
    if (type == 'enter') {
      // Sonido de bienvenida
      _playTone(523, 0.3); // Do
      Future.delayed(const Duration(milliseconds: 100), () {
        _playTone(659, 0.3); // Mi
      });
    } else if (type == 'add') {
      // Sonido de monedas
      _playTone(880, 0.15); // La
      Future.delayed(const Duration(milliseconds: 50), () {
        _playTone(1100, 0.15); // Do#
      });
    } else if (type == 'remove') {
      // Sonido de cajero
      _playTone(300, 0.2); // Re bajo
      Future.delayed(const Duration(milliseconds: 80), () {
        _playTone(250, 0.15); // Do bajo
      });
    } else if (type == 'success') {
      // Sonido de éxito
      _playTone(1047, 0.2); // Do alto
      Future.delayed(const Duration(milliseconds: 100), () {
        _playTone(1319, 0.2); // Mi alto
      });
    }
  }

  void _playTone(double frequency, double duration) {
    // Implementación simplificada de Web Audio API
    // En un entorno real, usaríamos la Web Audio API de JavaScript
  }

  void _handleTutorialComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', true);
    setState(() => showTutorial = false);

    // Show welcome splash after tutorial
    _showWelcomeSplash();
  }

  void _showWelcomeSplash() {
    setState(() => showTutorial = true); // Reuse tutorial state for welcome splash

    // Create a simple welcome splash
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF0FFF4),
                const Color(0xFFE6FBFF),
                const Color(0xFFFFF6EA),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
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
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
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
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcIn,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: const Color(0xFF2ECC71),
                        child: const Icon(
                          Icons.attach_money,
                          color: Colors.white,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Welcome text
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF2ECC71), Color(0xFF4FA3FF), Color(0xFF00C853)],
                ).createShader(bounds),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¡Bienvenido a AhorraMax ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Tu viaje hacia el ahorro inteligente comienza ahora',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Continue button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() => showTutorial = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '¡Comenzar!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAddExpense(Map<String, dynamic> expenseData) {
    final expense = Expense(
      category: expenseData['category'],
      amount: expenseData['amount'],
      description: expenseData['description'],
      date: expenseData['date'],
      photoUrl: expenseData['photoFile'] != null ? 'photo' : null,
      location: expenseData['location'],
      amountSaved: expenseData['amountSaved'],
    );

    setState(() {
      userExpenses.insert(0, expense); // Agregar al inicio para mostrar los más recientes
      monthlyExpenses += expense.amount;
      balance -= expense.amount;

      if (expense.amountSaved != null && expense.amountSaved! > 0) {
        savings += expense.amountSaved!;
        totalSavingsFromAI += expense.amountSaved!;
      }
    });

    _playSound("remove");

    // Forzar recarga de datos para asegurar persistencia
    _cargarDatosUsuario();
  }

  void _handleAddIncome(dynamic income) {
    setState(() {
      incomes.insert(0, income); // Agregar al inicio para mostrar los más recientes
      balance += income.amount;
    });
    _playSound("add");

    // Forzar recarga de datos para asegurar persistencia
    _cargarDatosUsuario();
  }

  Future<void> _handleDeleteExpense(int index) async {
    final expense = userExpenses[index];

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Buscar el documento del gasto en Firebase para eliminarlo
      QuerySnapshot expensesSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('gastos')
          .where('categoria', isEqualTo: expense.category)
          .where('monto', isEqualTo: expense.amount)
          .where('descripcion', isEqualTo: expense.description)
          .where('fecha', isEqualTo: Timestamp.fromDate(expense.date))
          .get();

      if (expensesSnapshot.docs.isNotEmpty) {
        await expensesSnapshot.docs.first.reference.delete();

        // Actualizar balance y ahorro total del usuario
        DocumentReference userDoc = FirebaseFirestore.instance.collection('usuarios').doc(uid);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(userDoc);
          if (snapshot.exists) {
            double currentBalance = snapshot['balanceActual'] ?? 0.0;
            double currentSavings = snapshot['ahorroTotal'] ?? 0.0;

            transaction.update(userDoc, {
              'balanceActual': currentBalance + expense.amount,
              'ahorroTotal': currentSavings - (expense.amountSaved ?? 0.0),
            });
          }
        });
      }

      setState(() {
        monthlyExpenses -= expense.amount;
        balance += expense.amount;
        if (expense.amountSaved != null && expense.amountSaved! > 0) {
          savings -= expense.amountSaved!;
          totalSavingsFromAI -= expense.amountSaved!;
        }
        userExpenses.removeAt(index);
      });

      _playSound("remove");
    } catch (e) {
      print("Error al eliminar gasto: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al eliminar gasto: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleResetExpenses() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Eliminar todos los gastos
      QuerySnapshot expensesSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('gastos')
          .get();

      for (var doc in expensesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Eliminar todos los ingresos
      QuerySnapshot incomesSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('ingresos')
          .get();

      for (var doc in incomesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Resetear balance y ahorros en el documento del usuario
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'balanceActual': 0.0,
        'ahorroTotal': 0.0,
      });

      setState(() {
        balance = 0;
        monthlyExpenses = 0;
        savings = 0;
        totalSavingsFromAI = 0;
        userExpenses.clear();
        incomes.clear();
        showResetConfirm = false;
      });

      print("Todos los datos han sido reseteados");
    } catch (e) {
      print("Error al resetear datos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al resetear datos: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAddMoney() async {
    if (addMoneyAmount.isNotEmpty && double.tryParse(addMoneyAmount) != null) {
      final amount = double.parse(addMoneyAmount);

      try {
        String uid = FirebaseAuth.instance.currentUser!.uid;

        // Actualizar balance en Firebase
        DocumentReference userDoc = FirebaseFirestore.instance.collection('usuarios').doc(uid);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(userDoc);
          if (snapshot.exists) {
            double currentBalance = (snapshot['balanceActual'] ?? 0.0).toDouble();
            transaction.update(userDoc, {
              'balanceActual': currentBalance + amount,
            });
          } else {
            // Si no existe el documento, crearlo
            transaction.set(userDoc, {
              'balanceActual': amount,
              'ahorroTotal': 0.0,
              'nombre': FirebaseAuth.instance.currentUser?.displayName ?? "Usuario",
              'email': FirebaseAuth.instance.currentUser?.email ?? "",
              'fechaRegistro': DateTime.now(),
            });
          }
        });

        setState(() {
          balance += amount;
          showAddMoney = false;
          addMoneyAmount = "";
        });
        _playSound("add");

        // Forzar recarga de datos para asegurar persistencia
        _cargarDatosUsuario();
      } catch (e) {
        print("Error al agregar dinero: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al agregar dinero: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAcceptSavings(double savingsAmount) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Actualizar ahorro total en Firebase
      DocumentReference userDoc = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDoc);
        if (snapshot.exists) {
          double currentSavings = snapshot['ahorroTotal'] ?? 0.0;
          transaction.update(userDoc, {
            'ahorroTotal': currentSavings + savingsAmount,
          });
        }
      });

      setState(() {
        totalSavingsFromAI += savingsAmount;
        savings += savingsAmount;
      });
      _playSound("success");
    } catch (e) {
      print("Error al aceptar ahorros: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al aceptar ahorros: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleDarkMode() {
    setState(() => isDarkMode = !isDarkMode);
  }

  void _openChatWithCategory(String category) {
    setState(() {
      chatCategory = category;
      showNavBar = false;
    });
  }

  void _handleNotificationClick(Map<String, String> notification) {
    setState(() => showNotifications = false);
    setState(() => chatCategory = notification['category']);
    // Remover la notificación
    setState(() {
      notifications.removeWhere((n) => n['id'] == notification['id']);
    });
  }

  String _formatLargeNumber(double num) {
    if (num >= 1000000000) {
      return '${(num / 1000000000).toStringAsFixed(1)} billones';
    }
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)} millones';
    }
    if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)} mil';
    }
    return num.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando tus datos...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2ECC71), Color(0xFF4FA3FF)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.attach_money, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF2ECC71), Color(0xFF4FA3FF)],
                              ).createShader(bounds),
                              child: Row(
                                children: [
                                  const Text(
                                    'AhorraMax',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'G',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => setState(() => showNavBar = !showNavBar),
                              icon: const Icon(Icons.search),
                            ),
                            IconButton(
                              onPressed: widget.toggleTheme,
                              icon: Icon(
                                Theme.of(context).brightness == Brightness.dark
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                color: Colors.white,
                              ),
                            ),
                            Stack(
                              children: [
                                IconButton(
                                  onPressed: () => setState(() => showNotifications = !showNotifications),
                                  icon: const Icon(Icons.calendar_month),
                                  tooltip: 'Calendario Rápido',
                                ),
                                if (notifications.isNotEmpty)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        notifications.length.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/profile'),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: const Text('MG', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),

                        // Navigation Bar
                        if (showNavBar) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '¿Qué estás buscando?',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    'Comida',
                                    'Transporte',
                                    'Compras',
                                    'Salud',
                                    'Entretenimiento',
                                    'Educación',
                                    'Servicios',
                                    'Hogar'
                                  ].map((category) => ElevatedButton.icon(
                                    onPressed: () => _openChatWithCategory(category.toLowerCase()),
                                    icon: Icon(_getCategoryIcon(category.toLowerCase())),
                                    label: Text(category),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                      foregroundColor: Theme.of(context).primaryColor,
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Main Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      Text(
                        'Hola, $userName',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Aquí está tu resumen financiero de hoy',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Total del día
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total del día:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${userExpenses.where((expense) {
                                final now = DateTime.now();
                                return expense.date.year == now.year &&
                                       expense.date.month == now.month &&
                                       expense.date.day == now.day;
                              }).fold<double>(0, (sum, expense) => sum + expense.amount).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Calendario después del resumen financiero
                      ExpenseCalendar(expenses: userExpenses),

                      const SizedBox(height: 24),

                      // Balance Cards
                      GridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // Balance Card
                          Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.green, Color(0xFF2E7D32)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () => setState(() => showAddMoney = true),
                                            icon: const Icon(Icons.add, color: Colors.white),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.white.withOpacity(0.2),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => setState(() => showResetConfirm = true),
                                            icon: const Icon(Icons.refresh, color: Colors.white),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.white.withOpacity(0.2),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Dinero Actual',
                                    style: TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                  Text(
                                    '\$${_formatLargeNumber(balance)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Savings Card
                          Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.blue, Colors.indigo],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.savings, color: Colors.white),
                                      ),
                                      const Icon(Icons.trending_up, color: Colors.white70),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Ahorros Totales',
                                    style: TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                  Text(
                                    '\$${savings.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (totalSavingsFromAI > 0) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Has ahorrado \$${totalSavingsFromAI.toStringAsFixed(2)} con recomendaciones de IA',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Expenses Card
                          Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.red, Colors.redAccent],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.credit_card, color: Colors.white),
                                      ),
                                      const Icon(Icons.trending_down, color: Colors.white70),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Gastos del Mes',
                                    style: TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                  Text(
                                    '\$${monthlyExpenses.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Haz clic para ver detalles',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Savings Goal Card
                      Card(
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
                                  Icon(Icons.savings, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Tu Meta de Ahorro',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (balance > 0) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Balance Actual',
                                        style: TextStyle(color: Colors.grey, fontSize: 14),
                                      ),
                                      Text(
                                        '\$${_formatLargeNumber(balance)}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Sugerencias para ti:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                _buildSavingsSuggestions(),
                              ] else ...[
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'Comienza agregando dinero a tu balance para ver sugerencias personalizadas',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Forms
                      Row(
                        children: [
                          Expanded(
                            child: AddExpenseForm(onAddExpense: _handleAddExpense),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AddIncomeForm(onAddIncome: _handleAddIncome),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Additional Components
                      const SizedBox(height: 24),
                      StreakTracker(),
                      const SizedBox(height: 16),
                      AIRecommendations(
                        expenses: userExpenses,
                        onAcceptSavings: _handleAcceptSavings,
                      ),
                      const SizedBox(height: 16),
                      ExpenseList(
                        expenses: userExpenses,
                        onDeleteExpense: _handleDeleteExpense,
                      ),
                      const SizedBox(height: 16),
                      ExpenseChart(expenses: userExpenses),

                    ],
                  ),
                ),
              ],
            ),
          ),

          // Notifications Panel / Calendar Quick Access
          if (showNotifications)
            Positioned(
              top: 80,
              right: 16,
              child: Container(
                width: 350,
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Calendario Rápido',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Mini Calendar Widget
                    Container(
                      height: 320,
                      width: double.infinity,
                      child: TableCalendar(
                        firstDay: DateTime(2020),
                        lastDay: DateTime(2030),
                        focusedDay: DateTime.now(),
                        calendarFormat: CalendarFormat.month,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          cellMargin: const EdgeInsets.all(3),
                          cellPadding: const EdgeInsets.all(1),
                          selectedDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          markerSize: 6,
                          markersMaxCount: 1,
                          defaultTextStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          weekendTextStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          outsideTextStyle: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        eventLoader: (day) {
                          return userExpenses.where((expense) =>
                            expense.date.year == day.year &&
                            expense.date.month == day.month &&
                            expense.date.day == day.day
                          ).toList();
                        },
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            final expensesForDay = userExpenses.where((expense) =>
                              expense.date.year == day.year &&
                              expense.date.month == day.month &&
                              expense.date.day == day.day
                            ).toList();

                            if (expensesForDay.isNotEmpty) {
                              // Obtener la categoría más común del día
                              final categoryCount = <String, int>{};
                              for (final expense in expensesForDay) {
                                categoryCount[expense.category] = (categoryCount[expense.category] ?? 0) + 1;
                              }
                              final mostCommonCategory = categoryCount.entries
                                  .reduce((a, b) => a.value > b.value ? a : b)
                                  .key;

                              return Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(mostCommonCategory).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _getCategoryColor(mostCommonCategory).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(mostCommonCategory),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).cardColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(mostCommonCategory),
                                          color: Colors.white,
                                          size: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (notifications.isNotEmpty) ...[
                      const Divider(),
                      const Text(
                        'Ofertas Cerca de Ti',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return ListTile(
                              dense: true,
                              title: Text(notification['message']!, style: const TextStyle(fontSize: 14)),
                              subtitle: const Text('Toca para más detalles en el chat IA', style: TextStyle(fontSize: 12)),
                              onTap: () => _handleNotificationClick(notification),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Add Money Dialog
          if (showAddMoney)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet, size: 48, color: Colors.green),
                        const SizedBox(height: 16),
                        const Text(
                          'Agregar más dinero',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('Ingresa la cantidad que quieres agregar a tu balance actual'),
                        const SizedBox(height: 16),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Ingresa cantidad',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => addMoneyAmount = value,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() {
                                  showAddMoney = false;
                                  addMoneyAmount = "";
                                }),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleAddMoney,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Agregar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Reset Confirm Dialog
          if (showResetConfirm)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          '¿Seguro quieres resetear todo?',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Esta acción eliminará todos tus ${userExpenses.length} gastos y ${incomes.length} ingresos registrados. Esta acción no se puede deshacer.',
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => showResetConfirm = false),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleResetExpenses,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Sí, Resetear'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Tutorial Overlay
          if (showTutorial)
            TutorialOverlay(onComplete: _handleTutorialComplete),

          // AI Chat
          if (chatCategory != null && !showTutorial)
            Positioned(
              bottom: 16,
              right: 16,
              child: AIChat(initialCategory: chatCategory!),
            ),

          // Money Mascot
          if (!showTutorial)
            const Positioned(
              bottom: 16,
              left: 16,
              child: MoneyMascot(),
            ),
        ],
      ),
    );
  }

  Widget _buildSavingsSuggestions() {
    if (balance < 100) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Text(
          '\$${(100 - balance).toStringAsFixed(2)} más y tendrás \$100 - perfecto para una comida especial',
        ),
      );
    } else if (balance >= 100 && balance < 200) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: const Text(
          'Con tu balance puedes comprar una cena para dos en un buen restaurante',
        ),
      );
    } else if (balance >= 200 && balance < 400) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Text(
          '\$${(400 - balance).toStringAsFixed(2)} más y tendrás \$400 - suficiente para un electrodoméstico útil',
        ),
      );
    } else if (balance >= 400 && balance < 1000) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: const Text(
          '🏆 Con tu balance puedes comprar una refrigeradora o TV de buena calidad',
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Text(
          '¡Excelente! Con \$${_formatLargeNumber(balance)} puedes comprar electrodomésticos premium, muebles o invertir',
        ),
      );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Restaurantes':
        return Colors.red;
      case 'Transporte':
        return Colors.blue;
      case 'Entretenimiento':
        return Colors.orange;
      case 'Compras':
        return Colors.purple;
      case 'Servicios':
        return Colors.teal;
      case 'Salud':
        return Colors.green;
      case 'Educación':
        return Colors.indigo;
      case 'Otros':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Restaurantes':
        return Icons.restaurant;
      case 'Transporte':
        return Icons.directions_car;
      case 'Entretenimiento':
        return Icons.tv;
      case 'Compras':
        return Icons.shopping_bag;
      case 'Servicios':
        return Icons.build;
      case 'Salud':
        return Icons.favorite;
      case 'Educación':
        return Icons.school;
      case 'Otros':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}