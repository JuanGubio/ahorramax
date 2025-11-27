import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/streak_models.dart';
import '../../services/streak_service.dart';

class EnhancedStreakTracker extends StatefulWidget {
  const EnhancedStreakTracker({Key? key}) : super(key: key);

  @override
  State<EnhancedStreakTracker> createState() => _EnhancedStreakTrackerState();
}

class _EnhancedStreakTrackerState extends State<EnhancedStreakTracker> 
    with TickerProviderStateMixin {
  
  late final StreakService _streakService;
  late final AnimationController _animationController;
  late final AnimationController _pulseController;
  
  StreamSubscription? _streakSubscription;
  StreamSubscription? _statsSubscription;
  
  Map<String, UserStreak> _streaks = {};
  UserStats? _userStats;
  bool _isLoading = true;
  int _selectedStreakIndex = 0;
  
  // Lista de tipos de rachas para mostrar
  final List<StreakType> _displayStreakTypes = [
    StreakType.dailySavings,
    StreakType.expenseTracking,
    StreakType.noImpulseSpending,
    StreakType.cookingAtHome,
    StreakType.publicTransport,
    StreakType.discountFinder,
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _streakService = StreakService();
    await _streakService.initialize();
    
    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Suscribirse a actualizaciones
    _streakSubscription = _streakService.streakUpdates.listen((streaks) {
      if (mounted) {
        setState(() {
          _streaks = streaks;
          _isLoading = false;
        });
      }
    });

    _statsSubscription = _streakService.userStatsUpdates.listen((stats) {
      if (mounted) {
        setState(() {
          _userStats = stats;
        });
      }
    });

    // Iniciar animaciones
    _animationController.forward();
    _pulseController.repeat();
  }

  @override
  void dispose() {
    _streakSubscription?.cancel();
    _statsSubscription?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    _streakService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStreakSelector(),
          const SizedBox(height: 16),
          _buildCurrentStreakCard(),
          const SizedBox(height: 16),
          _buildAchievementsSection(),
          const SizedBox(height: 16),
          _buildStatsOverview(),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 300,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando tus rachas...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + (_pulseController.value * 0.1),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistema de Rachas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mantén tus hábitos financieros',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_userStats != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '${_userStats!.totalPoints}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Puntos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStreakSelector() {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _displayStreakTypes.length,
        itemBuilder: (context, index) {
          final type = _displayStreakTypes[index];
          final streak = _streaks[type.toString()];
          final isSelected = index == _selectedStreakIndex;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedStreakIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF6366F1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF6366F1)
                      : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getStreakIcon(type),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${streak?.currentStreak ?? 0}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStreakCard() {
    final type = _displayStreakTypes[_selectedStreakIndex];
    final streak = _streaks[type.toString()];
    
    if (streak == null) {
      return _buildEmptyStreakCard(type);
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _animationController.value * 0.05 + 0.95,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getStreakColors(type),
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getStreakColors(type)[0].withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getStreakIcon(type),
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStreakTitle(type),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStreakDescription(type),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Racha Actual',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${streak.currentStreak}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mejor Racha',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${streak.longestStreak}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProgressBar(streak),
                const SizedBox(height: 16),
                _buildStreakActions(type, streak),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStreakCard(StreakType type) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            _getStreakIcon(type),
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            '¡Comienza tu racha!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStreakDescription(type),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _startNewStreak(type),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Empezar Racha'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(UserStreak streak) {
    final progress = streak.currentStreak / streak.nextMilestone;
    final progressPercentage = (progress * 100).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso al próximo hito',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${streak.currentStreak}/${streak.nextMilestone}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${progressPercentage.toInt()}% completado',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakActions(StreakType type, UserStreak streak) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _recordActivity(type),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Registrar Actividad'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => _breakStreak(type),
            icon: const Icon(Icons.cancel, color: Colors.white),
            tooltip: 'Romper Racha',
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    final unlockedAchievements = _streakService.getUnlockedAchievements();
    final totalAchievements = _streakService.getAvailableAchievements().length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFB800),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Logros Desbloqueados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$unlockedAchievements.length/$totalAchievements',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (unlockedAchievements.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No tienes logros desbloqueados aún',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: unlockedAchievements.take(6).map((achievement) {
                return Container(
                  width: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFB800).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        achievement.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.title,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    if (_userStats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Progreso',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Puntos',
                  '${_userStats!.totalPoints}',
                  Icons.stars,
                  const Color(0xFFFFB800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Logros',
                  '${_userStats!.totalAchievements}',
                  Icons.emoji_events,
                  const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Ahorros Totales',
                  '\$${_userStats!.totalSavingsTracked.toStringAsFixed(0)}',
                  Icons.savings,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Gastos Registrados',
                  '${_userStats!.expensesLogged}',
                  Icons.receipt_long,
                  const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares

  String _getStreakIcon(StreakType type) {
    switch (type) {
      case StreakType.dailySavings:
        return '💰';
      case StreakType.expenseTracking:
        return '📊';
      case StreakType.noImpulseSpending:
        return '🤔';
      case StreakType.cookingAtHome:
        return '👨‍🍳';
      case StreakType.publicTransport:
        return '🚌';
      case StreakType.discountFinder:
        return '🎯';
      case StreakType.goalCompletion:
        return '🎯';
      case StreakType.budgetPlanning:
        return '📅';
    }
  }

  String _getStreakTitle(StreakType type) {
    switch (type) {
      case StreakType.dailySavings:
        return 'Ahorro Diario';
      case StreakType.expenseTracking:
        return 'Registro de Gastos';
      case StreakType.noImpulseSpending:
        return 'Sin Gastos Impulsivos';
      case StreakType.cookingAtHome:
        return 'Cocinar en Casa';
      case StreakType.publicTransport:
        return 'Transporte Público';
      case StreakType.discountFinder:
        return 'Cazador de Descuentos';
      case StreakType.goalCompletion:
        return 'Completar Metas';
      case StreakType.budgetPlanning:
        return 'Planificación de Presupuesto';
    }
  }

  String _getStreakDescription(StreakType type) {
    switch (type) {
      case StreakType.dailySavings:
        return 'Ahorra dinero todos los días';
      case StreakType.expenseTracking:
        return 'Registra tus gastos diariamente';
      case StreakType.noImpulseSpending:
        return 'Evita compras impulsivas';
      case StreakType.cookingAtHome:
        return 'Cocina en casa en lugar de comer fuera';
      case StreakType.publicTransport:
        return 'Usa transporte público para ahorrar';
      case StreakType.discountFinder:
        return 'Encuentra y aprovecha descuentos';
      case StreakType.goalCompletion:
        return 'Alcanza tus metas financieras';
      case StreakType.budgetPlanning:
        return 'Planifica tu presupuesto';
    }
  }

  List<Color> _getStreakColors(StreakType type) {
    switch (type) {
      case StreakType.dailySavings:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case StreakType.expenseTracking:
        return [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
      case StreakType.noImpulseSpending:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case StreakType.cookingAtHome:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case StreakType.publicTransport:
        return [const Color(0xFF06B6D4), const Color(0xFF0891B2)];
      case StreakType.discountFinder:
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      case StreakType.goalCompletion:
        return [const Color(0xFFFFB800), const Color(0xFFA16207)];
      case StreakType.budgetPlanning:
        return [const Color(0xFFEC4899), const Color(0xFFBE185D)];
    }
  }

  // Métodos de acción

  Future<void> _startNewStreak(StreakType type) async {
    // Inicializar una nueva racha registrando la primera actividad
    await _recordActivity(type);
  }

  Future<void> _recordActivity(StreakType type) async {
    // Aquí puedes agregar lógica específica según el tipo de racha
    bool success = false;
    
    switch (type) {
      case StreakType.dailySavings:
        // Mostrar diálogo para ingresar monto de ahorro
        final amount = await _showAmountDialog('Monto ahorrado');
        if (amount != null && amount > 0) {
          success = await _streakService.recordDailySavings(amount);
        }
        break;
      case StreakType.expenseTracking:
        // Mostrar diálogo para registrar gasto
        final result = await _showExpenseDialog();
        if (result != null) {
          success = await _streakService.recordExpense(result['amount'], result['description']);
        }
        break;
      case StreakType.noImpulseSpending:
        success = await _streakService.recordNoImpulseDay();
        break;
      case StreakType.cookingAtHome:
        success = await _streakService.recordHomeCooking('Cociné en casa');
        break;
      case StreakType.publicTransport:
        success = await _streakService.recordPublicTransport('Usé transporte público');
        break;
      case StreakType.discountFinder:
        final savings = await _showAmountDialog('Ahorro encontrado');
        if (savings != null && savings > 0) {
          success = await _streakService.recordDiscountFound(savings);
        }
        break;
      default:
        success = await _streakService.recordActivity(type);
    }

    if (success) {
      // Mostrar notificación de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Actividad registrada para ${_getStreakTitle(type)}!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _breakStreak(StreakType type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Romper Racha'),
        content: Text('¿Estás seguro de que quieres romper tu racha de "${_getStreakTitle(type)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Romper', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _streakService.breakStreak(type);
      
      // Mostrar notificación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Racha rota'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<double?> _showAmountDialog(String title) async {
    final controller = TextEditingController();
    
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Ingresa el monto',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              Navigator.of(context).pop(amount);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    return result;
  }

  Future<Map<String, dynamic>?> _showExpenseDialog() async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Monto del gasto',
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                hintText: 'Descripción del gasto',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              final description = descriptionController.text;
              if (amount != null && amount > 0 && description.isNotEmpty) {
                Navigator.of(context).pop({
                  'amount': amount,
                  'description': description,
                });
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    return result;
  }
}