import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/streak_models.dart';
import '../services/enhanced_streak_service.dart';

/// Provider para el estado del sistema de rachas mejorado
/// Maneja el estado global de las rachas, logros y estadísticas del usuario
class StreakProvider extends ChangeNotifier {
  final EnhancedStreakService _streakService = EnhancedStreakService();
  
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _error;
  
  Map<String, UserStreak> _streaks = {};
  UserStats? _userStats;
  List<StreakAchievement> _availableAchievements = [];
  List<StreakAchievement> _unlockedAchievements = [];
  List<StreakReward> _availableRewards = [];
  List<Badge> _userBadges = [];
  
  // Estado de actividad reciente
  StreakActivityResult? _lastActivityResult;
  List<StreakMilestoneUpdate> _recentMilestones = [];
  
  // Suscripciones a streams
  StreamSubscription<Map<String, UserStreak>>? _streakSubscription;
  StreamSubscription<UserStats>? _statsSubscription;
  StreamSubscription<List<StreakAchievement>>? _achievementSubscription;
  StreamSubscription<StreakMilestoneUpdate>? _milestoneSubscription;

  // Getters públicos
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Map<String, UserStreak> get streaks => Map.from(_streaks);
  UserStats? get userStats => _userStats;
  List<StreakAchievement> get availableAchievements => List.from(_availableAchievements);
  List<StreakAchievement> get unlockedAchievements => List.from(_unlockedAchievements);
  List<StreakReward> get availableRewards => List.from(_availableRewards);
  List<Badge> get userBadges => List.from(_userBadges);
  
  StreakActivityResult? get lastActivityResult => _lastActivityResult;
  List<StreakMilestoneUpdate> get recentMilestones => List.from(_recentMilestones);

  /// Inicializar el provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Inicializar servicio
      await _streakService.initialize();
      
      // Suscribirse a streams
      _setupStreams();
      
      // Cargar datos iniciales
      await _loadInitialData();
      
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
      
      print('✅ StreakProvider inicializado correctamente');
    } catch (e) {
      _error = 'Error inicializando: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print('❌ Error inicializando StreakProvider: $e');
    }
  }

  /// Configurar suscripciones a streams
  void _setupStreams() {
    _streakSubscription = _streakService.streakUpdates.listen((streaks) {
      if (!_isInitialized) return;
      
      _streaks = streaks;
      notifyListeners();
      
      print('📊 Actualización de rachas recibida: ${streaks.length} rachas');
    });

    _statsSubscription = _streakService.userStatsUpdates.listen((stats) {
      if (!_isInitialized) return;
      
      _userStats = stats;
      _updateUnlockedAchievements();
      _updateUserBadges();
      notifyListeners();
      
      print('📈 Actualización de estadísticas: ${stats.totalPoints} puntos');
    });

    _achievementSubscription = _streakService.achievementUpdates.listen((achievements) {
      if (!_isInitialized) return;
      
      _unlockedAchievements = achievements;
      notifyListeners();
      
      print('🏆 Nuevos logros desbloqueados: ${achievements.length}');
      _showAchievementNotification(achievements);
    });

    _milestoneSubscription = _streakService.milestoneUpdates.listen((milestoneUpdate) {
      if (!_isInitialized) return;
      
      _recentMilestones.insert(0, milestoneUpdate);
      // Mantener solo los últimos 5 hitos
      if (_recentMilestones.length > 5) {
        _recentMilestones = _recentMilestones.take(5).toList();
      }
      notifyListeners();
      
      print('🎯 Hito completado: ${milestoneUpdate.milestone.title}');
      _showMilestoneNotification(milestoneUpdate);
    });
  }

  /// Cargar datos iniciales
  Future<void> _loadInitialData() async {
    // Cargar rachas
    _streaks = _streakService.getAllStreaks();
    
    // Cargar estadísticas
    _userStats = _streakService.getUserStats();
    
    // Cargar logros
    _availableAchievements = _streakService.getAvailableAchievements();
    _updateUnlockedAchievements();
    
    // Cargar recompensas
    _availableRewards = _streakService.getAvailableRewards();
    
    // Cargar badges
    _updateUserBadges();
  }

  /// Actualizar logros desbloqueados
  void _updateUnlockedAchievements() {
    if (_userStats == null) {
      _unlockedAchievements = [];
      return;
    }
    
    _unlockedAchievements = _availableAchievements.where((achievement) =>
        _userStats!.unlockedAchievements.contains(achievement.id)).toList();
  }

  /// Actualizar badges del usuario
  void _updateUserBadges() {
    _userBadges = _userStats?.badges ?? [];
  }

  /// Registrar nueva actividad
  Future<bool> recordActivity(
    StreakType streakType, {
    double? amount,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      _showError('Sistema no inicializado');
      return false;
    }

    try {
      final result = await _streakService.recordActivity(
        streakType,
        amount: amount,
        description: description,
        metadata: metadata,
      );
      
      _lastActivityResult = result;
      notifyListeners();
      
      if (result.success) {
        _showSuccess('¡Actividad registrada exitosamente!');
        return true;
      } else {
        _showError(result.error ?? 'Error desconocido');
        return false;
      }
    } catch (e) {
      _showError('Error registrando actividad: ${e.toString()}');
      return false;
    }
  }

  /// Métodos de conveniencia para tipos específicos de actividades
  
  /// Registrar ahorro diario
  Future<bool> recordDailySavings(double amount) {
    return recordActivity(StreakType.dailySavings, amount: amount);
  }

  /// Registrar gasto
  Future<bool> recordExpense(double amount, String description) {
    return recordActivity(StreakType.expenseTracking, amount: amount, description: description);
  }

  /// Registrar día sin gastos impulsivos
  Future<bool> recordNoImpulseDay() {
    return recordActivity(StreakType.noImpulseSpending);
  }

  /// Registrar día cocinando en casa
  Future<bool> recordHomeCooking(String description) {
    return recordActivity(StreakType.cookingAtHome, description: description);
  }

  /// Registrar uso de transporte público
  Future<bool> recordPublicTransport(String description) {
    return recordActivity(StreakType.publicTransport, description: description);
  }

  /// Registrar descuento encontrado
  Future<bool> recordDiscountFound(double savings) {
    return recordActivity(StreakType.discountFinder, amount: savings);
  }

  /// Romper racha
  Future<void> breakStreak(StreakType streakType, {String? reason}) async {
    if (!_isInitialized) return;
    
    await _streakService.breakStreak(streakType, reason: reason);
    notifyListeners();
  }

  /// Canjear recompensa
  Future<bool> redeemReward(StreakReward reward) async {
    if (!_isInitialized || _userStats == null) {
      _showError('Sistema no inicializado');
      return false;
    }
    
    if (_userStats!.totalPoints < reward.pointsCost) {
      _showError('Puntos insuficientes');
      return false;
    }
    
    final success = await _streakService.redeemReward(reward);
    if (success) {
      _showSuccess('¡Recompensa canjeada exitosamente!');
    } else {
      _showError('Error canjeando recompensa');
    }
    
    return success;
  }

  /// Obtener racha por tipo
  UserStreak? getStreak(StreakType streakType) {
    return _streaks[streakType.name];
  }

  /// Obtener estadísticas de racha específica
  StreakStatistics? getStreakStatistics(StreakType streakType) {
    final streak = getStreak(streakType);
    if (streak == null) return null;
    
    return StreakStatistics(
      currentStreak: streak.currentStreak,
      longestStreak: streak.longestStreak,
      nextMilestone: streak.nextMilestone,
      progressToNext: streak.progressToNextMilestone,
      performance: streak.performance,
      trend: streak.trend,
      status: streak.status,
    );
  }

  /// Obtener progreso general del usuario
  UserProgress getOverallProgress() {
    if (_userStats == null) {
      return UserProgress.empty();
    }
    
    final totalStreaks = _streaks.length;
    final activeStreaks = _streaks.values.where((s) => s.status == StreakStatus.active).length;
    final totalAchievements = _unlockedAchievements.length;
    final totalBadges = _userBadges.length;
    final averageStreak = _streaks.isEmpty ? 0.0 :
        _streaks.values.map((s) => s.currentStreak).reduce((a, b) => a + b) / _streaks.length;
    
    return UserProgress(
      totalStreaks: totalStreaks,
      activeStreaks: activeStreaks,
      totalPoints: _userStats!.totalPoints,
      totalAchievements: totalAchievements,
      totalBadges: totalBadges,
      userLevel: _userStats!.level,
      experiencePoints: _userStats!.experiencePoints,
      averageStreak: averageStreak,
      consecutiveLogins: _userStats!.consecutiveLogins,
      streakDaysTotal: _userStats!.streakDaysTotal,
    );
  }

  /// Generar reporte de rachas
  Future<Map<String, dynamic>> generateReport() async {
    if (!_isInitialized) {
      throw Exception('Sistema no inicializado');
    }
    
    return await _streakService.generateStreakReport();
  }

  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Mostrar notificación de éxito
  void _showSuccess(String message) {
    // En una implementación real, esto podría mostrar un SnackBar
    print('✅ $message');
  }

  /// Mostrar notificación de error
  void _showError(String message) {
    _error = message;
    notifyListeners();
    print('❌ $message');
  }

  /// Mostrar notificación de logros desbloqueados
  void _showAchievementNotification(List<StreakAchievement> achievements) {
    for (final achievement in achievements) {
      print('🏆 ¡Logro desbloqueado: ${achievement.title}!');
    }
  }

  /// Mostrar notificación de hito completado
  void _showMilestoneNotification(StreakMilestoneUpdate milestoneUpdate) {
    print('🎯 ¡Hito completado: ${milestoneUpdate.milestone.title}!');
  }

  @override
  void dispose() {
    _streakSubscription?.cancel();
    _statsSubscription?.cancel();
    _achievementSubscription?.cancel();
    _milestoneSubscription?.cancel();
    _streakService.dispose();
    super.dispose();
  }
}

/// Estadísticas específicas de una racha
class StreakStatistics {
  final int currentStreak;
  final int longestStreak;
  final int nextMilestone;
  final double progressToNext;
  final StreakPerformance performance;
  final StreakTrend trend;
  final StreakStatus status;

  const StreakStatistics({
    required this.currentStreak,
    required this.longestStreak,
    required this.nextMilestone,
    required this.progressToNext,
    required this.performance,
    required this.trend,
    required this.status,
  });

  String get statusDisplay => status.displayName;
  String get trendDisplay => trend.displayName;
  String get performanceLevel => performance.performanceLevel;
  double get performanceScore => performance.performanceScore;
  
  int get daysToNextMilestone => nextMilestone - currentStreak;
  bool get isActive => status == StreakStatus.active;
  bool get isBroken => status == StreakStatus.broken;
  bool get isPaused => status == StreakStatus.paused;
}

/// Progreso general del usuario
class UserProgress {
  final int totalStreaks;
  final int activeStreaks;
  final int totalPoints;
  final int totalAchievements;
  final int totalBadges;
  final UserLevel userLevel;
  final int experiencePoints;
  final double averageStreak;
  final int consecutiveLogins;
  final int streakDaysTotal;

  const UserProgress({
    required this.totalStreaks,
    required this.activeStreaks,
    required this.totalPoints,
    required this.totalAchievements,
    required this.totalBadges,
    required this.userLevel,
    required this.experiencePoints,
    required this.averageStreak,
    required this.consecutiveLogins,
    required this.streakDaysTotal,
  });

  factory UserProgress.empty() {
    return const UserProgress(
      totalStreaks: 0,
      activeStreaks: 0,
      totalPoints: 0,
      totalAchievements: 0,
      totalBadges: 0,
      userLevel: UserLevel.beginner,
      experiencePoints: 0,
      averageStreak: 0.0,
      consecutiveLogins: 0,
      streakDaysTotal: 0,
    );
  }

  double get completionRate {
    if (totalStreaks == 0) return 0.0;
    return (activeStreaks / totalStreaks) * 100;
  }

  UserLevel? get nextLevel => userLevel.nextLevel();
  int get xpToNextLevel {
    final next = nextLevel;
    if (next == null) return 0;
    return next.maxXp - experiencePoints;
  }

  String get levelDisplay => userLevel.displayName;
  String get nextLevelDisplay => nextLevel?.displayName ?? 'Máximo nivel';
}

/// Provider helper widget
class StreakProviderScope extends StatelessWidget {
  final Widget child;

  const StreakProviderScope({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StreakProvider(),
      child: child,
    );
  }
}