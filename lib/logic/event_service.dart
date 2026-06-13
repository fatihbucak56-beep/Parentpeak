import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:trusted_circle_demo/logic/family_circle_service.dart';
import 'package:trusted_circle_demo/models/event_invitation.dart';
import 'package:trusted_circle_demo/models/meetup_event.dart';
import 'package:trusted_circle_demo/models/event_participation.dart';

class EventService {
  final _familyCircleService = FamilyCircleService.instance;

  // Mock data - in production würde das von Firebase/Backend kommen
  static final List<MeetupEvent> _mockEvents = [
    MeetupEvent(
      id: '1',
      hosterId: 'host_001',
      title: 'Spielplatz Treffen',
      description: 'Treffen für Kinder zum gemeinsamen Spielen auf dem Spielplatz',
      category: EventCategory.socialGathering,
      ageGroups: [AgeGroup.toddler, AgeGroup.preschool],
      location: 'Zentralpark, Berlin',
      latitude: 52.5200,
      longitude: 13.4050,
      eventDate: DateTime.now().add(Duration(days: 3)),
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      paymentDate: DateTime.now().subtract(Duration(hours: 2)),
      maxParticipants: 15,
      currentParticipants: 5,
      photoUrl: 'https://via.placeholder.com/300x200?text=Playground',
      status: EventStatus.active,
    ),
    MeetupEvent(
      id: '2',
      hosterId: 'host_002',
      title: 'Kinderturnen im Park',
      description: 'Altersgerechtes Turntraining für kleine Sportler',
      category: EventCategory.sports,
      ageGroups: [AgeGroup.elementary],
      location: 'Sportplatz Mitte, Berlin',
      latitude: 52.5300,
      longitude: 13.4150,
      eventDate: DateTime.now().add(Duration(days: 5)),
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      paymentDate: DateTime.now().subtract(Duration(hours: 1)),
      maxParticipants: 20,
      currentParticipants: 12,
      photoUrl: 'https://via.placeholder.com/300x200?text=Sports',
      status: EventStatus.active,
    ),
  ];

  static final List<EventParticipation> _mockParticipations = [];
  static final List<EventInvitation> _mockInvitations = [];
  static final Map<String, String> _eventInviteCodes = {};
  static final Map<String, DateTime> _eventInviteExpiresAt = {};

  // Hole alle Events
  Future<List<MeetupEvent>> getEvents() async {
    await Future.delayed(Duration(milliseconds: 500)); // Simuliere API-Latenz
    return _mockEvents.where((e) => e.status == EventStatus.active).toList();
  }

  /// Events für den aktuellen Nutzer mit Sichtbarkeits- und Standortregeln.
  Future<List<MeetupEvent>> getDiscoverableEventsForUser({
    required String viewerUserId,
    required double viewerLatitude,
    required double viewerLongitude,
    List<AgeGroup>? ageGroups,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));

    final visible = _mockEvents.where((event) {
      if (event.status != EventStatus.active) return false;

      final canSee = _canUserSeeEvent(
        event: event,
        viewerUserId: viewerUserId,
        viewerLatitude: viewerLatitude,
        viewerLongitude: viewerLongitude,
      );
      if (!canSee) return false;

      if (ageGroups != null && ageGroups.isNotEmpty) {
        final hasMatchingAgeGroup =
            event.ageGroups.any((eg) => ageGroups.contains(eg));
        if (!hasMatchingAgeGroup) return false;
      }

      return true;
    }).toList();

    return visible;
  }

  Future<List<EventInvitation>> getInvitationsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 220));
    return _mockInvitations.where((i) => i.invitedUserId == userId).toList();
  }

  Future<void> respondToInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    await Future.delayed(const Duration(milliseconds: 220));

    final index = _mockInvitations.indexWhere((i) => i.id == invitationId);
    if (index == -1) return;

    final invite = _mockInvitations[index];
    _mockInvitations[index] = EventInvitation(
      id: invite.id,
      eventId: invite.eventId,
      hostUserId: invite.hostUserId,
      invitedUserId: invite.invitedUserId,
      createdAt: invite.createdAt,
      status: accept
          ? EventInvitationStatus.accepted
          : EventInvitationStatus.declined,
    );
  }

  String? getInviteCodeForEvent(String eventId) => _eventInviteCodes[eventId];

  String? getInviteLinkForEvent(String eventId) {
    final code = _eventInviteCodes[eventId];
    if (code == null) return null;
    final encoded = Uri.encodeComponent(code);
    return 'parentpeak://invite?code=$encoded';
  }

  DateTime? getInviteExpiryForEvent(String eventId) => _eventInviteExpiresAt[eventId];

  bool isInviteCodeExpired(String eventId) {
    final expiry = _eventInviteExpiresAt[eventId];
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  bool isInviteInputExpired(String input) {
    final normalizedInput = _extractCodeFromInput(input);
    if (normalizedInput.isEmpty) return false;

    String? eventId;
    for (final entry in _eventInviteCodes.entries) {
      if (entry.value.toUpperCase() == normalizedInput.toUpperCase()) {
        eventId = entry.key;
        break;
      }
    }

    if (eventId == null) return false;
    return isInviteCodeExpired(eventId);
  }

  Future<EventInvitation?> joinEventByInviteCode({
    required String code,
    required String userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 260));

    final normalizedInput = _extractCodeFromInput(code);
    if (normalizedInput.isEmpty) return null;

    String? targetEventId;
    for (final entry in _eventInviteCodes.entries) {
      if (entry.value.toUpperCase() == normalizedInput.toUpperCase()) {
        targetEventId = entry.key;
        break;
      }
    }

    if (targetEventId == null) return null;

    if (isInviteCodeExpired(targetEventId)) {
      return null;
    }

    final event = await getEventById(targetEventId);
    if (event == null) return null;

    final existing = _mockInvitations.where(
      (i) => i.eventId == targetEventId && i.invitedUserId == userId,
    );

    if (existing.isNotEmpty) {
      final existingInvite = existing.first;
      await respondToInvitation(invitationId: existingInvite.id, accept: true);
      return _mockInvitations.firstWhere((i) => i.id == existingInvite.id);
    }

    final invite = EventInvitation(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}_$userId',
      eventId: targetEventId,
      hostUserId: event.hosterId,
      invitedUserId: userId,
      createdAt: DateTime.now(),
      status: EventInvitationStatus.accepted,
    );
    _mockInvitations.add(invite);
    return invite;
  }

  // Hole Events nach Entfernung gefiltert
  Future<List<MeetupEvent>> getNearbyEvents({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    List<AgeGroup>? ageGroups,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));

    return _mockEvents.where((event) {
      // Berechne Entfernung (vereinfachte Haversine-Formel)
      final distance = _calculateDistance(
        latitude,
        longitude,
        event.latitude,
        event.longitude,
      );

      if (distance > radiusKm) return false;

      if (event.visibility == EventVisibility.privateOnly ||
          event.visibility == EventVisibility.familyCircle ||
          event.visibility == EventVisibility.inviteOnly) {
        return false;
      }

      final shareRadius = event.shareRadiusKm ?? radiusKm;
      if (distance > shareRadius) return false;

      if (ageGroups != null && ageGroups.isNotEmpty) {
        final hasMatchingAgeGroup =
            event.ageGroups.any((eg) => ageGroups.contains(eg));
        if (!hasMatchingAgeGroup) return false;
      }

      return event.status == EventStatus.active;
    }).toList();
  }

  bool _canUserSeeEvent({
    required MeetupEvent event,
    required String viewerUserId,
    required double viewerLatitude,
    required double viewerLongitude,
  }) {
    // Eigene Events sind immer sichtbar (auch private).
    if (event.hosterId == viewerUserId) return true;

    if (event.visibility == EventVisibility.privateOnly) {
      return false;
    }

    if (event.visibility == EventVisibility.familyCircle) {
      return _familyCircleService.areUsersConnected(
        userA: event.hosterId,
        userB: viewerUserId,
      );
    }

    if (event.visibility == EventVisibility.inviteOnly) {
      final invite = _mockInvitations.where((i) =>
          i.eventId == event.id &&
          i.invitedUserId == viewerUserId &&
          i.status == EventInvitationStatus.accepted);
      return invite.isNotEmpty;
    }

    // Öffentlich: nur im definierten Radius teilen.
    final distance = _calculateDistance(
      viewerLatitude,
      viewerLongitude,
      event.latitude,
      event.longitude,
    );
    final shareRadius = event.shareRadiusKm ?? 25;
    return distance <= shareRadius;
  }

  // Hole Event Details
  Future<MeetupEvent?> getEventById(String eventId) async {
    await Future.delayed(Duration(milliseconds: 300));
    try {
      return _mockEvents.firstWhere((e) => e.id == eventId);
    } catch (e) {
      return null;
    }
  }

  // Erstelle ein neues Event
  Future<MeetupEvent> createEvent(MeetupEvent event) async {
    await Future.delayed(Duration(milliseconds: 800));
    _mockEvents.add(event);

    if (event.visibility == EventVisibility.inviteOnly &&
        event.invitedUserIds.isNotEmpty) {
      for (final userId in event.invitedUserIds) {
        _mockInvitations.add(
          EventInvitation(
            id: 'inv_${event.id}_$userId',
            eventId: event.id,
            hostUserId: event.hosterId,
            invitedUserId: userId,
            createdAt: DateTime.now(),
          ),
        );
      }

      final code = _generateInviteCode(event.id);
      _eventInviteCodes[event.id] = code;
      _eventInviteExpiresAt[event.id] = event.inviteCodeExpiresAt ??
          DateTime.now().add(const Duration(days: 14));
      debugPrint('Invite code for ${event.id}: $code');
    }

    return event;
  }

  // Lösche ein Event
  Future<bool> deleteEvent(String eventId) async {
    await Future.delayed(Duration(milliseconds: 500));
    _mockEvents.removeWhere((e) => e.id == eventId);
    return true;
  }

  // Hole Partizipationen für einen User
  Future<List<EventParticipation>> getUserParticipations(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _mockParticipations.where((p) => p.userId == userId).toList();
  }

  // Hole ausstehende Anfragen für einen Host
  Future<List<EventParticipation>> getPendingRequestsForHost(
      String hosterId) async {
    await Future.delayed(Duration(milliseconds: 300));

    final hostEvents = _mockEvents.where((e) => e.hosterId == hosterId).toList();
    final hostEventIds = hostEvents.map((e) => e.id).toList();

    return _mockParticipations
        .where((p) =>
            hostEventIds.contains(p.eventId) && p.status == ParticipationStatus.pending)
        .toList();
  }

  // Entfernung berechnen (in km)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // math.pi / 180
    final a = 0.5 -
      math.cos((lat2 - lat1) * p) / 2 +
      math.cos(lat1 * p) *
        math.cos(lat2 * p) *
        (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  String _generateInviteCode(String eventId) {
    final suffix = eventId.length >= 4
        ? eventId.substring(eventId.length - 4)
        : eventId;
    return 'PP-${suffix.toUpperCase()}';
  }

  String _extractCodeFromInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    final asUri = Uri.tryParse(trimmed);
    if (asUri != null && asUri.queryParameters.containsKey('code')) {
      return (asUri.queryParameters['code'] ?? '').trim();
    }

    return trimmed;
  }

  Future<List<MeetupEvent>> getHostedInviteOnlyEvents(String hostUserId) async {
    await Future.delayed(const Duration(milliseconds: 220));
    return _mockEvents
        .where((e) =>
            e.hosterId == hostUserId &&
            e.status == EventStatus.active &&
            e.visibility == EventVisibility.inviteOnly)
        .toList();
  }

  Future<List<EventInvitation>> getAcceptedInvitationsForEvent(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 220));
    return _mockInvitations
        .where((i) =>
            i.eventId == eventId && i.status == EventInvitationStatus.accepted)
        .toList();
  }
}
