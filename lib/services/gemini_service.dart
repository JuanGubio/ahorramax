import 'package:google_generative_ai/google_generative_ai.dart';

/// Servicio centralizado para gestionar llamadas a Gemini API
/// Implementa cache, límites de frecuencia y optimizaciones de consumo
class GeminiService {
  static const String _apiKey = 'AIzaSyBxg6Ot1ZHCeXMnbHA8t9eVC9CL8aiJKWo';

  // Cache global para respuestas
  static final Map<String, _CachedResponse> _responseCache = {};

  // Modelo compartido para evitar múltiples inicializaciones
  static GenerativeModel? _model;

  // Estadísticas de uso
  static int _totalCalls = 0;
  static int _cachedResponses = 0;
  static DateTime? _lastApiCall;

  /// Obtiene el modelo Gemini (lazy initialization)
  static GenerativeModel get _getModel {
    _model ??= GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );
    return _model!;
  }

  /// Genera contenido con cache inteligente
  static Future<String> generateContent(
    List<Content> content, {
    String? cacheKey,
    Duration cacheDuration = const Duration(hours: 6),
    bool forceRefresh = false,
  }) async {
    // Si hay cache key, verificar cache
    if (cacheKey != null && !forceRefresh) {
      final cached = _responseCache[cacheKey];
      if (cached != null && !cached.isExpired(cacheDuration)) {
        _cachedResponses++;
        print('📋 Usando respuesta en cache para: $cacheKey');
        return cached.response;
      }
    }

    // Verificar límite de frecuencia (máximo 10 llamadas por minuto)
    if (_shouldThrottle()) {
      print('⏱️ Throttling: demasiadas llamadas recientes');
      throw Exception('Demasiadas llamadas a la API. Espera un momento.');
    }

    try {
      _totalCalls++;
      _lastApiCall = DateTime.now();

      print('🤖 Llamada ${cacheKey != null ? 'con cache' : 'sin cache'} - Total llamadas: $_totalCalls');

      final response = await _getModel.generateContent(content);

      if (response.text != null) {
        // Guardar en cache si hay cache key
        if (cacheKey != null) {
          _responseCache[cacheKey] = _CachedResponse(
            response: response.text!,
            timestamp: DateTime.now(),
          );
        }

        return response.text!;
      } else {
        throw Exception('Respuesta vacía de Gemini API');
      }
    } catch (e) {
      print('❌ Error en GeminiService: $e');
      throw e;
    }
  }

  /// Verifica si debe hacer throttling (máximo 10 llamadas por minuto)
  static bool _shouldThrottle() {
    if (_lastApiCall == null) return false;

    final now = DateTime.now();
    final timeSinceLastCall = now.difference(_lastApiCall!);

    // Si pasaron menos de 6 segundos desde la última llamada, throttle
    return timeSinceLastCall.inSeconds < 6;
  }

  /// Limpia cache expirado
  static void cleanExpiredCache() {
    final now = DateTime.now();
    _responseCache.removeWhere((key, cached) {
      final isExpired = cached.timestamp.add(const Duration(hours: 6)).isBefore(now);
      if (isExpired) {
        print('🗑️ Eliminando cache expirado: $key');
      }
      return isExpired;
    });
  }

  /// Obtiene estadísticas de uso
  static Map<String, dynamic> getStats() {
    return {
      'totalCalls': _totalCalls,
      'cachedResponses': _cachedResponses,
      'cacheSize': _responseCache.length,
      'lastApiCall': _lastApiCall?.toIso8601String(),
      'cacheHitRate': _totalCalls > 0 ? (_cachedResponses / _totalCalls * 100).round() : 0,
    };
  }

  /// Resetea estadísticas (para testing)
  static void resetStats() {
    _totalCalls = 0;
    _cachedResponses = 0;
    _lastApiCall = null;
    _responseCache.clear();
  }
}

/// Clase interna para cache de respuestas
class _CachedResponse {
  final String response;
  final DateTime timestamp;

  _CachedResponse({
    required this.response,
    required this.timestamp,
  });

  bool isExpired(Duration maxAge) {
    return timestamp.add(maxAge).isBefore(DateTime.now());
  }
}