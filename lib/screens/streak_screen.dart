import 'package:flutter/material.dart';
import '../services/streak_service.dart';
import '../models/streak_models.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> with TickerProviderStateMixin {
  final StreakService _streakService = StreakService();
  Map<String, UserStreak> _streaks = {};
  UserStats? _userStats;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeStreaks();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _streakService.dispose();
    super.dispose();
  }

  Future<void> _initializeStreaks() async {
    await _streakService.initialize();
    _loadStreakData();

    // Escuchar actualizaciones en tiempo real
    _streakService.streakUpdates.listen((streaks) {
      setState(() {
        _streaks = streaks;
      });
    });

    _streakService.userStatsUpdates.listen((stats) {
      setState(() {
        _userStats = stats;
      });
    });
  }

  void _loadStreakData() {
    setState(() {
      _streaks = _streakService.getAllStreaks();
      _userStats = _streakService.getUserStats();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Mis Rachas'),
            ],
          ),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando tus rachas...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Mis Rachas'),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estadísticas principales
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade400,
                    Colors.red.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade200.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _streaks.isNotEmpty ? _scaleAnimation.value : 1.0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.local_fire_department,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userStats?.totalAchievements.toString() ?? '0',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Logros desbloqueados',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _streaks.isNotEmpty ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _streaks.isNotEmpty ? Icons.check_circle : Icons.schedule,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _streaks.isNotEmpty ? '¡Tienes ${_streaks.length} rachas activas!' : 'No hay rachas activas',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Lista de rachas activas
            const Text(
              '🔥 Tus Rachas Activas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_streaks.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'No tienes rachas activas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Comienza registrando gastos e ingresos para activar tus rachas financieras',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._streaks.values.map((streak) => _buildStreakCard(streak)),

            const SizedBox(height: 24),

            // Información sobre cómo mantener la racha
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Cómo mantener tu racha',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTipItem(
                    Icons.add_circle,
                    'Registra gastos o ingresos diariamente',
                    'Cada transacción cuenta para mantener tu racha activa',
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem(
                    Icons.calendar_today,
                    'No pierdas días consecutivos',
                    'Si pierdes un día, tu racha se reinicia desde cero',
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem(
                    Icons.trending_up,
                    'Mantén el hábito',
                    'Las rachas largas demuestran disciplina financiera',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Motivación
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade400,
                    Colors.pink.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getMotivationalMessage(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(UserStreak streak) {
    final color = _getStreakColor(streak.type);
    final progress = streak.currentStreak / (streak.nextMilestone > 0 ? streak.nextMilestone : 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getStreakIcon(streak.type), color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streak.type.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'Racha actual: ${streak.currentStreak} días',
                      style: TextStyle(
                        fontSize: 14,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: streak.isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  streak.isActive ? 'Activa' : 'Inactiva',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: streak.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 8),
          Text(
            'Próximo hito: ${streak.nextMilestone} días (${streak.daysToNextMilestone} restantes)',
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
          if (streak.lastActivityDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Última actividad: ${_formatDate(streak.lastActivityDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildTipItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade700,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStreakColor(StreakType type) {
    switch (type) {
      case StreakType.dailySavings:
        return Colors.green;
      case StreakType.expenseTracking:
        return Colors.blue;
      case StreakType.noImpulseSpending:
        return Colors.purple;
      case StreakType.cookingAtHome:
        return Colors.orange;
      case StreakType.publicTransport:
        return Colors.teal;
      case StreakType.discountFinder:
        return Colors.red;
      case StreakType.goalCompletion:
        return Colors.indigo;
      case StreakType.budgetPlanning:
        return Colors.amber;
    }
  }

  IconData _getStreakIcon(StreakType type) {
    switch (type) {
      case StreakType.dailySavings:
        return Icons.savings;
      case StreakType.expenseTracking:
        return Icons.receipt;
      case StreakType.noImpulseSpending:
        return Icons.block;
      case StreakType.cookingAtHome:
        return Icons.restaurant;
      case StreakType.publicTransport:
        return Icons.directions_bus;
      case StreakType.discountFinder:
        return Icons.local_offer;
      case StreakType.goalCompletion:
        return Icons.flag;
      case StreakType.budgetPlanning:
        return Icons.account_balance_wallet;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getMotivationalMessage() {
    final totalStreaks = _streaks.length;
    final activeStreaks = _streaks.values.where((s) => s.isActive).length;

    if (totalStreaks == 0) {
      return '¡Comienza hoy tus rachas financieras!\nRegistra gastos e ingresos para activarlas.';
    } else if (activeStreaks == 0) {
      return '¡Tus rachas están esperando!\nRegistra actividad para reactivarlas.';
    } else if (activeStreaks < totalStreaks) {
      return '¡Vas por buen camino!\nTienes $activeStreaks rachas activas de $totalStreaks.';
    } else {
      return '¡Impresionante!\nTodas tus rachas están activas. ¡Sigue así!';
    }
  }
}