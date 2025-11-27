import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/add_expense_form.dart';
import '../widgets/add_income_form.dart';
import '../widgets/financial_overview_chart.dart';
import '../widgets/expense_list.dart';
import '../widgets/income_list.dart';
import '../widgets/expense_calendar.dart';
import '../widgets/financial_goals.dart';
import '../widgets/financial_chatbot.dart';
import '../widgets/advanced_statistics.dart';
import '../services/usage_limits_service.dart';
import '../services/goal_auto_assign_service.dart';
import '../services/streak_service.dart';
import '../models.dart';
import 'streak_screen.dart';

class DashboardScreenV2 extends StatefulWidget {
  final VoidCallback? toggleTheme;

  const DashboardScreenV2({super.key, this.toggleTheme});

  @override
  State<DashboardScreenV2> createState() => _DashboardScreenV2State();
}

class _DashboardScreenV2State extends State<DashboardScreenV2>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StreakService _streakService = StreakService();
  String userName = "Usuario";
  double balance = 0;
  double savings = 0;
  double monthlyExpenses = 0;
  double monthlyIncomes = 0;
  final List<Expense> userExpenses = [];
  final List<Income> incomes = [];
  bool showResetConfirm = false;
  bool showAddMoney = false;
  String addMoneyAmount = "";
  bool isDarkMode = false;
  bool showTutorial = false;
  bool? currentStep;
  double? mainSavingsGoal;
  bool isLoading = true;

  // Tab Controller - Solo 2 pestañas: Home y Historial
  late TabController _tabController;
  final int _initialTab = 0; // Home como pantalla por defecto

  // Streak data for AppBar icon
  int _currentStreak = 0;

  // Control de asignaciones automáticas
  bool _autoAssignNotificationsShown = false;
  final List<FinancialGoal> _goals = []; // Para acceder a las metas en las notificaciones

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: _initialTab);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();

    _loadTutorialStatus();
    _loadStreakData();
    _playSound("enter");
    _streakService.initialize(); // Inicializar servicio de rachas
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    _tabController.dispose();
    _streakService.dispose(); // Liberar servicio de rachas
    super.dispose();
  }

  Future<void> _loadStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentStreak = prefs.getInt('currentStreak') ?? 0;
    });
  }

  // Tutorial status is now handled in _cargarDatosUsuario() using Firestore
  Future<void> _loadTutorialStatus() async {
    // Tutorial logic moved to _cargarDatosUsuario() for better persistence
    // This method is kept for compatibility but does nothing
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Cargar datos del usuario
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();

      bool isNewUser = !userDoc.exists;
      bool hasSeenTutorial = false;

      if (userDoc.exists) {
        setState(() {
          userName = userDoc['nombre'] ?? "Usuario";
          balance = (userDoc['balanceActual'] ?? 0.0).toDouble();
          savings = (userDoc['ahorroTotal'] ?? 0.0).toDouble();
        });
        // Verificar si el usuario ya vio el tutorial
        hasSeenTutorial = userDoc['tutorialVisto'] ?? false;
      } else {
        // Si no existe el documento, crear uno con valores por defecto
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
          'nombre': FirebaseAuth.instance.currentUser?.displayName ?? "Usuario",
          'email': FirebaseAuth.instance.currentUser?.email ?? "",
          'balanceActual': 0.0,
          'ahorroTotal': 0.0,
          'fechaRegistro': DateTime.now(),
          'tutorialVisto': false, // Nuevo campo para controlar el tutorial
        });
        setState(() {
          userName = FirebaseAuth.instance.currentUser?.displayName ?? "Usuario";
          balance = 0.0;
          savings = 0.0;
        });
      }

      // Mostrar tutorial solo si es usuario nuevo O si no ha visto el tutorial
      print("🔍 Debug Tutorial - UID: $uid, isNewUser: $isNewUser, hasSeenTutorial: $hasSeenTutorial");

      if (isNewUser || !hasSeenTutorial) {
        print("📚 Mostrando tutorial para usuario: $uid");
        setState(() => showTutorial = true);
      } else {
        print("✅ Usuario $uid ya vio el tutorial, no se muestra");
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
      double currentMonthExpenses = 0;
      final now = DateTime.now();

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

        // Calcular gastos del mes actual
        if (expense.date.year == now.year && expense.date.month == now.month) {
          currentMonthExpenses += expense.amount;
        }
      }

      // Cargar ingresos
      QuerySnapshot incomesSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('ingresos')
          .orderBy('fechaCreacion', descending: true)
          .get();

      List<Income> loadedIncomes = [];
      double currentMonthIncomes = 0;

      for (var doc in incomesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Income income = Income(
          source: data['fuente'] ?? '',
          amount: data['monto'] ?? 0.0,
          description: data['descripcion'] ?? '',
          date: (data['fecha'] as Timestamp).toDate(),
        );
        loadedIncomes.add(income);

        // Calcular ingresos del mes actual
        if (income.date.year == now.year && income.date.month == now.month) {
          currentMonthIncomes += income.amount;
        }
      }

      // Cargar metas financieras
      QuerySnapshot goalsSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('metas')
          .get();

      List<FinancialGoal> loadedGoals = goalsSnapshot.docs
          .map((doc) => FinancialGoal.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      setState(() {
        userExpenses.clear();
        userExpenses.addAll(loadedExpenses);
        incomes.clear();
        incomes.addAll(loadedIncomes);
        _goals.clear();
        _goals.addAll(loadedGoals);
        monthlyExpenses = currentMonthExpenses; // Solo gastos del mes actual
        monthlyIncomes = currentMonthIncomes;   // Solo ingresos del mes actual
        isLoading = false;
      });

      print("Datos del usuario cargados correctamente - Gastos mes: \$${currentMonthExpenses.toStringAsFixed(2)}, Ingresos mes: \$${currentMonthIncomes.toStringAsFixed(2)}");

      // Procesar asignaciones automáticas después de cargar datos
      if (!isNewUser) {
        _processAutoAssignments();
      }
    } catch (e) {
      print("Error al cargar datos del usuario: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _processAutoAssignments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final assignments = await GoalAutoAssignService().processMonthlyAutoAssignment(user.uid);

      if (assignments.isNotEmpty && !_autoAssignNotificationsShown) {
        _showAutoAssignmentNotifications(assignments);
        _autoAssignNotificationsShown = true;

        // Recargar datos para mostrar los cambios
        await _cargarDatosUsuario();
      }
    } catch (e) {
      print('Error processing auto assignments: $e');
    }
  }

  void _showAutoAssignmentNotifications(Map<String, double> assignments) {
    final totalAssigned = assignments.values.fold<double>(0, (sum, amount) => sum + amount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.green),
            const SizedBox(width: 8),
            const Text('¡Asignaciones Automáticas!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se han asignado automáticamente \$${totalAssigned.toStringAsFixed(2)} a tus metas activas:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ...assignments.entries.map((entry) {
              final goal = _goals.firstWhere(
                (g) => g.id == entry.key,
                orElse: () => FinancialGoal(
                  id: entry.key,
                  title: 'Meta',
                  description: '',
                  targetAmount: 0,
                  currentAmount: 0,
                  type: GoalType.savings,
                  period: GoalPeriod.monthly,
                  createdDate: DateTime.now(),
                ),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '\$${entry.value.toStringAsFixed(2)} → ${goal.title}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Text(
                '¡Tus metas se están cumpliendo automáticamente! Sigue ahorrando y verás el progreso.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('¡Genial!'),
          ),
        ],
      ),
    );
  }

  // Tutorial ahora se maneja completamente en _cargarDatosUsuario() y _handleTutorialComplete()
  // usando Firestore para persistir el estado por usuario

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
      print("Audio no disponible: $type - continuando sin sonido");
    }
  }


  void _showWelcomeSplash() {
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

  Future<void> _handleAddExpense(Map<String, dynamic> expenseData) async {
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
      userExpenses.insert(0, expense);
      balance -= expense.amount;

      if (expense.amountSaved != null && expense.amountSaved! > 0) {
        savings += expense.amountSaved!;
      }

      // Recalcular gastos del mes actual
      final now = DateTime.now();
      monthlyExpenses = userExpenses
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .fold<double>(0, (sum, e) => sum + e.amount);
    });

    _playSound("remove");

    // Registrar actividad en el sistema de rachas
    await _streakService.recordExpense(expense.amount, expense.description);

    _cargarDatosUsuario();
  }

  Future<void> _handleAddIncome(Income income) async {
    setState(() {
      incomes.insert(0, income);
      balance += income.amount;

      // Recalcular ingresos del mes actual
      final now = DateTime.now();
      monthlyIncomes = incomes
          .where((i) => i.date.year == now.year && i.date.month == now.month)
          .fold<double>(0, (sum, i) => sum + i.amount);
    });
    _playSound("add");

    // Registrar actividad en el sistema de rachas para ahorros diarios
    await _streakService.recordDailySavings(income.amount);
  }

  Future<void> _handleDeleteExpense(Expense expense) async {

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

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
        balance += expense.amount;
        if (expense.amountSaved != null && expense.amountSaved! > 0) {
          savings -= expense.amountSaved!;
        }
        userExpenses.removeWhere((e) =>
          e.category == expense.category &&
          e.amount == expense.amount &&
          e.description == expense.description &&
          e.date == expense.date
        );

        // Recalcular gastos del mes actual
        final now = DateTime.now();
        monthlyExpenses = userExpenses
            .where((e) => e.date.year == now.year && e.date.month == now.month)
            .fold<double>(0, (sum, e) => sum + e.amount);
      });

      _playSound("remove");
    } catch (e) {
      print("Error al eliminar gasto: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al eliminar gasto: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteIncome(Income income) async {

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      QuerySnapshot incomesSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('ingresos')
          .where('fuente', isEqualTo: income.source)
          .where('monto', isEqualTo: income.amount)
          .where('descripcion', isEqualTo: income.description)
          .where('fecha', isEqualTo: Timestamp.fromDate(income.date))
          .get();

      if (incomesSnapshot.docs.isNotEmpty) {
        await incomesSnapshot.docs.first.reference.delete();

        DocumentReference userDoc = FirebaseFirestore.instance.collection('usuarios').doc(uid);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(userDoc);
          if (snapshot.exists) {
            double currentBalance = snapshot['balanceActual'] ?? 0.0;

            transaction.update(userDoc, {
              'balanceActual': currentBalance - income.amount,
            });
          }
        });
      }

      setState(() {
        balance -= income.amount;
        incomes.removeWhere((i) =>
          i.source == income.source &&
          i.amount == income.amount &&
          i.description == income.description &&
          i.date == income.date
        );

        // Recalcular ingresos del mes actual
        final now = DateTime.now();
        monthlyIncomes = incomes
            .where((i) => i.date.year == now.year && i.date.month == now.month)
            .fold<double>(0, (sum, i) => sum + i.amount);
      });

      _playSound("remove");
    } catch (e) {
      print("Error al eliminar ingreso: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al eliminar ingreso: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAddMoney() async {
    if (addMoneyAmount.isNotEmpty && double.tryParse(addMoneyAmount) != null) {
      final amount = double.parse(addMoneyAmount);

      try {
        String uid = FirebaseAuth.instance.currentUser!.uid;

        DocumentReference userDoc = FirebaseFirestore.instance.collection('usuarios').doc(uid);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(userDoc);
          if (snapshot.exists) {
            double currentBalance = (snapshot['balanceActual'] ?? 0.0).toDouble();
            transaction.update(userDoc, {
              'balanceActual': currentBalance + amount,
            });
          } else {
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
        _cargarDatosUsuario();
      } catch (e) {
        print("Error al agregar dinero: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al agregar dinero: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _openFinancialChatbot() {
    UsageLimitsService.showChatWarningDialog(context, () {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: FinancialChatbot(
            expenses: userExpenses,
            incomes: incomes,
            balance: balance,
            savings: savings,
          ),
        ),
      );
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

  String _getMotivationalMessage() {
    final messages = [
      '¡Cada paso cuenta en tu viaje financiero!',
      'La consistencia es la clave del éxito financiero.',
      '¡Estás construyendo hábitos que durarán toda la vida!',
      'Cada decisión financiera te acerca a tus metas.',
      '¡Tu futuro yo te agradecerá por estos esfuerzos!',
      'El ahorro inteligente es libertad financiera.',
      '¡Sigue adelante, estás en el camino correcto!',
      'La disciplina financiera trae tranquilidad.',
      'Cada día es una oportunidad para mejorar.',
      '¡Tu compromiso con tus finanzas es admirable!',
    ];

    // Usar el día del mes para seleccionar un mensaje consistente
    final dayOfMonth = DateTime.now().day;
    return messages[dayOfMonth % messages.length];
  }

  // Builds Home Tab (Dashboard)
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. MENSAJE DE BIENVENIDA PERSONALIZADO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.waving_hand,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, $userName! 👋',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const Text(
                            'Bienvenido de vuelta a tu viaje financiero',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: Color(0xFFFFA726),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getMotivationalMessage(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. FORMULARIOS DE AGREGAR GASTOS E INGRESOS DIRECTAMENTE EN DASHBOARD
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

          // 3. CALENDARIO DE ACTIVIDADES
          ExpenseCalendar(expenses: userExpenses),

          const SizedBox(height: 24),

          // 4. ESTADÍSTICAS GENERALES
          // Balance Cards
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
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

              // Income Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.teal, Colors.greenAccent],
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
                            child: const Icon(Icons.trending_up, color: Colors.white),
                          ),
                          const Icon(Icons.arrow_upward, color: Colors.white70),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ingresos del Mes',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '\$${monthlyIncomes.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Este mes',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
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
                        'Este mes',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
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
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Resumen del día (movido al final)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Resumen del día:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Gastos: -\$${userExpenses.where((expense) {
                            final now = DateTime.now();
                            return expense.date.year == now.year &&
                                   expense.date.month == now.month &&
                                   expense.date.day == now.day;
                          }).fold<double>(0, (sum, expense) => sum + expense.amount).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          'Ingresos: +\$${incomes.where((income) {
                            final now = DateTime.now();
                            return income.date.year == now.year &&
                                   income.date.month == now.month &&
                                   income.date.day == now.day;
                          }).fold<double>(0, (sum, income) => sum + income.amount).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Balance del día: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final now = DateTime.now();
                          final dayExpenses = userExpenses.where((expense) =>
                            expense.date.year == now.year &&
                            expense.date.month == now.month &&
                            expense.date.day == now.day
                          ).fold<double>(0, (sum, expense) => sum + expense.amount);

                          final dayIncomes = incomes.where((income) =>
                            income.date.year == now.year &&
                            income.date.month == now.month &&
                            income.date.day == now.day
                          ).fold<double>(0, (sum, income) => sum + income.amount);

                          final dayBalance = dayIncomes - dayExpenses;
                          final isPositive = dayBalance >= 0;

                          return Text(
                            '${isPositive ? '+' : ''}\$${dayBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Financial Goals (movido al final)
          const FinancialGoalsWidget(),
        ],
      ),
    );
  }

  // Builds History Tab
  Widget _buildHistoryTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Tab Header
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: const Color(0xFF2ECC71),
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(
                  icon: Icon(Icons.trending_down),
                  text: 'Gastos',
                ),
                Tab(
                  icon: Icon(Icons.trending_up),
                  text: 'Ingresos',
                ),
                Tab(
                  icon: Icon(Icons.analytics),
                  text: 'Estadísticas',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: TabBarView(
              children: [
                // Expenses Tab
                SingleChildScrollView(
                  child: Column(
                    children: [
                      ExpenseList(
                        expenses: userExpenses,
                        onDeleteExpense: _handleDeleteExpense,
                      ),
                      const SizedBox(height: 16),
                      if (userExpenses.isNotEmpty) ...[
                        FinancialOverviewChart(
                          expenses: userExpenses,
                          incomes: incomes,
                        ),
                      ],
                    ],
                  ),
                ),

                // Incomes Tab
                SingleChildScrollView(
                  child: IncomeList(
                    incomes: incomes,
                    onDeleteIncome: _handleDeleteIncome,
                  ),
                ),

                // Statistics Tab
                SingleChildScrollView(
                  child: AdvancedStatisticsWidget(
                    expenses: userExpenses,
                    incomes: incomes,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.attach_money),
            const SizedBox(width: 8),
            const Text('AhorraMax'),
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'G',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Fire icon with streak counter
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StreakScreen()),
                  );
                },
                icon: const Icon(Icons.local_fire_department, color: Colors.orange),
                tooltip: 'Mis Rachas',
              ),
              if (_currentStreak > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _currentStreak.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: widget.toggleTheme,
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColorLight,
              child: Text('MG', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.home),
              text: 'Inicio',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Historial',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),     // Inicio primera
          _buildHistoryTab(),  // Historial segunda
        ],
      ),
      
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _openFinancialChatbot,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.smart_toy),
        tooltip: 'Asistente Financiero IA',
      ),

      // Dialogs and overlays
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,

      // Add Money Dialog
      bottomSheet: showAddMoney ? null : null,
    );
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
        monthlyIncomes = 0;
        savings = 0;
        userExpenses.clear();
        incomes.clear();
      });

      print("Todos los datos han sido reseteados");
    } catch (e) {
      print("Error al resetear datos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al resetear datos: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}