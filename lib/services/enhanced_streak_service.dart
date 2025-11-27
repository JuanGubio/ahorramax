import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/streak_models.dart';

/// Servicio avanzado de rachas financieras
/// Versión 2.0 - Con lógica robusta y persistencia completa
class EnhancedStreakService {
  static final EnhancedStreakService _instance = EnhancedStreakService._internal();
  factory EnhancedStreakService() => _instance;
  EnhancedStreakService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache local para optimizar rendimiento
  final Map<String, UserStreak> _streakCache = {};
  UserStats? _userStats;
  List<StreakAchievement>? _achievements;
  List<StreakReward>? _rewards;
  
  // Streams para actualizaciones en tiempo real
  final _streakUpdatesController = StreamController<Map<String, UserStreak>>.broadcast();
  final _userStatsUpdatesController = StreamController<UserStats>.broadcast();
  final _achievementUpdatesController = StreamController<List<StreakAchievement>>.broadcast();
  final _milestoneUpdatesController = StreamController<StreakMilestoneUpdate>.broadcast();
  
  // Getters para streams públicos
  Stream<Map<String, UserStreak>> get streakUpdates => _streakUpdatesController.stream;
  Stream<UserStats> get userStatsUpdates => _userStatsUpdatesController.stream;
  Stream<List<StreakAchievement>> get achievementUpdates => _achievementUpdatesController.stream;
  Stream<StreakMilestoneUpdate> get milestoneUpdates => _milestoneUpdatesController.stream;
  
  // Estado de sincronización
  bool _isInitialized = false;
  bool _isOnline = true;
  Timer? _dailyMaintenanceTimer;

  /// Inicializar el servicio
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadConfiguration();
      await _initializeUser();
      await _startMaintenanceTimer();
      _isInitialized = true;
      
      print('✅ EnhancedStreakService inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando EnhancedStreakService: $e');
      rethrow;
    }
  }

  /// Cargar configuración de logros y recompensas
  Future<void> _loadConfiguration() async {
    try {
      // Cargar logros desde Firestore o crear defaults
      await _loadAchievements();
      
      // Cargar recompensas
      await _loadRewards();
      
      print('📋 Configuración cargada: ${_achievements?.length} logros, ${_rewards?.length} recompensas');
    } catch (e) {
      print('⚠️ Error cargando configuración: $e');
      // Crear configuración por defecto
      _createDefaultConfiguration();
    }
  }

  /// Cargar logros desde Firestore
  Future<void> _loadAchievements() async {
    try {
      final snapshot = await _firestore.collection('streakAchievements').get();
      
      if (snapshot.docs.isNotEmpty) {
        _achievements = snapshot.docs.map((doc) => 
            StreakAchievement.fromMap(doc.data())).toList();
      } else {
        // Crear logros por defecto si no existen
        _createDefaultAchievements();
        await _saveAchievementsToFirestore();
      }
    } catch (e) {
      print('⚠️ Error cargando logros: $e');
      _createDefaultAchievements();
    }
  }

  /// Cargar recompensas desde Firestore
  Future<void> _loadRewards() async {
    try {
      final snapshot = await _firestore.collection('streakRewards').get();
      
      if (snapshot.docs.isNotEmpty) {
        _rewards = snapshot.docs.map((doc) => 
            StreakReward.fromMap(doc.data())).toList();
      } else {
        _createDefaultRewards();
        await _saveRewardsToFirestore();
      }
    } catch (e) {
      print('⚠️ Error cargando recompensas: $e');
      _createDefaultRewards();
    }
  }

  /// Crear configuración por defecto
  void _createDefaultConfiguration() {
    _createDefaultAchievements();
    _createDefaultRewards();
  }

  /// Crear logros por defecto
  void _createDefaultAchievements() {
    _achievements = [
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
        requirements: ['ahorrar_al_menos_1_dolar_diario'],
        badgeUrl: 'badges/daily_saver_bronze.png',
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
        requirements: ['mantener_ahorro_promedio_5_dolares_diarios'],
        badgeUrl: 'badges/daily_saver_silver.png',
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
        requirements: ['ahorrar_mas_de_10_dolares_promedio_diario'],
        badgeUrl: 'badges/daily_saver_gold.png',
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
        category: 'Tracking',
        difficulty: DifficultyLevel.easy,
        requirements: ['registrar_al_menos_1_gasto_diario'],
        badgeUrl: 'badges/tracker_bronze.png',
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
        category: 'Tracking',
        difficulty: DifficultyLevel.medium,
        requirements: ['categorizar_todos_los_gastos'],
        badgeUrl: 'badges/tracker_silver.png',
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
        difficulty: DifficultyLevel.easy,
        requirements: ['no_compras_no_planificadas'],
        badgeUrl: 'badges/no_impulse_bronze.png',
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
        requirements: ['usar_regla_24_horas_compras'],
        badgeUrl: 'badges/no_impulse_silver.png',
      ),
      
      // Logros Especiales
      StreakAchievement(
        id: 'consistency_master',
        title: 'Maestro de la Consistencia',
        description: 'Mantén rachas activas en 3 categorías diferentes por 30 días',
        icon: '🌟',
        rarity: Rarity.diamond,
        targetStreak: 30,
        pointsReward: 2000,
        unlockFeatures: ['master_level', 'exclusive_rewards'],
        streakType: StreakType.dailySavings,
        category: 'Especial',
        difficulty: DifficultyLevel.extreme,
        requirements: ['streaks_activas_3_categorias'],
        badgeUrl: 'badges/consistency_master.png',
      ),
    ];
  }

  /// Crear recompensas por defecto
  void _createDefaultRewards() {
    _rewards = [
      StreakReward(
        id: 'custom_mascot',
        name: 'Mascota Personalizada',
        description: 'Cambia el avatar de tu mascota financiera',
        icon: '🦊',
        pointsCost: 500,
        benefits: ['custom_mascot', 'more_motivation'],
        rarity: Rarity.bronze,
        category: 'Personalización',
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
      ),
      StreakReward(
        id: 'ai_upgrade',
        name: 'IA Avanzada',
        description: 'Mejora tus recomendaciones de IA',
        icon: '🤖',
        pointsCost: 1200,
        benefits: ['better_recommendations', 'smarter_insights'],
        rarity: Rarity.gold,
        category: 'Funcionalidades',
      ),
      StreakReward(
        id: 'social_features',
        name: 'Funciones Sociales',
        description: 'Comparte logros con amigos',
        icon: '👥',
        pointsCost: 1000,
        benefits: ['social_sharing', 'friend_comparisons'],
        rarity: Rarity.gold,
        category: 'Social',
      ),
      StreakReward(
        id: 'premium_analytics',
        name: 'Analíticas Premium',
        description: 'Reportes financieros avanzados',
        icon: '📊',
        pointsCost: 2000,
        benefits: ['advanced_reports', 'export_data', 'custom_insights'],
        rarity: Rarity.diamond,
        category: 'Analíticas',
      ),
    ];
  }

  /// Guardar logros en Firestore
  Future<void> _saveAchievementsToFirestore() async {
    final batch = _firestore.batch();
    
    for (final achievement in _achievements!) {
      final docRef = _firestore.collection('streakAchievements').doc(achievement.id);
      batch.set(docRef, achievement.toMap());
    }
    
    await batch.commit();
  }

  /// Guardar recompensas en Firestore
  Future<void> _saveRewardsToFirestore() async {
    final batch = _firestore.batch();
    
    for (final reward in _rewards!) {
      final docRef = _firestore.collection('streakRewards').doc(reward.id);
      batch.set(docRef, reward.toMap());
    }
    
    await batch.commit();
  }

  /// Inicializar usuario
  Future<void> _initializeUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    // Cargar o crear estadísticas del usuario
    await _loadUserStats();
    
    // Cargar rachas existentes
    await _loadUserStreaks();
    
    // Verificar rachas que necesitan mantenimiento
    await _performDailyMaintenance();
  }

  /// Cargar estadísticas del usuario
  Future<void> _loadUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('userStats').doc(user.uid).get();
      
      if (doc.exists) {
        _userStats = UserStats.fromMap(doc.data()!);
      } else {
        // Crear estadísticas iniciales
        _userStats = _createInitialUserStats(user.uid);
        await _saveUserStats();
      }
      
      // Actualizar último login
      await _updateLastLogin();
      
    } catch (e) {
      print('⚠️ Error cargando stats del usuario: $e');
      // Crear stats por defecto
      _userStats = _createInitialUserStats(user.uid);
    }
  }

  /// Crear estadísticas iniciales del usuario
  UserStats _createInitialUserStats(String userId) {
    return UserStats(
      userId: userId,
      bestStreaks: {},
      unlockedRewards: [],
      unlockedAchievements: [],
      lastLoginDate: DateTime.now(),
      createdDate: DateTime.now(),
      level: UserLevel.beginner,
      badges: [],
    );
  }

  /// Cargar rachas del usuario
  Future<void> _loadUserStreaks() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final query = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('streaks')
          .get();

      for (final doc in query.docs) {
        final streak = UserStreak.fromMap(doc.data());
        _streakCache[streak.type.name] = streak;
      }

      // Emitir actualización inicial
      _streakUpdatesController.add(Map.from(_streakCache));
      
    } catch (e) {
      print('⚠️ Error cargando rachas: $e');
    }
  }

  /// Actualizar último login del usuario
  Future<void> _updateLastLogin() async {
    final user = _auth.currentUser;
    if (user == null || _userStats == null) return;

    final now = DateTime.now();
    final wasYesterday = _userStats!.lastLoginDate
        .add(const Duration(days: 1))
        .isAtSameMomentAs(DateTime(now.year, now.month, now.day));

    int newConsecutiveLogins = 1;
    if (wasYesterday) {
      newConsecutiveLogins = _userStats!.consecutiveLogins + 1;
    }

    _userStats = _userStats!.copyWith(
      lastLoginDate: now,
      consecutiveLogins: newConsecutiveLogins,
    );

    await _saveUserStats();
    _userStatsUpdatesController.add(_userStats!);
  }

  /// Registrar nueva actividad con validación robusta
  Future<StreakActivityResult> recordActivity(
    StreakType streakType, {
    double? amount,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return StreakActivityResult.failure('Usuario no autenticado');
    }

    final now = DateTime.now();
    final activity = StreakActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      streakType: streakType,
      timestamp: now,
      value: amount,
      description: description,
      metadata: metadata != null ? metadata.toString() : null,
    );

    try {
      // Obtener o crear racha
      UserStreak? streak = _streakCache[streakType.name];
      if (streak == null) {
        streak = UserStreak.create(userId: user.uid, type: streakType);
      }

      // Validar actividad
      final validation = _validateActivity(streakType, amount, description, metadata);
      if (!validation.isValid) {
        return StreakActivityResult.failure(validation.reason);
      }

      // Intentar agregar actividad
      final updatedStreak = streak.addActivity(now, value: amount, description: description);
      
      // Si no cambió la racha (ej: ya hay actividad hoy), retornar
      if (updatedStreak.currentStreak == streak.currentStreak && 
          updatedStreak.activityLog.length == streak.activityLog.length) {
        return StreakActivityResult.alreadyRecorded();
      }

      // Guardar cambios
      await _saveStreak(updatedStreak);
      _streakCache[streakType.name] = updatedStreak;

      // Guardar actividad en historial
      await _saveActivity(activity);

      // Verificar logros y hitos
      final achievementsUnlocked = await _checkAchievements(updatedStreak);
      final milestoneCompleted = await _checkMilestones(updatedStreak);

      // Actualizar estadísticas
      await _updateUserStats(streakType, amount);

      // Emitir actualizaciones
      _streakUpdatesController.add(Map.from(_streakCache));
      
      if (achievementsUnlocked.isNotEmpty) {
        _achievementUpdatesController.add(achievementsUnlocked);
      }
      
      if (milestoneCompleted != null) {
        _milestoneUpdatesController.add(milestoneCompleted);
      }

      return StreakActivityResult.success(
        streak: updatedStreak,
        achievementsUnlocked: achievementsUnlocked,
        milestoneCompleted: milestoneCompleted,
      );

    } catch (e) {
      print('❌ Error registrando actividad: $e');
      return StreakActivityResult.failure('Error interno: ${e.toString()}');
    }
  }

  /// Validar si una actividad es válida
  ActivityValidation _validateActivity(
    StreakType streakType,
    double? amount,
    String? description,
    Map<String, dynamic>? metadata,
  ) {
    // Validaciones básicas
    switch (streakType) {
      case StreakType.dailySavings:
        if (amount == null || amount <= 0) {
          return ActivityValidation.invalid('Debe ingresar un monto de ahorro mayor a 0');
        }
        if (amount > 10000) {
          return ActivityValidation.invalid('El monto excede el límite diario ($10,000)');
        }
        break;
        
      case StreakType.expenseTracking:
        if (amount == null || amount <= 0) {
          return ActivityValidation.invalid('Debe ingresar un monto de gasto mayor a 0');
        }
        if (description == null || description.trim().isEmpty) {
          return ActivityValidation.invalid('Debe ingresar una descripción del gasto');
        }
        break;
        
      case StreakType.noImpulseSpending:
        if (amount != null && amount > 0) {
          return ActivityValidation.invalid('No debe haber gastos para registrar este tipo de actividad');
        }
        break;
        
      case StreakType.cookingAtHome:
        if (description == null || 
            (!description.toLowerCase().contains('casa') && 
             !description.toLowerCase().contains('cocinar'))) {
          return ActivityValidation.invalid('La descripción debe incluir "casa" o "cocinar"');
        }
        break;
        
      case StreakType.publicTransport:
        if (description == null || 
            (!description.toLowerCase().contains('bus') && 
             !description.toLowerCase().contains('transporte') &&
             !description.toLowerCase().contains('metro'))) {
          return ActivityValidation.invalid('La descripción debe incluir "bus", "transporte" o "metro"');
        }
        break;
        
      case StreakType.discountFinder:
        if (amount == null || amount <= 0) {
          return ActivityValidation.invalid('Debe ingresar el monto ahorrado mayor a 0');
        }
        break;
    }

    return ActivityValidation.valid();
  }

  /// Verificar y otorgar logros
  Future<List<StreakAchievement>> _checkAchievements(UserStreak streak) async {
    final newlyUnlocked = <StreakAchievement>[];
    
    for (final achievement in _achievements!) {
      if (achievement.streakType != streak.type) continue;
      
      if (streak.currentStreak >= achievement.targetStreak) {
        // Verificar si ya está desbloqueado
        final alreadyUnlocked = _userStats!.unlockedAchievements.contains(achievement.id);
        if (!alreadyUnlocked) {
          newlyUnlocked.add(achievement);
          
          // Otorgar puntos
          await _awardPoints(achievement.pointsReward);
          
          // Agregar a logros desbloqueados
          _userStats = _userStats!.copyWith(
            unlockedAchievements: [..._userStats!.unlockedAchievements, achievement.id],
            totalAchievements: _userStats!.totalAchievements + 1,
          );
          
          // Crear badge
          final badge = Badge(
            id: 'badge_${achievement.id}',
            name: achievement.title,
            description: achievement.description,
            icon: achievement.icon,
            rarity: achievement.rarity,
            earnedDate: DateTime.now(),
            category: achievement.category,
            criteria: achievement.requirements.join(', '),
          );
          
          _userStats = _userStats!.copyWith(
            badges: [..._userStats!.badges, badge],
          );
          
          // Desbloquear características
          await _unlockFeatures(achievement.unlockFeatures);
          
          await _saveUserStats();
        }
      }
    }
    
    return newlyUnlocked;
  }

  /// Verificar hitos completados
  Future<StreakMilestoneUpdate?> _checkMilestones(UserStreak streak) async {
    for (int i = 0; i < streak.milestones.length; i++) {
      final milestone = streak.milestones[i];
      
      if (!milestone.isCompleted && streak.currentStreak >= milestone.targetDays) {
        // Marcar hito como completado
        final updatedMilestones = [...streak.milestones];
        updatedMilestones[i] = milestone.copyWith(
          isCompleted: true,
          completedDate: DateTime.now(),
        );
        
        final updatedStreak = streak.copyWith(milestones: updatedMilestones);
        
        await _saveStreak(updatedStreak);
        _streakCache[streak.type.name] = updatedStreak;
        
        // Otorgar puntos del hito
        if (milestone.pointsReward > 0) {
          await _awardPoints(milestone.pointsReward);
        }
        
        return StreakMilestoneUpdate(
          streakType: streak.type,
          milestone: updatedMilestones[i],
          streak: updatedStreak,
        );
      }
    }
    
    return null;
  }

  /// Otorgar puntos al usuario
  Future<void> _awardPoints(int points) async {
    if (_userStats == null) return;
    
    final newTotalPoints = _userStats!.totalPoints + points;
    final newExperiencePoints = _userStats!.experiencePoints + points;
    
    // Verificar subida de nivel
    UserLevel newLevel = _userStats!.level;
    UserLevel? potentialLevel = _userStats!.level.nextLevel();
    
    while (potentialLevel != null && newExperiencePoints >= potentialLevel.maxXp) {
      newLevel = potentialLevel;
      potentialLevel = newLevel.nextLevel();
    }
    
    _userStats = _userStats!.copyWith(
      totalPoints: newTotalPoints,
      experiencePoints: newExperiencePoints,
      level: newLevel,
    );
    
    await _saveUserStats();
    _userStatsUpdatesController.add(_userStats!);
  }

  /// Desbloquear características
  Future<void> _unlockFeatures(List<String> features) async {
    // Aquí se implementarían las integraciones con otras partes de la app
    // Por ejemplo: enviar eventos para desbloquear funcionalidades
    print('🔓 Desbloqueando características: ${features.join(', ')}');
  }

  /// Actualizar estadísticas del usuario
  Future<void> _updateUserStats(StreakType streakType, double? amount) async {
    if (_userStats == null) return;
    
    final newBestStreaks = Map<StreakType, int>.from(_userStats!.bestStreaks);
    final currentStreak = _streakCache[streakType.name];
    
    if (currentStreak != null) {
      newBestStreaks[streakType] = currentStreak.currentStreak;
    }
    
    final newExpensesLogged = _userStats!.expensesLogged + 
        (streakType == StreakType.expenseTracking ? 1 : 0);
    final newSavingsTracked = _userStats!.totalSavingsTracked + 
        (streakType == StreakType.dailySavings ? 1 : 0);
    final newTotalSavingsAmount = _userStats!.totalSavingsAmount + 
        (amount ?? 0);
    final newStreakDaysTotal = _userStats!.streakDaysTotal + 1;
    
    _userStats = _userStats!.copyWith(
      bestStreaks: newBestStreaks,
      expensesLogged: newExpensesLogged,
      totalSavingsTracked: newSavingsTracked,
      totalSavingsAmount: newTotalSavingsAmount,
      streakDaysTotal: newStreakDaysTotal,
    );
    
    await _saveUserStats();
    _userStatsUpdatesController.add(_userStats!);
  }

  /// Guardar racha en Firestore
  Future<void> _saveStreak(UserStreak streak) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('streaks')
          .doc(streak.type.name)
          .set(streak.toMap());
    } catch (e) {
      print('⚠️ Error guardando racha: $e');
      // En caso de error, guardar en cache local para sincronizar después
    }
  }

  /// Guardar actividad en historial
  Future<void> _saveActivity(StreakActivity activity) async {
    try {
      await _firestore
          .collection('usuarios')
          .doc(activity.userId)
          .collection('streakActivities')
          .doc(activity.id)
          .set(activity.toMap());
    } catch (e) {
      print('⚠️ Error guardando actividad: $e');
    }
  }

  /// Guardar estadísticas del usuario
  Future<void> _saveUserStats() async {
    final user = _auth.currentUser;
    if (user == null || _userStats == null) return;
    
    try {
      await _firestore
          .collection('userStats')
          .doc(user.uid)
          .set(_userStats!.toMap());
    } catch (e) {
      print('⚠️ Error guardando stats: $e');
    }
  }

  /// Realizar mantenimiento diario
  Future<void> _performDailyMaintenance() async {
    final now = DateTime.now();
    final updatedStreaks = <String, UserStreak>{};
    
    for (final entry in _streakCache.entries) {
      final streak = entry.value;
      
      // Verificar rachas que necesitan actualizarse
      if (streak.lastActivityDate != null) {
        final daysDiff = now.difference(streak.lastActivityDate!).inDays;
        
        // Si han pasado más de 1 día y la racha está activa, marcarla como rota
        if (daysDiff > 1 && streak.status == StreakStatus.active) {
          final brokenStreak = streak.breakStreak(reason: 'mantenimiento_diario');
          await _saveStreak(brokenStreak);
          updatedStreaks[streak.type.name] = brokenStreak;
        }
      }
    }
    
    // Actualizar cache
    _streakCache.addAll(updatedStreaks);
    
    if (updatedStreaks.isNotEmpty) {
      _streakUpdatesController.add(Map.from(_streakCache));
    }
  }

  /// Iniciar timer de mantenimiento
  void _startMaintenanceTimer() {
    // Ejecutar mantenimiento diario a las 00:00
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);
    
    Timer.periodic(const Duration(hours: 24), (timer) async {
      if (!_isOnline) return; // Solo ejecutar si está online
      
      await _performDailyMaintenance();
    });
  }

  /// Métodos públicos de consulta

  /// Obtener racha por tipo
  UserStreak? getStreak(StreakType streakType) {
    return _streakCache[streakType.name];
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
    return _achievements ?? [];
  }

  /// Obtener recompensas disponibles
  List<StreakReward> getAvailableRewards() {
    return _rewards ?? [];
  }

  /// Obtener logros desbloqueados
  List<StreakAchievement> getUnlockedAchievements() {
    if (_userStats == null) return [];
    
    return (_achievements ?? []).where((achievement) => 
        _userStats!.unlockedAchievements.contains(achievement.id)).toList();
  }

  /// Obtener badges del usuario
  List<Badge> getUserBadges() {
    return _userStats?.badges ?? [];
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
      print('❌ Error canjeando recompensa: $e');
      return false;
    }
  }

  /// Romper racha manualmente
  Future<void> breakStreak(StreakType streakType, {String? reason}) async {
    final streak = _streakCache[streakType.name];
    if (streak == null) return;

    final brokenStreak = streak.breakStreak(reason: reason);
    await _saveStreak(brokenStreak);
    _streakCache[streakType.name] = brokenStreak;

    _streakUpdatesController.add(Map.from(_streakCache));
  }

  /// Métodos de conveniencia para registrar actividades específicas

  /// Registrar ahorro diario
  Future<StreakActivityResult> recordDailySavings(double amount) {
    return recordActivity(StreakType.dailySavings, amount: amount);
  }

  /// Registrar gasto
  Future<StreakActivityResult> recordExpense(double amount, String description) {
    return recordActivity(StreakType.expenseTracking, amount: amount, description: description);
  }

  /// Registrar día sin gastos impulsivos
  Future<StreakActivityResult> recordNoImpulseDay() {
    return recordActivity(StreakType.noImpulseSpending);
  }

  /// Registrar día cocinando en casa
  Future<StreakActivityResult> recordHomeCooking(String description) {
    return recordActivity(StreakType.cookingAtHome, description: description);
  }

  /// Registrar uso de transporte público
  Future<StreakActivityResult> recordPublicTransport(String description) {
    return recordActivity(StreakType.publicTransport, description: description);
  }

  /// Registrar descuento encontrado
  Future<StreakActivityResult> recordDiscountFound(double savings) {
    return recordActivity(StreakType.discountFinder, amount: savings);
  }

  /// Generar reporte de rachas
  Future<Map<String, dynamic>> generateStreakReport() async {
    final report = {
      'generatedAt': DateTime.now().toIso8601String(),
      'userId': _auth.currentUser?.uid,
      'totalStreaks': _streakCache.length,
      'activeStreaks': _streakCache.values.where((s) => s.status == StreakStatus.active).length,
      'streaks': _streakCache.values.map((streak) => streak.toMap()).toList(),
      'userStats': _userStats?.toMap(),
      'achievements': getUnlockedAchievements().map((a) => a.toMap()).toList(),
      'badges': getUserBadges().map((b) => b.toMap()).toList(),
    };
    
    return report;
  }

  /// Liberar recursos
  void dispose() {
    _streakUpdatesController.close();
    _userStatsUpdatesController.close();
    _achievementUpdatesController.close();
    _milestoneUpdatesController.close();
    _dailyMaintenanceTimer?.cancel();
  }
}

/// Resultado de actividad de racha
class StreakActivityResult {
  final bool success;
  final String? error;
  final UserStreak? streak;
  final List<StreakAchievement> achievementsUnlocked;
  final StreakMilestoneUpdate? milestoneCompleted;

  const StreakActivityResult._({
    required this.success,
    this.error,
    this.streak,
    this.achievementsUnlocked = const [],
    this.milestoneCompleted,
  });

  factory StreakActivityResult.success({
    required UserStreak streak,
    List<StreakAchievement> achievementsUnlocked = const [],
    StreakMilestoneUpdate? milestoneCompleted,
  }) {
    return StreakActivityResult._(
      success: true,
      streak: streak,
      achievementsUnlocked: achievementsUnlocked,
      milestoneCompleted: milestoneCompleted,
    );
  }

  factory StreakActivityResult.failure(String error) {
    return StreakActivityResult._(success: false, error: error);
  }

  factory StreakActivityResult.alreadyRecorded() {
    return StreakActivityResult._(
      success: false,
      error: 'Ya registraste actividad para hoy',
    );
  }
}

/// Validación de actividad
class ActivityValidation {
  final bool isValid;
  final String reason;

  const ActivityValidation._({
    required this.isValid,
    required this.reason,
  });

  factory ActivityValidation.valid() {
    return const ActivityValidation._(isValid: true, reason: '');
  }

  factory ActivityValidation.invalid(String reason) {
    return ActivityValidation._(isValid: false, reason: reason);
  }
}

/// Actualización de hito completado
class StreakMilestoneUpdate {
  final StreakType streakType;
  final StreakMilestone milestone;
  final UserStreak streak;

  const StreakMilestoneUpdate({
    required this.streakType,
    required this.milestone,
    required this.streak,
  });
}