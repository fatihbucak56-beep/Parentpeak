import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/logic/family_circle_service.dart';
import 'package:trusted_circle_demo/models/family_contact.dart';
import 'package:trusted_circle_demo/models/meetup_event.dart';
import 'package:trusted_circle_demo/logic/auth_service.dart';
import 'package:trusted_circle_demo/ui/family_circle_screen.dart';
import 'package:trusted_circle_demo/ui/payment_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyCircleService = FamilyCircleService.instance;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _maxParticipantsController;

  EventCategory _selectedCategory = EventCategory.socialGathering;
  final List<AgeGroup> _selectedAgeGroups = [];
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  final double _latitude = 52.5200;
  final double _longitude = 13.4050;
  EventVisibility _visibility = EventVisibility.publicNearby;
  double _shareRadiusKm = 25;
  List<FamilyContact> _familyContacts = [];
  final Set<String> _selectedInvitees = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController(text: 'Berlin, Deutschland');
    _maxParticipantsController = TextEditingController(text: '10');
    _loadFamilyContacts();
  }

  Future<void> _loadFamilyContacts() async {
    final userId = AuthService.instance.currentUser?.uid ?? 'host_demo_001';
    final contacts = await _familyCircleService.getConnectedContacts(userId: userId);
    if (!mounted) return;
    setState(() {
      _familyContacts = contacts;
    });
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

  void _toggleInvitee(String userId) {
    setState(() {
      if (_selectedInvitees.contains(userId)) {
        _selectedInvitees.remove(userId);
      } else {
        _selectedInvitees.add(userId);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAgeGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bitte mindestens eine Altersgruppe auswählen')),
      );
      return;
    }

    if (_visibility == EventVisibility.inviteOnly && _selectedInvitees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte mindestens einen Kontakt einladen.'),
        ),
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
        hosterId: AuthService.instance.currentUser?.uid ?? 'host_demo_001',
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
        photoUrl:
            'https://via.placeholder.com/300x200?text=${_titleController.text}',
        status: EventStatus.active,
        price: 2.99, // Gebühr für das Veröffentlichen
        visibility: _visibility,
        shareRadiusKm:
            _visibility == EventVisibility.publicNearby ? _shareRadiusKm : null,
        invitedUserIds:
          _visibility == EventVisibility.inviteOnly ? _selectedInvitees.toList() : const [],
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivität veröffentlichen'),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5FBFA), Color(0xFFF9FAFD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Erstelle ein Event in wenigen Schritten und entscheide, ob es privat oder öffentlich geteilt wird.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Titel
                Text(
                  'Grundinformationen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titel der Aktivität',
                    hintText: 'z. B. Spielplatz-Treffen',
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

                // Sichtbarkeit & Standortverteilung
                Text(
                  'Sichtbarkeit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                RadioListTile<EventVisibility>(
                  value: EventVisibility.publicNearby,
                  groupValue: _visibility,
                  title: const Text('Öffentlich (in deiner Nähe sichtbar)'),
                  subtitle: const Text(
                      'Andere Eltern sehen dein Event im Standort-Radius.'),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _visibility = value);
                  },
                ),
                RadioListTile<EventVisibility>(
                  value: EventVisibility.familyCircle,
                  groupValue: _visibility,
                  title: const Text('Familienkreis (für deine Kontakte sichtbar)'),
                  subtitle: const Text(
                      'Nur verbundene Eltern aus deinem Familienkreis sehen das Event.'),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _visibility = value);
                  },
                ),
                RadioListTile<EventVisibility>(
                  value: EventVisibility.inviteOnly,
                  groupValue: _visibility,
                  title: const Text('Nur eingeladen (individuelle Einladungen)'),
                  subtitle: const Text(
                      'Nur ausgewählte Kontakte sehen und erhalten die Einladung.'),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _visibility = value);
                  },
                ),
                RadioListTile<EventVisibility>(
                  value: EventVisibility.privateOnly,
                  groupValue: _visibility,
                  title: const Text('Nur ich (nicht geteilt)'),
                  subtitle: const Text(
                      'Das Event bleibt nur in deinem Bereich sichtbar.'),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _visibility = value);
                  },
                ),

                if (_visibility == EventVisibility.publicNearby) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Öffentlich teilen im Umkreis',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${_shareRadiusKm.toStringAsFixed(0)} km',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Slider(
                    value: _shareRadiusKm,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    label: '${_shareRadiusKm.toStringAsFixed(0)} km',
                    onChanged: (v) => setState(() => _shareRadiusKm = v),
                  ),
                ],

                if (_visibility == EventVisibility.inviteOnly) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Kontakte auswählen',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_familyContacts.isEmpty)
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Noch keine Kontakte im Familienkreis. Bitte zuerst Kontakte verbinden.',
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FamilyCircleScreen(),
                              ),
                            ).then((_) => _loadFamilyContacts());
                          },
                          child: const Text('Öffnen'),
                        ),
                      ],
                    )
                  else
                    ..._familyContacts.map(
                      (contact) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: _selectedInvitees.contains(contact.userId),
                        title: Text(contact.displayName),
                        subtitle:
                            Text('${contact.city} · ${contact.childrenSummary}'),
                        onChanged: (_) => _toggleInvitee(contact.userId),
                      ),
                    ),
                ],

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
                        fontWeight: FontWeight.w700,
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
                        fontWeight: FontWeight.w700,
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
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Color(0xFF047857)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Veröffentlichungsgebühr: 2,99 € pro Event',
                          style: const TextStyle(color: Color(0xFF047857)),
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
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Weiter zur Zahlung'),
                  ),
                ),
              ],
            ),
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
