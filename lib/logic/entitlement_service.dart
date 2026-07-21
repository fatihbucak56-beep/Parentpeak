import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parentpeak/config/feature_flags.dart';
import 'package:parentpeak/logic/auth_service.dart';

/// Verwaltet Freemium-Berechtigungen und Usage-Limits.
///
/// Architektur:
///   - Prüft ob ein User Premium oder Free ist (via AuthService)
///   - Tracked tägliche Nutzung von limitierten Free-Features
///   - Gibt klare Antworten: "darfst du" / "Limit erreicht" / "nur Premium"
///
/// Free-Tier Limits:
///   - KI Elternberatung: 3 Nachrichten pro Tag
///   - Impulse & Entwicklung: Basis-Impulse sichtbar, Detail-Inhalte Premium
///   - Kalender: Voll nutzbar
///   - Organisation: Voll nutzbar
///
/// Premium: Alles unbegrenzt + Community-Features + Marktplatz
class EntitlementService extends ChangeNotifier {
  EntitlementService._();
  static final EntitlementService instance = EntitlementService._();

  // ─── Konfiguration ─────────────────────────────────────────────────────────

  /// Tägliches Limit für KI-Chat im Free-Tier.
  static const int freeTierDailyChatLimit = 3;

  /// Tägliches Limit für detaillierte Impulse-Inhalte im Free-Tier.
  static const int freeTierDailyImpulseDetailLimit = 1;

  // ─── State ─────────────────────────────────────────────────────────────────

  bool _initialized = false;
  SubscriptionTier _currentTier = SubscriptionTier.free;
  SubscriptionTier get currentTier => _currentTier;

  bool get isPremium => _currentTier == SubscriptionTier.premium;
  bool get isFree => _currentTier == SubscriptionTier.free;

  // ─── Initialisierung ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    await _refreshTierFromAuth();
    _initialized = true;
  }

  /// Aktualisiert den Tier basierend auf dem aktuellen Auth-Status.
  Future<void> _refreshTierFromAuth() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _currentTier = SubscriptionTier.free;
    } else if (user.isPremium || user.hasFullAccess) {
      _currentTier = SubscriptionTier.premium;
    } else {
      _currentTier = SubscriptionTier.free;
    }
    notifyListeners();
  }

  /// Wird nach Login/Logout/Subscription-Änderung aufgerufen.
  Future<void> refreshEntitlements() async {
    await _refreshTierFromAuth();
  }

  // ─── Berechtigungsprüfungen ────────────────────────────────────────────────

  /// Prüft ob der User ein bestimmtes Feature nutzen darf.
  ///
  /// Gibt ein [EntitlementResult] zurück mit Status und Grund.
  Future<EntitlementResult> checkAccess(String featureId) async {
    final featureFlags = FeatureFlagService.instance;

    // Feature muss überhaupt aktiviert sein
    if (!featureFlags.isEnabled(featureId)) {
      if (featureFlags.isComingSoon(featureId)) {
        return EntitlementResult.comingSoon(featureId);
      }
      return EntitlementResult.unavailable(featureId);
    }

    // Premium User haben überall Zugang
    if (isPremium) {
      return EntitlementResult.granted(featureId);
    }

    // Free-Tier: Prüfe ob das Feature überhaupt free verfügbar ist
    if (!featureFlags.isAvailableInFreeTier(featureId)) {
      return EntitlementResult.premiumRequired(
        featureId,
        reason: _getPremiumUpgradeReason(featureId),
      );
    }

    // Free-Tier: Prüfe Usage-Limits
    return await _checkUsageLimit(featureId);
  }

  /// Schnelle synchrone Prüfung ob ein Feature grundsätzlich zugänglich ist.
  /// Für UI-Rendering (zeige Lock-Icon oder nicht).
  bool canAccessSync(String featureId) {
    final featureFlags = FeatureFlagService.instance;

    if (!featureFlags.isEnabled(featureId)) return false;
    if (isPremium) return true;
    return featureFlags.isAvailableInFreeTier(featureId);
  }

  // ─── Usage-Tracking ────────────────────────────────────────────────────────

  /// Zeichnet eine Nutzung auf (z.B. eine KI-Chat-Nachricht).
  Future<void> recordUsage(String featureId) async {
    if (isPremium) return; // Premium trackt nicht

    final prefs = await SharedPreferences.getInstance();
    final key = _dailyUsageKey(featureId);
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
    notifyListeners();
  }

  /// Gibt die verbleibende Nutzung für heute zurück.
  /// Null = unbegrenzt (Premium oder kein Limit definiert).
  Future<int?> getRemainingUsage(String featureId) async {
    if (isPremium) return null;

    final limit = _getDailyLimit(featureId);
    if (limit == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final key = _dailyUsageKey(featureId);
    final used = prefs.getInt(key) ?? 0;
    final remaining = limit - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// Gibt die heutige Nutzung zurück.
  Future<int> getTodayUsage(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dailyUsageKey(featureId);
    return prefs.getInt(key) ?? 0;
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────

  int? _getDailyLimit(String featureId) {
    switch (featureId) {
      case 'ki_elternberatung':
        return freeTierDailyChatLimit;
      case 'impulse_entwicklung':
        return freeTierDailyImpulseDetailLimit;
      default:
        return null;
    }
  }

  Future<EntitlementResult> _checkUsageLimit(String featureId) async {
    final limit = _getDailyLimit(featureId);
    if (limit == null) {
      return EntitlementResult.granted(featureId);
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _dailyUsageKey(featureId);
    final used = prefs.getInt(key) ?? 0;

    if (used >= limit) {
      return EntitlementResult.limitReached(
        featureId,
        dailyLimit: limit,
        used: used,
      );
    }

    return EntitlementResult.granted(
      featureId,
      remainingToday: limit - used,
    );
  }

  String _dailyUsageKey(String featureId) {
    final now = DateTime.now();
    final day =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'entitlement.usage.$featureId.$day';
  }

  String _getPremiumUpgradeReason(String featureId) {
    switch (featureId) {
      case 'eltern_match':
        return 'Finde gleichgesinnte Eltern in deiner Nähe';
      case 'events_aktivitaeten':
        return 'Entdecke und erstelle Events für Familien';
      case 'verschenkmarkt':
        return 'Verschenke und finde Kindersachen in deiner Nähe';
      case 'gemeinsam_satt':
        return 'Teile Mahlzeiten und spare mit anderen Familien';
      case 'finanzen_budget':
        return 'Behalte Familienausgaben im Blick und spare smarter';
      default:
        return 'Schalte alle Funktionen frei mit Premium';
    }
  }
}

// ─── Ergebnis-Typ ──────────────────────────────────────────────────────────────

enum EntitlementStatus {
  /// Zugang gewährt.
  granted,

  /// Feature noch nicht verfügbar ("Coming Soon").
  comingSoon,

  /// Feature komplett nicht verfügbar (hidden).
  unavailable,

  /// Nur für Premium-User zugänglich.
  premiumRequired,

  /// Tägliches Limit erreicht.
  limitReached,
}

class EntitlementResult {
  final String featureId;
  final EntitlementStatus status;
  final String? reason;
  final int? dailyLimit;
  final int? used;
  final int? remainingToday;

  const EntitlementResult._({
    required this.featureId,
    required this.status,
    this.reason,
    this.dailyLimit,
    this.used,
    this.remainingToday,
  });

  factory EntitlementResult.granted(String featureId, {int? remainingToday}) {
    return EntitlementResult._(
      featureId: featureId,
      status: EntitlementStatus.granted,
      remainingToday: remainingToday,
    );
  }

  factory EntitlementResult.comingSoon(String featureId) {
    return EntitlementResult._(
      featureId: featureId,
      status: EntitlementStatus.comingSoon,
      reason: 'Dieses Feature kommt bald!',
    );
  }

  factory EntitlementResult.unavailable(String featureId) {
    return EntitlementResult._(
      featureId: featureId,
      status: EntitlementStatus.unavailable,
    );
  }

  factory EntitlementResult.premiumRequired(
    String featureId, {
    String? reason,
  }) {
    return EntitlementResult._(
      featureId: featureId,
      status: EntitlementStatus.premiumRequired,
      reason: reason,
    );
  }

  factory EntitlementResult.limitReached(
    String featureId, {
    required int dailyLimit,
    required int used,
  }) {
    return EntitlementResult._(
      featureId: featureId,
      status: EntitlementStatus.limitReached,
      dailyLimit: dailyLimit,
      used: used,
      reason:
          'Du hast dein tägliches Limit erreicht ($used/$dailyLimit). Upgrade auf Premium für unbegrenzten Zugang.',
    );
  }

  bool get isGranted => status == EntitlementStatus.granted;
  bool get isBlocked =>
      status != EntitlementStatus.granted;
}
