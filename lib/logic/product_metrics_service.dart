import 'package:shared_preferences/shared_preferences.dart';

class ProductMetricsService {
  ProductMetricsService._();

  static final ProductMetricsService instance = ProductMetricsService._();

  String _todayKey() {
    final now = DateTime.now().toLocal();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  Future<void> _incrementCounter(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  Future<void> _setLastPayload(String event, Map<String, String> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'metrics.last_payload.$event';
    final normalized = payload.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(';');
    await prefs.setString(key, normalized);
  }

  Future<bool> _markUniquePerDay(String event, String fingerprint) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'metrics.unique.$event.${_todayKey()}.$fingerprint';
    final alreadyMarked = prefs.getBool(key) ?? false;
    if (alreadyMarked) {
      return false;
    }
    await prefs.setBool(key, true);
    return true;
  }

  Future<void> recordHomeQuickCheckCtaTap({String? userId}) async {
    const event = 'home_quickcheck_cta_tap';
    await _incrementCounter('metrics.total.$event');
    await _incrementCounter('metrics.daily.$event.${_todayKey()}');

    final fingerprint = userId == null || userId.trim().isEmpty
        ? 'anonymous'
        : userId.trim();
    final isUnique = await _markUniquePerDay(event, fingerprint);
    if (isUnique) {
      await _incrementCounter('metrics.daily_unique.$event.${_todayKey()}');
    }

    await _setLastPayload(event, {
      'fingerprint': fingerprint,
      'uniqueToday': isUnique ? '1' : '0',
    });
  }

  Future<void> recordHomeDevelopmentDirectCtaTap({String? userId}) async {
    const event = 'home_development_direct_cta_tap';
    await _incrementCounter('metrics.total.$event');
    await _incrementCounter('metrics.daily.$event.${_todayKey()}');

    final fingerprint = userId == null || userId.trim().isEmpty
        ? 'anonymous'
        : userId.trim();
    final isUnique = await _markUniquePerDay(event, fingerprint);
    if (isUnique) {
      await _incrementCounter('metrics.daily_unique.$event.${_todayKey()}');
    }

    await _setLastPayload(event, {
      'fingerprint': fingerprint,
      'uniqueToday': isUnique ? '1' : '0',
    });
  }

  Future<void> recordHomeFallbackRouteTap({
    required String from,
    required String to,
    String? userId,
  }) async {
    const event = 'home_fallback_route_tap';
    await _incrementCounter('metrics.total.$event');
    await _incrementCounter('metrics.daily.$event.${_todayKey()}');

    final source = from.trim().toLowerCase();
    final target = to.trim().toLowerCase();
    final fingerprint = userId == null || userId.trim().isEmpty
        ? 'anonymous'
        : userId.trim();
    final uniqueKey = '$fingerprint-$source-$target';
    final isUnique = await _markUniquePerDay(event, uniqueKey);
    if (isUnique) {
      await _incrementCounter('metrics.daily_unique.$event.${_todayKey()}');
    }

    await _setLastPayload(event, {
      'fingerprint': fingerprint,
      'from': source,
      'to': target,
      'uniqueToday': isUnique ? '1' : '0',
    });
  }

  Future<void> recordChatFallbackRouteTap({
    required String from,
    required String to,
    String? userId,
  }) async {
    const event = 'chat_fallback_route_tap';
    await _incrementCounter('metrics.total.$event');
    await _incrementCounter('metrics.daily.$event.${_todayKey()}');

    final source = from.trim().toLowerCase();
    final target = to.trim().toLowerCase();
    final fingerprint = userId == null || userId.trim().isEmpty
        ? 'anonymous'
        : userId.trim();
    final uniqueKey = '$fingerprint-$source-$target';
    final isUnique = await _markUniquePerDay(event, uniqueKey);
    if (isUnique) {
      await _incrementCounter('metrics.daily_unique.$event.${_todayKey()}');
    }

    await _setLastPayload(event, {
      'fingerprint': fingerprint,
      'from': source,
      'to': target,
      'uniqueToday': isUnique ? '1' : '0',
    });
  }

  Future<void> recordWeeklyImpulseFallbackRouteTap({
    required String from,
    required String to,
    String? userId,
  }) async {
    const event = 'weekly_impulse_fallback_route_tap';
    await _incrementCounter('metrics.total.$event');
    await _incrementCounter('metrics.daily.$event.${_todayKey()}');

    final source = from.trim().toLowerCase();
    final target = to.trim().toLowerCase();
    final fingerprint = userId == null || userId.trim().isEmpty
        ? 'anonymous'
        : userId.trim();
    final uniqueKey = '$fingerprint-$source-$target';
    final isUnique = await _markUniquePerDay(event, uniqueKey);
    if (isUnique) {
      await _incrementCounter('metrics.daily_unique.$event.${_todayKey()}');
    }

    await _setLastPayload(event, {
      'fingerprint': fingerprint,
      'from': source,
      'to': target,
      'uniqueToday': isUnique ? '1' : '0',
    });
  }

  Future<void> recordCalendarFallbackRouteTap({
    required String from,
    required String to,
    String? userId,
  }) async {
    const event = 'calendar_fallback_route_tap';
    await _incrementCounter('metrics.total.$event');
    await _incrementCounter('metrics.daily.$event.${_todayKey()}');

    final source = from.trim().toLowerCase();
    final target = to.trim().toLowerCase();
    final fingerprint = userId == null || userId.trim().isEmpty
        ? 'anonymous'
        : userId.trim();
    final uniqueKey = '$fingerprint-$source-$target';
    final isUnique = await _markUniquePerDay(event, uniqueKey);
    if (isUnique) {
      await _incrementCounter('metrics.daily_unique.$event.${_todayKey()}');
    }

    await _setLastPayload(event, {
      'fingerprint': fingerprint,
      'from': source,
      'to': target,
      'uniqueToday': isUnique ? '1' : '0',
    });
  }

  Future<void> recordUtilityFallbackRouteTap({
    required String surface,
    required String from,
    required String to,
    String? userId,
  }) async {
    const event = 'utility_fallback_route_tap';
    await _incrementCounter('metrics.total.$event');
    await _incrementCounter('metrics.daily.$event.${_todayKey()}');

    final normalizedSurface = surface.trim().toLowerCase();
    final source = from.trim().toLowerCase();
    final target = to.trim().toLowerCase();
    final fingerprint = userId == null || userId.trim().isEmpty
        ? 'anonymous'
        : userId.trim();
    final uniqueKey = '$fingerprint-$normalizedSurface-$source-$target';
    final isUnique = await _markUniquePerDay(event, uniqueKey);
    if (isUnique) {
      await _incrementCounter('metrics.daily_unique.$event.${_todayKey()}');
    }

    await _setLastPayload(event, {
      'fingerprint': fingerprint,
      'surface': normalizedSurface,
      'from': source,
      'to': target,
      'uniqueToday': isUnique ? '1' : '0',
    });
  }

  Future<void> recordShortCheckCompleted({
    required String childId,
    required int phaseIndex,
    required String focusDomainId,
    required int answeredCount,
  }) async {
    const event = 'shortcheck_completed';
    await _incrementCounter('metrics.total.$event');
    await _incrementCounter('metrics.daily.$event.${_todayKey()}');

    final fingerprint = '$childId-p$phaseIndex-$focusDomainId';
    final isUnique = await _markUniquePerDay(event, fingerprint);
    if (isUnique) {
      await _incrementCounter('metrics.daily_unique.$event.${_todayKey()}');
    }

    await _setLastPayload(event, {
      'childId': childId,
      'phaseIndex': '$phaseIndex',
      'focusDomainId': focusDomainId,
      'answeredCount': '$answeredCount',
      'uniqueToday': isUnique ? '1' : '0',
    });
  }
}
