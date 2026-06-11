import 'dart:math' as Math;
import 'package:trusted_circle_demo/models/meetup_event.dart';
import 'package:trusted_circle_demo/models/event_participation.dart';

class EventService {
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

  // Hole alle Events
  Future<List<MeetupEvent>> getEvents() async {
    await Future.delayed(Duration(milliseconds: 500)); // Simuliere API-Latenz
    return _mockEvents;
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

      if (ageGroups != null && ageGroups.isNotEmpty) {
        final hasMatchingAgeGroup =
            event.ageGroups.any((eg) => ageGroups.contains(eg));
        if (!hasMatchingAgeGroup) return false;
      }

      return event.status == EventStatus.active;
    }).toList();
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
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        Math.cos((lat2 - lat1) * p) / 2 +
        Math.cos(lat1 * p) *
            Math.cos(lat2 * p) *
            (1 - Math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * Math.asin(Math.sqrt(a)); // 2 * R; R = 6371 km
  }
}
