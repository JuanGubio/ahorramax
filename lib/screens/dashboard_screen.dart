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
import '../widgets/streak_tracker.dart';
import '../widgets/money_mascot.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/financial_goals.dart';
import '../widgets/weekly_insights.dart';
import '../widgets/financial_chatbot.dart';
import '../widgets/custom_nav_bar.dart';
import 'wallet_screen.dart';
import '../models.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? toggleTheme;
  final VoidCallback? setLightTheme;

  const DashboardScreen({super.key, this.toggleTheme, this.setLightTheme});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String userName = "Usuario";
  double balance = 0;
  double savings = 0;
  double monthlyExpenses = 0;
  final List<Expense> userExpenses = [];
  final List<Income> incomes = [];
  bool showResetConfirm = false;
  bool showAddMoney = false;
  String addMoneyAmount = "";
  bool isDarkMode = false;
  bool showNavBar = false;
  bool showTutorial = false;
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
      // Si no hay archivos de audio disponibles, continuar sin sonido
      // No mostrar error al usuario, solo continuar silenciosamente
      print("Audio no disponible: $type - continuando sin sonido");
    }
  }


  void _handleTutorialComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', true);
    setState(() => showTutorial = false);

    // Set theme to light after tutorial
    widget.setLightTheme?.call();

    // Show welcome splash after tutorial
    _showWelcomeSplash();
  }

  void _showWelcomeSplash() {
    // Don't reuse tutorial state - just show welcome splash without tutorial
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.attach_money,
                              color: Colors.white,
                              size: 20,
                            );
                          },
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
                  // Don't set showTutorial = false since we're not using tutorial state
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
      }
    });

    _playSound("remove");

    // Forzar recarga de datos para asegurar persistencia
    _cargarDatosUsuario();
  }

  void _handleAddIncome(Income income) {
    setState(() {
      incomes.insert(0, income); // Agregar al inicio para mostrar los más recientes
      balance += income.amount;
    });
    _playSound("add");

    // Nota: Los datos ya fueron guardados en Firebase por el formulario,
    // no necesitamos recargar ya que causaría una condición de carrera
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

  Future<void> _handleDeleteIncome(int index) async {
    final income = incomes[index];

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Buscar el documento del ingreso en Firebase para eliminarlo
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

        // Actualizar balance del usuario
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
        incomes.removeAt(index);
      });

      _playSound("remove");
    } catch (e) {
      print("Error al eliminar ingreso: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al eliminar ingreso: $e"),
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





  void _openFinancialChatbot() {
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
  }



  bool _hasActivityToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if there are any expenses today
    final hasExpensesToday = userExpenses.any((expense) {
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      return expenseDate == today;
    });

    // Check if there are any incomes today
    final hasIncomesToday = incomes.any((income) {
      final incomeDate = DateTime(income.date.year, income.date.month, income.date.day);
      return incomeDate == today;
    });

    return hasExpensesToday || hasIncomesToday;
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
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2ECC71), Color(0xFF4FA3FF)],
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Cargando tus datos...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
              ),
              const SizedBox(height: 16),
              Text(
                'Preparando tu experiencia financiera',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openFinancialChatbot,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.smart_toy),
        tooltip: 'Asistente Financiero IA',
      ),
      bottomNavigationBar: showTutorial ? null : CustomNavBar(
        onHomeTap: () {
          // Scroll to top or stay on dashboard
        },
        onAddTap: () => setState(() => showAddMoney = true),
        onWalletTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WalletScreen(
            balance: balance,
            monthlyExpenses: monthlyExpenses,
            savings: savings,
            incomes: incomes,
            expenses: userExpenses,
          )),
        ),
      ),
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
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
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
                                    onPressed: () => _openFinancialChatbot(),
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

                      // Resumen del día
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

                      // Calendario después del resumen financiero
                      ExpenseCalendar(expenses: userExpenses),

                      const SizedBox(height: 24),

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
                                    '\$${incomes.fold<double>(0, (sum, income) => sum + income.amount).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Total recibido',
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
                                    'Haz clic para ver detalles',
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
                      StreakTracker(hasActivityToday: _hasActivityToday()),
                      const SizedBox(height: 16),
                      const FinancialGoalsWidget(),
                      const SizedBox(height: 16),
                      WeeklyInsights(expenses: userExpenses, incomes: incomes),
                      const SizedBox(height: 16),

                      // Transaction History Tabs
                      DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
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
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color,
                                tabs: const [
                                  Tab(
                                    icon: Icon(Icons.trending_down),
                                    text: 'Gastos',
                                  ),
                                  Tab(
                                    icon: Icon(Icons.trending_up),
                                    text: 'Ingresos',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 400, // Fixed height for tab content
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
                                        FinancialOverviewChart(
                                          expenses: userExpenses,
                                          incomes: incomes,
                                        ),
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ],
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


        ],
      ),
    );
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