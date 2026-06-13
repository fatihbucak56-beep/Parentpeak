import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/logic/participation_service.dart';
import 'package:trusted_circle_demo/models/meetup_event.dart';
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
    const userId = 'user_demo_001';
    final participation = await _participationService.getParticipationByUserAndEvent(
      userId: userId,
      eventId: widget.event.id,
    );

    if (!mounted) return;
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

      if (!mounted) return;
      setState(() {
        _hasRequested = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teilnahmeanfrage gesendet!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event-Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 220,
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
                        color: Colors.white.withValues(alpha: 0.95),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _MetaPill(
                                icon: Icons.people_outline_rounded,
                                label: 'Plätze',
                                value:
                                    '${widget.event.currentParticipants}/${widget.event.maxParticipants}',
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MetaPill(
                                icon: Icons.schedule_rounded,
                                label: 'Status',
                                value: widget.event.isFull ? 'Voll' : 'Offen',
                                color: widget.event.isFull
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildInfoTile(
                    icon: Icons.calendar_today,
                    title:
                        '${widget.event.eventDate.day}.${widget.event.eventDate.month}.${widget.event.eventDate.year}',
                    subtitle:
                        '${widget.event.eventDate.hour.toString().padLeft(2, '0')}:${widget.event.eventDate.minute.toString().padLeft(2, '0')} Uhr',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoTile(
                    icon: Icons.location_on,
                    title: widget.event.location,
                    subtitle:
                        '${widget.event.latitude.toStringAsFixed(3)}, ${widget.event.longitude.toStringAsFixed(3)}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoTile(
                    icon: Icons.people,
                    title:
                        '${widget.event.currentParticipants}/${widget.event.maxParticipants} Teilnehmer',
                    subtitle: widget.event.spotsAvailable > 0
                        ? '${widget.event.spotsAvailable} Plätze verfügbar'
                        : 'Vollständig ausgebucht',
                  ),
                  const SizedBox(height: 12),
                  _buildAgeGroupChips(),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Beschreibung',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.event.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isApproved)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBanner(
                          icon: Icons.check_circle,
                          text: 'Du bist angemeldet!',
                          bgColor: const Color(0xFFDCFCE7),
                          textColor: const Color(0xFF166534),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MeetupChatScreen(
                                    event: widget.event,
                                  ),
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
                    _buildStatusBanner(
                      icon: Icons.schedule,
                      text: 'Anfrage ausstehend',
                      bgColor: const Color(0xFFFEF3C7),
                      textColor: const Color(0xFF92400E),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
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

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeGroupChips() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Altersgruppen',
          style: theme.textTheme.titleSmall?.copyWith(
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
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
