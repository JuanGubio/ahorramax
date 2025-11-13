import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakTracker extends StatefulWidget {
  const StreakTracker({super.key});

  @override
  State<StreakTracker> createState() => _StreakTrackerState();
}

class _StreakTrackerState extends State<StreakTracker> with TickerProviderStateMixin {
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalDaysTracked = 0;
  DateTime? _lastTrackedDate;
  bool _trackedToday = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadStreakData();
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
    super.dispose();
  }

  Future<void> _loadStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentStreak = prefs.getInt('currentStreak') ?? 0;
      _bestStreak = prefs.getInt('bestStreak') ?? 0;
      _totalDaysTracked = prefs.getInt('totalDaysTracked') ?? 0;
      final lastTrackedString = prefs.getString('lastTrackedDate');
      if (lastTrackedString != null) {
        _lastTrackedDate = DateTime.parse(lastTrackedString);
      }
      _checkIfTrackedToday();
    });
  }

  void _checkIfTrackedToday() {
    if (_lastTrackedDate != null) {
      final today = DateTime.now();
      final lastTracked = DateTime(
        _lastTrackedDate!.year,
        _lastTrackedDate!.month,
        _lastTrackedDate!.day,
      );
      final todayNormalized = DateTime(today.year, today.month, today.day);

      if (lastTracked == todayNormalized) {
        _trackedToday = true;
      } else if (lastTracked.difference(todayNormalized).inDays == -1) {
        // Ayer - streak continua
        _trackedToday = false;
      } else {
        // Más de un día - streak se rompe
        _trackedToday = false;
        if (_currentStreak > 0) {
          _saveStreakData();
        }
      }
    }
  }

  Future<void> _saveStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentStreak', _currentStreak);
    await prefs.setInt('bestStreak', _bestStreak);
    await prefs.setInt('totalDaysTracked', _totalDaysTracked);
    if (_lastTrackedDate != null) {
      await prefs.setString('lastTrackedDate', _lastTrackedDate!.toIso8601String());
    }
  }

  Future<void> _trackToday() async {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    if (_trackedToday) return;

    setState(() {
      _trackedToday = true;
      _totalDaysTracked++;
      _lastTrackedDate = todayNormalized;

      if (_lastTrackedDate != null) {
        final yesterday = todayNormalized.subtract(const Duration(days: 1));
        final lastTrackedNormalized = DateTime(
          _lastTrackedDate!.year,
          _lastTrackedDate!.month,
          _lastTrackedDate!.day,
        );

        if (lastTrackedNormalized == yesterday) {
          _currentStreak++;
        } else {
          _currentStreak = 1;
        }
      } else {
        _currentStreak = 1;
      }

      if (_currentStreak > _bestStreak) {
        _bestStreak = _currentStreak;
      }
    });

    await _saveStreakData();
    _animationController.forward().then((_) => _animationController.reverse());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Excelente! Racha actual: $_currentStreak días'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Racha de Ahorro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStreakCard(
                    'Racha Actual',
                    _currentStreak.toString(),
                    Icons.whatshot,
                    Colors.orange,
                    _trackedToday,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStreakCard(
                    'Mejor Racha',
                    _bestStreak.toString(),
                    Icons.emoji_events,
                    Colors.amber,
                    false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Días totales rastreados: $_totalDaysTracked',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _trackedToday
                        ? '¡Ya registraste hoy!'
                        : '¿Registraste algún gasto o ingreso hoy?',
                    style: TextStyle(
                      fontSize: 14,
                      color: _trackedToday ? Colors.green.shade700 : Colors.grey.shade600,
                      fontWeight: _trackedToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _trackedToday ? null : _trackToday,
                icon: Icon(_trackedToday ? Icons.check_circle : Icons.track_changes),
                label: Text(_trackedToday ? '¡Ya registrado hoy!' : 'Registrar Día de Hoy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _trackedToday ? Colors.green : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _trackedToday ? 0 : 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mantén tu racha registrando gastos e ingresos diariamente',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(String title, String value, IconData icon, Color color, bool isCompleted) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isCompleted ? _scaleAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
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
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}