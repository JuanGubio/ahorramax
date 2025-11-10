import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/add_expense_form.dart';
import '../widgets/add_income_form.dart';
import '../widgets/expense_chart.dart';
import '../widgets/expense_list.dart';
import '../widgets/ai_recommendations.dart';
import '../widgets/expense_calendar.dart';
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
  final String userName = "María García";
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
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
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
      {'message': '🍕 Pizza Hut tiene 2x1 en pizzas medianas hoy', 'category': 'comida'},
      {'message': '🛒 Mi Comisariato: 30% descuento en lácteos', 'category': 'compras'},
      {'message': '🚌 Descuento en tarjeta de transporte público', 'category': 'transporte'},
      {'message': '🍔 KFC: Combo familiar a \$12.99', 'category': 'comida'},
      {'message': '🏪 Tía: Ofertas en productos de limpieza', 'category': 'hogar'},
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
                child: const Text(
                  '¡Bienvenido a AhorraMax!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
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
      userExpenses.add(expense);
      monthlyExpenses += expense.amount;
      balance -= expense.amount;

      if (expense.amountSaved != null && expense.amountSaved! > 0) {
        savings += expense.amountSaved!;
        totalSavingsFromAI += expense.amountSaved!;
      }
    });

    _playSound("remove");
  }

  void _handleAddIncome(dynamic income) {
    setState(() {
      incomes.add(income);
      balance += income.amount;
    });
    _playSound("add");
  }

  void _handleDeleteExpense(int index) {
    final expense = userExpenses[index];
    setState(() {
      monthlyExpenses -= expense.amount;
      balance += expense.amount;
      userExpenses.removeAt(index);
    });
    _playSound("remove");
  }

  void _handleResetExpenses() {
    setState(() {
      balance = 0;
      monthlyExpenses = 0;
      savings = 0;
      totalSavingsFromAI = 0;
      userExpenses.clear();
      incomes.clear();
      showResetConfirm = false;
    });
  }

  void _handleAddMoney() {
    if (addMoneyAmount.isNotEmpty && double.tryParse(addMoneyAmount) != null) {
      final amount = double.parse(addMoneyAmount);
      setState(() {
        balance += amount;
        showAddMoney = false;
        addMoneyAmount = "";
      });
      _playSound("add");
    }
  }

  void _handleAcceptSavings(double savingsAmount) {
    setState(() {
      totalSavingsFromAI += savingsAmount;
      savings += savingsAmount;
    });
    _playSound("success");
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
                              child: const Text(
                                'AhorraMax',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
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
                                  icon: const Icon(Icons.notifications),
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
                      Text(
                        'Hola, $userName',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Aquí está tu resumen financiero de hoy',
                        style: TextStyle(color: Colors.grey),
                      ),
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
                                      'Has ahorrado \$${totalSavingsFromAI.toStringAsFixed(2)} con recomendaciones de IA ✨',
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
                      ExpenseCalendar(expenses: userExpenses),
                      const SizedBox(height: 16),
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

          // Notifications Panel
          if (showNotifications)
            Positioned(
              top: 80,
              right: 16,
              child: Container(
                width: 300,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ofertas Cerca de Ti',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (notifications.isEmpty)
                      const Text('No hay notificaciones nuevas')
                    else
                      Column(
                        children: notifications.map((notification) => ListTile(
                          title: Text(notification['message']!),
                          subtitle: const Text('Toca para más detalles en el chat IA'),
                          onTap: () => _handleNotificationClick(notification),
                        )).toList(),
                      ),
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
          '💡 \$${(100 - balance).toStringAsFixed(2)} más y tendrás \$100 - perfecto para una comida especial',
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
          '🎯 Con tu balance puedes comprar una cena para dos en un buen restaurante',
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
          '⭐ \$${(400 - balance).toStringAsFixed(2)} más y tendrás \$400 - suficiente para un electrodoméstico útil',
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
          '💎 ¡Excelente! Con \$${_formatLargeNumber(balance)} puedes comprar electrodomésticos premium, muebles o invertir',
        ),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'comida':
        return Icons.restaurant;
      case 'transporte':
        return Icons.directions_car;
      case 'compras':
        return Icons.shopping_bag;
      case 'salud':
        return Icons.favorite;
      case 'entretenimiento':
        return Icons.tv;
      case 'educacion':
        return Icons.school;
      case 'servicios':
        return Icons.build;
      case 'hogar':
        return Icons.home;
      default:
        return Icons.category;
    }
  }
}