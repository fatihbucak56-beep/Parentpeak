import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/logic/auth_service.dart';
import 'package:trusted_circle_demo/logic/event_service.dart';
import 'package:trusted_circle_demo/logic/family_circle_service.dart';
import 'package:trusted_circle_demo/models/event_invitation.dart';
import 'package:trusted_circle_demo/models/family_contact.dart';
import 'package:trusted_circle_demo/models/meetup_event.dart';

class EventInvitationsScreen extends StatefulWidget {
  final String? initialInviteInput;

  const EventInvitationsScreen({super.key, this.initialInviteInput});

  @override
  State<EventInvitationsScreen> createState() => _EventInvitationsScreenState();
}

class _EventInvitationsScreenState extends State<EventInvitationsScreen> {
  final _eventService = EventService();
  final _familyCircleService = FamilyCircleService.instance;
  final _codeCtrl = TextEditingController();

  List<EventInvitation> _invitations = [];
  Map<String, MeetupEvent> _eventsById = {};
  List<MeetupEvent> _hostedInviteEvents = [];
  Map<String, List<EventInvitation>> _acceptedByEvent = {};
  Map<String, FamilyContact> _contactsById = {};
  bool _isLoading = true;

  String get _currentUserId =>
      AuthService.instance.currentUser?.uid ?? 'host_demo_001';

  @override
  void initState() {
    super.initState();
    final initialInput = widget.initialInviteInput?.trim();
    if (initialInput != null && initialInput.isNotEmpty) {
      _codeCtrl.text = initialInput;
    }
    _load();
    if (initialInput != null && initialInput.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _joinByCode();
      });
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final invites = await _eventService.getInvitationsForUser(_currentUserId);
    final hosted = await _eventService.getHostedInviteOnlyEvents(_currentUserId);
    final contacts =
        await _familyCircleService.getConnectedContacts(userId: _currentUserId);

    final map = <String, MeetupEvent>{};
    for (final i in invites) {
      final event = await _eventService.getEventById(i.eventId);
      if (event != null) {
        map[i.eventId] = event;
      }
    }

    for (final event in hosted) {
      map[event.id] = event;
    }

    final acceptedByEvent = <String, List<EventInvitation>>{};
    for (final event in hosted) {
      acceptedByEvent[event.id] =
          await _eventService.getAcceptedInvitationsForEvent(event.id);
    }

    if (!mounted) return;
    setState(() {
      _invitations = invites;
      _eventsById = map;
      _hostedInviteEvents = hosted;
      _acceptedByEvent = acceptedByEvent;
      _contactsById = {for (final c in contacts) c.userId: c};
      _isLoading = false;
    });
  }

  Future<void> _respond(EventInvitation invite, bool accept) async {
    await _eventService.respondToInvitation(
      invitationId: invite.id,
      accept: accept,
    );

    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accept ? 'Zusage gespeichert.' : 'Absage gespeichert.'),
      ),
    );
  }

  Future<void> _joinByCode() async {
    final input = _codeCtrl.text.trim();
    if (input.isEmpty) return;

    final invite = await _eventService.joinEventByInviteCode(
      code: input,
      userId: _currentUserId,
    );

    if (!mounted) return;

    if (invite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _eventService.isInviteInputExpired(input)
                ? 'Dieser Code ist abgelaufen.'
                : 'Code oder Link konnte nicht gefunden werden.',
          ),
        ),
      );
      return;
    }

    _codeCtrl.clear();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Du bist jetzt dabei.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _invitations
        .where((i) => i.status == EventInvitationStatus.pending)
        .toList();
    final accepted = _invitations
        .where((i) => i.status == EventInvitationStatus.accepted)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einladungen'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deine Einladungen',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Gemeinsam loslegen.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _CountPill(
                                icon: Icons.mark_email_unread_rounded,
                                label: 'Ausstehend',
                                value: pending.length.toString(),
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CountPill(
                                icon: Icons.check_circle_outline_rounded,
                                label: 'Zugesagt',
                                value: accepted.length.toString(),
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CountPill(
                                icon: Icons.celebration_rounded,
                                label: 'Meine Events',
                                value: _hostedInviteEvents.length.toString(),
                                color: const Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCE4FF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mit Code starten',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codeCtrl,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Code oder Link einfügen',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _joinByCode,
                              child: const Text('Starten'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Ausstehend',
                    subtitle: pending.isEmpty
                        ? 'Nichts offen'
                        : '${pending.length} offen',
                  ),
                  const SizedBox(height: 8),
                  if (pending.isEmpty)
                    const _EmptyTile(
                      icon: Icons.inbox_rounded,
                      text: 'Gerade ist alles beantwortet.',
                    )
                  else
                    ...pending.map(
                      (i) {
                        final event = _eventsById[i.eventId];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PendingInviteRow(
                            title: event?.title ?? 'Event',
                            subtitle: event?.location ?? 'Unbekannter Ort',
                            onDecline: () => _respond(i, false),
                            onAccept: () => _respond(i, true),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Zugesagt',
                    subtitle: accepted.isEmpty
                        ? 'Noch keine'
                        : '${accepted.length} aktiv',
                  ),
                  const SizedBox(height: 8),
                  if (accepted.isEmpty)
                    const _EmptyTile(
                      icon: Icons.check_circle_outline_rounded,
                      text: 'Noch keine aktiven Zusagen.',
                    )
                  else
                    ...accepted.map(
                      (i) {
                        final event = _eventsById[i.eventId];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SimpleInviteRow(
                            icon: Icons.check_circle_outline_rounded,
                            title: event?.title ?? 'Event',
                            subtitle: event?.location ?? 'Unbekannter Ort',
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Als Gastgeber',
                    subtitle: _hostedInviteEvents.isEmpty
                        ? 'Keine Events'
                        : '${_hostedInviteEvents.length} Events',
                  ),
                  const SizedBox(height: 8),
                  if (_hostedInviteEvents.isEmpty)
                    const _EmptyTile(
                      icon: Icons.celebration_outlined,
                      text: 'Keine eigenen privaten Events vorhanden.',
                    )
                  else
                    ..._hostedInviteEvents.map((event) {
                      final acceptedList = _acceptedByEvent[event.id] ?? const [];
                      final code = _eventService.getInviteCodeForEvent(event.id) ?? '-';
                      final expiry = _eventService.getInviteExpiryForEvent(event.id);
                      final expired = _eventService.isInviteCodeExpired(event.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text('Code: $code'),
                            if (expiry != null)
                              Text(
                                'Gültig bis: ${expiry.day.toString().padLeft(2, '0')}.${expiry.month.toString().padLeft(2, '0')}.${expiry.year}${expired ? ' (abgelaufen)' : ''}',
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Zusagen (${acceptedList.length})',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            if (acceptedList.isEmpty)
                              const Text(
                                'Noch keine Zusagen.',
                                style: TextStyle(color: Colors.black54),
                              )
                            else
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: acceptedList.map((invite) {
                                  final contact = _contactsById[invite.invitedUserId];
                                  return Chip(
                                    label: Text(
                                      contact?.displayName ?? invite.invitedUserId,
                                    ),
                                    avatar: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 16,
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
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
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingInviteRow extends StatelessWidget {
  const _PendingInviteRow({
    required this.title,
    required this.subtitle,
    required this.onDecline,
    required this.onAccept,
  });

  final String title;
  final String subtitle;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  child: const Text('Absagen'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  child: const Text('Zusagen'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleInviteRow extends StatelessWidget {
  const _SimpleInviteRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _EmptyTile extends StatelessWidget {
  const _EmptyTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
