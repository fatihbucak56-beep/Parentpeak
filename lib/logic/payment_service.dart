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

  Future<Map<String, dynamic>> initiateStripePayment({
    required String eventId,
    required String hosterId,
    required double amount,
  }) async {
    lastSyncError = null;

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

        if (payload is Map<String, dynamic>) {
          return payload['item'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(payload['item'] as Map)
              : payload;
        }
      } catch (e) {
        lastSyncError = 'Stripe-Initialisierung fehlgeschlagen: $e';
      }
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    return {
      'clientSecret': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'requires_payment_method',
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
      }
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    return {
      'approvalUrl':
          'https://paypal.com/mock/approve/${DateTime.now().millisecondsSinceEpoch}',
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  Future<PaymentTransaction> confirmPayment({
    required String eventId,
    required String hosterId,
    required double amount,
    required String paymentMethod,
    String? stripePaymentIntentId,
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
      }
    }

    await Future.delayed(const Duration(milliseconds: 800));

    final transaction = PaymentTransaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      eventId: eventId,
      hosterId: hosterId,
      amount: amount,
      status: 'completed',
      paymentMethod: paymentMethod,
      stripePaymentIntentId: stripePaymentIntentId,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );

    return _storeLocalTransaction(transaction);
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
      return _transactions.firstWhere((transaction) => transaction.id == transactionId);
    } catch (_) {
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