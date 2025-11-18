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
import '../widgets/success_notification.dart';
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
                    fit: BoxFit.contain,
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

    // Mostrar notificación de éxito
    SuccessNotification.show(
      context,
      message: 'Gasto agregado exitosamente',
      amount: expense.amount.toStringAsFixed(2),
      isIncome: false,
    );

    // Forzar recarga de datos para asegurar persistencia
    _cargarDatosUsuario();
  }

  void _handleAddIncome(Income income) {
    setState(() {
      incomes.insert(0, income); // Agregar al inicio para mostrar los más recientes
      balance += income.amount;
    });
    _playSound("add");

    // Mostrar notificación de éxito
    SuccessNotification.show(
      context,
      message: 'Ingreso agregado exitosamente',
      amount: income.amount.toStringAsFixed(2),
      isIncome: true,
    );

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

      // Mostrar notificación de éxito
      SuccessNotification.show(
        context,
        message: 'Gasto eliminado exitosamente',
        amount: expense.amount.toStringAsFixed(2),
        isIncome: false,
      );
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

      // Mostrar notificación de éxito
      SuccessNotification.show(
        context,
        message: 'Ingreso eliminado exitosamente',
        amount: income.amount.toStringAsFixed(2),
        isIncome: false,
      );
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

      // Mostrar notificación de éxito
      SuccessNotification.show(
        context,
        message: 'Datos reseteados exitosamente',
        amount: '0.00',
        isIncome: false,
      );
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

        // Mostrar notificación de éxito
        SuccessNotification.show(
          context,
          message: 'Dinero agregado exitosamente',
          amount: amount.toStringAsFixed(2),
          isIncome: true,
        );

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

  Widget _buildBalanceCard({
    required String title,
    required String amount,
    required IconData icon,
    required List<Color> gradient,
    bool showButtons = false,
    bool showArrow = false,
    IconData arrowIcon = Icons.arrow_upward,
    String? subtitle,
    required bool isVerySmallScreen,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 120), // Minimum height to prevent collapse
        padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  child: Icon(icon, color: Colors.white, size: isVerySmallScreen ? 16 : 20),
                ),
                if (showButtons) ...[
                  IconButton(
                    onPressed: () => setState(() => showAddMoney = true),
                    icon: const Icon(Icons.add, color: Colors.white),
                    iconSize: 18,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => showResetConfirm = true),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    iconSize: 18,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ] else if (showArrow) ...[
                  Icon(arrowIcon, color: Colors.white70, size: isVerySmallScreen ? 16 : 20),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isVerySmallScreen ? 11 : 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '\$$amount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isVerySmallScreen ? 18 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (subtitle != null && !isVerySmallScreen) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final isVerySmallScreen = screenWidth < 360;

                            return Row(
                              children: [
                                Container(
                                  width: isVerySmallScreen ? 32 : 40,
                                  height: isVerySmallScreen ? 32 : 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2ECC71), Color(0xFF4FA3FF)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(Icons.attach_money, color: Colors.white, size: isVerySmallScreen ? 16 : 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFF2ECC71), Color(0xFF4FA3FF)],
                                    ).createShader(bounds),
                                    child: Text(
                                      'AhorraMax',
                                      style: TextStyle(
                                        fontSize: isVerySmallScreen ? 16 : 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if (!isVerySmallScreen) ...[
                                  IconButton(
                                    onPressed: () => setState(() => showNavBar = !showNavBar),
                                    icon: const Icon(Icons.search),
                                    iconSize: 20,
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
                                    iconSize: 20,
                                  ),
                                ],
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, '/profile'),
                                  child: CircleAvatar(
                                    radius: isVerySmallScreen ? 14 : 18,
                                    backgroundColor: Theme.of(context).primaryColor,
                                    child: Text('MG', style: TextStyle(color: Colors.white, fontSize: isVerySmallScreen ? 10 : 12)),
                                  ),
                                ),
                              ],
                            );
                          },
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
                                      foregroundColor: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
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

                      // Resumen del día mejorado
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF667EEA).withOpacity(0.1),
                              const Color(0xFF764BA2).withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF667EEA).withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header con ícono
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF667EEA).withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.today,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Resumen del día',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Estadísticas en fila - Mobile Optimized
                            Builder(
                              builder: (context) {
                                final screenWidth = MediaQuery.of(context).size.width;
                                final isVerySmallScreen = screenWidth < 360;
                                final cardPadding = isVerySmallScreen ? 10.0 : 14.0;
                                final iconSize = isVerySmallScreen ? 12.0 : 14.0;
                                final titleFontSize = isVerySmallScreen ? 10.0 : 11.0;
                                final amountFontSize = isVerySmallScreen ? 14.0 : 16.0;

                                return Row(
                                  children: [
                                    // Gastos del día
                                    Expanded(
                                      child: Container(
                                        constraints: const BoxConstraints(minHeight: 70),
                                        padding: EdgeInsets.all(cardPadding),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.trending_down,
                                                  color: Colors.red[600],
                                                  size: iconSize,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'Gastos',
                                                  style: TextStyle(
                                                    fontSize: titleFontSize,
                                                    color: Colors.red[600],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: isVerySmallScreen ? 2 : 4),
                                            Builder(
                                              builder: (context) {
                                                final now = DateTime.now();
                                                final dayExpenses = userExpenses.where((expense) =>
                                                  expense.date.year == now.year &&
                                                  expense.date.month == now.month &&
                                                  expense.date.day == now.day
                                                ).fold<double>(0, (sum, expense) => sum + expense.amount);

                                                return FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    '-\$${dayExpenses.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: amountFontSize,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isVerySmallScreen ? 6 : 10),

                                    // Ingresos del día
                                    Expanded(
                                      child: Container(
                                        constraints: const BoxConstraints(minHeight: 70),
                                        padding: EdgeInsets.all(cardPadding),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.trending_up,
                                                  color: Colors.green[600],
                                                  size: iconSize,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'Ingresos',
                                                  style: TextStyle(
                                                    fontSize: titleFontSize,
                                                    color: Colors.green[600],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: isVerySmallScreen ? 2 : 4),
                                            Builder(
                                              builder: (context) {
                                                final now = DateTime.now();
                                                final dayIncomes = incomes.where((income) =>
                                                  income.date.year == now.year &&
                                                  income.date.month == now.month &&
                                                  income.date.day == now.day
                                                ).fold<double>(0, (sum, income) => sum + income.amount);

                                                return FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    '+\$${dayIncomes.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: amountFontSize,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green,
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
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // Balance del día destacado
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.grey.shade50,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF667EEA).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet,
                                      color: Color(0xFF667EEA),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Balance del día',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
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
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isPositive ? Colors.green[700] : Colors.red[700],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),


                      // Balance Cards - Mobile-First Responsive Design
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final isVerySmallScreen = screenWidth < 360;
                          final isSmallScreen = screenWidth < 400;
                          final crossAxisCount = screenWidth > 600 ? 4 : 2;

                          // Ensure minimum card height and proper spacing
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 16),
                            mainAxisSpacing: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 16),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: isVerySmallScreen ? 1.1 : (isSmallScreen ? 1.2 : 1.3),
                            children: [
                              // Balance Card
                              _buildBalanceCard(
                                title: 'Dinero Actual',
                                amount: _formatLargeNumber(balance),
                                icon: Icons.account_balance_wallet,
                                gradient: const [Colors.green, Color(0xFF2E7D32)],
                                showButtons: !isSmallScreen,
                                isVerySmallScreen: isVerySmallScreen,
                              ),

                              // Income Card
                              _buildBalanceCard(
                                title: 'Ingresos del Mes',
                                amount: incomes.fold<double>(0, (sum, income) => sum + income.amount).toStringAsFixed(2),
                                icon: Icons.trending_up,
                                gradient: const [Colors.teal, Colors.greenAccent],
                                showArrow: true,
                                subtitle: !isVerySmallScreen ? 'Total recibido' : null,
                                isVerySmallScreen: isVerySmallScreen,
                              ),

                              // Expenses Card
                              _buildBalanceCard(
                                title: 'Gastos del Mes',
                                amount: monthlyExpenses.toStringAsFixed(2),
                                icon: Icons.credit_card,
                                gradient: const [Colors.red, Colors.redAccent],
                                showArrow: true,
                                arrowIcon: Icons.trending_down,
                                subtitle: !isVerySmallScreen ? 'Haz clic para ver detalles' : null,
                                isVerySmallScreen: isVerySmallScreen,
                              ),

                              // Savings Card
                              _buildBalanceCard(
                                title: 'Ahorros Totales',
                                amount: savings.toStringAsFixed(2),
                                icon: Icons.savings,
                                gradient: const [Colors.blue, Colors.indigo],
                                showArrow: true,
                                isVerySmallScreen: isVerySmallScreen,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),


                      // Forms - Responsive Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final isSmallScreen = screenWidth < 600;

                          if (isSmallScreen) {
                            return Column(
                              children: [
                                AddExpenseForm(onAddExpense: _handleAddExpense),
                                const SizedBox(height: 16),
                                AddIncomeForm(onAddIncome: _handleAddIncome),
                              ],
                            );
                          } else {
                            return Row(
                              children: [
                                Expanded(
                                  child: AddExpenseForm(onAddExpense: _handleAddExpense),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AddIncomeForm(onAddIncome: _handleAddIncome),
                                ),
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Additional Components
                      const SizedBox(height: 24),
                      ExpenseCalendar(expenses: userExpenses),
                      const SizedBox(height: 16),
                      StreakTracker(hasActivityToday: _hasActivityToday()),
                      const SizedBox(height: 16),
                      const FinancialGoalsWidget(),
                      const SizedBox(height: 16),
                      WeeklyInsights(expenses: userExpenses, incomes: incomes),
                      const SizedBox(height: 16),

                      // Transaction History Tabs - Improved Design
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).cardColor,
                              Theme.of(context).cardColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black38
                                  : Colors.grey.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black26
                                  : Colors.white.withOpacity(0.8),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              // Header with title
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).primaryColor.withOpacity(0.1),
                                      Theme.of(context).primaryColor.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).primaryColor,
                                            Theme.of(context).primaryColor.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.receipt_long,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Historial de Transacciones',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).textTheme.titleLarge?.color,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${userExpenses.length + incomes.length} transacciones registradas',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Tab Bar
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[850]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TabBar(
                                  indicator: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).primaryColor,
                                        Theme.of(context).primaryColor.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color,
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  unselectedLabelStyle: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  tabs: [
                                    Tab(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.trending_down,
                                            size: MediaQuery.of(context).size.width < 360 ? 18 : 20,
                                          ),
                                          SizedBox(width: MediaQuery.of(context).size.width < 360 ? 4 : 8),
                                          Text(
                                            'Gastos',
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Tab(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.trending_up,
                                            size: MediaQuery.of(context).size.width < 360 ? 18 : 20,
                                          ),
                                          SizedBox(width: MediaQuery.of(context).size.width < 360 ? 4 : 8),
                                          Text(
                                            'Ingresos',
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Tab Content
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                                  minHeight: 250,
                                ),
                                child: TabBarView(
                                  children: [
                                    // Expenses Tab
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      child: userExpenses.isEmpty
                                          ? _buildEmptyState(
                                              'No hay gastos registrados',
                                              'Registra tu primer gasto para comenzar a trackear tus finanzas',
                                              Icons.receipt,
                                              Colors.red,
                                            )
                                          : SingleChildScrollView(
                                              child: Column(
                                                children: [
                                                  ExpenseList(
                                                    expenses: userExpenses,
                                                    onDeleteExpense: _handleDeleteExpense,
                                                  ),
                                                  const SizedBox(height: 20),
                                                  FinancialOverviewChart(
                                                    expenses: userExpenses,
                                                    incomes: incomes,
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),

                                    // Incomes Tab
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      child: incomes.isEmpty
                                          ? _buildEmptyState(
                                              'No hay ingresos registrados',
                                              'Registra tus ingresos para tener un mejor control financiero',
                                              Icons.trending_up,
                                              Colors.green,
                                            )
                                          : SingleChildScrollView(
                                              child: IncomeList(
                                                incomes: incomes,
                                                onDeleteIncome: _handleDeleteIncome,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
                  margin: const EdgeInsets.all(24),
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
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 15,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2ECC71).withOpacity(0.1),
                                const Color(0xFF4FA3FF).withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF2ECC71).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2ECC71), Color(0xFF4FA3FF)],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2ECC71).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFF2ECC71), Color(0xFF4FA3FF)],
                                    ).createShader(bounds),
                                    child: const Text(
                                      '💰 Agregar Dinero',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Incrementa tu balance actual',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Amount Input
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    color: Colors.green.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Monto a Agregar',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '\$',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                    hintText: '0.00',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 18,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 20,
                                    ),
                                  ),
                                  onChanged: (value) => addMoneyAmount = value,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Buttons
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  child: OutlinedButton(
                                    onPressed: () => setState(() {
                                      showAddMoney = false;
                                      addMoneyAmount = "";
                                    }),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancelar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green.shade500,
                                        Colors.teal.shade500,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.shade300.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _handleAddMoney,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      '💰 Agregar Dinero',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ],
                      ),
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

          // Money Mascot
          if (!showTutorial)
            const Positioned(
              bottom: 100,
              left: 16,
              child: MoneyMascot(),
            ),


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