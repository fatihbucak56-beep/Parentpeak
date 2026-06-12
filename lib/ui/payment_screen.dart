import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/models/meetup_event.dart';
import 'package:trusted_circle_demo/logic/payment_service.dart';
import 'package:trusted_circle_demo/logic/event_service.dart';

class PaymentScreen extends StatefulWidget {
  final MeetupEvent event;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.event,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _paymentService = PaymentService();
  final _eventService = EventService();

  String _selectedPaymentMethod = 'stripe'; // stripe oder paypal
  bool _isProcessing = false;
  bool _agreeToTerms = false;

  Future<void> _processPayment() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte stimme den Bedingungen zu')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simuliere Payment-Prozess
      if (_selectedPaymentMethod == 'stripe') {
        await _paymentService.initiateStripePayment(
          eventId: widget.event.id,
          hosterId: widget.event.hosterId,
          amount: widget.amount,
        );
      } else {
        await _paymentService.initiatePayPalPayment(
          eventId: widget.event.id,
          hosterId: widget.event.hosterId,
          amount: widget.amount,
        );
      }

      // Bestätige Payment
      final transaction = await _paymentService.confirmPayment(
        eventId: widget.event.id,
        hosterId: widget.event.hosterId,
        amount: widget.amount,
        paymentMethod: _selectedPaymentMethod,
      );

      // Erstelle das Event
      final eventWithPayment = MeetupEvent(
        id: widget.event.id,
        hosterId: widget.event.hosterId,
        title: widget.event.title,
        description: widget.event.description,
        category: widget.event.category,
        ageGroups: widget.event.ageGroups,
        location: widget.event.location,
        latitude: widget.event.latitude,
        longitude: widget.event.longitude,
        eventDate: widget.event.eventDate,
        createdAt: widget.event.createdAt,
        paymentDate: DateTime.now(),
        maxParticipants: widget.event.maxParticipants,
        photoUrl: widget.event.photoUrl,
        status: EventStatus.active,
        price: widget.event.price,
        visibility: widget.event.visibility,
        shareRadiusKm: widget.event.shareRadiusKm,
      );

      await _eventService.createEvent(eventWithPayment);

      if (mounted) {
        // Zeige Erfolgs-Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: Icon(Icons.check_circle, color: Colors.green[700], size: 48),
            title: const Text('Zahlung erfolgreich!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Deine Aktivität "${widget.event.title}" ist nun live!',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Transaktions-ID: ${transaction.id}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Betrag: ${transaction.amount.toStringAsFixed(2)} €',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Fertig'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Zahlungsfehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isProcessing,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Zahlungsbestätigung'),
          elevation: 0,
          automaticallyImplyLeading: !_isProcessing,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bestellübersicht',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Aktivität: ${widget.event.title}'),
                        const Text(''),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Veröffentlichungsgebühr'),
                        Text(
                          '${widget.amount.toStringAsFixed(2)} €',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Zahlungsmethode
              Text(
                'Zahlungsmethode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),

              // Stripe Option
              Card(
                child: RadioListTile<String>(
                  title: Row(
                    children: [
                      const Icon(Icons.credit_card, size: 20),
                      const SizedBox(width: 8),
                      const Text('Stripe'),
                    ],
                  ),
                  subtitle: const Text('Visa, Mastercard, etc.'),
                  value: 'stripe',
                  groupValue: _selectedPaymentMethod,
                  onChanged: _isProcessing
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedPaymentMethod = value);
                          }
                        },
                ),
              ),
              const SizedBox(height: 12),

              // PayPal Option
              Card(
                child: RadioListTile<String>(
                  title: Row(
                    children: [
                      const Icon(Icons.payment, size: 20),
                      const SizedBox(width: 8),
                      const Text('PayPal'),
                    ],
                  ),
                  subtitle: const Text('Bezahl mit deinem PayPal-Konto'),
                  value: 'paypal',
                  groupValue: _selectedPaymentMethod,
                  onChanged: _isProcessing
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedPaymentMethod = value);
                          }
                        },
                ),
              ),
              const SizedBox(height: 24),

              // Sicherheits-Hinweis
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Deine Zahlungsdaten sind sicher verschlüsselt',
                        style: TextStyle(color: Colors.blue[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Terms & Conditions
              CheckboxListTile(
                title: const Text('Bedingungen akzeptieren'),
                subtitle: const Text('Ich akzeptiere die Zahlungsbedingungen'),
                value: _agreeToTerms,
                onChanged: _isProcessing
                    ? null
                    : (value) {
                        setState(() => _agreeToTerms = value ?? false);
                      },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              // Pay Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (!_agreeToTerms || _isProcessing)
                      ? null
                      : _processPayment,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.payment),
                  label: Text(
                    _isProcessing
                        ? 'Wird verarbeitet...'
                        : '${widget.amount.toStringAsFixed(2)} € zahlen',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
