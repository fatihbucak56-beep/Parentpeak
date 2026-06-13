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
        content: Text(accept ? 'Einladung angenommen' : 'Einladung abgelehnt'),
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
                ? 'Dieser Einladungscode ist abgelaufen.'
                : 'Ungültiger Einladungscode oder Link.',
          ),
        ),
      );
      return;
    }

    _codeCtrl.clear();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event per Code hinzugefügt.')),
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
        title: const Text('Event-Einladungen'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Einladungscode eingeben',
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
                                      'z. B. PP-AB12 oder parentpeak://invite?code=PP-AB12',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _joinByCode,
                              child: const Text('Beitreten'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Offene Einladungen',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (pending.isEmpty)
                    const Text('Keine offenen Einladungen.')
                  else
                    ...pending.map(
                      (i) {
                        final event = _eventsById[i.eventId];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(event?.title ?? 'Event'),
                            subtitle: Text(event?.location ?? 'Unbekannter Ort'),
                            trailing: Wrap(
                              spacing: 6,
                              children: [
                                IconButton(
                                  onPressed: () => _respond(i, false),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                                FilledButton(
                                  onPressed: () => _respond(i, true),
                                  child: const Text('Annehmen'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Angenommene Einladungen',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (accepted.isEmpty)
                    const Text('Noch keine angenommenen Einladungen.')
                  else
                    ...accepted.map(
                      (i) {
                        final event = _eventsById[i.eventId];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.check_circle_outline_rounded),
                            title: Text(event?.title ?? 'Event'),
                            subtitle: Text(event?.location ?? 'Unbekannter Ort'),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Als Gastgeber: Zusagen',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (_hostedInviteEvents.isEmpty)
                    const Text('Keine eigenen Invite-Only-Events vorhanden.')
                  else
                    ..._hostedInviteEvents.map((event) {
                      final acceptedList = _acceptedByEvent[event.id] ?? const [];
                      final code = _eventService.getInviteCodeForEvent(event.id) ?? '-';
                      final expiry = _eventService.getInviteExpiryForEvent(event.id);
                      final expired = _eventService.isInviteCodeExpired(event.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
