import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:trusted_circle_demo/config/api_config.dart';
import 'package:trusted_circle_demo/logic/backend_api_client.dart';
import 'package:trusted_circle_demo/logic/backend_service_factory.dart';
import 'package:trusted_circle_demo/models/payment_transaction.dart';

class PaymentService {
  PaymentService({BackendApiClient? apiClient})
      : _apiClient = apiClient ?? BackendServiceFactory.createApiClient();

  static final List<PaymentTransaction> _transactions = [];

  final BackendApiClient? _apiClient;
  String? lastSyncError;

  bool get isBackendEnabled => _apiClient != null;

  Never _throwBackendRequired(String context) {
    throw StateError(
      lastSyncError ??
          '$context fehlgeschlagen und Mock-Fallback ist in Release deaktiviert.',
    );
  }

  PaymentTransaction _storeLocalTransaction(PaymentTransaction transaction) {
    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    if (index == -1) {
      _transactions.add(transaction);
    } else {
      _transactions[index] = transaction;
    }
    return transaction;
  }

  PaymentTransaction _parseTransaction(Map<String, dynamic> raw) {
    return PaymentTransaction(
      id: (raw['id'] ?? '').toString(),
      eventId: (raw['eventId'] ?? '').toString(),
      hosterId: (raw['hosterId'] ?? '').toString(),
      amount: raw['amount'] is num
          ? (raw['amount'] as num).toDouble()
          : double.tryParse(raw['amount']?.toString() ?? '') ?? 0,
      status: (raw['status'] ?? 'completed').toString(),
      paymentMethod: (raw['paymentMethod'] ?? 'unknown').toString(),
      stripePaymentIntentId: raw['stripePaymentIntentId']?.toString(),
      createdAt: DateTime.tryParse((raw['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      completedAt: DateTime.tryParse((raw['completedAt'] ?? '').toString()),
    );
  }

  /// Presents the Stripe PaymentSheet and returns the clientSecret on success.
  /// In non-release builds without a backend the function falls back to a mock
  /// clientSecret so the flow can still be exercised in testing.
  Future<Map<String, dynamic>> initiateStripePayment({
    required String eventId,
    required String hosterId,
    required double amount,
  }) async {
    lastSyncError = null;

    if (kIsWeb || !APIConfig.isStripePaymentSheetSupportedPlatform()) {
      throw StateError(
        'Stripe PaymentSheet wird auf dieser Plattform nicht unterstuetzt.',
      );
    }

    String? clientSecret;

    if (_apiClient != null) {
      try {
        final payload = await _apiClient!.postJsonAny(
          APIConfig.getBackendPaymentsStripeInitPath(),
          {
            'eventId': eventId,
            'hosterId': hosterId,
            'amount': amount,
            'schemaVersion': APIConfig.getBackendApiVersion(),
          },
        );

        final data = payload is Map<String, dynamic>
            ? (payload['item'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(payload['item'] as Map)
                : payload)
            : <String, dynamic>{};
        clientSecret = data['clientSecret']?.toString();
      } catch (e) {
        lastSyncError = 'Stripe-Initialisierung fehlgeschlagen: $e';
        _throwBackendRequired('Stripe-Initialisierung');
      }
    }

    if (clientSecret == null) {
      _throwBackendRequired('Stripe-Initialisierung');
    }

    // Only show PaymentSheet for real Stripe client secrets (not mocks).
    if (!clientSecret.contains('_mock_')) {
      try {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Parentpeak',
            style: ThemeMode.system,
          ),
        );
        await Stripe.instance.presentPaymentSheet();
      } on StripeException catch (e) {
        lastSyncError = 'Stripe-Zahlung fehlgeschlagen: ${e.error.localizedMessage ?? e.toString()}';
        rethrow;
      }
    }

    return {
      'clientSecret': clientSecret,
      'status': clientSecret.contains('_mock_')
          ? 'mock_succeeded'
          : 'succeeded',
    };
  }

  Future<Map<String, dynamic>> initiatePayPalPayment({
    required String eventId,
    required String hosterId,
    required double amount,
  }) async {
    lastSyncError = null;

    if (_apiClient != null) {
      try {
        final payload = await _apiClient!.postJsonAny(
          APIConfig.getBackendPaymentsPayPalInitPath(),
          {
            'eventId': eventId,
            'hosterId': hosterId,
            'amount': amount,
            'schemaVersion': APIConfig.getBackendApiVersion(),
          },
        );

        if (payload is Map<String, dynamic>) {
          return payload['item'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(payload['item'] as Map)
              : payload;
        }
      } catch (e) {
        lastSyncError = 'PayPal-Initialisierung fehlgeschlagen: $e';
        _throwBackendRequired('PayPal-Initialisierung');
      }
    }

    _throwBackendRequired('PayPal-Initialisierung');
  }

  Future<PaymentTransaction> confirmPayment({
    required String eventId,
    required String hosterId,
    required double amount,
    required String paymentMethod,
    String? stripePaymentIntentId,
    String? providerTransactionRef,
    String initialStatus = 'pending',
    bool providerVerified = false,
  }) async {
    lastSyncError = null;

    if (_apiClient != null) {
      try {
        final payload = await _apiClient!.postJsonAny(
          APIConfig.getBackendPaymentsConfirmPath(),
          {
            'eventId': eventId,
            'hosterId': hosterId,
            'amount': amount,
            'paymentMethod': paymentMethod,
            'stripePaymentIntentId': stripePaymentIntentId,
            'providerTransactionRef': providerTransactionRef,
            'status': initialStatus,
            'providerVerified': providerVerified,
            'schemaVersion': APIConfig.getBackendApiVersion(),
          },
        );

        final raw = payload is Map<String, dynamic>
            ? (payload['item'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(payload['item'] as Map)
                : payload)
            : <String, dynamic>{};
        if (raw.isNotEmpty) {
          return _storeLocalTransaction(_parseTransaction(raw));
        }
      } catch (e) {
        lastSyncError = 'Zahlungsbestaetigung fehlgeschlagen: $e';
        _throwBackendRequired('Zahlungsbestaetigung');
      }
    }

    _throwBackendRequired('Zahlungsbestaetigung');
  }

  Future<PaymentTransaction?> reportProviderEvent({
    required String transactionId,
    required String provider,
    required String providerTransactionRef,
    required String status,
    required bool verified,
  }) async {
    lastSyncError = null;

    if (_apiClient != null) {
      try {
        final payload = await _apiClient!.postJsonAny(
          APIConfig.getBackendPaymentsProviderEventsPath(),
          {
            'transactionId': transactionId,
            'provider': provider,
            'providerTransactionRef': providerTransactionRef,
            'status': status,
            'verified': verified,
            'schemaVersion': APIConfig.getBackendApiVersion(),
          },
        );

        final raw = payload is Map<String, dynamic>
            ? (payload['item'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(payload['item'] as Map)
                : payload)
            : <String, dynamic>{};
        if (raw.isNotEmpty) {
          return _storeLocalTransaction(_parseTransaction(raw));
        }
        return null;
      } catch (e) {
        lastSyncError = 'Provider-Event konnte nicht verarbeitet werden: $e';
        _throwBackendRequired('Provider-Event Verarbeitung');
      }
    }

    _throwBackendRequired('Provider-Event Verarbeitung');
  }

  Future<PaymentTransaction?> getTransaction(String transactionId) async {
    lastSyncError = null;

    if (_apiClient != null) {
      try {
        final payload = await _apiClient!.getJson(
          '${APIConfig.getBackendPaymentsTransactionsPath()}/$transactionId',
        );
        final raw = payload is Map<String, dynamic>
            ? (payload['item'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(payload['item'] as Map)
                : payload)
            : <String, dynamic>{};
        if (raw.isNotEmpty) {
          return _storeLocalTransaction(_parseTransaction(raw));
        }
      } catch (e) {
        lastSyncError = 'Transaktion konnte nicht geladen werden: $e';
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));

    try {
      return _transactions
          .firstWhere((transaction) => transaction.id == transactionId);
    } catch (e) {
      debugPrint('PaymentService.getTransaction(): local lookup failed: $e');
      return null;
    }
  }

  Future<List<PaymentTransaction>> getHostTransactions(String hosterId) async {
    lastSyncError = null;

    if (_apiClient != null) {
      try {
        final payload = await _apiClient!.getJson(
          '${APIConfig.getBackendPaymentsHostPath()}/$hosterId',
        );
        if (payload is Map<String, dynamic> && payload['items'] is List) {
          final items = (payload['items'] as List)
              .whereType<Map>()
              .map((item) => _parseTransaction(Map<String, dynamic>.from(item)))
              .toList();
          for (final transaction in items) {
            _storeLocalTransaction(transaction);
          }
          return items;
        }
      } catch (e) {
        lastSyncError = 'Host-Transaktionen konnten nicht geladen werden: $e';
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    return _transactions.where((transaction) => transaction.hosterId == hosterId).toList();
  }

  Future<bool> refundPayment(String transactionId) async {
    lastSyncError = null;

    if (_apiClient != null) {
      try {
        await _apiClient!.postJsonAny(
          '${APIConfig.getBackendPaymentsTransactionsPath()}/$transactionId/refund',
          {'schemaVersion': APIConfig.getBackendApiVersion()},
        );
        return true;
      } catch (e) {
        lastSyncError = 'Rueckerstattung fehlgeschlagen: $e';
      }
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    final index = _transactions.indexWhere((transaction) => transaction.id == transactionId);
    return index != -1;
  }
}