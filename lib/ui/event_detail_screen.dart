import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/models/meetup_event.dart';
import 'package:trusted_circle_demo/logic/participation_service.dart';
import 'package:trusted_circle_demo/ui/meetup_chat_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final MeetupEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _participationService = ParticipationService();
  bool _hasRequested = false;
  bool _isApproved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkParticipationStatus();
  }

  Future<void> _checkParticipationStatus() async {
    // In echtem System würde hier der aktuelle User-ID verwendet
    const userId = 'user_demo_001';
    
    final participation = await _participationService.getParticipationByUserAndEvent(
      userId: userId,
      eventId: widget.event.id,
    );

    setState(() {
      _isApproved = participation != null;
      _hasRequested = true;
    });
  }

  Future<void> _requestParticipation() async {
    const userId = 'user_demo_001';

    setState(() => _isLoading = true);

    try {
      await _participationService.requestParticipation(
        eventId: widget.event.id,
        userId: userId,
      );

      setState(() {
        _hasRequested = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teilnahmeanfrage gesendet!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titelbild
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.event.photoUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getCategoryLabel(widget.event.category),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titel
                  Text(
                    widget.event.title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Datum und Uhrzeit
                  _buildInfoRow(
                    Icons.calendar_today,
                    '${widget.event.eventDate.day}.${widget.event.eventDate.month}.${widget.event.eventDate.year}',
                    '${widget.event.eventDate.hour.toString().padLeft(2, '0')}:${widget.event.eventDate.minute.toString().padLeft(2, '0')} Uhr',
                  ),
                  const SizedBox(height: 12),

                  // Ort
                  _buildInfoRow(
                    Icons.location_on,
                    widget.event.location,
                    '${widget.event.latitude.toStringAsFixed(3)}, ${widget.event.longitude.toStringAsFixed(3)}',
                  ),
                  const SizedBox(height: 12),

                  // Teilnehmer
                  _buildInfoRow(
                    Icons.people,
                    '${widget.event.currentParticipants}/${widget.event.maxParticipants} Teilnehmer',
                    widget.event.spotsAvailable > 0
                        ? '${widget.event.spotsAvailable} Plätze verfügbar'
                        : 'Vollständig ausgebucht',
                  ),
                  const SizedBox(height: 12),

                  // Altersgruppen
                  _buildAgeGroupChips(),
                  const SizedBox(height: 20),

                  // Beschreibung
                  Text(
                    'Beschreibung',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (_isApproved)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Du bist angemeldet!',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MeetupChatScreen(event: widget.event),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat),
                            label: const Text('Zum Chat'),
                          ),
                        ),
                      ],
                    )
                  else if (_hasRequested)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.amber[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Anfrage ausstehend',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.event.isFull ? null : _requestParticipation,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.person_add),
                        label: const Text('Teilnahme anfragen'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgeGroupChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Altersgruppen',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.event.ageGroups
              .map(
                (ageGroup) => Chip(
                  label: Text(_getAgeGroupLabel(ageGroup)),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
              )
              .toList(),
        ),
      ],
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
