import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/models/meetup_event.dart';
import 'package:trusted_circle_demo/logic/event_service.dart';
import 'package:trusted_circle_demo/logic/payment_service.dart';
import 'package:trusted_circle_demo/ui/payment_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _maxParticipantsController;

  EventCategory _selectedCategory = EventCategory.socialGathering;
  List<AgeGroup> _selectedAgeGroups = [];
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  double _latitude = 52.5200;
  double _longitude = 13.4050;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController(text: 'Berlin, Deutschland');
    _maxParticipantsController = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _toggleAgeGroup(AgeGroup ageGroup) {
    setState(() {
      if (_selectedAgeGroups.contains(ageGroup)) {
        _selectedAgeGroups.remove(ageGroup);
      } else {
        _selectedAgeGroups.add(ageGroup);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAgeGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte mindestens eine Altersgruppe auswählen')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Erstelle Event-Objekt
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final event = MeetupEvent(
        id: 'event_${DateTime.now().millisecondsSinceEpoch}',
        hosterId: 'host_demo_001',
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        ageGroups: _selectedAgeGroups,
        location: _locationController.text,
        latitude: _latitude,
        longitude: _longitude,
        eventDate: eventDateTime,
        createdAt: DateTime.now(),
        maxParticipants: int.parse(_maxParticipantsController.text),
        photoUrl: 'https://via.placeholder.com/300x200?text=${_titleController.text}',
        status: EventStatus.active,
        price: 2.99, // Gebühr für das Veröffentlichen
      );

      // Gehe zu Payment-Screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              event: event,
              amount: event.price ?? 2.99,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivität erstellen'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titel
              Text(
                'Grundinformationen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel der Aktivität',
                  hintText: 'z.B. Spielplatz Treffen',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Bitte einen Titel eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  hintText: 'Beschreibe deine Aktivität...',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Bitte eine Beschreibung eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kategorie
              DropdownButtonFormField<EventCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategorie',
                  prefixIcon: Icon(Icons.category),
                ),
                items: EventCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(_getCategoryLabel(category)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Altersgruppen
              Text(
                'Zielgruppe (Altersgruppen)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AgeGroup.values
                    .map(
                      (ageGroup) => FilterChip(
                        label: Text(_getAgeGroupLabel(ageGroup)),
                        selected: _selectedAgeGroups.contains(ageGroup),
                        onSelected: (_) => _toggleAgeGroup(ageGroup),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Datum & Zeit
              Text(
                'Termin',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                      ),
                      onTap: _selectDate,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                      ),
                      onTap: _selectTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ort
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Treffpunkt',
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'z.B. Zentralpark, Berlin',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Bitte einen Ort eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Max Teilnehmer
              TextFormField(
                controller: _maxParticipantsController,
                decoration: const InputDecoration(
                  labelText: 'Maximale Teilnehmerzahl',
                  prefixIcon: Icon(Icons.people),
                  hintText: '10',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Bitte eine Zahl eingeben';
                  }
                  if (int.tryParse(value!) == null) {
                    return 'Bitte nur Zahlen eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Gebühr Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Diese Aktivität wird mit 2,99 € veröffentlicht',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Zur Zahlung'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(EventCategory category) {
    const labels = {
      EventCategory.sports: 'Sport',
      EventCategory.outdoor: 'Outdoor',
      EventCategory.education: 'Bildung',
      EventCategory.arts: 'Kunst',
      EventCategory.socialGathering: 'Treffen',
      EventCategory.other: 'Sonstiges',
    };
    return labels[category] ?? 'Sonstiges';
  }

  String _getAgeGroupLabel(AgeGroup ageGroup) {
    const labels = {
      AgeGroup.infant: 'Baby (0-1)',
      AgeGroup.toddler: 'Kleinkind (1-3)',
      AgeGroup.preschool: 'Vorschule (3-5)',
      AgeGroup.elementary: 'Grundschule (6-12)',
      AgeGroup.teenager: 'Teenager (13+)',
      AgeGroup.mixed: 'Altersgemischt',
    };
    return labels[ageGroup] ?? '';
  }
}
