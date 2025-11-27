// Sistema de Rachas Mejorado - Modelos de Datos
// Versión: 2.0 - Con lógica robusta y persistencia Firebase

import 'dart:math' as math;

/// Enum para tipos de rachas financieras
enum StreakType {
  dailySavings('Ahorro Diario'),
  expenseTracking('Registro de Gastos'),
  noImpulseSpending('Sin Gastos Impulsivos'),
  cookingAtHome('Cocinar en Casa'),
  publicTransport('Transporte Público'),
  discountFinder('Cazador de Descuentos'),
  goalCompletion('Completar Metas'),
  budgetPlanning('Planificación de Presupuesto');

  const StreakType(this.displayName);
  final String displayName;
}

/// Enum para rareza de logros
enum Rarity {
  bronze('Bronce', 0xFFCD7F32),
  silver('Plata', 0xFFC0C0C0),
  gold('Oro', 0xFFFFD700),
  diamond('Diamante', 0xFFB9F2FF),
  legendary('Legendario', 0xFFFF6B35);

  const Rarity(this.displayName, this.colorHex);
  final String displayName;
  final int colorHex;
}

/// Logro desbloqueable por el usuario
class StreakAchievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final Rarity rarity;
  final int targetStreak;
  final int pointsReward;
  final List<String> unlockFeatures;
  final StreakType streakType;
  final String category;
  final DifficultyLevel difficulty;
  final List<String> requirements;
  final String badgeUrl;

  const StreakAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.targetStreak,
    required this.pointsReward,
    required this.unlockFeatures,
    required this.streakType,
    required this.category,
    required this.difficulty,
    required this.requirements,
    required this.badgeUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'rarity': rarity.name,
      'targetStreak': targetStreak,
      'pointsReward': pointsReward,
      'unlockFeatures': unlockFeatures,
      'streakType': streakType.name,
      'category': category,
      'difficulty': difficulty.name,
      'requirements': requirements,
      'badgeUrl': badgeUrl,
    };
  }

  factory StreakAchievement.fromMap(Map<String, dynamic> map) {
    return StreakAchievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      rarity: Rarity.values.firstWhere(
        (e) => e.name == map['rarity'],
        orElse: () => Rarity.bronze,
      ),
      targetStreak: map['targetStreak'] ?? 0,
      pointsReward: map['pointsReward'] ?? 0,
      unlockFeatures: List<String>.from(map['unlockFeatures'] ?? []),
      streakType: StreakType.values.firstWhere(
        (e) => e.name == map['streakType'],
        orElse: () => StreakType.dailySavings,
      ),
      category: map['category'] ?? '',
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      requirements: List<String>.from(map['requirements'] ?? []),
      badgeUrl: map['badgeUrl'] ?? '',
    );
  }

  String get rarityDisplayName => rarity.displayName;
  int get rarityColor => rarity.colorHex;
  String get displayName => title;
  String get streakTypeDisplayName => streakType.displayName;
}

/// Nivel de dificultad de los logros
enum DifficultyLevel {
  easy('Fácil'),
  medium('Medio'),
  hard('Difícil'),
  extreme('Extremo');

  const DifficultyLevel(this.displayName);
  final String displayName;
}

/// Racha del usuario con lógica robusta
class UserStreak {
  final String id;
  final String userId;
  final StreakType type;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final DateTime createdDate;
  final DateTime updatedDate;
  final List<DateTime> activityLog; // Historial completo de actividades
  final bool isActive;
  final StreakStatus status;
  final double averageStreakValue;
  final List<StreakMilestone> milestones;
  final DateTime? streakStartDate;
  final StreakTrend trend;

  const UserStreak({
    required this.id,
    required this.userId,
    required this.type,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    required this.createdDate,
    required this.updatedDate,
    required this.activityLog,
    this.isActive = true,
    this.status = StreakStatus.active,
    this.averageStreakValue = 0.0,
    required this.milestones,
    this.streakStartDate,
    this.trend = StreakTrend.stable,
  });

  /// Crear nueva racha
  factory UserStreak.create({
    required String userId,
    required StreakType type,
  }) {
    final now = DateTime.now();
    return UserStreak(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      currentStreak: 0,
      longestStreak: 0,
      createdDate: now,
      updatedDate: now,
      activityLog: [],
      isActive: true,
      status: StreakStatus.active,
      milestones: _generateMilestones(type),
      streakStartDate: null,
      trend: StreakTrend.stable,
    );
  }

  /// Agregar nueva actividad con validación robusta
  UserStreak addActivity(DateTime activityDate, {double? value, String? description}) {
    final normalizedDate = DateTime(activityDate.year, activityDate.month, activityDate.day);
    
    // Verificar si ya existe actividad en esta fecha
    if (activityLog.any((date) => 
        date.year == normalizedDate.year && 
        date.month == normalizedDate.month && 
        date.day == normalizedDate.day)) {
      return this; // Ya hay actividad hoy
    }

    // Verificar si es una actividad válida
    if (!_isValidActivity(normalizedDate, value, description)) {
      return this;
    }

    final newActivityLog = [...activityLog, normalizedDate]..sort();
    
    // Calcular nueva racha
    final newCurrentStreak = _calculateNewStreak(normalizedDate);
    final newLongestStreak = math.max(currentStreak, newCurrentStreak);
    
    // Calcular tendencia
    final newTrend = _calculateTrend(newActivityLog);
    
    // Actualizar estadísticas
    final newAverageValue = _calculateAverageValue(value);
    
    return copyWith(
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      lastActivityDate: normalizedDate,
      activityLog: newActivityLog,
      updatedDate: DateTime.now(),
      status: StreakStatus.active,
      averageStreakValue: newAverageValue,
      streakStartDate: currentStreak == 0 ? normalizedDate : streakStartDate,
      trend: newTrend,
    );
  }

  /// Romper racha con confirmación
  UserStreak breakStreak({String? reason}) {
    return copyWith(
      currentStreak: 0,
      updatedDate: DateTime.now(),
      status: StreakStatus.broken,
      trend: StreakTrend.declining,
    );
  }

  /// Pausar racha temporalmente
  UserStreak pauseStreak() {
    return copyWith(
      updatedDate: DateTime.now(),
      status: StreakStatus.paused,
    );
  }

  /// Reactivar racha
  UserStreak resumeStreak() {
    return copyWith(
      updatedDate: DateTime.now(),
      status: StreakStatus.active,
    );
  }

  /// Verificar si una fecha mantiene continuidad
  bool isConsecutiveDate(DateTime date) {
    if (activityLog.isEmpty) return true;
    
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final lastActivity = activityLog.last;
    final difference = normalizedDate.difference(lastActivity).inDays;
    
    return difference == 1; // Debe ser exactamente 1 día de diferencia
  }

  /// Calcular próximo hito
  int get nextMilestone {
    for (final milestone in milestones) {
      if (currentStreak < milestone.targetDays) {
        return milestone.targetDays;
      }
    }
    return milestones.last.targetDays;
  }

  /// Días restantes para próximo hito
  int get daysToNextMilestone {
    return nextMilestone - currentStreak;
  }

  /// Progreso al próximo hito (0.0 - 1.0)
  double get progressToNextMilestone {
    return currentStreak / nextMilestone;
  }

  /// Verificar si completó un hito
  bool hasReachedMilestone() {
    return milestones.any((milestone) => 
        milestone.targetDays <= currentStreak && !milestone.isCompleted);
  }

  /// Obtener hitos completados
  List<StreakMilestone> get completedMilestones {
    return milestones.where((milestone) => 
        milestone.targetDays <= currentStreak).toList();
  }

  /// Obtener hitos pendientes
  List<StreakMilestone> get pendingMilestones {
    return milestones.where((milestone) => 
        milestone.targetDays > currentStreak).toList();
  }

  /// Calcular racha promedio mensual
  double get monthlyAverageStreak {
    if (activityLog.isEmpty) return 0.0;
    
    // Agrupar por mes
    final monthlyGroups = <String, List<DateTime>>{};
    for (final date in activityLog) {
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthlyGroups[monthKey] = (monthlyGroups[monthKey] ?? [])..add(date);
    }
    
    // Calcular promedio mensual
    final monthlyStreaks = monthlyGroups.values.map((dates) => dates.length).toList();
    return monthlyStreaks.isEmpty ? 0.0 : 
        monthlyStreaks.reduce((a, b) => a + b) / monthlyStreaks.length;
  }

  /// Obtener estadísticas de rendimiento
  StreakPerformance get performance {
    final totalDays = activityLog.isEmpty ? 1 : 
        activityLog.last.difference(activityLog.first).inDays + 1;
    final consistencyRate = activityLog.length / totalDays;
    
    return StreakPerformance(
      consistencyRate: consistencyRate,
      monthlyAverage: monthlyAverageStreak,
      currentValue: averageStreakValue,
      trend: trend,
      status: status,
    );
  }

  UserStreak copyWith({
    String? id,
    String? userId,
    StreakType? type,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    DateTime? createdDate,
    DateTime? updatedDate,
    List<DateTime>? activityLog,
    bool? isActive,
    StreakStatus? status,
    double? averageStreakValue,
    List<StreakMilestone>? milestones,
    DateTime? streakStartDate,
    StreakTrend? trend,
  }) {
    return UserStreak(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      activityLog: activityLog ?? this.activityLog,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      averageStreakValue: averageStreakValue ?? this.averageStreakValue,
      milestones: milestones ?? this.milestones,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      trend: trend ?? this.trend,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': lastActivityDate?.toIso8601String(),
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate.toIso8601String(),
      'activityLog': activityLog.map((date) => date.toIso8601String()).toList(),
      'isActive': isActive,
      'status': status.name,
      'averageStreakValue': averageStreakValue,
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'streakStartDate': streakStartDate?.toIso8601String(),
      'trend': trend.name,
    };
  }

  factory UserStreak.fromMap(Map<String, dynamic> map) {
    return UserStreak(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: StreakType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => StreakType.dailySavings,
      ),
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastActivityDate: map['lastActivityDate'] != null 
          ? DateTime.parse(map['lastActivityDate']) 
          : null,
      createdDate: DateTime.parse(map['createdDate'] ?? DateTime.now().toIso8601String()),
      updatedDate: DateTime.parse(map['updatedDate'] ?? DateTime.now().toIso8601String()),
      activityLog: (map['activityLog'] as List<dynamic>?)
          ?.map((dateStr) => DateTime.parse(dateStr))
          .toList() ?? [],
      isActive: map['isActive'] ?? true,
      status: StreakStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StreakStatus.active,
      ),
      averageStreakValue: (map['averageStreakValue'] ?? 0.0).toDouble(),
      milestones: (map['milestones'] as List<dynamic>?)
          ?.map((data) => StreakMilestone.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
      streakStartDate: map['streakStartDate'] != null 
          ? DateTime.parse(map['streakStartDate']) 
          : null,
      trend: StreakTrend.values.firstWhere(
        (e) => e.name == map['trend'],
        orElse: () => StreakTrend.stable,
      ),
    );
  }

  // Métodos privados de cálculo

  int _calculateNewStreak(DateTime newDate) {
    if (activityLog.isEmpty) return 1;
    
    final normalizedDate = DateTime(newDate.year, newDate.month, newDate.day);
    return isConsecutiveDate(normalizedDate) ? currentStreak + 1 : 1;
  }

  StreakTrend _calculateTrend(List<DateTime> newActivityLog) {
    if (newActivityLog.length < 3) return StreakTrend.stable;

    final recentActivities = newActivityLog.sublist(newActivityLog.length > 5 ? newActivityLog.length - 5 : 0);
    final intervals = <int>[];

    for (int i = 1; i < recentActivities.length; i++) {
      intervals.add(recentActivities[i].difference(recentActivities[i-1]).inDays);
    }

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

    if (avgInterval < 1.5) return StreakTrend.improving;
    if (avgInterval > 2.5) return StreakTrend.declining;
    return StreakTrend.stable;
  }

  double _calculateAverageValue(double? newValue) {
    if (newValue == null || newValue <= 0) return averageStreakValue;
    
    if (activityLog.isEmpty) return newValue;
    
    // Calcular promedio ponderado
    final oldWeight = 0.7;
    final newWeight = 0.3;
    
    return (averageStreakValue * oldWeight) + (newValue * newWeight);
  }

  bool _isValidActivity(DateTime date, double? value, String? description) {
    // Validaciones específicas por tipo
    switch (type) {
      case StreakType.dailySavings:
        return value != null && value > 0;
      case StreakType.expenseTracking:
        return value != null && value > 0 && description != null && description.isNotEmpty;
      case StreakType.noImpulseSpending:
        return value == null || value <= 0; // No gasto = actividad válida
      case StreakType.cookingAtHome:
        return description?.toLowerCase().contains('casa') == true ||
               description?.toLowerCase().contains('cocinar') == true;
      case StreakType.publicTransport:
        return description?.toLowerCase().contains('bus') == true ||
               description?.toLowerCase().contains('transporte') == true;
      case StreakType.discountFinder:
        return value != null && value > 0; // Debe haber ahorrado dinero
      default:
        return true;
    }
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

/// Estado de la racha
enum StreakStatus {
  active('Activa'),
  paused('Pausada'),
  broken('Rota'),
  completed('Completada');

  const StreakStatus(this.displayName);
  final String displayName;
}

/// Tendencia de la racha
enum StreakTrend {
  improving('Mejorando'),
  stable('Estable'),
  declining('Declinando');

  const StreakTrend(this.displayName);
  final String displayName;
}

/// Hito dentro de una racha
class StreakMilestone {
  final int targetDays;
  final String title;
  final String icon;
  final Rarity rarity;
  final bool isCompleted;
  final DateTime? completedDate;
  final String? description;
  final int pointsReward;

  const StreakMilestone(
    this.targetDays,
    this.title,
    this.icon,
    this.rarity, {
    this.isCompleted = false,
    this.completedDate,
    this.description,
    this.pointsReward = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'targetDays': targetDays,
      'title': title,
      'icon': icon,
      'rarity': rarity.name,
      'isCompleted': isCompleted,
      'completedDate': completedDate?.toIso8601String(),
      'description': description,
      'pointsReward': pointsReward,
    };
  }

  factory StreakMilestone.fromMap(Map<String, dynamic> map) {
    return StreakMilestone(
      map['targetDays'] ?? 0,
      map['title'] ?? '',
      map['icon'] ?? '',
      Rarity.values.firstWhere(
        (e) => e.name == map['rarity'],
        orElse: () => Rarity.bronze,
      ),
      isCompleted: map['isCompleted'] ?? false,
      completedDate: map['completedDate'] != null 
          ? DateTime.parse(map['completedDate']) 
          : null,
      description: map['description'],
      pointsReward: map['pointsReward'] ?? 0,
    );
  }

  StreakMilestone copyWith({
    bool? isCompleted,
    DateTime? completedDate,
  }) {
    return StreakMilestone(
      targetDays,
      title,
      icon,
      rarity,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      description: description,
      pointsReward: pointsReward,
    );
  }
}

/// Rendimiento de la racha
class StreakPerformance {
  final double consistencyRate; // 0.0 - 1.0
  final double monthlyAverage;
  final double currentValue;
  final StreakTrend trend;
  final StreakStatus status;

  const StreakPerformance({
    required this.consistencyRate,
    required this.monthlyAverage,
    required this.currentValue,
    required this.trend,
    required this.status,
  });

  double get performanceScore {
    // Calcular puntuación de rendimiento (0-100)
    final consistencyScore = consistencyRate * 40;
    final trendScore = _getTrendScore() * 30;
    const statusScore = 30; // Bonus por mantener racha activa
    
    return (consistencyScore + trendScore + statusScore).clamp(0, 100);
  }

  double _getTrendScore() {
    switch (trend) {
      case StreakTrend.improving: return 1.0;
      case StreakTrend.stable: return 0.7;
      case StreakTrend.declining: return 0.3;
    }
  }

  String get performanceLevel {
    if (performanceScore >= 90) return 'Excelente';
    if (performanceScore >= 75) return 'Muy Bueno';
    if (performanceScore >= 60) return 'Bueno';
    if (performanceScore >= 40) return 'Regular';
    return 'Necesita Mejorar';
  }
}

/// Recompensa canjeable
class StreakReward {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int pointsCost;
  final List<String> benefits;
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final Rarity rarity;
  final String category;
  final bool isLimited;

  const StreakReward({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.pointsCost,
    required this.benefits,
    this.isUnlocked = false,
    this.unlockedDate,
    required this.rarity,
    required this.category,
    this.isLimited = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'pointsCost': pointsCost,
      'benefits': benefits,
      'isUnlocked': isUnlocked,
      'unlockedDate': unlockedDate?.toIso8601String(),
      'rarity': rarity.name,
      'category': category,
      'isLimited': isLimited,
    };
  }

  factory StreakReward.fromMap(Map<String, dynamic> map) {
    return StreakReward(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      pointsCost: map['pointsCost'] ?? 0,
      benefits: List<String>.from(map['benefits'] ?? []),
      isUnlocked: map['isUnlocked'] ?? false,
      unlockedDate: map['unlockedDate'] != null 
          ? DateTime.parse(map['unlockedDate']) 
          : null,
      rarity: Rarity.values.firstWhere(
        (e) => e.name == map['rarity'],
        orElse: () => Rarity.bronze,
      ),
      category: map['category'] ?? '',
      isLimited: map['isLimited'] ?? false,
    );
  }
}

/// Estadísticas del usuario
class UserStats {
  final String userId;
  final int totalPoints;
  final int totalAchievements;
  final Map<StreakType, int> bestStreaks;
  final List<String> unlockedRewards;
  final List<String> unlockedAchievements;
  final DateTime lastLoginDate;
  final int consecutiveLogins;
  final int totalSavingsTracked;
  final int expensesLogged;
  final double totalSavingsAmount;
  final int streakDaysTotal;
  final DateTime createdDate;
  final UserLevel level;
  final int experiencePoints;
  final List<Badge> badges;

  const UserStats({
    required this.userId,
    this.totalPoints = 0,
    this.totalAchievements = 0,
    required this.bestStreaks,
    required this.unlockedRewards,
    required this.unlockedAchievements,
    required this.lastLoginDate,
    this.consecutiveLogins = 0,
    this.totalSavingsTracked = 0,
    this.expensesLogged = 0,
    this.totalSavingsAmount = 0.0,
    this.streakDaysTotal = 0,
    required this.createdDate,
    required this.level,
    this.experiencePoints = 0,
    required this.badges,
  });

  UserStats copyWith({
    String? userId,
    int? totalPoints,
    int? totalAchievements,
    Map<StreakType, int>? bestStreaks,
    List<String>? unlockedRewards,
    List<String>? unlockedAchievements,
    DateTime? lastLoginDate,
    int? consecutiveLogins,
    int? totalSavingsTracked,
    int? expensesLogged,
    double? totalSavingsAmount,
    int? streakDaysTotal,
    DateTime? createdDate,
    UserLevel? level,
    int? experiencePoints,
    List<Badge>? badges,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      totalAchievements: totalAchievements ?? this.totalAchievements,
      bestStreaks: bestStreaks ?? this.bestStreaks,
      unlockedRewards: unlockedRewards ?? this.unlockedRewards,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      consecutiveLogins: consecutiveLogins ?? this.consecutiveLogins,
      totalSavingsTracked: totalSavingsTracked ?? this.totalSavingsTracked,
      expensesLogged: expensesLogged ?? this.expensesLogged,
      totalSavingsAmount: totalSavingsAmount ?? this.totalSavingsAmount,
      streakDaysTotal: streakDaysTotal ?? this.streakDaysTotal,
      createdDate: createdDate ?? this.createdDate,
      level: level ?? this.level,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'totalAchievements': totalAchievements,
      'bestStreaks': bestStreaks.map((key, value) => MapEntry(key.name, value)),
      'unlockedRewards': unlockedRewards,
      'unlockedAchievements': unlockedAchievements,
      'lastLoginDate': lastLoginDate.toIso8601String(),
      'consecutiveLogins': consecutiveLogins,
      'totalSavingsTracked': totalSavingsTracked,
      'expensesLogged': expensesLogged,
      'totalSavingsAmount': totalSavingsAmount,
      'streakDaysTotal': streakDaysTotal,
      'createdDate': createdDate.toIso8601String(),
      'level': level.name,
      'experiencePoints': experiencePoints,
      'badges': badges.map((b) => b.toMap()).toList(),
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      userId: map['userId'] ?? '',
      totalPoints: map['totalPoints'] ?? 0,
      totalAchievements: map['totalAchievements'] ?? 0,
      bestStreaks: Map<StreakType, int>.from(
        (map['bestStreaks'] as Map<String, dynamic>?)
            ?.map((key, value) => MapEntry(
                  StreakType.values.firstWhere((e) => e.name == key),
                  value,
                )) ?? {},
      ),
      unlockedRewards: List<String>.from(map['unlockedRewards'] ?? []),
      unlockedAchievements: List<String>.from(map['unlockedAchievements'] ?? []),
      lastLoginDate: DateTime.parse(map['lastLoginDate'] ?? DateTime.now().toIso8601String()),
      consecutiveLogins: map['consecutiveLogins'] ?? 0,
      totalSavingsTracked: map['totalSavingsTracked'] ?? 0,
      expensesLogged: map['expensesLogged'] ?? 0,
      totalSavingsAmount: (map['totalSavingsAmount'] ?? 0.0).toDouble(),
      streakDaysTotal: map['streakDaysTotal'] ?? 0,
      createdDate: DateTime.parse(map['createdDate'] ?? DateTime.now().toIso8601String()),
      level: UserLevel.values.firstWhere(
        (e) => e.name == map['level'],
        orElse: () => UserLevel.beginner,
      ),
      experiencePoints: map['experiencePoints'] ?? 0,
      badges: (map['badges'] as List<dynamic>?)
          ?.map((data) => Badge.fromMap(data as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

/// Nivel del usuario
enum UserLevel {
  beginner('Principiante', 0, 100),
  apprentice('Aprendiz', 100, 300),
  expert('Experto', 300, 600),
  master('Maestro', 600, 1000),
  legend('Leyenda', 1000, 2000);

  const UserLevel(this.displayName, this.minXp, this.maxXp);
  final String displayName;
  final int minXp;
  final int maxXp;

  bool hasLevel(int experiencePoints) {
    return experiencePoints >= minXp && experiencePoints < maxXp;
  }

  UserLevel? nextLevel() {
    switch (this) {
      case UserLevel.beginner:
        return UserLevel.apprentice;
      case UserLevel.apprentice:
        return UserLevel.expert;
      case UserLevel.expert:
        return UserLevel.master;
      case UserLevel.master:
        return UserLevel.legend;
      case UserLevel.legend:
        return null;
    }
  }
}

/// Insignia del usuario
class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final Rarity rarity;
  final DateTime earnedDate;
  final String category;
  final String criteria;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.earnedDate,
    required this.category,
    required this.criteria,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'rarity': rarity.name,
      'earnedDate': earnedDate.toIso8601String(),
      'category': category,
      'criteria': criteria,
    };
  }

  factory Badge.fromMap(Map<String, dynamic> map) {
    return Badge(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      rarity: Rarity.values.firstWhere(
        (e) => e.name == map['rarity'],
        orElse: () => Rarity.bronze,
      ),
      earnedDate: DateTime.parse(map['earnedDate'] ?? DateTime.now().toIso8601String()),
      category: map['category'] ?? '',
      criteria: map['criteria'] ?? '',
    );
  }
}

/// Evento de actividad para tracking
class StreakActivity {
  final String id;
  final String userId;
  final StreakType streakType;
  final DateTime timestamp;
  final double? value;
  final String? description;
  final String? metadata;
  final bool isValid;
  final String validationReason;

  const StreakActivity({
    required this.id,
    required this.userId,
    required this.streakType,
    required this.timestamp,
    this.value,
    this.description,
    this.metadata,
    this.isValid = true,
    this.validationReason = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'streakType': streakType.name,
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'description': description,
      'metadata': metadata,
      'isValid': isValid,
      'validationReason': validationReason,
    };
  }

  factory StreakActivity.fromMap(Map<String, dynamic> map) {
    return StreakActivity(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      streakType: StreakType.values.firstWhere(
        (e) => e.name == map['streakType'],
        orElse: () => StreakType.dailySavings,
      ),
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      value: map['value']?.toDouble(),
      description: map['description'],
      metadata: map['metadata'],
      isValid: map['isValid'] ?? true,
      validationReason: map['validationReason'] ?? '',
    );
  }
}