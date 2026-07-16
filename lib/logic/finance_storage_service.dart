import 'dart:convert';

import 'package:parentpeak/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parentpeak/logic/advanced_balance_provider.dart';
import 'package:parentpeak/logic/backend_api_client.dart';
import 'package:parentpeak/models/care_activity.dart';
import 'package:parentpeak/models/expense.dart';

class FinanceStorageSnapshot {
  const FinanceStorageSnapshot({
    required this.expenses,
    required this.careActivities,
    required this.savingsOpportunities,
  });

  final List<Expense> expenses;
  final List<CareActivity> careActivities;
  final List<SavingsOpportunity> savingsOpportunities;
}

class FinanceStorageService {
  FinanceStorageService({this.apiClient});

  final BackendApiClient? apiClient;
  String? lastSyncError;

  static const String _expensesKey = 'finance.expenses.v1';
  static const String _careKey = 'finance.care_activities.v1';
  static const String _savingsKey = 'finance.savings.v1';

  Future<FinanceStorageSnapshot> loadSnapshot() async {
    lastSyncError = null;

    if (apiClient != null) {
      try {
        final payload = await apiClient!.getJson(APIConfig.getBackendFinancePath());
        final parsed = _parseSnapshot(payload);
        await saveSnapshot(parsed, syncBackend: false);
        return parsed;
      } catch (e) {
        lastSyncError = _friendlySyncError(
          action: 'Server-Sync nicht verfügbar',
          error: e,
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();

    final expenses = _decodeList(
      raw: prefs.getString(_expensesKey),
      parser: (item) => Expense.fromMap(item),
    );
    final careActivities = _decodeList(
      raw: prefs.getString(_careKey),
      parser: (item) => CareActivity.fromMap(item),
    );
    final savings = _decodeList(
      raw: prefs.getString(_savingsKey),
      parser: (item) => SavingsOpportunity.fromMap(item),
    );

    return FinanceStorageSnapshot(
      expenses: expenses,
      careActivities: careActivities,
      savingsOpportunities: savings,
    );
  }

  Future<void> saveSnapshot(
    FinanceStorageSnapshot snapshot, {
    bool syncBackend = true,
  }) async {
    lastSyncError = null;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _expensesKey,
      jsonEncode(snapshot.expenses.map((item) => item.toMap()).toList()),
    );
    await prefs.setString(
      _careKey,
      jsonEncode(snapshot.careActivities.map((item) => item.toMap()).toList()),
    );
    await prefs.setString(
      _savingsKey,
      jsonEncode(snapshot.savingsOpportunities.map((item) => item.toMap()).toList()),
    );

    if (syncBackend && apiClient != null) {
      try {
        await apiClient!.postJsonAny(
          APIConfig.getBackendFinancePath(),
          {
            'expenses': snapshot.expenses.map((item) => item.toMap()).toList(),
            'careActivities':
                snapshot.careActivities.map((item) => item.toMap()).toList(),
            'savingsOpportunities':
                snapshot.savingsOpportunities.map((item) => item.toMap()).toList(),
          },
        );
      } catch (e) {
        lastSyncError = _friendlySyncError(
          action: 'Server-Sync nicht verfügbar',
          error: e,
        );
      }
    }
  }

  FinanceStorageSnapshot _parseSnapshot(dynamic payload) {
    if (payload is! Map) {
      return const FinanceStorageSnapshot(
        expenses: [],
        careActivities: [],
        savingsOpportunities: [],
      );
    }

    final rawExpenses = payload['expenses'];
    final rawCare = payload['careActivities'];
    final rawSavings = payload['savingsOpportunities'];

    return FinanceStorageSnapshot(
      expenses: _decodeFromAny(rawExpenses, (item) => Expense.fromMap(item)),
      careActivities:
          _decodeFromAny(rawCare, (item) => CareActivity.fromMap(item)),
      savingsOpportunities: _decodeFromAny(
        rawSavings,
        (item) => SavingsOpportunity.fromMap(item),
      ),
    );
  }

  List<T> _decodeFromAny<T>(
    dynamic raw,
    T Function(Map<String, dynamic> item) parser,
  ) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => parser(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<T> _decodeList<T>({
    required String? raw,
    required T Function(Map<String, dynamic> item) parser,
  }) {
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => parser(Map<String, dynamic>.from(item)))
        .toList();
  }

  String _friendlySyncError({
    required String action,
    required Object error,
  }) {
    final raw = error.toString().toLowerCase();

    if (raw.contains('handshakeexception') ||
        raw.contains('tls') ||
        raw.contains('ssl') ||
        raw.contains('certificate')) {
      return 'Lokaler Modus aktiv. Verbindung zum Server ist aktuell nicht sicher verfügbar.';
    }

    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('connection refused') ||
        raw.contains('timed out') ||
        raw.contains('timeout')) {
      return 'Lokaler Modus aktiv. Server derzeit nicht erreichbar.';
    }

    return '$action: $error';
  }
}
