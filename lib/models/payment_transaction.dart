class PaymentTransaction {
  final String id;
  final String eventId;
  final String hosterId;
  final double amount;
  final String status; // pending, completed, failed
  final String paymentMethod; // stripe, paypal
  final String? stripePaymentIntentId;
  final DateTime createdAt;
  final DateTime? completedAt;

  PaymentTransaction({
    required this.id,
    required this.eventId,
    required this.hosterId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.stripePaymentIntentId,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) =>
      PaymentTransaction(
        id: json['id'] as String,
        eventId: json['eventId'] as String,
        hosterId: json['hosterId'] as String,
        amount: (json['amount'] as num).toDouble(),
        status: json['status'] as String,
        paymentMethod: json['paymentMethod'] as String,
        stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'hosterId': hosterId,
        'amount': amount,
        'status': status,
        'paymentMethod': paymentMethod,
        'stripePaymentIntentId': stripePaymentIntentId,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };
}
