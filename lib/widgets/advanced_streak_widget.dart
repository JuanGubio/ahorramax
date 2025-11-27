import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/streak_models.dart';
import '../../providers/streak_provider.dart';

/// Widget principal del sistema de rachas mejorado
/// Versión 2.0 - Interfaz moderna y funcionalidad completa
class AdvancedStreakWidget extends StatefulWidget {
  final StreakType? initialStreakType;
  final bool showQuickActions;
  final bool compactMode;

  const AdvancedStreakWidget({
    Key? key,
    this.initialStreakType,
    this.showQuickActions = true,
    this.compactMode = false,
  }) : super(key: key);

  @override
  State<AdvancedStreakWidget> createState() => _AdvancedStreakWidgetState();
}

class _AdvancedStreakWidgetState extends State<AdvancedStreakWidget>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _pulseController;
  late AnimationController _celebrationController;
  
  int _selectedStreakIndex = 0;
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAutoRefresh();
  }

  void _initializeControllers() {
    final streakCount = StreakType.values.length;
    _tabController = TabController(length: streakCount, vsync: this);
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Configurar índice inicial
    if (widget.initialStreakType != null) {
      _selectedStreakIndex = StreakType.values.indexOf(widget.initialStreakType!);
      _tabController.index = _selectedStreakIndex;
    }
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        // Actualizar datos cada 5 minutos
        context.read<StreakProvider>().initialize();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _celebrationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StreakProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized) {
          return _buildLoadingState();
        }

        if (provider.error != null) {
          return _buildErrorState(provider);
        }

        if (widget.compactMode) {
          return _buildCompactMode(provider);
        }

        return _buildFullMode(provider);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 300,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Inicializando sistema de rachas...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(StreakProvider provider) {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error: ${provider.error}',
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                provider.initialize();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMode(StreakProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(provider),
            const SizedBox(height: 16),
            _buildQuickStats(provider),
            const SizedBox(height: 16),
            if (widget.showQuickActions) _buildQuickActions(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildFullMode(StreakProvider provider) {
    return DefaultTabController(
      length: StreakType.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sistema de Rachas'),
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            isScrollable: true,
            tabs: StreakType.values.map((type) {
              final streak = provider.getStreak(type);
              return Tab(
                height: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_getStreakIcon(type), style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      '${streak?.currentStreak ?? 0}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: StreakType.values.map((type) {
            return _buildStreakTab(type, provider);
          }).toList(),
        ),
        floatingActionButton: widget.showQuickActions ? _buildQuickActionFab(provider) : null,
      ),
    );
  }

  Widget _buildHeader(StreakProvider provider) {
    final progress = provider.getOverallProgress();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 24,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nivel ${progress.levelDisplay} • ${progress.totalPoints} puntos',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.completionRate / 100,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress.activeStreaks}/${progress.totalStreaks} rachas activas',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(StreakProvider provider) {
    final progress = provider.getOverallProgress();
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Rachas Activas',
            '${progress.activeStreaks}',
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Logros',
            '${progress.totalAchievements}',
            Icons.emoji_events,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Badges',
            '${progress.totalBadges}',
            Icons.workspace_premium,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(StreakProvider provider) {
    final actions = [
      _QuickAction(
        'Registrar Ahorro',
        Icons.savings,
        Colors.green,
        () => _showRecordActivityDialog(StreakType.dailySavings, provider),
      ),
      _QuickAction(
        'Agregar Gasto',
        Icons.receipt_long,
        Colors.red,
        () => _showRecordExpenseDialog(provider),
      ),
      _QuickAction(
        'Sin Gastos Impulsivos',
        Icons.self_improvement,
        Colors.blue,
        () => provider.recordNoImpulseDay(),
      ),
      _QuickAction(
        'Cocinar en Casa',
        Icons.kitchen,
        Colors.orange,
        () => _showRecordActivityDialog(StreakType.cookingAtHome, provider),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickActionCard(action);
      },
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return Card(
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                action.color.withOpacity(0.1),
                action.color.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(action.icon, color: action.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: action.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionFab(StreakProvider provider) {
    return FloatingActionButton(
      onPressed: () => _showRecordActivityDialog(StreakType.dailySavings, provider),
      backgroundColor: const Color(0xFF6366F1),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildStreakTab(StreakType streakType, StreakProvider provider) {
    final streak = provider.getStreak(streakType);
    final statistics = provider.getStreakStatistics(streakType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (streak != null) ...[
            _buildStreakOverviewCard(streak, streakType),
            const SizedBox(height: 16),
            _buildMilestonesCard(streak),
            const SizedBox(height: 16),
            _buildPerformanceCard(statistics!),
            const SizedBox(height: 16),
          ] else ...[
            _buildEmptyStreakCard(streakType, provider),
          ],
          _buildRecentActivities(provider),
        ],
      ),
    );
  }

  Widget _buildStreakOverviewCard(UserStreak streak, StreakType streakType) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getStreakColors(streakType),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_getStreakIcon(streakType), style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStreakTitle(streakType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStreakDescription(streakType),
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
                  child: _buildStreakMetric(
                    'Racha Actual',
                    '${streak.currentStreak}',
                    'días',
                    Icons.local_fire_department,
                  ),
                ),
                Expanded(
                  child: _buildStreakMetric(
                    'Mejor Racha',
                    '${streak.longestStreak}',
                    'días',
                    Icons.emoji_events,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(streak),
            const SizedBox(height: 16),
            _buildStreakActions(streakType, streak, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakMetric(String label, String value, String unit, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white),
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: unit,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(UserStreak streak) {
    final progress = streak.progressToNextMilestone;
    final daysToNext = streak.daysToNextMilestone;

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
          '${(progress * 100).toInt()}% completado • $daysToNext días restantes',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakActions(StreakType streakType, UserStreak streak, StreakProvider provider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showRecordActivityDialog(streakType, provider),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Registrar Actividad'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
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
            onPressed: () => _showBreakStreakDialog(streakType, provider),
            icon: const Icon(Icons.cancel, color: Colors.white),
            tooltip: 'Romper Racha',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStreakCard(StreakType streakType, StreakProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_getStreakIcon(streakType), style: const TextStyle(fontSize: 48)),
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
              _getStreakDescription(streakType),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showRecordActivityDialog(streakType, provider),
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
      ),
    );
  }

  Widget _buildMilestonesCard(UserStreak streak) {
    final completedMilestones = streak.completedMilestones;
    final pendingMilestones = streak.pendingMilestones.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Hitos y Logros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (completedMilestones.isNotEmpty) ...[
              Text(
                'Completados',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(height: 8),
              ...completedMilestones.map((milestone) => _buildMilestoneItem(milestone, true)),
              const SizedBox(height: 16),
            ],
            if (pendingMilestones.isNotEmpty) ...[
              Text(
                'Próximos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(height: 8),
              ...pendingMilestones.map((milestone) => _buildMilestoneItem(milestone, false)),
            ] else if (completedMilestones.isEmpty) ...[
              const Text(
                'No hay hitos configurados',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneItem(StreakMilestone milestone, bool completed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: completed ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: completed ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(milestone.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${milestone.targetDays} días',
                  style: TextStyle(
                    fontSize: 12,
                    color: completed ? Colors.green[600] : Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? Colors.green[600] : Colors.blue[600],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(StreakStatistics statistics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Análisis de Rendimiento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    'Consistencia',
                    '${(statistics.performance.consistencyRate * 100).toInt()}%',
                    statistics.performance.consistencyRate >= 0.8 ? Colors.green : 
                    statistics.performance.consistencyRate >= 0.6 ? Colors.orange : Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildPerformanceMetric(
                    'Tendencia',
                    statistics.trendDisplay,
                    _getTrendColor(statistics.trend),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: statistics.performanceScore / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getPerformanceColor(statistics.performanceScore),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Puntuación: ${statistics.performanceScore.toInt()}/100 - ${statistics.performanceLevel}',
              style: TextStyle(
                fontSize: 14,
                color: _getPerformanceColor(statistics.performanceScore),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildRecentActivities(StreakProvider provider) {
    final result = provider.lastActivityResult;
    
    if (result == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Última Actividad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: result.success ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: result.success ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    result.success ? Icons.check_circle : Icons.error,
                    color: result.success ? Colors.green[600] : Colors.red[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.success ? '¡Actividad registrada exitosamente!' : 
                      result.error ?? 'Error desconocido',
                      style: TextStyle(
                        color: result.success ? Colors.green[600] : Colors.red[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogos y métodos de acción

  Future<void> _showRecordActivityDialog(StreakType streakType, StreakProvider provider) async {
    switch (streakType) {
      case StreakType.dailySavings:
        return _showAmountDialog(
          'Registrar Ahorro',
          'Ingresa el monto ahorrado',
          (amount) => provider.recordDailySavings(amount),
          provider,
        );
      case StreakType.expenseTracking:
        return _showExpenseDialog(provider);
      case StreakType.noImpulseSpending:
        final success = await provider.recordNoImpulseDay();
        if (success) {
          _showSuccessSnackBar('¡Día sin gastos impulsivos registrado!');
        }
        break;
      case StreakType.cookingAtHome:
        return _showTextDialog(
          'Cocinar en Casa',
          'Describe lo que cocinaste',
          (description) => provider.recordHomeCooking(description),
          provider,
        );
      case StreakType.publicTransport:
        return _showTextDialog(
          'Transporte Público',
          'Describe cómo te movilizaste',
          (description) => provider.recordPublicTransport(description),
          provider,
        );
      case StreakType.discountFinder:
        return _showAmountDialog(
          'Descuento Encontrado',
          'Ingresa el monto ahorrado',
          (savings) => provider.recordDiscountFound(savings),
          provider,
        );
      default:
        break;
    }
  }

  Future<void> _showRecordExpenseDialog(StreakProvider provider) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Monto del gasto',
                prefixText: '\$',
              ),
              id: 'amount',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(),
              decoration: const InputDecoration(
                hintText: 'Descripción del gasto',
              ),
              id: 'description',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(
                (context.findRenderObject() as dynamic).widget.key == 'amount'
                    ? (context.findRenderObject() as dynamic).controller.text
                    : '0'
              );
              final description = 'Descripción'; // Obtener del campo correspondiente
              
              if (amount != null && amount > 0 && description.isNotEmpty) {
                Navigator.of(context).pop({'amount': amount, 'description': description});
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      final success = await provider.recordExpense(result['amount'], result['description']);
      if (success) {
        _showSuccessSnackBar('¡Gasto registrado exitosamente!');
      }
    }
  }

  Future<void> _showAmountDialog(
    String title,
    String hint,
    Function(double) onSubmit,
    StreakProvider provider,
  ) async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
    ).then((amount) {
      if (amount != null && amount > 0) {
        onSubmit(amount);
      }
    });
  }

  Future<void> _showTextDialog(
    String title,
    String hint,
    Function(String) onSubmit,
    StreakProvider provider,
  ) async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final description = controller.text;
              Navigator.of(context).pop(description);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ).then((description) {
      if (description != null && description.isNotEmpty) {
        onSubmit(description);
      }
    });
  }

  Future<void> _showBreakStreakDialog(StreakType streakType, StreakProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Romper Racha'),
        content: Text('¿Estás seguro de que quieres romper tu racha de "${_getStreakTitle(streakType)}"?'),
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
      await provider.breakStreak(streakType);
      _showSuccessSnackBar('Racha rota');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
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

  Color _getTrendColor(StreakTrend trend) {
    switch (trend) {
      case StreakTrend.improving:
        return Colors.green;
      case StreakTrend.stable:
        return Colors.blue;
      case StreakTrend.declining:
        return Colors.red;
    }
  }

  Color _getPerformanceColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

/// Clase para acciones rápidas
class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(this.title, this.icon, this.color, this.onTap);
}