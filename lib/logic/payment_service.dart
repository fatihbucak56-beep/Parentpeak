import 'package:trusted_circle_demo/models/payment_transaction.dart';

class PaymentService {
  static final List<PaymentTransaction> _transactions = [];

  // Initialisiere Stripe Payment (Placeholder)
  Future<Map<String, dynamic>> initiateStripePayment({
    required String eventId,
    required String hosterId,
    required double amount,
  }) async {
    await Future.delayed(Duration(milliseconds: 1000));

    // In echtem System würde hier Stripe-API aufgerufen
    return {
      'clientSecret': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'requires_payment_method',
    };
  }

  // Initialisiere PayPal Payment (Placeholder)
  Future<Map<String, dynamic>> initiatePayPalPayment({
    required String eventId,
    required String hosterId,
    required double amount,
  }) async {
    await Future.delayed(Duration(milliseconds: 1000));

    // In echtem System würde hier PayPal-API aufgerufen
    return {
      'approvalUrl':
          'https://paypal.com/mock/approve/${DateTime.now().millisecondsSinceEpoch}',
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // Bestätige Payment
  Future<PaymentTransaction> confirmPayment({
    required String eventId,
    required String hosterId,
    required double amount,
    required String paymentMethod,
    String? stripePaymentIntentId,
  }) async {
    await Future.delayed(Duration(milliseconds: 800));

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

    _transactions.add(transaction);
    return transaction;
  }

  // Hole Transaction Details
  Future<PaymentTransaction?> getTransaction(String transactionId) async {
    await Future.delayed(Duration(milliseconds: 200));

    try {
      return _transactions.firstWhere((t) => t.id == transactionId);
    } catch (e) {
      return null;
    }
  }

  // Hole alle Transactions für einen Host
  Future<List<PaymentTransaction>> getHostTransactions(String hosterId) async {
    await Future.delayed(Duration(milliseconds: 300));

    return _transactions.where((t) => t.hosterId == hosterId).toList();
  }

  // Hole Rückerstattung Optionen (Placeholder)
  Future<bool> refundPayment(String transactionId) async {
    await Future.delayed(Duration(milliseconds: 1000));

    try {
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        // Markiere als refunded
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
