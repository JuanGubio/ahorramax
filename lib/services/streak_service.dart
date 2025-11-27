import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/streak_models.dart';

class StreakService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache local para evitar múltiples lecturas
  final Map<String, UserStreak> _streakCache = {};
  UserStats? _userStats;
  
  // Stream para actualizaciones en tiempo real
  final _streakUpdatesController = StreamController<Map<String, UserStreak>>.broadcast();
  Stream<Map<String, UserStreak>> get streakUpdates => _streakUpdatesController.stream;
  
  final _userStatsUpdatesController = StreamController<UserStats>.broadcast();
  Stream<UserStats> get userStatsUpdates => _userStatsUpdatesController.stream;
  
  // Definición de logros disponibles
  static final List<StreakAchievement> achievements = [
    // Logros de Ahorro Diario
    StreakAchievement(
      id: 'daily_saver_bronze',
      title: 'Ahorrador Dedicado',
      description: 'Ahorra dinero durante 7 días seguidos',
      icon: '💰',
      rarity: Rarity.bronze,
      targetStreak: 7,
      pointsReward: 100,
      unlockFeatures: ['tutorial_advanced'],
      streakType: StreakType.dailySavings,
      category: 'Ahorro',
      difficulty: DifficultyLevel.easy,
      requirements: [],
      badgeUrl: '',
    ),
    StreakAchievement(
      id: 'daily_saver_silver',
      title: 'Maestro del Ahorro',
      description: 'Ahorra dinero durante 30 días seguidos',
      icon: '🏆',
      rarity: Rarity.silver,
      targetStreak: 30,
      pointsReward: 500,
      unlockFeatures: ['advanced_chat', 'custom_goals'],
      streakType: StreakType.dailySavings,
      category: 'Ahorro',
      difficulty: DifficultyLevel.medium,
      requirements: [],
      badgeUrl: '',
    ),
    StreakAchievement(
      id: 'daily_saver_gold',
      title: 'Leyenda del Ahorro',
      description: 'Ahorra dinero durante 100 días seguidos',
      icon: '👑',
      rarity: Rarity.gold,
      targetStreak: 100,
      pointsReward: 1500,
      unlockFeatures: ['premium_features', 'social_sharing'],
      streakType: StreakType.dailySavings,
      category: 'Ahorro',
      difficulty: DifficultyLevel.hard,
      requirements: [],
      badgeUrl: '',
    ),
    
    // Logros de Tracking de Gastos
    StreakAchievement(
      id: 'tracker_bronze',
      title: 'Contador Detallado',
      description: 'Registra gastos durante 14 días seguidos',
      icon: '📊',
      rarity: Rarity.bronze,
      targetStreak: 14,
      pointsReward: 150,
      unlockFeatures: ['expense_analytics'],
      streakType: StreakType.expenseTracking,
      category: 'Control de Gastos',
      difficulty: DifficultyLevel.easy,
      requirements: [],
      badgeUrl: '',
    ),
    StreakAchievement(
      id: 'tracker_silver',
      title: 'Analista Financiero',
      description: 'Registra gastos durante 30 días seguidos',
      icon: '📈',
      rarity: Rarity.silver,
      targetStreak: 30,
      pointsReward: 600,
      unlockFeatures: ['advanced_insights'],
      streakType: StreakType.expenseTracking,
      category: 'Control de Gastos',
      difficulty: DifficultyLevel.medium,
      requirements: [],
      badgeUrl: '',
    ),
    StreakAchievement(
      id: 'tracker_gold',
      title: 'Gurú de las Finanzas',
      description: 'Registra gastos durante 60 días seguidos',
      icon: '🧠',
      rarity: Rarity.gold,
      targetStreak: 60,
      pointsReward: 1200,
      unlockFeatures: ['pro_analytics', 'export_reports'],
      streakType: StreakType.expenseTracking,
      category: 'Control de Gastos',
      difficulty: DifficultyLevel.hard,
      requirements: [],
      badgeUrl: '',
    ),
    
    // Logros de No Gastos Impulsivos
    StreakAchievement(
      id: 'no_impulse_bronze',
      title: 'Pensador Reflexivo',
      description: '7 días sin gastos impulsivos',
      icon: '🤔',
      rarity: Rarity.bronze,
      targetStreak: 7,
      pointsReward: 200,
      unlockFeatures: ['impulse_tracker'],
      streakType: StreakType.noImpulseSpending,
      category: 'Disciplina',
      difficulty: DifficultyLevel.medium,
      requirements: [],
      badgeUrl: '',
    ),
    StreakAchievement(
      id: 'no_impulse_silver',
      title: 'Maestro del Control',
      description: '30 días sin gastos impulsivos',
      icon: '🎯',
      rarity: Rarity.silver,
      targetStreak: 30,
      pointsReward: 800,
      unlockFeatures: ['advanced_budgeting'],
      streakType: StreakType.noImpulseSpending,
      category: 'Disciplina',
      difficulty: DifficultyLevel.hard,
      requirements: [],
      badgeUrl: '',
    ),
    StreakAchievement(
      id: 'no_impulse_diamond',
      title: 'Señor de la Disciplina',
      description: '90 días sin gastos impulsivos',
      icon: '💎',
      rarity: Rarity.diamond,
      targetStreak: 90,
      pointsReward: 2000,
      unlockFeatures: ['master_level', 'exclusive_rewards'],
      streakType: StreakType.noImpulseSpending,
      category: 'Disciplina',
      difficulty: DifficultyLevel.extreme,
      requirements: [],
      badgeUrl: '',
    ),
    
    // Logros de Cocinar en Casa
    StreakAchievement(
      id: 'home_cook_bronze',
      title: 'Chef Casero',
      description: '10 días cocinando en casa',
      icon: '👨‍🍳',
      rarity: Rarity.bronze,
      targetStreak: 10,
      pointsReward: 250,
      unlockFeatures: ['recipe_suggestions'],
      streakType: StreakType.cookingAtHome,
      category: 'Estilo de Vida',
      difficulty: DifficultyLevel.easy,
      requirements: [],
      badgeUrl: '',
    ),
    StreakAchievement(
      id: 'home_cook_silver',
      title: 'Maestro Culinario',
      description: '25 días cocinando en casa',
      icon: '🍳',
      rarity: Rarity.silver,
      targetStreak: 25,
      pointsReward: 750,
      unlockFeatures: ['meal_planning', 'grocery_savings'],
      streakType: StreakType.cookingAtHome,
      category: 'Estilo de Vida',
      difficulty: DifficultyLevel.medium,
      requirements: [],
      badgeUrl: '',
    ),
    
    // Logros de Transporte Público
    StreakAchievement(
      id: 'eco_friendly_bronze',
      title: 'Guerrero Eco-Friendly',
      description: '15 días usando transporte público',
      icon: '🚌',
      rarity: Rarity.bronze,
      targetStreak: 15,
      pointsReward: 300,
      unlockFeatures: ['eco_tracking'],
      streakType: StreakType.publicTransport,
      category: 'Sostenibilidad',
      difficulty: DifficultyLevel.easy,
      requirements: [],
      badgeUrl: '',
    ),
    StreakAchievement(
      id: 'eco_friendly_gold',
      title: 'Embajador Verde',
      description: '40 días usando transporte público',
      icon: '🌱',
      rarity: Rarity.gold,
      targetStreak: 40,
      pointsReward: 1000,
      unlockFeatures: ['carbon_calculator', 'green_badge'],
      streakType: StreakType.publicTransport,
      category: 'Sostenibilidad',
      difficulty: DifficultyLevel.medium,
      requirements: [],
      badgeUrl: '',
    ),
    
    // Logros de Cazador de Descuentos
    StreakAchievement(
      id: 'discount_hunter_bronze',
      title: 'Cazador de Ofertas',
      description: 'Encuentra 5 descuentos exitosos',
      icon: '🎯',
      rarity: Rarity.bronze,
      targetStreak: 5,
      pointsReward: 400,
      unlockFeatures: ['price_alerts'],
      streakType: StreakType.discountFinder,
      category: 'Ahorro Inteligente',
      difficulty: DifficultyLevel.easy,
      requirements: [],
      badgeUrl: '',
    ),
    StreakAchievement(
      id: 'discount_hunter_legendary',
      title: 'Señor de las Ofertas',
      description: 'Encuentra 25 descuentos exitosos',
      icon: '👑',
      rarity: Rarity.legendary,
      targetStreak: 25,
      pointsReward: 2500,
      unlockFeatures: ['exclusive_deals', 'vip_access'],
      streakType: StreakType.discountFinder,
      category: 'Ahorro Inteligente',
      difficulty: DifficultyLevel.hard,
      requirements: [],
      badgeUrl: '',
    ),
  ];
  
  // Recompensas disponibles
  static final List<StreakReward> rewards = [
    StreakReward(
      id: 'custom_mascot',
      name: 'Mascota Personalizada',
      description: 'Cambia el avatar de tu mascota financiera',
      icon: '🦊',
      pointsCost: 500,
      benefits: ['custom_mascot', 'more_motivation'],
      rarity: Rarity.bronze,
      category: 'Personalización',
      isLimited: false,
    ),
    StreakReward(
      id: 'theme_pack',
      name: 'Paquete de Temas',
      description: 'Desbloquea 5 nuevos temas visuales',
      icon: '🎨',
      pointsCost: 750,
      benefits: ['theme_variety', 'visual_customization'],
      rarity: Rarity.silver,
      category: 'Personalización',
      isLimited: false,
    ),
    StreakReward(
      id: 'ai_upgrade',
      name: 'IA Avanzada',
      description: 'Mejora tus recomendaciones de IA',
      icon: '🤖',
      pointsCost: 1200,
      benefits: ['better_recommendations', 'smarter_insights'],
      rarity: Rarity.gold,
      category: 'Funcionalidad',
      isLimited: false,
    ),
    StreakReward(
      id: 'social_features',
      name: 'Funciones Sociales',
      description: 'Comparte logros con amigos',
      icon: '👥',
      pointsCost: 1000,
      benefits: ['social_sharing', 'friend_comparisons'],
      rarity: Rarity.silver,
      category: 'Social',
      isLimited: false,
    ),
    StreakReward(
      id: 'premium_analytics',
      name: 'Analíticas Premium',
      description: 'Reportes financieros avanzados',
      icon: '📊',
      pointsCost: 2000,
      benefits: ['advanced_reports', 'export_data', 'custom_insights'],
      rarity: Rarity.diamond,
      category: 'Funcionalidad',
      isLimited: false,
    ),
  ];

  /// Inicializar el servicio y cargar datos del usuario
  Future<void> initialize() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cargar stats del usuario
    await _loadUserStats();
    
    // Cargar todas las rachas del usuario
    await _loadUserStreaks();
    
    // Verificar rachas que necesitan actualizarse (por días perdidos)
    await _checkAndUpdateStreaks();
  }

  /// Cargar estadísticas del usuario
  Future<void> _loadUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('userStats').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _userStats = UserStats(
        userId: user.uid,
        totalPoints: data['totalPoints'] ?? 0,
        totalAchievements: data['totalAchievements'] ?? 0,
        bestStreaks: Map<StreakType, int>.from(
          (data['bestStreaks'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(
                    StreakType.values.firstWhere((e) => e.name == key, orElse: () => StreakType.dailySavings),
                    value,
                  )) ?? {},
        ),
        unlockedRewards: List<String>.from(data['unlockedRewards'] ?? []),
        unlockedAchievements: List<String>.from(data['unlockedAchievements'] ?? []),
        lastLoginDate: DateTime.parse(data['lastLoginDate'] ?? DateTime.now().toIso8601String()),
        consecutiveLogins: data['consecutiveLogins'] ?? 0,
        totalSavingsTracked: data['totalSavingsTracked'] ?? 0,
        expensesLogged: data['expensesLogged'] ?? 0,
        createdDate: DateTime.parse(data['createdDate'] ?? DateTime.now().toIso8601String()),
        level: UserLevel.values.firstWhere(
          (e) => e.name == (data['level'] ?? 'beginner'),
          orElse: () => UserLevel.beginner,
        ),
        badges: (data['badges'] as List<dynamic>?)
            ?.map((b) => Badge.fromMap(b as Map<String, dynamic>))
            .toList() ?? [],
      );
    } else {
      // Crear stats iniciales
      _userStats = UserStats(
        userId: user.uid,
        bestStreaks: {},
        unlockedRewards: [],
        unlockedAchievements: [],
        lastLoginDate: DateTime.now(),
        createdDate: DateTime.now(),
        level: UserLevel.beginner,
        badges: [],
      );
      await _saveUserStats();
    }
  }

  /// Cargar todas las rachas del usuario
  Future<void> _loadUserStreaks() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final query = await _firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('streaks')
        .get();

    for (final doc in query.docs) {
      final streak = UserStreak.fromMap(doc.data());
      _streakCache[streak.type.name] = streak;
    }

    // Emitir actualizaciones
    _streakUpdatesController.add(Map.from(_streakCache));
  }

  /// Verificar y actualizar rachas (para detectar días perdidos)
  Future<void> _checkAndUpdateStreaks() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    for (final entry in _streakCache.entries) {
      final streak = entry.value;
      if (streak.lastActivityDate != null) {
        final daysDiff = now.difference(streak.lastActivityDate!).inDays;
        
        // Si han pasado más de 1 día desde la última actividad, romper racha
        if (daysDiff > 1) {
          await breakStreak(streak.type);
        }
      }
    }
  }

  /// Registrar actividad para un tipo de racha específico
  Future<bool> recordActivity(StreakType type, {double? amount, String? description}) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final today = DateTime.now();
    final normalizedDate = DateTime(today.year, today.month, today.day); // Sin hora

    try {
      // Obtener o crear racha
      UserStreak? streak = _streakCache[type];
      if (streak == null) {
        streak = await _createNewStreak(type);
      }

      // Verificar si ya hay actividad hoy
      if (streak.activityLog.any((date) => 
          date.year == normalizedDate.year && 
          date.month == normalizedDate.month && 
          date.day == normalizedDate.day)) {
        return false; // Ya hay actividad hoy
      }

      // Validaciones específicas por tipo
      if (!_validateActivity(type, amount, description)) {
        return false;
      }

      // Actualizar racha
      streak = streak.addActivity(normalizedDate);

      // Guardar en Firestore
      await _saveStreak(streak);

      // Actualizar cache
      _streakCache[type.name] = streak;

      // Verificar logros
      await _checkAchievements(streak);

      // Actualizar estadísticas del usuario
      await _updateUserStats(type, amount);

      // Emitir actualizaciones
      _streakUpdatesController.add(Map.from(_streakCache));

      return true;
    } catch (e) {
      print('Error registrando actividad: $e');
      return false;
    }
  }

  /// Validar que la actividad es válida para el tipo de racha
  bool _validateActivity(StreakType type, double? amount, String? description) {
    switch (type) {
      case StreakType.dailySavings:
        return amount != null && amount > 0;
      case StreakType.expenseTracking:
        return amount != null && amount > 0 && description != null;
      case StreakType.noImpulseSpending:
        return amount == null || amount <= 0; // No gasto = actividad válida
      case StreakType.cookingAtHome:
        return description?.toLowerCase().contains('casa') == true ||
               description?.toLowerCase().contains('cocinar') == true;
      case StreakType.publicTransport:
        return description?.toLowerCase().contains('bus') == true ||
               description?.toLowerCase().contains('transporte') == true;
      case StreakType.discountFinder:
        return amount != null && amount > 0; // Debe haber ahorrado dinero
      case StreakType.goalCompletion:
        return true; // Se valida internamente
      case StreakType.budgetPlanning:
        return true; // Se valida internamente
    }
  }

  /// Crear nueva racha
  Future<UserStreak> _createNewStreak(StreakType type) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final streak = UserStreak(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      type: type,
      currentStreak: 0,
      longestStreak: 0,
      createdDate: DateTime.now(),
      updatedDate: DateTime.now(),
      activityLog: [],
      milestones: _generateMilestones(type),
    );

    await _saveStreak(streak);
    return streak;
  }

  /// Romper racha manualmente
  Future<void> breakStreak(StreakType type) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final streak = _streakCache[type];
    if (streak == null) return;

    final brokenStreak = streak.breakStreak();
    await _saveStreak(brokenStreak);
    _streakCache[type.name] = brokenStreak;

    _streakUpdatesController.add(Map.from(_streakCache));
  }

  /// Verificar y otorgar logros
  Future<void> _checkAchievements(UserStreak streak) async {
    final newlyUnlocked = <String>[];

    for (final achievement in achievements) {
      if (achievement.streakType == streak.type &&
          streak.currentStreak >= achievement.targetStreak) {
        
        // Verificar si ya se desbloqueó este logro
        final alreadyUnlocked = _userStats!.unlockedRewards.contains(achievement.id);
        if (!alreadyUnlocked) {
          newlyUnlocked.add(achievement.id);
          
          // Otorgar puntos
          await _awardPoints(achievement.pointsReward);
          
          // Desbloquear características
          for (final feature in achievement.unlockFeatures) {
            // Implementar desbloqueo de características
          }
        }
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      _userStats = _userStats!.copyWith(
        totalAchievements: _userStats!.totalAchievements + newlyUnlocked.length,
        unlockedRewards: [..._userStats!.unlockedRewards, ...newlyUnlocked],
      );
      await _saveUserStats();
      _userStatsUpdatesController.add(_userStats!);
    }
  }

  /// Otorgar puntos al usuario
  Future<void> _awardPoints(int points) async {
    _userStats = _userStats!.copyWith(totalPoints: _userStats!.totalPoints + points);
    await _saveUserStats();
    _userStatsUpdatesController.add(_userStats!);
  }

  /// Actualizar estadísticas del usuario
  Future<void> _updateUserStats(StreakType type, double? amount) async {
    if (_userStats == null) return;

    final newBestStreaks = Map<StreakType, int>.from(_userStats!.bestStreaks);
    final currentStreak = _streakCache[type];
    if (currentStreak != null) {
      newBestStreaks[type] = currentStreak.currentStreak;
    }

    final newExpensesLogged = _userStats!.expensesLogged + 
        (type == StreakType.expenseTracking ? 1 : 0);
    final newSavingsTracked = _userStats!.totalSavingsTracked + 
        (amount ?? 0);

    _userStats = _userStats!.copyWith(
      bestStreaks: newBestStreaks,
      expensesLogged: newExpensesLogged,
      totalSavingsTracked: newSavingsTracked.toInt(),
    );

    await _saveUserStats();
    _userStatsUpdatesController.add(_userStats!);
  }

  /// Guardar racha en Firestore
  Future<void> _saveStreak(UserStreak streak) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('streaks')
        .doc(streak.type.name)
        .set(streak.toMap());
  }

  /// Guardar estadísticas del usuario
  Future<void> _saveUserStats() async {
    final user = _auth.currentUser;
    if (user == null || _userStats == null) return;

    await _firestore
        .collection('userStats')
        .doc(user.uid)
        .set(_userStats!.toMap());
  }

  /// Obtener racha por tipo
  UserStreak? getStreak(StreakType type) {
    return _streakCache[type.name];
  }

  /// Obtener todas las rachas
  Map<String, UserStreak> getAllStreaks() {
    return Map.from(_streakCache);
  }

  /// Obtener estadísticas del usuario
  UserStats? getUserStats() {
    return _userStats;
  }

  /// Obtener logros disponibles
  List<StreakAchievement> getAvailableAchievements() {
    return achievements;
  }

  /// Obtener recompensas disponibles
  List<StreakReward> getAvailableRewards() {
    return rewards;
  }

  /// Obtener logros desbloqueados por el usuario
  List<StreakAchievement> getUnlockedAchievements() {
    if (_userStats == null) return [];
    
    return achievements.where((achievement) => 
        _userStats!.unlockedRewards.contains(achievement.id)).toList();
  }

  /// Canjear recompensa
  Future<bool> redeemReward(StreakReward reward) async {
    if (_userStats == null || _userStats!.totalPoints < reward.pointsCost) {
      return false;
    }

    // Verificar si ya está desbloqueada
    if (_userStats!.unlockedRewards.contains(reward.id)) {
      return false;
    }

    try {
      // Descontar puntos
      _userStats = _userStats!.copyWith(
        totalPoints: _userStats!.totalPoints - reward.pointsCost,
        unlockedRewards: [..._userStats!.unlockedRewards, reward.id],
      );

      await _saveUserStats();
      _userStatsUpdatesController.add(_userStats!);

      // Implementar desbloqueo de beneficios aquí
      
      return true;
    } catch (e) {
      print('Error canjeando recompensa: $e');
      return false;
    }
  }

  /// Métodos de conveniencia para registrar actividades específicas
  
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

  /// Liberar recursos
  void dispose() {
    _streakUpdatesController.close();
    _userStatsUpdatesController.close();
  }

  static List<StreakMilestone> _generateMilestones(StreakType type) {
    // Generar hitos basados en el tipo de racha
    switch (type) {
      case StreakType.dailySavings:
        return [
          StreakMilestone(7, 'Primera Semana', '💰', Rarity.bronze),
          StreakMilestone(30, 'Mes Completo', '🏆', Rarity.silver),
          StreakMilestone(100, 'Centuria de Ahorro', '👑', Rarity.gold),
          StreakMilestone(365, 'Año de Disciplina', '💎', Rarity.diamond),
        ];
      case StreakType.expenseTracking:
        return [
          StreakMilestone(7, 'Primera Semana', '📊', Rarity.bronze),
          StreakMilestone(30, 'Mes Completo', '📈', Rarity.silver),
          StreakMilestone(90, 'Trimestre Perfecto', '🧠', Rarity.gold),
          StreakMilestone(180, 'Semestre Disciplinado', '💎', Rarity.diamond),
        ];
      default:
        return [
          StreakMilestone(7, 'Primera Semana', '⭐', Rarity.bronze),
          StreakMilestone(30, 'Mes Completo', '🏆', Rarity.silver),
          StreakMilestone(100, 'Centuria', '👑', Rarity.gold),
        ];
    }
  }
}